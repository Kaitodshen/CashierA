import 'package:cashiera/core/catalog/catalog_item.dart';
import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:drift/drift.dart';

/// Read side of the terminal catalog (local SQLite only, works offline).
class TerminalCatalogRepository {
  new(this._db);

  final AppDatabase _db;

  static const _select = '''
SELECT v.id AS variant_id, p.id AS product_id, p.name AS product_name,
       v.name AS variant_name, v.sku, v.barcode, p.category_id,
       u.code AS unit_code, u.allow_decimal, v.price AS base_price,
       s.price_override, p.is_taxable, p.track_stock,
       COALESCE(st.quantity_milli, 0) AS stock_milli,
       s.reorder_point_milli, COALESCE(s.is_available, 1) AS is_available,
       v.cost, fav.sort_order AS favorite_order,
       EXISTS (SELECT 1 FROM product_modifier_groups pmg
               WHERE pmg.product_id = p.id) AS has_modifiers
FROM product_variants v
JOIN products p ON p.id = v.product_id
JOIN units u ON u.id = p.unit_id
LEFT JOIN store_variant_settings s ON s.variant_id = v.id
LEFT JOIN stock_levels st ON st.variant_id = v.id
LEFT JOIN store_favorites fav ON fav.product_id = p.id
WHERE v.is_active = 1 AND p.is_active = 1 AND p.product_type <> 'ingredient'
''';

  Set<ResultSetImplementation<dynamic, dynamic>> get _tables => {
    _db.productVariants,
    _db.products,
    _db.units,
    _db.storeVariantSettings,
    _db.stockLevels,
    _db.storeFavorites,
    _db.productModifierGroups,
  };

  /// Items matching [search] (name, variant, SKU contains; barcode exact) in
  /// [categoryId], or all.
  Stream<List<CatalogItem>> watchItems({
    String search = '',
    String? categoryId,
  }) {
    final term = search.trim();
    return _db
        .customSelect(
          '$_select'
          'AND (?1 IS NULL OR p.category_id = ?1) '
          "AND (?2 = '' OR p.name LIKE ?3 OR v.name LIKE ?3 "
          'OR v.sku LIKE ?3 OR v.barcode = ?2) '
          'ORDER BY p.name COLLATE NOCASE, v.sort_order',
          variables: [
            Variable<String>(categoryId),
            Variable<String>(term),
            Variable<String>('%$term%'),
          ],
          readsFrom: _tables,
        )
        .watch()
        .map((rows) => rows.map(_item).toList());
  }

  /// Exact barcode or SKU (any case): what a barcode scanner types.
  Future<CatalogItem?> findByCode(String code) async {
    final term = code.trim();
    if (term.isEmpty) return null;
    final row = await _db
        .customSelect(
          '$_select AND (v.barcode = ?1 OR v.sku = ?1 COLLATE NOCASE) LIMIT 1',
          variables: [Variable<String>(term)],
          readsFrom: _tables,
        )
        .getSingleOrNull();
    return row == null ? null : _item(row);
  }

  /// The product's active modifier groups and options, in display order.
  Future<List<ModifierGroupOption>> modifierGroups(String productId) async {
    final groups = await _db
        .customSelect(
          'SELECT g.id, g.name, g.min_select, g.max_select '
          'FROM product_modifier_groups pmg '
          'JOIN modifier_groups g ON g.id = pmg.group_id '
          'WHERE pmg.product_id = ?1 AND g.is_active = 1 '
          'ORDER BY pmg.sort_order, g.sort_order',
          variables: [Variable<String>(productId)],
          readsFrom: {_db.productModifierGroups, _db.modifierGroups},
        )
        .get();
    return [
      for (final g in groups)
        ModifierGroupOption(
          id: g.read<String>('id'),
          name: g.read<String>('name'),
          minSelect: g.read<int>('min_select'),
          maxSelect: g.read<int>('max_select'),
          options: [
            for (final m
                in await (_db.select(_db.modifiers)
                      ..where(
                        (m) =>
                            m.groupId.equals(g.read<String>('id')) &
                            m.isActive.equals(true),
                      )
                      ..orderBy([(m) => OrderingTerm.asc(m.sortOrder)]))
                    .get())
              ModifierOption(
                id: m.id,
                name: m.name,
                priceDelta: Money(m.priceDelta),
              ),
          ],
        ),
    ];
  }

  Stream<List<CatalogCategory>> watchCategories() =>
      (_db.select(_db.categories)
            ..where((c) => c.isActive.equals(true))
            ..orderBy([
              (c) => OrderingTerm.asc(c.sortOrder),
              (c) => OrderingTerm.asc(c.name),
            ]))
          .watch()
          .map(
            (rows) => [
              for (final c in rows)
                CatalogCategory(id: c.id, name: c.name, color: c.color),
            ],
          );

  CatalogItem _item(QueryRow r) {
    final reorder = r.readNullable<int>('reorder_point_milli');
    final override = r.readNullable<int>('price_override');
    return CatalogItem(
      variantId: r.read<String>('variant_id'),
      productId: r.read<String>('product_id'),
      productName: r.read<String>('product_name'),
      variantName: r.read<String>('variant_name'),
      sku: r.read<String>('sku'),
      barcode: r.readNullable<String>('barcode'),
      categoryId: r.readNullable<String>('category_id'),
      unitCode: r.read<String>('unit_code'),
      allowDecimal: r.read<bool>('allow_decimal'),
      basePrice: Money(r.read<int>('base_price')),
      priceOverride: override == null ? null : Money(override),
      isTaxable: r.read<bool>('is_taxable'),
      trackStock: r.read<bool>('track_stock'),
      stock: Qty(r.read<int>('stock_milli')),
      reorderPoint: reorder == null ? null : Qty(reorder),
      isAvailable: r.read<bool>('is_available'),
      cost: Money(r.read<int>('cost')),
      favoriteOrder: r.readNullable<int>('favorite_order'),
      hasModifiers: r.read<bool>('has_modifiers'),
    );
  }
}
