import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/design_system/theme.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/features/back_office/presentation/admin_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Widget shell() => ProviderScope(
  child: MaterialApp.router(
    theme: AppTheme.backOffice(),
    locale: const Locale('en'),
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
            GoRoute(
              path: AppRoutes.adminSettings,
              builder: (_, _) => const Text('settings page'),
            ),
          ],
        ),
      ],
    ),
  ),
);

void main() {
  testWidgets(
    'the side menu scrolls on a laptop screen instead of overflowing',
    (tester) async {
      // The browser viewport from the bug report: 1920 x 940.
      tester.view
        ..physicalSize = const Size(1920, 940)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(shell());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'no RenderFlex overflow');
      expect(find.byKey(const Key('admin-rail-scroll')), findsOneWidget);

      // The last destination is reachable by scrolling, and it works.
      await tester.scrollUntilVisible(
        find.text('Store settings'),
        200,
        scrollable: find.descendant(
          of: find.byKey(const Key('admin-rail-scroll')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(find.text('Store settings'));
      await tester.pumpAndSettle();
      expect(find.text('settings page'), findsOneWidget);
    },
  );
}
