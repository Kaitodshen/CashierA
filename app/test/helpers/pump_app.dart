import 'package:cashiera/core/design_system/theme.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

extension PumpApp on WidgetTester {
  /// Pumps [child] inside a themed, localized MaterialApp.
  Future<void> pumpLocalized(
    Widget child, {
    Locale locale = const Locale('id'),
  }) => pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    ),
  );
}
