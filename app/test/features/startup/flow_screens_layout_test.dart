import 'dart:convert';

import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/design_system/theme.dart';
import 'package:cashiera/core/design_system/widgets/glass.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/features/pairing/presentation/pairing_screen.dart';
import 'package:cashiera/features/startup/presentation/setup_screen.dart';
import 'package:cashiera/features/startup/presentation/splash_screen.dart';
import 'package:cashiera/features/startup/presentation/welcome_screen.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/till_harness.dart';

Future<void> pumpScreen(WidgetTester t, Widget screen, Size size) async {
  t.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: screen,
      ),
    ),
  );
  await t.pump();
}

Finder inGlass(Finder f) =>
    find.ancestor(of: f, matching: find.byType(GlassCard));

void main() {
  for (final size in [const Size(1280, 800), const Size(360, 640)]) {
    testWidgets('welcome is one glass card, $size', (t) async {
      await pumpScreen(t, const WelcomeScreen(), size);
      expect(find.byType(AppBar), findsNothing);
      expect(inGlass(find.byKey(const Key('welcome-pair'))), findsWidgets);
      expect(t.takeException(), isNull);
    });

    testWidgets('pairing is one glass card, $size', (t) async {
      await pumpScreen(t, const PairingScreen(), size);
      expect(find.byType(AppBar), findsNothing);
      expect(inGlass(find.byKey(const Key('pairing-code'))), findsWidgets);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('splash and setup sit on glass without an app bar', (t) async {
    await pumpScreen(t, const SplashScreen(), const Size(1280, 800));
    expect(inGlass(find.byType(CircularProgressIndicator)), findsWidgets);

    await pumpScreen(t, const SetupScreen(), const Size(1280, 800));
    expect(find.byType(AppBar), findsNothing);
    expect(inGlass(find.byIcon(Icons.settings_suggest_outlined)), findsWidgets);
  });

  for (final size in [const Size(1280, 800), const Size(360, 640)]) {
    testWidgets('PIN lock on glass with a long staff name, $size', (t) async {
      final (db, _) = await openTill(t, size);
      await db
          .into(db.localStaff)
          .insert(
            LocalStaffCompanion.insert(
              employeeId: 'e-long',
              fullName: 'Raden Ayu Siti Nurhaliza Kusumawardhani ' * 2,
              roleCode: 'cashier',
              permissions: jsonEncode(['pos.sell']),
              pinHash: const Value('111111'),
              isActive: true,
              syncedAt: at,
            ),
          );
      if (size.width < 600) {
        await tapKey(t, 'terminal-more');
      }
      await tapKey(t, 'terminal-lock');

      expect(find.byType(AppBar), findsNothing);
      expect(inGlass(find.byKey(const Key('staff-e-long'))), findsWidgets);
      expect(t.takeException(), isNull);

      await tapKey(t, 'staff-e-eko');
      expect(t.takeException(), isNull);
      await finish(t);
    });
  }
}
