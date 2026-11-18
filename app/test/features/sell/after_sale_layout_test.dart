import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/app/router.dart';
import 'package:cashiera/core/design_system/widgets/glass_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/till_harness.dart';

String path(ProviderContainer c) =>
    c.read(routerProvider).routeInformationProvider.value.uri.path;

Future<void> tapVisible(WidgetTester t, String key) async {
  await t.ensureVisible(find.byKey(Key(key)));
  await t.pumpAndSettle();
  await tapKey(t, key);
}

/// One Mie paid in exact cash; ends on its receipt.
Future<void> sellOne(WidgetTester t, ProviderContainer c) async {
  await tapKey(t, 'sell-item-MIE-GRG-ORI');
  await go(t, c, AppRoutes.pay);
  await tapVisible(t, 'pay-method-cash');
  await tapVisible(t, 'pay-quick-0');
  await tapVisible(t, 'pay-finish');
  await waitForToasts(t);
}

void main() {
  testWidgets('receipt has a Back header to the orders', (t) async {
    final (_, c) = await openTill(t, const Size(1280, 800));
    await sellOne(t, c);
    expect(path(c), startsWith('/pos/receipt/'));
    expect(find.byType(AppBar), findsNothing);

    await tapVisible(t, 'receipt-back');
    expect(path(c), AppRoutes.orders);
    await finish(t);
  });

  testWidgets('orders are a glass table with a Back header', (t) async {
    final (_, c) = await openTill(t, const Size(1280, 800));
    await sellOne(t, c);
    await go(t, c, AppRoutes.orders);

    expect(find.byType(AppBar), findsNothing);
    expect(find.byWidgetPredicate((w) => w is GlassTable), findsOneWidget);
    expect(find.text('NO. PESANAN'), findsOneWidget);
    expect(find.byKey(const Key('orders-total')), findsOneWidget);

    await tapVisible(t, 'orders-back');
    expect(path(c), AppRoutes.sell);
    await finish(t);
  });

  testWidgets('refund has a Back header to its receipt', (t) async {
    final (_, c) = await openTill(t, const Size(1280, 800), staff: manager);
    await sellOne(t, c);
    final receipt = path(c);

    await tapVisible(t, 'receipt-refund');
    expect(find.byType(AppBar), findsNothing);
    await tapVisible(t, 'refund-back');
    expect(path(c), receipt);
    await finish(t);
  });

  testWidgets('receipt and refund fit a phone', (t) async {
    final (_, c) = await openTill(t, const Size(360, 740), staff: manager);
    await sellOne(t, c);
    expect(t.takeException(), isNull);

    await tapVisible(t, 'receipt-refund');
    expect(t.takeException(), isNull);
    await finish(t);
  });
}
