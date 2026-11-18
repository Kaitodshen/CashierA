import 'package:cashiera/core/design_system/theme.dart';
import 'package:cashiera/core/design_system/widgets/glass.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/features/back_office/presentation/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpSignIn(WidgetTester t, Size size) async {
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
        home: const SignInScreen(),
      ),
    ),
  );
  await t.pump();
}

void main() {
  testWidgets('sign-in is one glass card without an app bar', (t) async {
    await pumpSignIn(t, const Size(1280, 800));
    expect(find.byType(AppBar), findsNothing);
    expect(
      find.ancestor(
        of: find.byKey(const Key('sign-in-email')),
        matching: find.byType(GlassCard),
      ),
      findsWidgets,
    );
  });

  testWidgets('sign-in fits a short phone', (t) async {
    await pumpSignIn(t, const Size(390, 640));
    expect(t.takeException(), isNull);
  });
}
