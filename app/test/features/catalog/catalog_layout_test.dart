import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/catalog/catalog_item.dart';
import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/features/catalog/presentation/catalog_browser_screen.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/till_harness.dart';

CatalogItem item({bool track = true, int stock = 10000, int? reorder = 5000}) =>
    CatalogItem(
      variantId: 'v',
      productId: 'p',
      productName: 'Teh',
      variantName: 'Default',
      sku: 'TEH',
      barcode: null,
      categoryId: null,
      unitCode: 'pcs',
      allowDecimal: false,
      basePrice: const Money(5000),
      priceOverride: null,
      isTaxable: true,
      trackStock: track,
      stock: Qty(stock),
      reorderPoint: reorder == null ? null : Qty(reorder),
      isAvailable: true,
    );

const stockKeeper = StaffMember(
  employeeId: 'e-eko',
  fullName: 'Eko Saputra',
  roleCode: 'cashier',
  permissions: {'pos.sell', 'shift.manage', 'inventory.adjust'},
  pinHash: null,
);

void main() {
  test('stock filter: all, low and out', () {
    final healthy = item();
    final low = item(stock: 3000);
    final out = item(stock: 0);
    final untracked = item(track: false, stock: 0);

    for (final i in [healthy, low, out, untracked]) {
      expect(matchesStockFilter(i, StockFilter.all), isTrue);
    }
    expect(matchesStockFilter(healthy, StockFilter.low), isFalse);
    expect(matchesStockFilter(low, StockFilter.low), isTrue);
    expect(matchesStockFilter(untracked, StockFilter.low), isFalse);

    expect(matchesStockFilter(out, StockFilter.out), isTrue);
    expect(matchesStockFilter(low, StockFilter.out), isFalse);
    expect(matchesStockFilter(untracked, StockFilter.out), isFalse);
    expect(matchesStockFilter(item(stock: -1000), StockFilter.out), isTrue);
  });

  testWidgets('wide catalog is a table with upper-case headers', (t) async {
    final (_, c) = await openTill(t, const Size(1280, 800));
    await go(t, c, AppRoutes.catalog);

    expect(find.text('PRODUK'), findsOneWidget);
    expect(find.text('STOK'), findsOneWidget);
    expect(find.text('HARGA'), findsOneWidget);
    expect(find.byKey(const Key('catalog-item-MIE-GRG-ORI')), findsOneWidget);
    expect(find.text('Rp 3.500'), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    await finish(t);
  });

  testWidgets('tapping a row opens the item sheet with stock in', (t) async {
    final (_, c) = await openTill(t, const Size(1280, 800), staff: stockKeeper);
    await go(t, c, AppRoutes.catalog);

    await tapKey(t, 'catalog-item-MIE-GRG-ORI');
    expect(find.byKey(const Key('item-stock-in')), findsOneWidget);
    await finish(t);
  });

  testWidgets('out-of-stock filter hides items in stock', (t) async {
    final (_, c) = await openTill(t, const Size(1280, 800));
    await go(t, c, AppRoutes.catalog);

    await t.tap(find.text('Habis'));
    await settleAndFlush(t);
    expect(find.byKey(const Key('catalog-item-MIE-GRG-ORI')), findsNothing);
    await finish(t);
  });

  testWidgets('phone catalog shows cards, long names do not overflow', (
    t,
  ) async {
    final (db, c) = await openTill(t, const Size(360, 740));
    final long = 'Kopi Susu Gula Aren Premium ' * 3;
    await db.batch((b) {
      b
        ..insert(
          db.products,
          ProductsCompanion.insert(
            id: 'p-long',
            unitId: 'u-pcs',
            name: long.trim(),
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
            id: 'v-long',
            productId: 'p-long',
            name: 'Default',
            sku: 'KOPI-LONG',
            barcode: const Value(null),
            price: 25000,
            cost: 10000,
            sortOrder: 1,
            isActive: true,
            updatedAt: at,
          ),
        );
    });
    await go(t, c, AppRoutes.catalog);

    expect(find.byKey(const Key('catalog-item-KOPI-LONG')), findsOneWidget);
    expect(find.text('PRODUK'), findsNothing);
    expect(t.takeException(), isNull);
    await finish(t);
  });
}
