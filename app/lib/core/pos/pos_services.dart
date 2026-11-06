import 'dart:convert';

import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/pos/cart.dart';
import 'package:cashiera/core/pos/order_payload.dart';
import 'package:cashiera/core/pos/pos_config.dart';
import 'package:cashiera/core/pos/pos_errors.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

export 'package:cashiera/core/pos/audit_service.dart';
export 'package:cashiera/core/pos/pos_errors.dart';
export 'package:cashiera/core/pos/refund_service.dart';
export 'package:cashiera/core/pos/shift_service.dart';

/// Adds a customer on the terminal (`customer.upsert`).
class CustomerService {
  new(this._db, {this._uuid = const Uuid()});

  final AppDatabase _db;
  final Uuid _uuid;

  static final phonePattern = RegExp(r'^\+?[0-9]{8,15}$');

  Future<CartCustomer> quickAdd({
    required StaffMember staff,
    required String storeId,
    required String name,
    String? phone,
  }) async {
    if (!staff.can('customer.manage')) {
      throw const PosPermissionException('customer.manage');
    }
    final cleanName = name.trim();
    final cleanPhone = phone?.replaceAll(RegExp(r'[\s-]'), '');
    if (cleanName.isEmpty) throw ArgumentError.value(name, 'name');
    if (cleanPhone != null &&
        cleanPhone.isNotEmpty &&
        !phonePattern.hasMatch(cleanPhone)) {
      throw ArgumentError.value(phone, 'phone');
    }
    final id = _uuid.v7();
    final phoneValue = cleanPhone == null || cleanPhone.isEmpty
        ? null
        : cleanPhone;
    return await _db.transaction(() async {
      await _db
          .into(_db.localCustomers)
          .insert(
            LocalCustomersCompanion.insert(
              id: id,
              name: cleanName,
              phone: Value(phoneValue),
              isActive: true,
              updatedAt: clock.now(),
            ),
          );
      await _db.syncQueueDao.enqueue(
        entity: 'customer',
        action: 'upsert',
        clientUuid: _uuid.v7(),
        payload: {
          'id': id,
          'store_id': storeId,
          'name': cleanName,
          'phone': phoneValue,
          'employee_id': staff.employeeId,
        },
      );
      return CartCustomer(id: id, name: cleanName, phone: phoneValue);
    });
  }
}

/// Where a sale happens: store, terminal, shift.
class SaleContext {
  const new({
    required this.config,
    required this.deviceCode,
    required this.staff,
    this.shiftId,
  });

  final PosConfig config;
  final String deviceCode;
  final StaffMember staff;
  final String? shiftId;
}

/// `PST-T1-261106-0001` (orders) or `R-PST-T1-261106-0001` (refunds,
/// [kind] `refund`): counted per terminal, per kind and per store-local
/// business date. Call inside the transaction that saves the document.
Future<String> nextDocumentNumber(
  AppDatabase db,
  SaleContext ctx,
  DateTime at, {
  String kind = 'order',
}) async {
  final date = DateFormat('yyMMdd').format(ctx.config.businessDate(at));
  final name = '$kind:${ctx.deviceCode}:$date';
  final current = await (db.select(
    db.localCounters,
  )..where((c) => c.name.equals(name))).getSingleOrNull();
  final next = (current?.value ?? 0) + 1;
  await db
      .into(db.localCounters)
      .insertOnConflictUpdate(
        LocalCountersCompanion.insert(name: name, value: next),
      );
  final prefix = kind == 'order' ? '' : 'R-';
  return '$prefix${ctx.config.storeCode}-${ctx.deviceCode}-$date-'
      '${next.toString().padLeft(4, '0')}';
}

/// Holds, finishes and cancels bills. Each change writes the local order,
/// the local stock and the outbox item in one transaction, so a sale is
/// never half-saved, and receipts work offline at once.
class OrderService {
  new(this._db, {this._uuid = const Uuid()});

  final AppDatabase _db;
  final Uuid _uuid;

  Future<String> _nextNumber(SaleContext ctx, DateTime at) =>
      nextDocumentNumber(_db, ctx, at);

  void _checkDiscounts(Cart cart, Bill bill, SaleContext ctx) {
    if (bill.maxManualBps > 0 && !ctx.staff.can('pos.discount')) {
      throw const PosPermissionException('pos.discount');
    }
    if (bill.needsApproval(ctx.config.discountApprovalBps) &&
        cart.approvedBy == null) {
      throw const PosStateException('approval_required');
    }
  }

  /// Parks the bill (status `held`). Returns the cart with its number and
  /// version, to keep editing or to finish later.
  Future<Cart> hold({
    required Cart cart,
    required Bill bill,
    required SaleContext ctx,
  }) async {
    if (cart.isEmpty) throw const PosStateException('empty');
    _checkDiscounts(cart, bill, ctx);
    return await _db.transaction(() async {
      final now = clock.now();
      final number = cart.orderNumber ?? await _nextNumber(ctx, now);
      final saved = cart.copyWith(
        orderNumber: number,
        version: cart.version + 1,
      );
      final payload = buildOrderPayload(
        cart: saved,
        bill: bill,
        config: ctx.config,
        cashierId: ctx.staff.employeeId,
        orderNumber: number,
        status: OrderStatus.held,
        version: saved.version,
        shiftId: ctx.shiftId,
        uuid: _uuid,
      );
      await _save(saved, payload, bill, ctx, OrderStatus.held, now);
      return saved;
    });
  }

  /// Finishes the sale: payments must cover the bill exactly (change only
  /// on cash), a shift must be open, kasbon needs a customer.
  Future<LocalOrderRow> complete({
    required Cart cart,
    required Bill bill,
    required Settlement settlement,
    required SaleContext ctx,
  }) async {
    if (cart.isEmpty) throw const PosStateException('empty');
    if (ctx.shiftId == null) throw const PosStateException('shift_required');
    if (!settlement.isComplete) throw const PosStateException('not_paid');
    if (settlement.kasbonAmount.rupiah > 0) {
      if (cart.customer == null) {
        throw const PosStateException('kasbon_requires_customer');
      }
      if (!ctx.staff.can('kasbon.manage')) {
        throw const PosPermissionException('kasbon.manage');
      }
    }
    _checkDiscounts(cart, bill, ctx);

    return await _db.transaction(() async {
      final now = clock.now();
      final number = cart.orderNumber ?? await _nextNumber(ctx, now);
      final saved = cart.copyWith(
        orderNumber: number,
        version: cart.version + 1,
      );
      final payload = buildOrderPayload(
        cart: saved,
        bill: bill,
        config: ctx.config,
        cashierId: ctx.staff.employeeId,
        orderNumber: number,
        status: OrderStatus.completed,
        version: saved.version,
        shiftId: ctx.shiftId,
        settlement: settlement,
        completedAt: now,
        uuid: _uuid,
      );
      for (final line in saved.lines.where((l) => l.trackStock)) {
        await _db.customUpdate(
          'UPDATE stock_levels SET quantity_milli = quantity_milli - ? '
          'WHERE variant_id = ?',
          variables: [
            Variable.withInt(line.quantity.milli),
            Variable.withString(line.variantId),
          ],
          updates: {_db.stockLevels},
        );
      }
      return await _save(saved, payload, bill, ctx, OrderStatus.completed, now);
    });
  }

  /// Cancels a held bill. The person needs `pos.void`; otherwise
  /// [approvedBy] (someone who has it) cancels on their behalf.
  Future<void> cancelHeld({
    required LocalOrderRow order,
    required SaleContext ctx,
    required String reason,
    String? approvedBy,
  }) async {
    final canVoid = ctx.staff.can('pos.void');
    if (!canVoid && approvedBy == null) {
      throw const PosPermissionException('pos.void');
    }
    return await _db.transaction(() async {
      final now = clock.now();
      final payload = (jsonDecode(order.payloadJson) as Map)
          .cast<String, dynamic>();
      final version = order.version + 1;
      payload
        ..['status'] = OrderStatus.cancelled.code
        ..['version'] = version
        ..['payments'] = const <Object>[]
        ..['cancel'] = {
          'cancelled_by': canVoid ? ctx.staff.employeeId : approvedBy,
          'reason': reason.trim(),
          'approved_by': canVoid ? null : approvedBy,
          'cancelled_at': now.toUtc().toIso8601String(),
        };
      await (_db.update(
        _db.localOrders,
      )..where((o) => o.id.equals(order.id))).write(
        LocalOrdersCompanion(
          status: Value(OrderStatus.cancelled.code),
          version: Value(version),
          payloadJson: Value(jsonEncode(payload)),
          updatedAt: Value(now),
        ),
      );
      await _db.syncQueueDao.enqueue(
        entity: 'order',
        action: 'upsert',
        clientUuid: _uuid.v7(),
        payload: payload,
      );
    });
  }

  /// Voids a completed sale: the stock comes back and the cash leaves the
  /// drawer of the shift open now. The person needs `pos.void`, or
  /// [approver] (who has it) voids on their behalf. After the receipt was
  /// printed, [approver] must hold `pos.void_after_print`.
  Future<void> voidOrder({
    required LocalOrderRow order,
    required SaleContext ctx,
    required String reason,
    StaffMember? approver,
  }) async {
    if (order.status != OrderStatus.completed.code) {
      throw const PosStateException('not_completed');
    }
    if (ctx.shiftId == null) throw const PosStateException('shift_required');
    if (reason.trim().length < 3) {
      throw const PosStateException('reason_required');
    }
    final printed = order.printedAt != null;
    if (printed && approver == null) {
      throw const PosStateException('approval_required');
    }
    if (printed && !approver!.can('pos.void_after_print')) {
      throw const PosPermissionException('pos.void_after_print');
    }
    final canVoid = ctx.staff.can('pos.void');
    if (!canVoid && !(approver?.can('pos.void') ?? false)) {
      throw const PosPermissionException('pos.void');
    }
    return await _db.transaction(() async {
      final refunds = await (_db.select(
        _db.localRefunds,
      )..where((r) => r.orderId.equals(order.id))).get();
      if (refunds.isNotEmpty) {
        throw const PosStateException('void_after_refund');
      }
      final now = clock.now();
      final by = canVoid ? ctx.staff : approver!;
      await (_db.update(
        _db.localOrders,
      )..where((o) => o.id.equals(order.id))).write(
        LocalOrdersCompanion(
          status: const Value('voided'),
          voidedAt: Value(now),
          voidReason: Value(reason.trim()),
          voidedByName: Value(by.fullName),
          voidedShiftId: Value(ctx.shiftId),
          updatedAt: Value(now),
        ),
      );
      final cart = Cart.fromJson(
        (jsonDecode(order.cartJson) as Map).cast<String, dynamic>(),
      );
      for (final line in cart.lines.where((l) => l.trackStock)) {
        await _db.customUpdate(
          'UPDATE stock_levels SET quantity_milli = quantity_milli + ? '
          'WHERE variant_id = ?',
          variables: [
            Variable.withInt(line.quantity.milli),
            Variable.withString(line.variantId),
          ],
          updates: {_db.stockLevels},
        );
      }
      await _db.syncQueueDao.enqueue(
        entity: 'order',
        action: 'void',
        clientUuid: _uuid.v7(),
        payload: {
          'order_id': order.id,
          'voided_by': by.employeeId,
          'approved_by': approver?.employeeId,
          'reason': reason.trim(),
          'shift_id': ctx.shiftId,
          'voided_at': now.toUtc().toIso8601String(),
          'receipt_printed_at': order.printedAt?.toUtc().toIso8601String(),
        },
      );
    });
  }

  /// The receipt went to a printer: later voids need approval.
  Future<void> markPrinted(String orderId) => _db.transaction(() async {
    final order = await (_db.select(
      _db.localOrders,
    )..where((o) => o.id.equals(orderId))).getSingle();
    if (order.printedAt != null) return;
    final now = clock.now();
    await (_db.update(_db.localOrders)..where((o) => o.id.equals(orderId)))
        .write(LocalOrdersCompanion(printedAt: Value(now)));
    await _db.syncQueueDao.enqueue(
      entity: 'order',
      action: 'mark_printed',
      clientUuid: _uuid.v7(),
      payload: {
        'order_id': orderId,
        'printed_at': now.toUtc().toIso8601String(),
      },
    );
  });

  Future<LocalOrderRow> _save(
    Cart cart,
    Map<String, dynamic> payload,
    Bill bill,
    SaleContext ctx,
    OrderStatus status,
    DateTime now,
  ) async {
    final existing = await (_db.select(
      _db.localOrders,
    )..where((o) => o.id.equals(cart.orderId))).getSingleOrNull();
    final row = LocalOrderRow(
      id: cart.orderId,
      orderNumber: cart.orderNumber!,
      status: status.code,
      version: cart.version,
      cartJson: jsonEncode(cart.toJson()),
      payloadJson: jsonEncode(payload),
      grandTotal: bill.grandTotal.rupiah,
      itemCount: cart.itemCount,
      customerName: cart.customer?.name,
      cashierName: ctx.staff.fullName,
      shiftId: ctx.shiftId,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      completedAt: status == OrderStatus.completed ? now : null,
      printedAt: existing?.printedAt,
    );
    await _db.into(_db.localOrders).insertOnConflictUpdate(row);
    await _db.syncQueueDao.enqueue(
      entity: 'order',
      action: 'upsert',
      clientUuid: _uuid.v7(),
      payload: payload,
    );
    return row;
  }

  Stream<List<LocalOrderRow>> watch({
    required Set<String> statuses,
    DateTime? since,
  }) {
    final select = _db.select(_db.localOrders)
      ..where((o) => o.status.isIn(statuses));
    if (since != null) {
      select.where((o) => o.updatedAt.isBiggerOrEqualValue(since));
    }
    select.orderBy([(o) => OrderingTerm.desc(o.updatedAt)]);
    return select.watch();
  }

  Stream<LocalOrderRow?> watchOne(String id) => (_db.select(
    _db.localOrders,
  )..where((o) => o.id.equals(id))).watchSingleOrNull();

  Future<LocalOrderRow?> find(String id) => (_db.select(
    _db.localOrders,
  )..where((o) => o.id.equals(id))).getSingleOrNull();
}
