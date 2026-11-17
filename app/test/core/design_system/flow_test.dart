import 'package:cashiera/core/design_system/theme.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/flow.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child) => ProviderScope(
  child: MaterialApp(
    theme: AppTheme.light(),
    locale: const Locale('id'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  ),
);

void main() {
  testWidgets('flow header shows the title and goes back', (t) async {
    var back = 0;
    await t.pumpWidget(
      host(
        Scaffold(
          body: FlowHeader(title: 'Pembayaran', onBack: () => back++),
        ),
      ),
    );
    expect(find.text('Pembayaran'), findsOneWidget);
    expect(find.text('Kembali'), findsOneWidget);
    await t.tap(find.byKey(const Key('flow-back')));
    expect(back, 1);
  });

  testWidgets('centred glass page scrolls tall content on a phone', (t) async {
    t.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      host(
        CenteredGlassPage(
          child: Column(
            children: [for (var i = 0; i < 40; i++) Text('Baris $i')],
          ),
        ),
      ),
    );
    expect(t.takeException(), isNull);
    expect(find.byType(Scrollable), findsOneWidget);
  });

  test('selected segments are rose, not green', () {
    final style = AppTheme.light().segmentedButtonTheme.style!;
    expect(
      style.backgroundColor!.resolve({WidgetState.selected}),
      AppColors.primarySoft,
    );
    expect(
      style.foregroundColor!.resolve({WidgetState.selected}),
      AppColors.primary,
    );
  });
}
