import 'dart:convert';

import 'package:cashiera/core/catalog/catalog_source.dart';
import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/database/tables.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:drift/drift.dart';

class PullSummary {
  const new({
    required this.rows,
    required this.deleted,
    required this.stockSkipped,
  });

  final int rows;
  final int deleted;

  /// True when stock was not refreshed because local stock changes are still
  /// waiting in the outbox (a pull would undo them on screen).
  final bool stockSkipped;
}

/// Outbox entities that change stock on the server.
const stockChangingEntities = {
  'stock_adjustment',
  'stock_opname',
  'order',
  'refund',
};

/// Outbox entities that change points or kasbon balances on the server.
const balanceChangingEntities = {'order', 'refund', 'receivable_payment'};

/// Brings the local catalog mirror up to date: per table, rows changed since
/// the cursor (minus [overlap], so rows committed late are not missed), then
/// server-side deletes from tombstones. Upserts are idempotent.
class CatalogPullService {
  new({
    required this.db,
    required this.source,
    required this.storeId,
    this.pageSize = 500,
  });

  static const overlap = Duration(minutes: 5);
  static const tombstoneCursor = 'tombstones';

  final AppDatabase db;
  final CatalogSource source;
  final String storeId;
  final int pageSize;

  Future<PullSummary> pull({bool includeStock = true}) async {
    var rows = 0;
    var stockSkipped = false;
    _keepLocalBalances = await _pending(balanceChangingEntities);
    for (final spec in mirrorSpecs) {
      if (spec.isStock) {
        if (!includeStock || await _stockChangesPending()) {
          stockSkipped = true;
          continue;
        }
      }
      rows += await _pullTable(spec);
    }
    final deleted = await _applyTombstones();
    return PullSummary(
      rows: rows,
      deleted: deleted,
      stockSkipped: stockSkipped,
    );
  }

  Future<int> _pullTable(MirrorSpec spec) async {
    final cursor = await _readCursor(spec.table);
    final since =
        cursor?.subtract(overlap) ?? DateTime.fromMillisecondsSinceEpoch(0);
    var newest = cursor;
    var offset = 0;
    var total = 0;
    while (true) {
      final page = await source.fetchChanged(
        spec,
        since: since,
        storeId: storeId,
        offset: offset,
        limit: pageSize,
      );
      if (page.isEmpty) break;
      await db.batch((b) {
        for (final json in page) {
          if (spec.isJson) {
            b.insert(
              db.mirrorRecords,
              MirrorRecordsCompanion.insert(
                sourceTable: spec.table,
                pk: spec.keyOf(json),
                data: jsonEncode(json),
                updatedAt: DateTime.parse(json['updated_at'] as String),
              ),
              mode: InsertMode.insertOrReplace,
            );
          } else {
            _upsert(b, spec.table, json);
          }
        }
      });
      for (final json in page) {
        final at = DateTime.parse(json['updated_at'] as String);
        if (newest == null || at.isAfter(newest)) newest = at;
      }
      total += page.length;
      if (page.length < pageSize) break;
      offset += pageSize;
    }
    if (newest != null && newest != cursor) {
      await _writeCursor(spec.table, newest.toUtc().toIso8601String());
    }
    return total;
  }

  Future<int> _applyTombstones() async {
    final after = int.tryParse(await _readRaw(tombstoneCursor) ?? '') ?? 0;
    final tombstones = await source.fetchTombstones(afterId: after);
    if (tombstones.isEmpty) return 0;
    var deleted = 0;
    await db.transaction(() async {
      for (final t in tombstones) {
        final spec = mirrorSpecFor(t.table);
        final shared = spec?.isJson == true && !spec!.storeScoped;
        if (!shared && t.storeId != null && t.storeId != storeId) continue;
        deleted += spec?.isJson == true
            ? await (db.delete(db.mirrorRecords)..where(
                    (r) =>
                        r.sourceTable.equals(t.table) &
                        r.pk.equals(spec!.keyOf(t.rowPk)),
                  ))
                  .go()
            : await _delete(t);
      }
      await _writeCursor(tombstoneCursor, '${tombstones.last.id}');
    });
    return deleted;
  }

  Future<int> _delete(Tombstone t) {
    String key(String column) => t.rowPk[column] as String;
    return switch (t.table) {
      'categories' => (db.delete(
        db.categories,
      )..where((r) => r.id.equals(key('id')))).go(),
      'units' => (db.delete(
        db.units,
      )..where((r) => r.id.equals(key('id')))).go(),
      'products' => (db.delete(
        db.products,
      )..where((r) => r.id.equals(key('id')))).go(),
      'product_variants' => (db.delete(
        db.productVariants,
      )..where((r) => r.id.equals(key('id')))).go(),
      'modifier_groups' => (db.delete(
        db.modifierGroups,
      )..where((r) => r.id.equals(key('id')))).go(),
      'modifiers' => (db.delete(
        db.modifiers,
      )..where((r) => r.id.equals(key('id')))).go(),
      'product_modifier_groups' =>
        (db.delete(db.productModifierGroups)..where(
              (r) =>
                  r.productId.equals(key('product_id')) &
                  r.groupId.equals(key('group_id')),
            ))
            .go(),
      'store_variant_settings' => (db.delete(
        db.storeVariantSettings,
      )..where((r) => r.variantId.equals(key('variant_id')))).go(),
      'store_favorites' => (db.delete(
        db.storeFavorites,
      )..where((r) => r.productId.equals(key('product_id')))).go(),
      'customers' => (db.delete(
        db.localCustomers,
      )..where((r) => r.id.equals(key('id')))).go(),
      'receivables' => (db.delete(
        db.localReceivables,
      )..where((r) => r.receivableId.equals(key('id')))).go(),
      _ => Future.value(0),
    };
  }

  Future<bool> _stockChangesPending() => _pending(stockChangingEntities);

  /// While sales, refunds or kasbon installments wait in the outbox, the
  /// server's points and kasbon balances are older than this terminal's:
  /// pulled rows keep the local balance (like stock).
  bool _keepLocalBalances = false;

  Future<bool> _pending(Set<String> entities) async {
    final count = db.syncQueue.id.count();
    final query = db.selectOnly(db.syncQueue)
      ..addColumns([count])
      ..where(
        db.syncQueue.status.equalsValue(SyncStatus.done).not() &
            db.syncQueue.entity.isIn(entities),
      );
    return ((await query.getSingle()).read(count) ?? 0) > 0;
  }

  Future<String?> _readRaw(String name) async => (await (db.select(
    db.syncCursors,
  )..where((c) => c.name.equals(name))).getSingleOrNull())?.value;

  Future<DateTime?> _readCursor(String name) async {
    final raw = await _readRaw(name);
    return raw == null ? null : DateTime.parse(raw);
  }

  Future<void> _writeCursor(String name, String value) => db
      .into(db.syncCursors)
      .insertOnConflictUpdate(
        SyncCursorsCompanion.insert(name: name, value: value),
      );

  void _upsert(Batch b, String table, Map<String, dynamic> j) {
    DateTime at() => DateTime.parse(j['updated_at'] as String);
    String s(String k) => j[k] as String;
    String? os(String k) => j[k] as String?;
    int i(String k) => (j[k] as num).toInt();
    int? oi(String k) => (j[k] as num?)?.toInt();
    bool f(String k) => j[k] as bool;

    switch (table) {
      case 'units':
        b.insert(
          db.units,
          UnitsCompanion.insert(
            id: s('id'),
            code: s('code'),
            name: s('name'),
            allowDecimal: f('allow_decimal'),
            updatedAt: at(),
          ),
          mode: InsertMode.insertOrReplace,
        );
      case 'categories':
        b.insert(
          db.categories,
          CategoriesCompanion.insert(
            id: s('id'),
            parentId: Value(os('parent_id')),
            name: s('name'),
            sortOrder: i('sort_order'),
            color: Value(os('color')),
            icon: Value(os('icon')),
            kitchenStation: Value(os('kitchen_station')),
            isActive: f('is_active'),
            updatedAt: at(),
          ),
          mode: InsertMode.insertOrReplace,
        );
      case 'products':
        b.insert(
          db.products,
          ProductsCompanion.insert(
            id: s('id'),
            categoryId: Value(os('category_id')),
            unitId: s('unit_id'),
            name: s('name'),
            description: Value(os('description')),
            productType: s('product_type'),
            trackStock: f('track_stock'),
            isTaxable: f('is_taxable'),
            kitchenStation: Value(os('kitchen_station')),
            imagePath: Value(os('image_path')),
            isActive: f('is_active'),
            updatedAt: at(),
          ),
          mode: InsertMode.insertOrReplace,
        );
      case 'product_variants':
        b.insert(
          db.productVariants,
          ProductVariantsCompanion.insert(
            id: s('id'),
            productId: s('product_id'),
            name: s('name'),
            sku: s('sku'),
            barcode: Value(os('barcode')),
            price: i('price'),
            cost: i('cost'),
            sortOrder: i('sort_order'),
            isActive: f('is_active'),
            updatedAt: at(),
          ),
          mode: InsertMode.insertOrReplace,
        );
      case 'modifier_groups':
        b.insert(
          db.modifierGroups,
          ModifierGroupsCompanion.insert(
            id: s('id'),
            name: s('name'),
            minSelect: i('min_select'),
            maxSelect: i('max_select'),
            sortOrder: i('sort_order'),
            isActive: f('is_active'),
            updatedAt: at(),
          ),
          mode: InsertMode.insertOrReplace,
        );
      case 'modifiers':
        b.insert(
          db.modifiers,
          ModifiersCompanion.insert(
            id: s('id'),
            groupId: s('group_id'),
            name: s('name'),
            priceDelta: i('price_delta'),
            sortOrder: i('sort_order'),
            isActive: f('is_active'),
            updatedAt: at(),
          ),
          mode: InsertMode.insertOrReplace,
        );
      case 'product_modifier_groups':
        b.insert(
          db.productModifierGroups,
          ProductModifierGroupsCompanion.insert(
            productId: s('product_id'),
            groupId: s('group_id'),
            sortOrder: i('sort_order'),
            updatedAt: at(),
          ),
          mode: InsertMode.insertOrReplace,
        );
      case 'store_variant_settings':
        b.insert(
          db.storeVariantSettings,
          StoreVariantSettingsCompanion.insert(
            variantId: s('variant_id'),
            priceOverride: Value(oi('price_override')),
            reorderPointMilli: Value(toMilli(j['reorder_point'])),
            reorderQtyMilli: Value(toMilli(j['reorder_qty'])),
            isAvailable: f('is_available'),
            updatedAt: at(),
          ),
          mode: InsertMode.insertOrReplace,
        );
      case 'store_favorites':
        b.insert(
          db.storeFavorites,
          StoreFavoritesCompanion.insert(
            productId: s('product_id'),
            sortOrder: i('sort_order'),
            updatedAt: at(),
          ),
          mode: InsertMode.insertOrReplace,
        );
      case 'stores':
        b.insert(
          db.localStores,
          LocalStoresCompanion.insert(
            id: s('id'),
            code: s('code'),
            name: s('name'),
            address: Value(os('address')),
            phone: Value(os('phone')),
            timezone: s('timezone'),
            fnbMode: f('fnb_mode'),
          ),
          mode: InsertMode.insertOrReplace,
        );
      case 'store_settings':
        b.insert(
          db.localStoreSettings,
          LocalStoreSettingsCompanion.insert(
            storeId: s('store_id'),
            taxEnabled: f('tax_enabled'),
            taxName: s('tax_name'),
            taxRateBps: i('tax_rate_bps'),
            taxInclusive: f('tax_inclusive'),
            serviceChargeEnabled: f('service_charge_enabled'),
            serviceChargeBps: i('service_charge_bps'),
            serviceChargeTaxable: f('service_charge_taxable'),
            roundingMode: s('rounding_mode'),
            roundingUnit: i('rounding_unit'),
            discountApprovalBps: i('discount_approval_bps'),
            kasbonEnabled: f('kasbon_enabled'),
            receiptHeader: Value(os('receipt_header')),
            receiptFooter: s('receipt_footer'),
            receiptPaperMm: i('receipt_paper_mm'),
          ),
          mode: InsertMode.insertOrReplace,
        );
      case 'customers':
        final customer = LocalCustomersCompanion.insert(
          id: s('id'),
          code: Value(os('code')),
          name: s('name'),
          phone: Value(os('phone')),
          pointsBalance: Value(i('points_balance')),
          kasbonLimit: Value(oi('kasbon_limit')),
          isActive: f('is_active'),
          updatedAt: at(),
        );
        b.insert(
          db.localCustomers,
          customer,
          onConflict: DoUpdate(
            (_) => _keepLocalBalances
                ? customer.copyWith(pointsBalance: const Value.absent())
                : customer,
          ),
        );
      case 'receivables':
        final receivable = LocalReceivablesCompanion.insert(
          orderId: s('order_id'),
          receivableId: Value(s('id')),
          customerId: s('customer_id'),
          amount: i('amount'),
          paidAmount: i('paid_amount'),
          dueDate: DateTime.parse('${s('due_date')}T00:00:00Z'),
          status: s('status'),
          updatedAt: at(),
        );
        b.insert(
          db.localReceivables,
          receivable,
          onConflict: DoUpdate(
            (_) => _keepLocalBalances
                ? receivable.copyWith(
                    paidAmount: const Value.absent(),
                    status: const Value.absent(),
                  )
                : receivable,
          ),
        );
      case 'stock_levels':
        b.insert(
          db.stockLevels,
          StockLevelsCompanion.insert(
            variantId: s('variant_id'),
            quantityMilli: toMilli(j['quantity']) ?? 0,
            updatedAt: at(),
          ),
          mode: InsertMode.insertOrReplace,
        );
    }
  }
}

/// A Postgres numeric(14,3) from JSON (number or string) as thousandths.
int? toMilli(Object? value) {
  if (value == null) return null;
  if (value is int) return value * 1000;
  return Qty.parse(value.toString()).milli;
}
