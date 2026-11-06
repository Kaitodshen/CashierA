import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:clock/clock.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

/// Reasons a terminal can record (same values as stock_adjustments.reason).
enum StockReason {
  stockIn('stock_in', increases: true),
  stockOut('stock_out', increases: false),
  damaged('damaged', increases: false),
  expired('expired', increases: false),
  lost('lost', increases: false);

  new(this.code, {required this.increases});
  final String code;
  final bool increases;
}

class StockPermissionException implements Exception {
  const new(this.permission);
  final String permission;

  @override
  String toString() => 'missing permission $permission';
}

/// Offline stock changes on a terminal: local stock changes immediately and
/// the server command is queued in the same transaction.
class StockService {
  new(this._db, {this._uuid = const Uuid()});

  final AppDatabase _db;
  final Uuid _uuid;

  /// Records [quantity] (always positive) in or out of stock. Returns the
  /// adjustment id.
  Future<String> adjust({
    required String storeId,
    required String deviceCode,
    required StaffMember staff,
    required String variantId,
    required Qty quantity,
    required StockReason reason,
    String? note,
  }) {
    if (!staff.can('inventory.adjust')) {
      throw const StockPermissionException('inventory.adjust');
    }
    if (quantity.milli <= 0) {
      throw ArgumentError.value(quantity.milli, 'quantity', 'must be positive');
    }
    final delta = reason.increases ? quantity.milli : -quantity.milli;
    final id = _uuid.v7();
    return _db.transaction(() async {
      await _addStock(variantId, delta);
      await _db.syncQueueDao.enqueue(
        entity: 'stock_adjustment',
        action: 'create',
        clientUuid: _uuid.v7(),
        payload: {
          'id': id,
          'store_id': storeId,
          'adjustment_number': _number('ADJ', deviceCode),
          'reason': reason.code,
          'note': note,
          'employee_id': staff.employeeId,
          'occurred_at': clock.now().toUtc().toIso8601String(),
          'items': [
            {
              'id': _uuid.v7(),
              'variant_id': variantId,
              'quantity_delta': Qty(delta).toPayload(),
            },
          ],
        },
      );
      return id;
    });
  }

  /// Submits a count: local stock becomes the counted quantities and the
  /// server applies the differences as a stock opname. Returns the opname id.
  Future<String> submitOpname({
    required String storeId,
    required String deviceCode,
    required StaffMember staff,
    required Map<String, Qty> counts,
    String? note,
  }) {
    if (!staff.can('inventory.opname')) {
      throw const StockPermissionException('inventory.opname');
    }
    if (counts.isEmpty) throw ArgumentError('count at least one item');
    final id = _uuid.v7();
    final now = clock.now();
    return _db.transaction(() async {
      for (final entry in counts.entries) {
        await _db
            .into(_db.stockLevels)
            .insertOnConflictUpdate(
              StockLevelsCompanion.insert(
                variantId: entry.key,
                quantityMilli: entry.value.milli,
                updatedAt: now,
              ),
            );
      }
      await _db.syncQueueDao.enqueue(
        entity: 'stock_opname',
        action: 'submit',
        clientUuid: _uuid.v7(),
        payload: {
          'id': id,
          'store_id': storeId,
          'opname_number': _number('OP', deviceCode),
          'note': note,
          'employee_id': staff.employeeId,
          'items': [
            for (final entry in counts.entries)
              {'variant_id': entry.key, 'counted_qty': entry.value.toPayload()},
          ],
        },
      );
      return id;
    });
  }

  /// Called inside a transaction, so the read and the write can't interleave
  /// with another local change.
  Future<void> _addStock(String variantId, int deltaMilli) async {
    final current = await (_db.select(
      _db.stockLevels,
    )..where((s) => s.variantId.equals(variantId))).getSingleOrNull();
    await _db
        .into(_db.stockLevels)
        .insertOnConflictUpdate(
          StockLevelsCompanion.insert(
            variantId: variantId,
            quantityMilli: (current?.quantityMilli ?? 0) + deltaMilli,
            updatedAt: clock.now(),
          ),
        );
  }

  /// Unique per terminal: `ADJ-T1-261105143005-7f3a`.
  String _number(String prefix, String deviceCode) {
    final stamp = DateFormat('yyMMddHHmmss').format(clock.now());
    return '$prefix-$deviceCode-$stamp-${_uuid.v4().substring(0, 4)}';
  }
}
