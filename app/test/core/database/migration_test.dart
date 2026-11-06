import 'dart:io';

import 'package:cashiera/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a Phase 4 terminal (v3) keeps its shifts and orders on v5', () async {
    final dir = await Directory.systemTemp.createTemp('cashiera-migration');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/terminal.sqlite');

    // Build the v3 shape: today's schema minus the Phase 5 parts.
    final v3 = AppDatabase(NativeDatabase(file));
    await v3.customSelect('SELECT 1').get();
    for (final sql in [
      'DROP TABLE local_cash_movements',
      'DROP TABLE local_refunds',
      'DROP TABLE local_printers',
      'DROP TABLE local_receivables',
      'DROP TABLE local_receivable_payments',
      for (final c in [
        'closed_by',
        'closed_by_name',
        'counted_cash',
        'expected_cash',
        'close_note',
      ])
        'ALTER TABLE local_shifts DROP COLUMN $c',
      for (final c in [
        'voided_at',
        'void_reason',
        'voided_by_name',
        'voided_shift_id',
      ])
        'ALTER TABLE local_orders DROP COLUMN $c',
      '''
INSERT INTO local_shifts
  (id, store_id, opened_by, opened_by_name, opened_at, opening_cash, status)
VALUES ('s-1', 'store', 'e-1', 'Eko', '2026-11-06T01:00:00.000Z', 200000,
  'open')''',
      '''
INSERT INTO local_orders
  (id, order_number, status, version, cart_json, payload_json, grand_total,
   item_count, cashier_name, shift_id, created_at, updated_at)
VALUES ('o-1', 'PST-T1-261106-0001', 'completed', 1, '{}', '{}', 7000, 2,
  'Eko', 's-1', '2026-11-06T01:00:00.000Z', '2026-11-06T01:00:00.000Z')''',
      'PRAGMA user_version = 3',
    ]) {
      await v3.customStatement(sql);
    }
    await v3.close();

    final v4 = AppDatabase(NativeDatabase(file));
    addTearDown(v4.close);
    final shift = await v4.select(v4.localShifts).getSingle();
    expect(shift.id, 's-1');
    expect(shift.countedCash, isNull);
    final order = await v4.select(v4.localOrders).getSingle();
    expect(order.orderNumber, 'PST-T1-261106-0001');
    expect(order.voidedShiftId, isNull);

    await v4
        .into(v4.localCashMovements)
        .insert(
          CashMovementRow(
            id: 'cm-1',
            shiftId: 's-1',
            movementType: 'in',
            amount: 1000,
            reason: 'Uang kecil',
            employeeName: 'Eko',
            occurredAt: DateTime.utc(2026, 11, 6),
          ),
        );
    expect(await v4.select(v4.localCashMovements).get(), hasLength(1));
    expect(await v4.select(v4.localRefunds).get(), isEmpty);
    expect(await v4.select(v4.localPrinters).get(), isEmpty);
    final version = await v4.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, 5);
    expect(await v4.select(v4.localReceivables).get(), isEmpty);
    expect(await v4.select(v4.localReceivablePayments).get(), isEmpty);
  });
}
