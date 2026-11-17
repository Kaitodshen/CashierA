import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/app/router.dart';
import 'package:cashiera/core/design_system/visual_effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/till_harness.dart';

void main() {
  testWidgets('visual effects off is stored and removes the blur', (t) async {
    final (db, c) = await openTill(t, const Size(1280, 1000));
    await go(t, c, AppRoutes.printer);
    expect(find.byType(BackdropFilter), findsWidgets);

    await t.ensureVisible(find.byKey(const Key('settings-visual-effects')));
    await tapKey(t, 'settings-visual-effects');

    final stored =
        await (db.select(
              db.localCounters,
            )..where((r) => r.name.equals(VisualEffectsRepository.counterName)))
            .getSingle();
    expect(stored.value, 0);
    expect(find.byType(BackdropFilter), findsNothing);
    await finish(t);
  });

  testWidgets('store card shows the store and its tax', (t) async {
    final (_, c) = await openTill(t, const Size(1280, 1000));
    await go(t, c, AppRoutes.printer);

    final card = find.byKey(const Key('settings-store'));
    expect(
      find.descendant(of: card, matching: find.text('CashierA Pusat')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.textContaining('PPN')),
      findsOneWidget,
    );
    expect(find.byType(AppBar), findsNothing);
    await finish(t);
  });

  testWidgets('open sync goes to the sync screen', (t) async {
    final (_, c) = await openTill(t, const Size(1280, 1000));
    await go(t, c, AppRoutes.printer);

    await t.ensureVisible(find.byKey(const Key('settings-open-sync')));
    await tapKey(t, 'settings-open-sync');
    expect(
      c.read(routerProvider).routeInformationProvider.value.uri.path,
      AppRoutes.sync,
    );
    await finish(t);
  });

  testWidgets('settings fit a phone', (t) async {
    final (_, c) = await openTill(t, const Size(360, 740));
    await go(t, c, AppRoutes.printer);
    expect(t.takeException(), isNull);
    await finish(t);
  });
}
