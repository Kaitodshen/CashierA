import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/app/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/till_harness.dart';

void main() {
  testWidgets('opname: Back header to the catalog, rows on glass', (t) async {
    final (_, c) = await openTill(t, const Size(1280, 800));
    await go(t, c, AppRoutes.opname);

    expect(find.byType(AppBar), findsNothing);
    expect(find.byKey(const Key('opname-MIE-GRG-ORI')), findsOneWidget);
    expect(find.byKey(const Key('opname-submit')), findsOneWidget);

    await t.ensureVisible(find.byKey(const Key('opname-back')));
    await tapKey(t, 'opname-back');
    expect(
      c.read(routerProvider).routeInformationProvider.value.uri.path,
      AppRoutes.catalog,
    );
    await finish(t);
  });

  testWidgets('opname fits a phone', (t) async {
    final (_, c) = await openTill(t, const Size(360, 740));
    await go(t, c, AppRoutes.opname);
    expect(t.takeException(), isNull);
    await finish(t);
  });
}
