@Tags(['screenshots'])
library;

import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/database/app_database.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/till_harness.dart';
import 'shells_screenshot_test.dart' show loadFonts, phone, shot, tablet;

/// Review screenshots of the five Stitch screens on the terminal, written to
/// `test/screenshots/out/` (git-ignored). Not goldens: nothing is compared.

/// A second product, two customers (one with kasbon) for fuller screens.
Future<void> sampleData(AppDatabase db) async {
  await db.batch((b) {
    b
      ..insert(
        db.products,
        ProductsCompanion.insert(
          id: 'p-teh',
          unitId: 'u-pcs',
          name: 'Teh Botol Manis',
          productType: 'standard',
          trackStock: true,
          isTaxable: true,
          isActive: true,
          updatedAt: at,
        ),
      )
      ..insert(
        db.productVariants,
        ProductVariantsCompanion.insert(
          id: 'v-teh',
          productId: 'p-teh',
          name: '350 ml',
          sku: 'TEH-BTL-350',
          barcode: const Value('8990000000011'),
          price: 6000,
          cost: 4200,
          sortOrder: 1,
          isActive: true,
          updatedAt: at,
        ),
      )
      ..insert(
        db.stockLevels,
        StockLevelsCompanion.insert(
          variantId: 'v-teh',
          quantityMilli: 3000,
          updatedAt: at,
        ),
      );
    for (final (id, name, phone, points) in [
      ('c-sari', 'Sari Wulandari', '081200000001', 120),
      ('c-rudi', 'Rudi Hartono', '081200000002', 45),
    ]) {
      b.insert(
        db.localCustomers,
        LocalCustomersCompanion.insert(
          id: id,
          name: name,
          phone: Value(phone),
          pointsBalance: Value(points),
          isActive: true,
          updatedAt: at,
        ),
      );
    }
    b.insert(
      db.localReceivables,
      LocalReceivablesCompanion.insert(
        orderId: 'o-old',
        receivableId: const Value('r-1'),
        customerId: 'c-rudi',
        amount: 35000,
        paidAmount: 0,
        dueDate: DateTime.utc(2026, 12),
        status: 'open',
        updatedAt: at,
      ),
    );
  });
}

Future<void> snap(WidgetTester t, String name) => expectLater(
  find.byType(MaterialApp),
  matchesGoldenFile('out/terminal_$name.png'),
);

void main() {
  setUpAll(loadFonts);

  for (final (name, size) in [('tablet', tablet), ('phone', phone)]) {
    shot('register with two cart lines $name', (t) async {
      final (db, _) = await openTill(t, size);
      await sampleData(db);
      await t.pumpAndSettle();
      if (size == tablet) {
        await tapKey(t, 'sell-item-MIE-GRG-ORI');
        await tapKey(t, 'sell-item-MIE-GRG-ORI');
        await tapKey(t, 'sell-item-TEH-BTL-350');
      }
      await snap(t, 'register_$name');
      await finish(t);
    });

    shot('overview after one sale $name', (t) async {
      final (db, c) = await openTill(t, tablet);
      await sampleData(db);
      await t.pumpAndSettle();
      await tapKey(t, 'sell-item-MIE-GRG-ORI');
      await tapKey(t, 'sell-pay');
      await tapKey(t, 'pay-method-cash');
      await tapKey(t, 'pay-quick-0');
      await tapKey(t, 'pay-finish');
      await waitForToasts(t);
      t.view.physicalSize = size;
      await go(t, c, AppRoutes.shift);
      await snap(t, 'overview_$name');
      await finish(t);
    });

    for (final (page, location) in [
      ('catalog', AppRoutes.catalog),
      ('members', AppRoutes.customers),
      ('settings', AppRoutes.printer),
    ]) {
      shot('$page $name', (t) async {
        final (db, c) = await openTill(t, size);
        await sampleData(db);
        await go(t, c, location);
        await snap(t, '${page}_$name');
        await finish(t);
      });
    }
  }
}
