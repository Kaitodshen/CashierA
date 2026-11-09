import 'package:cashiera/app/app_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/till_harness.dart';

const tablet = Size(1280, 800);

TextField fieldOf(WidgetTester t, String key) => t.widget<TextField>(
  find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField)),
);

Future<void> scan(WidgetTester t, String key, String code) async {
  await t.enterText(find.byKey(Key(key)), code);
  await t.testTextInput.receiveAction(TextInputAction.search);
  await t.pumpAndSettle();
}

void main() {
  testWidgets('scanning a known code in the top bar adds it and clears', (
    t,
  ) async {
    await openTill(t, tablet);
    await scan(t, 'sell-search', '2000000000213');
    expect(
      t.widget<Text>(find.byKey(const Key('sell-total'))).data,
      'Rp 3.500',
    );
    expect(fieldOf(t, 'sell-search').controller!.text, isEmpty);
    // Ready for the next scan.
    expect(fieldOf(t, 'sell-search').focusNode!.hasFocus, isTrue);
  });

  testWidgets('an unknown code shows not found', (t) async {
    await openTill(t, tablet);
    await scan(t, 'sell-search', '999');
    expect(find.textContaining('999'), findsWidgets);
    expect(t.widget<Text>(find.byKey(const Key('sell-total'))).data, 'Rp 0');
    await waitForToasts(t);
  });

  testWidgets('typing filters the product grid', (t) async {
    await openTill(t, tablet);
    expect(find.byKey(const Key('sell-item-MIE-GRG-ORI')), findsOneWidget);
    await t.enterText(find.byKey(const Key('sell-search')), 'zzz');
    await t.pumpAndSettle();
    expect(find.byKey(const Key('sell-item-MIE-GRG-ORI')), findsNothing);
  });

  testWidgets('the field shows only on Register and Catalog', (t) async {
    final (_, c) = await openTill(t, tablet);
    expect(find.byKey(const Key('sell-search')), findsOneWidget);
    await go(t, c, AppRoutes.catalog);
    expect(find.byKey(const Key('catalog-search')), findsOneWidget);
    expect(find.byKey(const Key('sell-search')), findsNothing);
    await go(t, c, AppRoutes.shift);
    expect(find.byKey(const Key('catalog-search')), findsNothing);
  });

  testWidgets('a catalog query does not leak into Register', (t) async {
    final (_, c) = await openTill(t, tablet);
    await go(t, c, AppRoutes.catalog);
    await t.enterText(find.byKey(const Key('catalog-search')), 'zzz');
    await t.pumpAndSettle();
    await go(t, c, AppRoutes.sell);
    expect(fieldOf(t, 'sell-search').controller!.text, isEmpty);
    expect(find.byKey(const Key('sell-item-MIE-GRG-ORI')), findsOneWidget);
  });
}
