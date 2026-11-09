import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/design_system/theme.dart';
import 'package:cashiera/core/design_system/visual_effects.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/features/back_office/presentation/admin_nav.dart';
import 'package:cashiera/features/back_office/presentation/admin_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Widget shell() => ProviderScope(
  overrides: [visualEffectsProvider.overrideWith((ref) => Stream.value(true))],
  child: MaterialApp.router(
    theme: AppTheme.light(),
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: GoRouter(
      initialLocation: AppRoutes.admin,
      routes: [
        ShellRoute(
          builder: (_, _, child) => AdminShell(child: child),
          routes: [
            for (final (path, text) in [
              (AppRoutes.admin, 'home'),
              (AppRoutes.adminProducts, 'products page'),
              (AppRoutes.adminSettings, 'settings page'),
              (AppRoutes.adminTables, 'tables page'),
            ])
              GoRoute(path: path, builder: (_, _) => Text(text)),
          ],
        ),
      ],
    ),
  ),
);

void setSize(WidgetTester t, Size size) {
  t.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

void main() {
  testWidgets('five sections fit a laptop screen without scrolling', (t) async {
    // The browser viewport from the old overflow bug report: 1920 x 940.
    setSize(t, const Size(1920, 940));
    await t.pumpWidget(shell());
    await t.pumpAndSettle();
    expect(t.takeException(), isNull, reason: 'no RenderFlex overflow');
    for (final s in AdminSection.values) {
      expect(find.byKey(Key('admin-nav-${s.name}')), findsOneWidget);
    }
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('Settings section shows its tabs and opens Tables', (t) async {
    setSize(t, const Size(1280, 800));
    await t.pumpWidget(shell());
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('admin-nav-settings')));
    await t.pumpAndSettle();
    expect(find.text('settings page'), findsOneWidget);
    await t.tap(find.byKey(const Key('admin-tab-${AppRoutes.adminTables}')));
    await t.pumpAndSettle();
    expect(find.text('tables page'), findsOneWidget);
  });

  testWidgets('Catalog section opens Products', (t) async {
    setSize(t, const Size(1280, 800));
    await t.pumpWidget(shell());
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('admin-nav-catalog')));
    await t.pumpAndSettle();
    expect(find.text('products page'), findsOneWidget);
  });

  testWidgets('sign out stays reachable', (t) async {
    setSize(t, const Size(1280, 800));
    await t.pumpWidget(shell());
    await t.pumpAndSettle();
    expect(find.byKey(const Key('sign-out')), findsOneWidget);
  });

  testWidgets('phone: drawer with five sections, no overflow', (t) async {
    setSize(t, const Size(360, 740));
    await t.pumpWidget(shell());
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    await t.tap(find.byKey(const Key('admin-drawer-button')));
    await t.pumpAndSettle();
    for (final s in AdminSection.values) {
      expect(find.byKey(Key('admin-nav-${s.name}')), findsOneWidget);
    }
    await t.tap(find.byKey(const Key('admin-nav-settings')));
    await t.pumpAndSettle();
    expect(find.text('settings page'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
