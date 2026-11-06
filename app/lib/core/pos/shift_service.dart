import 'dart:async';
import 'dart:convert';

import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/pos/pos_config.dart';
import 'package:cashiera/core/pos/pos_errors.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

/// Opens and closes the terminal's shift, records kas masuk / keluar, and
/// builds the X and Z reports from the terminal's own rows.
class ShiftService {
  new(this._db, {this._uuid = const Uuid()});

  final AppDatabase _db;
  final Uuid _uuid;

  Stream<ShiftRow?> watchOpen(String storeId) =>
      (_db.select(_db.localShifts)
            ..where((s) => s.storeId.equals(storeId) & s.status.equals('open')))
          .watchSingleOrNull();

  Future<ShiftRow?> openShift(String storeId) =>
      (_db.select(_db.localShifts)
            ..where((s) => s.storeId.equals(storeId) & s.status.equals('open')))
          .getSingleOrNull();

  Future<ShiftRow?> find(String id) => (_db.select(
    _db.localShifts,
  )..where((s) => s.id.equals(id))).getSingleOrNull();

  /// Shifts of this terminal, newest first.
  Stream<List<ShiftRow>> watchRecent({int limit = 30}) =>
      (_db.select(_db.localShifts)
            ..orderBy([(s) => OrderingTerm.desc(s.openedAt)])
            ..limit(limit))
          .watch();

  Future<ShiftRow> open({
    required String storeId,
    required StaffMember staff,
    required Money openingCash,
  }) async {
    if (!staff.can('shift.manage')) {
      throw const PosPermissionException('shift.manage');
    }
    return await _db.transaction(() async {
      final existing = await openShift(storeId);
      if (existing != null) return existing;
      final now = clock.now();
      final row = ShiftRow(
        id: _uuid.v7(),
        storeId: storeId,
        openedBy: staff.employeeId,
        openedByName: staff.fullName,
        openedAt: now,
        openingCash: openingCash.rupiah,
        status: 'open',
      );
      await _db.into(_db.localShifts).insert(row);
      await _db.syncQueueDao.enqueue(
        entity: 'shift',
        action: 'open',
        clientUuid: _uuid.v7(),
        payload: {
          'id': row.id,
          'store_id': storeId,
          'opened_by': staff.employeeId,
          'opened_at': now.toUtc().toIso8601String(),
          'opening_cash': openingCash.rupiah,
        },
      );
      return row;
    });
  }

  Stream<List<CashMovementRow>> watchMovements(String shiftId) =>
      (_db.select(_db.localCashMovements)
            ..where((c) => c.shiftId.equals(shiftId))
            ..orderBy([(c) => OrderingTerm.desc(c.occurredAt)]))
          .watch();

  /// Kas masuk ([isIn]) or kas keluar. A cash out can't take more than the
  /// drawer should hold.
  Future<CashMovementRow> cashMovement({
    required ShiftRow shift,
    required StaffMember staff,
    required bool isIn,
    required Money amount,
    required String reason,
    required PosConfig config,
  }) async {
    if (!staff.can('shift.cash_movement')) {
      throw const PosPermissionException('shift.cash_movement');
    }
    if (amount.rupiah <= 0) throw ArgumentError.value(amount, 'amount');
    final why = reason.trim();
    if (why.length < 3) throw const PosStateException('reason_required');
    return await _db.transaction(() async {
      final current = await find(shift.id);
      if (current == null || current.status != 'open') {
        throw const PosStateException('shift_closed');
      }
      if (!isIn) {
        final available = (await report(current, config: config)).cash.expected;
        if (amount.rupiah > available.rupiah) {
          throw DrawerShortException(available);
        }
      }
      final now = clock.now();
      final row = CashMovementRow(
        id: _uuid.v7(),
        shiftId: shift.id,
        movementType: isIn ? 'in' : 'out',
        amount: amount.rupiah,
        reason: why,
        employeeName: staff.fullName,
        occurredAt: now,
      );
      await _db.into(_db.localCashMovements).insert(row);
      await _db.syncQueueDao.enqueue(
        entity: 'cash_movement',
        action: 'create',
        clientUuid: _uuid.v7(),
        payload: {
          'id': row.id,
          'shift_id': shift.id,
          'movement_type': row.movementType,
          'amount': amount.rupiah,
          'reason': why,
          'employee_id': staff.employeeId,
          'occurred_at': now.toUtc().toIso8601String(),
        },
      );
      return row;
    });
  }

  /// Closes [shift] with the cash counted in the drawer. The close goes into
  /// the outbox after every sale of the shift, so the server computes the
  /// expected cash over the same rows (`client_expected_cash` is this
  /// terminal's figure). Returns the Z report.
  Future<ShiftReport> close({
    required ShiftRow shift,
    required StaffMember staff,
    required Money counted,
    required PosConfig config,
    String? deviceCode,
    String? note,
  }) async {
    if (!staff.can('shift.manage')) {
      throw const PosPermissionException('shift.manage');
    }
    if (counted.isNegative) throw ArgumentError.value(counted, 'counted');
    final cleanNote = note?.trim().isEmpty ?? true ? null : note!.trim();
    return await _db.transaction(() async {
      final current = await find(shift.id);
      if (current == null || current.status != 'open') {
        throw const PosStateException('shift_closed');
      }
      final expected = (await report(current, config: config)).cash.expected;
      final now = clock.now();
      await (_db.update(
        _db.localShifts,
      )..where((s) => s.id.equals(shift.id))).write(
        LocalShiftsCompanion(
          status: const Value('closed'),
          closedAt: Value(now),
          closedBy: Value(staff.employeeId),
          closedByName: Value(staff.fullName),
          countedCash: Value(counted.rupiah),
          expectedCash: Value(expected.rupiah),
          closeNote: Value(cleanNote),
        ),
      );
      await _db.syncQueueDao.enqueue(
        entity: 'shift',
        action: 'close',
        clientUuid: _uuid.v7(),
        payload: {
          'id': shift.id,
          'closed_by': staff.employeeId,
          'closed_at': now.toUtc().toIso8601String(),
          'counted_cash': counted.rupiah,
          'client_expected_cash': expected.rupiah,
          'note': cleanNote,
        },
      );
      return await report(
        (await find(shift.id))!,
        config: config,
        deviceCode: deviceCode,
      );
    });
  }

  /// The X (open) or Z (closed) report of [shift], from local rows.
  Future<ShiftReport> report(
    ShiftRow shift, {
    required PosConfig config,
    String? deviceCode,
  }) async {
    final orders =
        await (_db.select(_db.localOrders)..where(
              (o) =>
                  o.shiftId.equals(shift.id) | o.voidedShiftId.equals(shift.id),
            ))
            .get();
    final orderIds = [for (final o in orders) o.id];
    final refunds =
        await (_db.select(_db.localRefunds)..where(
              (r) => r.shiftId.equals(shift.id) | r.orderId.isIn(orderIds),
            ))
            .get();
    final moves = await (_db.select(
      _db.localCashMovements,
    )..where((c) => c.shiftId.equals(shift.id))).get();

    final refundedByOrder = <String, Map<String, Qty>>{};
    for (final r in refunds) {
      final perItem = refundedByOrder.putIfAbsent(r.orderId, () => {});
      for (final raw in jsonDecode(r.itemsJson) as List) {
        final item = (raw as Map).cast<String, dynamic>();
        final id = item['order_item_id'] as String;
        final qty = Qty.parse(item['quantity'] as String);
        perItem[id] = Qty((perItem[id]?.milli ?? 0) + qty.milli);
      }
    }

    return ShiftReport.build(
      shift: ShiftInfo(
        id: shift.id,
        openingCash: Money(shift.openingCash),
        openedAt: shift.openedAt.toUtc().toIso8601String(),
        closedAt: shift.closedAt?.toUtc().toIso8601String(),
        deviceCode: deviceCode,
        openedByName: shift.openedByName,
        closedByName: shift.closedByName,
        businessDate: DateFormat('yyyy-MM-dd')
            .format(config.businessDate(shift.openedAt)),
        countedCash: shift.countedCash == null
            ? null
            : Money(shift.countedCash!),
      ),
      orders: [
        for (final o in orders)
          ShiftOrder.fromPayload(
            (jsonDecode(o.payloadJson) as Map).cast<String, dynamic>(),
            status: o.status,
            shiftId: o.shiftId,
            voidedShiftId: o.voidedShiftId,
            refundedQuantities: refundedByOrder[o.id] ?? const {},
          ),
      ],
      refunds: [
        for (final r in refunds)
          ShiftRefund(
            shiftId: r.shiftId,
            amount: Money(r.amount),
            methodType: r.methodType,
          ),
      ],
      movements: [
        for (final c in moves)
          ShiftCashMovement(
            shiftId: c.shiftId,
            isIn: c.movementType == 'in',
            amount: Money(c.amount),
          ),
      ],
      methods: {
        for (final (i, o) in config.paymentOptions.indexed)
          o.id: PaymentMethodInfo(name: o.name, sortOrder: i),
      },
    );
  }

  /// [report], again whenever a sale, refund, cash movement or the shift
  /// itself changes.
  Stream<ShiftReport> watchReport(
    ShiftRow shift, {
    required PosConfig config,
    String? deviceCode,
  }) async* {
    Future<ShiftReport> build() async => await report(
      await find(shift.id) ?? shift,
      config: config,
      deviceCode: deviceCode,
    );
    yield await build();
    await for (final _ in _db.tableUpdates(
      TableUpdateQuery.onAllTables([
        _db.localOrders,
        _db.localRefunds,
        _db.localCashMovements,
        _db.localShifts,
      ]),
    )) {
      yield await build();
    }
  }
}
