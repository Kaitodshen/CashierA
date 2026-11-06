import 'dart:convert';

import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/payments/payment_gateway.dart';
import 'package:cashiera/core/providers.dart';
import 'package:cashiera/features/sell/presentation/sell_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/till_harness.dart';

Future<void> addDynamicQris(AppDatabase db) => db
    .into(db.mirrorRecords)
    .insert(
      MirrorRecordsCompanion.insert(
        sourceTable: 'payment_methods',
        pk: 'm-qd',
        data: jsonEncode({
          'id': 'm-qd',
          'code': 'qris_dynamic',
          'name': 'QRIS Dinamis',
          'method_type': 'qris',
          'requires_reference': false,
          'sort_order': 21,
          'is_active': true,
          'gateway': 'midtrans',
        }),
        updatedAt: at,
      ),
    );

/// Rings up two Mie (Rp 7.000) and opens the QR for the whole bill.
Future<void> startQris(WidgetTester tester) async {
  await tapKey(tester, 'sell-item-MIE-GRG-ORI');
  await tapKey(tester, 'sell-item-MIE-GRG-ORI');
  await tapKey(tester, 'sell-pay');
  await tapKey(tester, 'pay-method-qris_dynamic');
  await tapKey(tester, 'pay-qris-create');
}

void main() {
  testWidgets('dynamic QRIS: pay, keep it on the bill, book it', (
    tester,
  ) async {
    final gateway = MockGateway();
    final (db, container) = await openTill(
      tester,
      const Size(1280, 900),
      overrides: [paymentGatewayProvider.overrideWithValue(gateway)],
    );
    await addDynamicQris(db);
    await tester.pumpAndSettle();
    await startQris(tester);

    expect(find.byKey(const Key('qris-code')), findsOneWidget);
    expect(find.text('QRIS Rp 7.000'), findsOneWidget);
    final request = gateway.requests.single;
    expect(request.amount.rupiah, 7000);
    expect(request.paymentMethodId, 'm-qd');
    expect(request.orderId, container.read(cartControllerProvider).orderId);

    gateway.markPaid(request.chargeId);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('qris-code')), findsNothing);
    expect(find.byIcon(Icons.verified), findsOneWidget);
    await waitForToasts(tester);

    // The paid QRIS stays with the bill: it can't be cleared.
    await go(tester, container, AppRoutes.sell);
    await tapKey(tester, 'sell-clear');
    expect(find.textContaining('sudah diterima'), findsOneWidget);
    expect(container.read(cartControllerProvider).lines, isNotEmpty);
    await waitForToasts(tester);

    await go(tester, container, AppRoutes.pay);
    await tapKey(tester, 'pay-finish');
    final order = await lastQueued(db, 'order.upsert');
    expect(order['status'], 'completed');
    final pay = (order['payments'] as List).single as Map;
    expect(pay['id'], request.chargeId, reason: 'the payment is the charge');
    expect(pay['method_type'], 'qris');
    expect(pay['amount'], 7000);
    expect(pay['provider'], 'midtrans');
    expect(pay['provider_ref'], 'MOCK-${request.chargeId}');
    expect(container.read(cartControllerProvider).gatewayTenders, isEmpty);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('an expired QR books nothing; a new QR gets paid', (
    tester,
  ) async {
    final gateway = MockGateway();
    final (db, container) = await openTill(
      tester,
      const Size(1280, 900),
      overrides: [paymentGatewayProvider.overrideWithValue(gateway)],
    );
    await addDynamicQris(db);
    await tester.pumpAndSettle();
    await startQris(tester);

    gateway.expire(gateway.requests.single.chargeId);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('qris-final')), findsOneWidget);
    expect(find.textContaining('kedaluwarsa'), findsOneWidget);

    await tapKey(tester, 'qris-new');
    expect(gateway.requests, hasLength(2));
    final second = gateway.requests.last.chargeId;
    expect(second, isNot(gateway.requests.first.chargeId));
    gateway.markPaid(second);
    await tester.pumpAndSettle();
    await tapKey(tester, 'pay-finish');
    final pay =
        ((await lastQueued(db, 'order.upsert'))['payments'] as List).single
            as Map;
    expect(pay['id'], second);
    await waitForToasts(tester);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('cancel while the customer just paid: it counts as paid', (
    tester,
  ) async {
    final gateway = MockGateway()..paidBeforeCancel = true;
    final (db, container) = await openTill(
      tester,
      const Size(1280, 900),
      overrides: [paymentGatewayProvider.overrideWithValue(gateway)],
    );
    await addDynamicQris(db);
    await tester.pumpAndSettle();
    await startQris(tester);

    await tapKey(tester, 'qris-cancel');
    expect(find.byKey(const Key('qris-code')), findsNothing);
    expect(
      container
          .read(cartControllerProvider)
          .gatewayTenders
          .single
          .amount
          .rupiah,
      7000,
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('pay-finish')))
          .onPressed,
      isNotNull,
    );
    await waitForToasts(tester);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('without a gateway the method is not offered', (tester) async {
    final (db, _) = await openTill(tester, const Size(1280, 900));
    await addDynamicQris(db);
    await tester.pumpAndSettle();
    await tapKey(tester, 'sell-item-MIE-GRG-ORI');
    await tapKey(tester, 'sell-pay');
    expect(find.byKey(const Key('pay-method-cash')), findsOneWidget);
    expect(find.byKey(const Key('pay-method-qris_dynamic')), findsNothing);
    await waitForToasts(tester);
    await tester.pumpWidget(const SizedBox());
  });
}
