import 'dart:convert';

import 'package:cashiera/features/sell/presentation/sell_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/till_harness.dart';

void main() {
  testWidgets('a full cash sale works offline, from shift to receipt', (
    tester,
  ) async {
    final (db, _) = await openTill(tester, const Size(1280, 900));

    // Scan once (Enter), tap twice.
    await tester.enterText(
      find.byKey(const Key('sell-search')),
      '2000000000213',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sell-item-MIE-GRG-ORI')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cart-plus-MIE-GRG-ORI')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('sell-total'))).data,
      'Rp 10.500',
    );

    await tester.tap(find.byKey(const Key('sell-pay')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pay-method-cash')));
    await tester.pumpAndSettle();
    // Quick amounts for 10.500: exact, 15.000, 20.000, 50.000.
    await tester.tap(find.byKey(const Key('pay-quick-1')));
    await tester.pumpAndSettle();
    expect(find.text('Kembalian Rp 4.500'), findsOneWidget);
    await tester.tap(find.byKey(const Key('pay-finish')));
    await tester.pumpAndSettle();

    // Receipt with the change on top.
    expect(find.byKey(const Key('receipt-change')), findsOneWidget);
    expect(
      find.textContaining(RegExp(r'^PST-T1-[0-9]{6}-0001$')),
      findsWidgets,
    );

    final queue = await db.select(db.syncQueue).get();
    expect(queue.map((q) => '${q.entity}.${q.action}'), [
      'shift.open',
      'order.upsert',
    ]);
    final order = jsonDecode(queue.last.payload) as Map<String, dynamic>;
    expect(order['status'], 'completed');
    expect(order['grand_total'], 10500);
    expect(order['tax_total'], 1041);
    expect(order['paid_total'], 10500);
    expect(order['change_total'], 4500);
    expect(order['shift_id'], isNotNull);
    expect((await db.select(db.stockLevels).getSingle()).quantityMilli, 7000);

    // Leave the screens so periodic timers stop before the test ends.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('phone layout: hold a bill, resume it, pay exact', (
    tester,
  ) async {
    final (db, container) = await openTill(tester, const Size(400, 860));

    await tapKey(tester, 'sell-item-MIE-GRG-ORI');
    await tapKey(tester, 'sell-open-cart');
    await tapKey(tester, 'sell-hold');
    expect(find.textContaining('ditahan'), findsOneWidget);
    // The toast covers the app bar for 4 seconds.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // Held orders moved from the old sell app bar to the shell top bar.
    await tapKey(tester, 'terminal-held-orders');
    await tester.tap(find.text('Ditahan (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining(RegExp('^PST-T1-')).first);
    await tester.pumpAndSettle();

    // Back on the cashier screen with the held bill.
    await tapKey(tester, 'sell-pay-bar');
    await tapKey(tester, 'pay-method-cash');
    await tapKey(tester, 'pay-quick-0');
    await tapKey(tester, 'pay-finish');
    expect(find.byKey(const Key('receipt-new-sale')), findsOneWidget);

    final orders = [
      for (final q in await db.select(db.syncQueue).get())
        if (q.entity == 'order') jsonDecode(q.payload) as Map<String, dynamic>,
    ];
    expect(orders.map((o) => o['status']), ['held', 'completed']);
    expect(orders.map((o) => o['id']).toSet(), hasLength(1));
    expect(orders.last['version'], 2);
    expect(orders.last['change_total'], 0);
    expect(container.read(cartControllerProvider).isEmpty, isTrue);

    await tester.pumpWidget(const SizedBox());
  });
}
