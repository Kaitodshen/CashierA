import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/app/router.dart';
import 'package:cashiera/app/shell/terminal_nav.dart';
import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/design_system/visual_effects.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/till_harness.dart';

const kitchenCashier = StaffMember(
  employeeId: 'e-eko',
  fullName: 'Eko Saputra',
  roleCode: 'cashier',
  permissions: {'pos.sell', 'shift.manage', 'kitchen.view'},
  pinHash: null,
);

Future<void> setFnb(WidgetTester t, AppDatabase db, {required bool on}) async {
  await db
      .update(db.localStores)
      .write(LocalStoresCompanion(fnbMode: Value(on)));
  await t.pumpAndSettle();
}

void main() {
  const tablet = Size(1280, 800);

  testWidgets('five sidebar items, Register selected, navigation works', (
    t,
  ) async {
    final (_, c) = await openTill(t, tablet);
    for (final s in TerminalSection.values) {
      expect(find.byKey(Key('terminal-nav-${s.name}')), findsOneWidget);
    }
    await tapKey(t, 'terminal-nav-overview');
    expect(c.read(routerProvider).state.matchedLocation, AppRoutes.shift);
    await tapKey(t, 'terminal-nav-register');
    expect(c.read(routerProvider).state.matchedLocation, AppRoutes.sell);
  });

  testWidgets('/pos redirects to Register', (t) async {
    final (_, c) = await openTill(t, tablet);
    await go(t, c, AppRoutes.pos);
    expect(c.read(routerProvider).state.matchedLocation, AppRoutes.sell);
  });

  testWidgets('kitchen pill hidden without F&B mode', (t) async {
    final (db, _) = await openTill(t, tablet, staff: kitchenCashier);
    await setFnb(t, db, on: false);
    expect(find.byKey(const Key('terminal-kitchen')), findsNothing);
  });

  testWidgets('kitchen pill hidden without kitchen.view', (t) async {
    final (db, _) = await openTill(t, tablet);
    await setFnb(t, db, on: true);
    expect(find.byKey(const Key('terminal-kitchen')), findsNothing);
  });

  testWidgets('kitchen pill shows for kitchen staff in F&B mode', (t) async {
    final (db, c) = await openTill(t, tablet, staff: kitchenCashier);
    await setFnb(t, db, on: true);
    expect(find.byKey(const Key('terminal-kitchen')), findsOneWidget);
    await tapKey(t, 'terminal-kitchen');
    expect(c.read(routerProvider).state.matchedLocation, AppRoutes.kitchen);
    await finish(t);
  });

  testWidgets('held orders pill opens the orders list', (t) async {
    final (_, c) = await openTill(t, tablet);
    await tapKey(t, 'terminal-held-orders');
    expect(c.read(routerProvider).state.matchedLocation, AppRoutes.orders);
  });

  testWidgets('visual effects off leaves no blur in the shell', (t) async {
    await openTill(
      t,
      tablet,
      overrides: [
        visualEffectsProvider.overrideWith((ref) => Stream.value(false)),
      ],
    );
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('visual effects on blurs the top bar', (t) async {
    await openTill(t, tablet);
    expect(find.byType(BackdropFilter), findsWidgets);
  });

  testWidgets('sidebar collapses to an icon rail', (t) async {
    await openTill(t, tablet);
    expect(find.text('Ringkasan'), findsOneWidget);
    await tapKey(t, 'terminal-sidebar-toggle');
    expect(find.text('Ringkasan'), findsNothing);
    expect(find.byKey(const Key('terminal-nav-overview')), findsOneWidget);
  });

  testWidgets('phone: bottom bar, no overflow', (t) async {
    final (_, c) = await openTill(t, const Size(360, 740));
    expect(t.takeException(), isNull);
    expect(find.byKey(const Key('terminal-bottom-bar')), findsOneWidget);
    await t.tap(find.byKey(const Key('terminal-nav-members')));
    await settleAndFlush(t);
    expect(c.read(routerProvider).state.matchedLocation, AppRoutes.customers);
    expect(t.takeException(), isNull);
  });

  testWidgets('lock button locks the terminal', (t) async {
    final (_, c) = await openTill(t, tablet);
    await tapKey(t, 'terminal-lock');
    expect(c.read(routerProvider).state.matchedLocation, AppRoutes.lock);
  });
}
