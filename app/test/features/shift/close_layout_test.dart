import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/app/router.dart';
import 'package:cashiera/core/design_system/widgets/data_display.dart';
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
  testWidgets('close shift: Back header and a difference chip', (t) async {
    final (_, c) = await openTill(t, const Size(1280, 800));
    await go(t, c, AppRoutes.shiftClose);
    expect(find.byType(AppBar), findsNothing);

    await t.tap(find.text('Masukkan total'));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('close-total')), '199500');
    await t.pumpAndSettle();
    expect(
      find.ancestor(
        of: find.byKey(const Key('close-difference')),
        matching: find.byType(StatusChip),
      ),
      findsOneWidget,
    );

    await tapVisible(t, 'close-back');
    expect(path(c), AppRoutes.shift);
    await finish(t);
  });

  testWidgets('shift report: Back header to the overview', (t) async {
    final (db, c) = await openTill(t, const Size(1280, 800));
    final shift = await db.select(db.localShifts).getSingle();
    await go(t, c, AppRoutes.shiftReport(shift.id));
    expect(find.byType(AppBar), findsNothing);
    expect(find.byKey(const Key('report-print')), findsOneWidget);

    await tapVisible(t, 'report-back');
    expect(path(c), AppRoutes.shift);
    await finish(t);
  });

  testWidgets('sync: header with sync now, no app bar', (t) async {
    final (_, c) = await openTill(t, const Size(1280, 800));
    await go(t, c, AppRoutes.sync);
    expect(find.byType(AppBar), findsNothing);
    expect(find.byKey(const Key('sync-now')), findsOneWidget);
    await finish(t);
  });

  testWidgets('close shift fits a phone', (t) async {
    final (_, c) = await openTill(t, const Size(360, 740));
    await go(t, c, AppRoutes.shiftClose);
    expect(t.takeException(), isNull);
    await finish(t);
  });
}
