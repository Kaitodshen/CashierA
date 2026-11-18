import 'dart:io';

import 'package:cashiera/core/design_system/theme.dart';
import 'package:cashiera/core/design_system/visual_effects.dart';
import 'package:cashiera/core/design_system/widgets/glass.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/features/sell/presentation/sell_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> openDiscount(WidgetTester t) async {
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        visualEffectsProvider.overrideWith((ref) => Stream.value(true)),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showDiscountDialog(context, title: 'Diskon'),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await t.tap(find.text('open'));
  await t.pumpAndSettle();
}

void main() {
  test('terminal features use glass dialogs and sheets only', () {
    final offenders = <String>[];
    for (final folder in ['sell', 'shift', 'catalog', 'customers', 'fnb']) {
      for (final f in Directory(
        'lib/features/$folder',
      ).listSync(recursive: true)) {
        if (f is! File || !f.path.endsWith('.dart')) continue;
        final src = f.readAsStringSync();
        if (src.contains('AlertDialog(') ||
            src.contains('showModalBottomSheet')) {
          offenders.add(f.path);
        }
      }
    }
    expect(offenders, isEmpty);
  });

  testWidgets('the discount dialog is a glass dialog', (t) async {
    await openDiscount(t);
    expect(find.byType(GlassDialog), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('the discount dialog fits a short phone with a keyboard', (
    t,
  ) async {
    t.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1
      ..viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(t.view.reset);
    await openDiscount(t);
    expect(t.takeException(), isNull);
  });
}
