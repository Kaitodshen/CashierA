import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/app/router.dart';
import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/design_system/theme.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/visual_effects.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/features/back_office/presentation/admin_shell.dart';
import 'package:cashiera/features/back_office/presentation/gateway_payments_screen.dart';
import 'package:cashiera/features/back_office/presentation/purchase_orders_screen.dart';
import 'package:cashiera/features/back_office/presentation/transfers_screen.dart';
import 'package:cashiera/features/fnb/tables_screen.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/till_harness.dart';

/// Regressions found in the phase 1 whole-branch review.
void main() {
  const tablet = Size(1280, 800);

  testWidgets('F&B terminals can open Tables from the top bar', (t) async {
    final (db, c) = await openTill(t, tablet);
    expect(find.byKey(const Key('terminal-tables')), findsNothing);
    await db
        .update(db.localStores)
        .write(const LocalStoresCompanion(fnbMode: Value(true)));
    await t.pumpAndSettle();
    await tapKey(t, 'terminal-tables');
    expect(c.read(routerProvider).state.matchedLocation, AppRoutes.tables);
  });

  testWidgets('screens inside the shell do not add the status bar again', (
    t,
  ) async {
    t.view.padding = const FakeViewPadding(top: 48);
    addTearDown(t.view.resetPadding);
    await openTill(t, tablet);
    // The sell screen's own AppBar sits under the shell top bar.
    final inner = t.element(find.byType(AppBar).first);
    expect(MediaQuery.paddingOf(inner).top, 0);
  });

  testWidgets('phone cart sheet covers the bottom bar', (t) async {
    final (_, c) = await openTill(t, const Size(360, 740));
    await tapKey(t, 'sell-open-cart');
    await t.tap(
      find.byKey(const Key('terminal-nav-members')),
      warnIfMissed: false,
    );
    await t.pumpAndSettle();
    expect(c.read(routerProvider).state.matchedLocation, AppRoutes.sell);
  });

  test('in-between statuses keep their own colour', () {
    expect(tableColor('cleaning'), isNot(tableColor('available')));
    expect(poStatusColor('ordered'), isNot(poStatusColor('received')));
    expect(
      transferStatusColor('in_transit'),
      isNot(transferStatusColor('received')),
    );
  });

  test('muted text is dark enough to read on glass', () {
    expect(AppColors.textMuted, const Color(0xFF475569));
    expect(
      AppTheme.light().colorScheme.onSurfaceVariant,
      const Color(0xFF475569),
    );
  });

  testWidgets('back-office phone drawer is not see-through', (t) async {
    t.view
      ..physicalSize = const Size(360, 740)
      ..devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          visualEffectsProvider.overrideWith((ref) => Stream.value(true)),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: GoRouter(
            initialLocation: AppRoutes.admin,
            routes: [
              ShellRoute(
                builder: (_, _, child) => AdminShell(child: child),
                routes: [
                  GoRoute(
                    path: AppRoutes.admin,
                    builder: (_, _) => const Text('home'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('admin-drawer-button')));
    await t.pumpAndSettle();
    final drawer = t.widget<Drawer>(find.byType(Drawer));
    expect(drawer.backgroundColor!.a, greaterThanOrEqualTo(0.9));
  });

  test('gateway charges that failed are not shown as paid', () {
    final paid = chargeColorFor(status: 'paid', unmatched: false);
    for (final s in ['failed', 'expired', 'cancelled']) {
      expect(chargeColorFor(status: s, unmatched: false), isNot(paid));
    }
  });
}
