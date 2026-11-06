import 'dart:convert';

import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/pos/cart.dart';
import 'package:cashiera/core/printing/printer_setting.dart';
import 'package:cashiera/core/providers.dart';
import 'package:cashiera/features/sell/presentation/sell_providers.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/till_harness.dart';

Future<void> _customer(AppDatabase db, {int points = 0}) => db
    .into(db.localCustomers)
    .insert(
      LocalCustomersCompanion.insert(
        id: 'c-rudi',
        name: 'Rudi Hartono',
        phone: const Value('081200000002'),
        pointsBalance: Value(points),
        isActive: true,
        updatedAt: at,
      ),
    );

Future<void> _loyalty(AppDatabase db) => db
    .into(db.mirrorRecords)
    .insert(
      MirrorRecordsCompanion.insert(
        sourceTable: 'business_profile',
        pk: '1',
        data: jsonEncode({
          'id': 1,
          'name': 'CashierA',
          'loyalty_enabled': true,
          'loyalty_earn_amount': 10000,
          'loyalty_point_value': 100,
          'loyalty_min_redeem_points': 10,
          'kasbon_default_due_days': 30,
        }),
        updatedAt: at,
      ),
    );

void main() {
  testWidgets('points: spend 20 at the till, earn on the rest', (tester) async {
    final (db, container) = await openTill(tester, const Size(1280, 1000));
    await _customer(db, points: 50);
    await _loyalty(db);
    await tester.pumpAndSettle();

    for (var i = 0; i < 10; i++) {
      await tester.tap(find.byKey(const Key('sell-item-MIE-GRG-ORI')));
      await tester.pump();
    }
    container
        .read(cartControllerProvider.notifier)
        .setCustomer(const CartCustomer(id: 'c-rudi', name: 'Rudi Hartono'));
    await tester.pumpAndSettle();
    expect(find.text('50 poin'), findsOneWidget);

    await tapKey(tester, 'sell-points');
    expect(find.text('Saldo 50 poin'), findsOneWidget);
    // Too few, then the maximum the bill allows.
    await tester.enterText(find.byKey(const Key('points-field')), '5');
    await tapKey(tester, 'points-use');
    expect(find.text('Paling sedikit 10 poin.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('points-field')), '20');
    await tapKey(tester, 'points-use');
    expect(find.text('−20 poin'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('sell-total'))).data,
      'Rp 33.000',
    );

    await tapKey(tester, 'sell-pay');
    await tapKey(tester, 'pay-method-cash');
    await tapKey(tester, 'pay-quick-0');
    await tapKey(tester, 'pay-finish');
    expect(find.text('Poin didapat: 3'), findsOneWidget);

    final order = await lastQueued(db, 'order.upsert');
    expect(order['points_redeemed'], 20);
    expect(order['points_discount'], 2000);
    expect(order['points_earned'], 3);
    final rudi = await db.select(db.localCustomers).getSingle();
    expect(rudi.pointsBalance, 33);

    await waitForToasts(tester);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('kasbon: pay in two installments with a balance slip', (
    tester,
  ) async {
    final printer = FakePrinterTransport();
    final (db, container) = await openTill(
      tester,
      const Size(1280, 1200),
      printer: printer,
    );
    await container
        .read(printerRepositoryProvider)
        .save(
          const PrinterSetting(
            name: 'Kasir',
            connection: PrinterConnection.network,
            address: '10.0.0.5',
            opensCashDrawer: true,
          ),
        );
    await _customer(db);
    await db
        .into(db.mirrorRecords)
        .insert(
          MirrorRecordsCompanion.insert(
            sourceTable: 'payment_methods',
            pk: 'm-trf',
            data: jsonEncode({
              'id': 'm-trf',
              'code': 'transfer',
              'name': 'Transfer Bank',
              'method_type': 'transfer',
              'requires_reference': true,
              'sort_order': 50,
              'is_active': true,
            }),
            updatedAt: at,
          ),
        );
    await db
        .into(db.localReceivables)
        .insert(
          LocalReceivablesCompanion.insert(
            orderId: 'o-old',
            receivableId: const Value('r-1'),
            customerId: 'c-rudi',
            amount: 35000,
            paidAmount: 0,
            dueDate: DateTime.utc(2026, 10),
            status: 'open',
            updatedAt: at,
          ),
        );

    await go(tester, container, AppRoutes.customers);
    expect(find.text('Kasbon Rp 35.000'), findsOneWidget);
    await tester.tap(find.text('Rudi Hartono'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Terlambat'), findsOneWidget);

    // More than owed is refused in the dialog.
    await tapKey(tester, 'customer-pay');
    await tester.enterText(find.byKey(const Key('repay-amount')), '40000');
    await tapKey(tester, 'repay-submit');
    expect(find.text('Melebihi sisa kasbon.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('repay-amount')), '15000');
    await tapKey(tester, 'repay-submit');

    expect(
      tester.widget<Text>(find.byKey(const Key('customer-owed'))).data,
      'Kasbon Rp 20.000',
    );
    expect(printer.text, contains('PEMBAYARAN KASBON'));
    expect(printer.text, contains('Sisa kasbon'));
    expect(printer.text, contains('Rp 20.000'));
    await waitForToasts(tester);

    // Pay the rest by transfer: settled, no drawer.
    await tapKey(tester, 'customer-pay');
    await tapKey(tester, 'repay-all');
    await tapKey(tester, 'repay-method-transfer');
    await tester.enterText(find.byKey(const Key('repay-reference')), 'TRF-9');
    await tapKey(tester, 'repay-submit');
    expect(find.text('Tidak ada kasbon.'), findsOneWidget);
    expect(printer.text, contains('LUNAS'));

    final sent = [
      for (final q in await db.select(db.syncQueue).get())
        if (q.entity == 'receivable_payment')
          (jsonDecode(q.payload) as Map).cast<String, dynamic>(),
    ];
    expect(sent.map((p) => (p['amount'], p['method_type'], p['reference'])), [
      (15000, 'cash', null),
      (20000, 'transfer', 'TRF-9'),
    ]);
    expect(sent.every((p) => p['order_id'] == 'o-old'), isTrue);

    await waitForToasts(tester);
    await tester.pumpWidget(const SizedBox());
  });
}
