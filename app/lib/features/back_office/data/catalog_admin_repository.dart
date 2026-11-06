import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/features/back_office/data/catalog_admin_models.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Back-office catalog and stock data (online; Supabase with RLS).
class CatalogAdminRepository {
  new(this._client, {this._uuid = const Uuid()});

  final SupabaseClient _client;
  final Uuid _uuid;

  // Categories ----------------------------------------------------------------
  Future<List<AdminCategory>> categories() => _guard(() async {
    final rows = await _client
        .from('categories')
        .select('id, name, sort_order, is_active, color')
        .order('sort_order')
        .order('name');
    return rows.map(AdminCategory.fromJson).toList();
  });

  Future<void> saveCategory({
    required String name,
    String? id,
    String? color,
    int? sortOrder,
    bool isActive = true,
  }) => _guard(() async {
    await _client.from('categories').upsert({
      'id': id ?? _uuid.v7(),
      'name': name.trim(),
      'color': color,
      'sort_order': ?sortOrder,
      'is_active': isActive,
    });
  });

  /// Persists the new order (10, 20, 30 ...) of the cashier-screen pills.
  Future<void> reorderCategories(List<AdminCategory> ordered) =>
      _guard(() async {
        for (final (i, c) in ordered.indexed) {
          if (c.sortOrder == (i + 1) * 10) continue;
          await _client
              .from('categories')
              .update({'sort_order': (i + 1) * 10})
              .eq('id', c.id);
        }
      });

  // Units ---------------------------------------------------------------------
  Future<List<AdminUnit>> units() => _guard(() async {
    final rows = await _client
        .from('units')
        .select('id, code, name, allow_decimal')
        .order('code');
    return rows.map(AdminUnit.fromJson).toList();
  });

  Future<void> addUnit({
    required String code,
    required String name,
    required bool allowDecimal,
  }) => _guard(() async {
    await _client.from('units').insert({
      'code': code.trim().toLowerCase(),
      'name': name.trim(),
      'allow_decimal': allowDecimal,
    });
  });

  // Suppliers -----------------------------------------------------------------
  Future<List<AdminSupplier>> suppliers() => _guard(() async {
    final rows = await _client.from('suppliers').select().order('name');
    return rows.map(AdminSupplier.fromJson).toList();
  });

  Future<void> saveSupplier(AdminSupplier supplier) => _guard(() async {
    await _client.from('suppliers').upsert(supplier.toJson());
  });

  // Products ------------------------------------------------------------------
  Future<List<ProductSummary>> products({
    String search = '',
    String? categoryId,
  }) => _guard(() async {
    var query = _client
        .from('products')
        .select(
          'id, name, is_active, category:categories(name), unit:units(code), '
          'variants:product_variants(price, is_active)',
        )
        .neq('product_type', 'ingredient');
    if (search.trim().isNotEmpty) {
      query = query.ilike('name', '%${search.trim()}%');
    }
    if (categoryId != null) query = query.eq('category_id', categoryId);
    final rows = await query.order('name').limit(500);
    return rows.map(ProductSummary.fromJson).toList();
  });

  Future<ProductDraft> product(String id) => _guard(() async {
    final p = await _client
        .from('products')
        .select(
          'id, name, category_id, unit_id, is_taxable, track_stock, is_active, '
          'variants:product_variants(id, name, sku, barcode, price, cost, '
          'is_active, sort_order)',
        )
        .eq('id', id)
        .single();
    final variants =
        [
          for (final v in (p['variants'] as List).cast<Map<String, dynamic>>())
            v,
        ]..sort(
          (a, b) => (a['sort_order'] as int).compareTo(b['sort_order'] as int),
        );
    final ids = variants.map((v) => v['id'] as String).toList();
    final settings = ids.isEmpty
        ? const <Map<String, dynamic>>[]
        : await _client
              .from('store_variant_settings')
              .select(
                'store_id, variant_id, price_override, reorder_point, '
                'is_available',
              )
              .inFilter('variant_id', ids);
    return ProductDraft(
      id: p['id'] as String,
      name: p['name'] as String,
      categoryId: p['category_id'] as String?,
      unitId: p['unit_id'] as String,
      isTaxable: p['is_taxable'] as bool,
      trackStock: p['track_stock'] as bool,
      isActive: p['is_active'] as bool,
      variants: variants.map(VariantDraft.fromJson).toList(),
      storeSettings: settings.map(StoreSettingDraft.fromJson).toList(),
    );
  });

  ProductDraft newProduct(String unitId) => ProductDraft(
    id: _uuid.v7(),
    unitId: unitId,
    variants: [VariantDraft(id: _uuid.v7())],
  );

  VariantDraft newVariant() => VariantDraft(id: _uuid.v7(), name: '');

  Future<void> saveProduct(ProductDraft draft) => _guard(() async {
    await _client.rpc<dynamic>('save_product', params: {'p': draft.toJson()});
  });

  // Stock ---------------------------------------------------------------------
  Future<List<StockRow>> stockOverview(String storeId) => _guard(() async {
    final rows = await _client.rpc<dynamic>(
      'stock_overview',
      params: {'p_store_id': storeId},
    );
    return [
      for (final r in rows as List)
        StockRow.fromJson((r as Map).cast<String, dynamic>()),
    ];
  });

  Future<List<MovementRow>> movements(String storeId, String variantId) =>
      _guard(() async {
        final rows = await _client
            .from('stock_movements')
            .select(
              'created_at, movement_type, quantity_delta, balance_after, note',
            )
            .eq('store_id', storeId)
            .eq('variant_id', variantId)
            .order('created_at', ascending: false)
            .limit(50);
        return rows.map(MovementRow.fromJson).toList();
      });

  Future<List<AlertRow>> openAlerts(String storeId) => _guard(() async {
    final rows = await _client
        .from('alerts')
        .select('id, alert_type, message, created_at')
        .eq('store_id', storeId)
        .neq('status', 'resolved')
        .inFilter('alert_type', [
          'LOW_STOCK',
          'STOCK_DISCREPANCY',
          'TRANSFER_DISCREPANCY',
        ])
        .order('created_at', ascending: false)
        .limit(100);
    return rows.map(AlertRow.fromJson).toList();
  });

  Future<void> resolveAlert(String alertId, String employeeId) =>
      _guard(() async {
        await _client
            .from('alerts')
            .update({
              'status': 'resolved',
              'resolved_by': employeeId,
              'resolved_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', alertId);
      });

  /// Stock in/out from the back office goes through the same validated path
  /// as terminals (`sync_push`, acting as the signed-in employee).
  Future<void> adjustStock({
    required String storeId,
    required String employeeId,
    required String variantId,
    required Qty delta,
    required String reason,
    String? note,
  }) => _guard(() async {
    final result = await _client.rpc<dynamic>(
      'sync_push',
      params: {
        'p_client_uuid': _uuid.v7(),
        'p_entity': 'stock_adjustment',
        'p_action': 'create',
        'p_payload': {
          'id': _uuid.v7(),
          'store_id': storeId,
          'adjustment_number':
              'ADJ-BO-${DateTime.now().millisecondsSinceEpoch}',
          'reason': reason,
          'note': note,
          'employee_id': employeeId,
          'items': [
            {
              'id': _uuid.v7(),
              'variant_id': variantId,
              'quantity_delta': delta.toPayload(),
            },
          ],
        },
      },
    );
    final map = (result as Map).cast<String, dynamic>();
    if (map['status'] == 'rejected') {
      throw BackendException(
        map['code'] as String? ?? 'rejected',
        map['message'] as String? ?? '',
      );
    }
  });

  // Import / export --------------------------------------------------------------
  Future<ImportSummary> importCatalog(List<CatalogImportRow> rows) =>
      _guard(() async {
        final result = await _client.rpc<dynamic>(
          'import_catalog',
          params: {
            'p_rows': [for (final r in rows) r.toJson()],
          },
        );
        return ImportSummary((result as Map).cast<String, dynamic>());
      });

  Future<List<CatalogExportRow>> exportCatalog() => _guard(() async {
    final rows = await _client.rpc<dynamic>('catalog_export');
    return [
      for (final r in (rows as List).cast<Map<String, dynamic>>())
        CatalogExportRow(
          productName: r['product_name'] as String,
          variantName: r['variant_name'] as String,
          sku: r['sku'] as String,
          barcode: r['barcode'] as String?,
          category: r['category'] as String? ?? '',
          unit: r['unit'] as String,
          price: (r['price'] as num).toInt(),
          cost: (r['cost'] as num).toInt(),
          taxable: r['taxable'] as bool,
          trackStock: r['track_stock'] as bool,
          reorderPoint: r['reorder_point'] == null
              ? null
              : Qty.parse('${r['reorder_point']}'),
          stock: {
            for (final e in ((r['stock'] as Map?) ?? const {}).entries)
              e.key as String: Qty.parse('${e.value}'),
          },
        ),
    ];
  });
}

Future<T> _guard<T>(Future<T> Function() body) async {
  try {
    return await body();
  } on PostgrestException catch (e) {
    throw BackendException.fromMessage(e.message);
  }
}
