import 'package:cashiera/core/database/catalog_tables.dart';
import 'package:cashiera/core/database/pos_tables.dart';
import 'package:cashiera/core/database/tables.dart';
import 'package:cashiera/core/sync/sync_queue_dao.dart';
import 'package:drift/drift.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    SyncQueue,
    LocalDevice,
    LocalStores,
    LocalStoreSettings,
    LocalStaff,
    PinAttempts,
    SyncCursors,
    // v2: catalog mirror (Phase 3)
    Categories,
    Units,
    Products,
    ProductVariants,
    StoreVariantSettings,
    ModifierGroups,
    Modifiers,
    ProductModifierGroups,
    StoreFavorites,
    StockLevels,
    // v3: cashier (Phase 4)
    MirrorRecords,
    LocalCustomers,
    LocalShifts,
    LocalOrders,
    LocalCounters,
    // v4: shifts, refunds, printing (Phase 5)
    LocalCashMovements,
    LocalRefunds,
    LocalPrinters,
    // v5: kasbon (Phase 6)
    LocalReceivables,
    LocalReceivablePayments,
  ],
  daos: [SyncQueueDao],
)
class AppDatabase extends _$AppDatabase {
  new(super.e);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createIndexes();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        for (final table in <TableInfo<Table, dynamic>>[
          categories,
          units,
          products,
          productVariants,
          storeVariantSettings,
          modifierGroups,
          modifiers,
          productModifierGroups,
          storeFavorites,
          stockLevels,
        ]) {
          await m.createTable(table);
        }
        await _createCatalogIndexes();
      }
      if (from < 3) {
        for (final table in <TableInfo<Table, dynamic>>[
          mirrorRecords,
          localCustomers,
          localShifts,
          localOrders,
          localCounters,
        ]) {
          await m.createTable(table);
        }
        await _createPosIndexes();
      }
      if (from == 3) {
        // Tables created at v3 lack the Phase 5 columns.
        await m.addColumn(localShifts, localShifts.closedBy);
        await m.addColumn(localShifts, localShifts.closedByName);
        await m.addColumn(localShifts, localShifts.countedCash);
        await m.addColumn(localShifts, localShifts.expectedCash);
        await m.addColumn(localShifts, localShifts.closeNote);
        await m.addColumn(localOrders, localOrders.voidedAt);
        await m.addColumn(localOrders, localOrders.voidReason);
        await m.addColumn(localOrders, localOrders.voidedByName);
        await m.addColumn(localOrders, localOrders.voidedShiftId);
      }
      if (from < 4) {
        for (final table in <TableInfo<Table, dynamic>>[
          localCashMovements,
          localRefunds,
          localPrinters,
        ]) {
          await m.createTable(table);
        }
        await _createShiftIndexes();
      }
      if (from < 5) {
        await m.createTable(localReceivables);
        await m.createTable(localReceivablePayments);
        await _createKasbonIndexes();
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS sync_queue_status_idx '
      'ON sync_queue (status, id)',
    );
    await _createCatalogIndexes();
    await _createPosIndexes();
    await _createShiftIndexes();
    await _createKasbonIndexes();
  }

  Future<void> _createKasbonIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS local_receivables_customer_idx '
      'ON local_receivables (customer_id, status)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS local_receivable_payments_shift_idx '
      'ON local_receivable_payments (shift_id)',
    );
  }

  Future<void> _createShiftIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS local_refunds_order_idx '
      'ON local_refunds (order_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS local_cash_movements_shift_idx '
      'ON local_cash_movements (shift_id)',
    );
  }

  Future<void> _createPosIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS local_orders_status_idx '
      'ON local_orders (status, created_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS local_customers_name_idx '
      'ON local_customers (name COLLATE NOCASE)',
    );
  }

  Future<void> _createCatalogIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS product_variants_product_idx '
      'ON product_variants (product_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS product_variants_barcode_idx '
      'ON product_variants (barcode)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS product_variants_sku_idx '
      'ON product_variants (sku COLLATE NOCASE)',
    );
  }

  /// Removes the pairing and everything cached for the store (unpair /
  /// revoked terminal). The outbox is kept: unsent sales must never vanish.
  Future<void> clearTerminalData() => transaction(() async {
    for (final table in <TableInfo<Table, dynamic>>[
      localDevice,
      localStores,
      localStoreSettings,
      localStaff,
      pinAttempts,
      categories,
      units,
      products,
      productVariants,
      storeVariantSettings,
      modifierGroups,
      modifiers,
      productModifierGroups,
      storeFavorites,
      stockLevels,
      mirrorRecords,
      localCustomers,
      localShifts,
      localOrders,
      localCashMovements,
      localRefunds,
      localReceivables,
      localReceivablePayments,
    ]) {
      await delete(table).go();
    }
    await delete(syncCursors).go();
  });
}
