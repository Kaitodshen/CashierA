import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/app/router.dart';
import 'package:cashiera/core/design_system/widgets/buttons.dart';
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

void main() {
  testWidgets('wide payment: summary and methods side by side', (t) async {
    final (_, c) = await openTill(t, const Size(1280, 800));
    await tapKey(t, 'sell-item-MIE-GRG-ORI');
    await go(t, c, AppRoutes.pay);

    expect(find.byType(AppBar), findsNothing);
    final due = t.getCenter(find.byKey(const Key('pay-due')));
    final cash = t.getCenter(find.byKey(const Key('pay-method-cash')));
    expect((cash.dx - due.dx).abs(), greaterThan(300));

    await tapKey(t, 'pay-back');
    expect(path(c), AppRoutes.sell);
    await finish(t);
  });

  testWidgets('phone payment: split cash reaches an enabled finish', (t) async {
    final (_, c) = await openTill(t, const Size(360, 740));
    await tapKey(t, 'sell-item-MIE-GRG-ORI');
    await go(t, c, AppRoutes.pay);
    expect(t.takeException(), isNull);

    bool finishEnabled() =>
        switch (t.widget(find.byKey(const Key('pay-finish')))) {
          final PrimaryButton b => b.onPressed != null,
          final ButtonStyleButton b => b.enabled,
          _ => throw StateError('pay-finish is not a button'),
        };

    await tapVisible(t, 'pay-method-cash');
    await t.enterText(find.byKey(const Key('pay-amount')), '2000');
    await tapVisible(t, 'pay-add');
    await t.ensureVisible(find.byKey(const Key('pay-finish')));
    await t.pumpAndSettle();
    expect(finishEnabled(), isFalse);

    // Adding a tender clears the method; pick cash again for the rest.
    await tapVisible(t, 'pay-method-cash');
    await tapVisible(t, 'pay-quick-0');
    await t.ensureVisible(find.byKey(const Key('pay-finish')));
    await t.pumpAndSettle();
    expect(finishEnabled(), isTrue);
    expect(t.takeException(), isNull);
    await finish(t);
  });
}
