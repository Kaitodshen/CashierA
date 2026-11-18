import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/app/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/till_harness.dart';

const tablet = Size(1280, 900);

String amountText(WidgetTester t) => t
    .widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('pay-amount')),
        matching: find.byType(TextField),
        matchRoot: true,
      ),
    )
    .controller!
    .text;

void main() {
  testWidgets('the cash tile opens payment with cash and the due amount', (
    t,
  ) async {
    final (_, c) = await openTill(t, tablet);
    await tapKey(t, 'sell-item-MIE-GRG-ORI');
    await tapKey(t, 'cart-tender-m-cash');
    expect(c.read(routerProvider).state.matchedLocation, AppRoutes.pay);
    expect(amountText(t).replaceAll('.', ''), '3500');
    await finish(t);
  });

  testWidgets('a quick-cash chip pre-fills the amount', (t) async {
    final (_, c) = await openTill(t, tablet);
    await tapKey(t, 'sell-item-MIE-GRG-ORI');
    await tapKey(t, 'cart-cash-10000');
    expect(c.read(routerProvider).state.matchedLocation, AppRoutes.pay);
    expect(amountText(t).replaceAll('.', ''), '10000');
    await finish(t);
  });

  testWidgets('an unknown method in the URL is ignored', (t) async {
    final (_, c) = await openTill(t, tablet);
    await tapKey(t, 'sell-item-MIE-GRG-ORI');
    await go(t, c, AppRoutes.payWith(methodId: 'nope', amount: 999999999));
    expect(t.takeException(), isNull);
    expect(find.byKey(const Key('pay-amount')), findsNothing);
    await finish(t);
  });

  testWidgets('F12 opens payment', (t) async {
    final (_, c) = await openTill(t, tablet);
    await tapKey(t, 'sell-item-MIE-GRG-ORI');
    await t.sendKeyEvent(LogicalKeyboardKey.f12);
    await t.pumpAndSettle();
    expect(c.read(routerProvider).state.matchedLocation, AppRoutes.pay);
    await finish(t);
  });

  testWidgets('the ticket shows walk-in customer and item count', (t) async {
    await openTill(t, tablet);
    await tapKey(t, 'sell-item-MIE-GRG-ORI');
    expect(find.text('Pelanggan umum'), findsOneWidget);
    expect(find.text('1 barang'), findsWidgets);
  });
}
