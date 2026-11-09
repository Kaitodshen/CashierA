import 'package:cashiera/core/database/app_database.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/till_harness.dart';

Future<void> putInCategory(WidgetTester t, AppDatabase db) async {
  await db
      .into(db.categories)
      .insert(
        CategoriesCompanion.insert(
          id: 'c-food',
          name: 'Makanan',
          sortOrder: 1,
          isActive: true,
          updatedAt: at,
        ),
      );
  await (db.update(db.products)..where((p) => p.id.equals('p-mie'))).write(
    const ProductsCompanion(categoryId: Value('c-food')),
  );
  await t.pumpAndSettle();
}

Future<void> rename(WidgetTester t, AppDatabase db, String name) async {
  await (db.update(db.products)..where((p) => p.id.equals('p-mie'))).write(
    ProductsCompanion(name: Value(name)),
  );
  await t.pumpAndSettle();
}

void main() {
  testWidgets('a tile shows category, price, stock and adds with +', (t) async {
    final (db, _) = await openTill(t, const Size(1280, 800));
    await putInCategory(t, db);
    final tile = find.byKey(const Key('sell-item-MIE-GRG-ORI'));
    Finder inTile(Finder f) => find.descendant(of: tile, matching: f);
    expect(inTile(find.text('MAKANAN')), findsOneWidget);
    expect(inTile(find.text('Rp 3.500')), findsOneWidget);
    expect(inTile(find.textContaining('10')), findsWidgets); // stock badge
    await t.tap(find.byKey(const Key('sell-add-MIE-GRG-ORI')));
    await t.pumpAndSettle();
    expect(
      t.widget<Text>(find.byKey(const Key('sell-total'))).data,
      'Rp 3.500',
    );
  });

  testWidgets('Register has no inner app bar under the shell', (t) async {
    await openTill(t, const Size(1280, 800));
    expect(find.byType(AppBar), findsNothing);
  });

  for (final size in [const Size(1280, 800), const Size(360, 740)]) {
    testWidgets('a very long product name never overflows at $size', (t) async {
      final (db, _) = await openTill(t, size);
      await rename(t, db, 'Mie Goreng Instan Rasa Ayam Bawang Pedas ' * 2);
      expect(t.takeException(), isNull);
    });
  }
}
