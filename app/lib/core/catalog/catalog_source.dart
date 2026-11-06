import 'package:supabase_flutter/supabase_flutter.dart';

/// One server table the terminal mirrors.
class MirrorSpec {
  const new(
    this.table, {
    required this.orderKey,
    this.storeScoped = false,
    this.isStock = false,
    this.jsonKey,
  });

  final String table;

  /// Tie-breaker after updated_at, so paging is stable.
  final String orderKey;

  /// Filtered to this terminal's store.
  final bool storeScoped;

  /// stock_levels: skipped while stock-changing items wait in the outbox.
  final bool isStock;

  /// Kept as JSON in `mirror_records`, keyed by these columns.
  final List<String>? jsonKey;

  bool get isJson => jsonKey != null;

  /// The `mirror_records.pk` of [row] (a server row or a tombstone key).
  String keyOf(Map<String, dynamic> row) =>
      jsonKey!.map((c) => '${row[c]}').join('|');
}

/// Mirrored tables, parents before children.
const mirrorSpecs = [
  MirrorSpec('units', orderKey: 'id'),
  MirrorSpec('categories', orderKey: 'id'),
  MirrorSpec('products', orderKey: 'id'),
  MirrorSpec('product_variants', orderKey: 'id'),
  MirrorSpec('modifier_groups', orderKey: 'id'),
  MirrorSpec('modifiers', orderKey: 'id'),
  MirrorSpec('product_modifier_groups', orderKey: 'product_id'),
  MirrorSpec(
    'store_variant_settings',
    orderKey: 'variant_id',
    storeScoped: true,
  ),
  MirrorSpec('store_favorites', orderKey: 'product_id', storeScoped: true),
  MirrorSpec(
    'stock_levels',
    orderKey: 'variant_id',
    storeScoped: true,
    isStock: true,
  ),
  // Phase 4: the cashier screen.
  MirrorSpec('stores', orderKey: 'id'),
  MirrorSpec('store_settings', orderKey: 'store_id', storeScoped: true),
  MirrorSpec('business_profile', orderKey: 'id', jsonKey: ['id']),
  MirrorSpec('payment_methods', orderKey: 'id', jsonKey: ['id']),
  MirrorSpec(
    'store_payment_methods',
    orderKey: 'payment_method_id',
    storeScoped: true,
    jsonKey: ['store_id', 'payment_method_id'],
  ),
  MirrorSpec('promotions', orderKey: 'id', jsonKey: ['id']),
  // Every store's rows: an empty list means "all stores", so the terminal
  // must see the rows of other stores too.
  MirrorSpec(
    'promotion_stores',
    orderKey: 'promotion_id',
    jsonKey: ['promotion_id', 'store_id'],
  ),
  MirrorSpec('vouchers', orderKey: 'id', jsonKey: ['id']),
  MirrorSpec('customers', orderKey: 'id'),
  // Phase 6: this store's kasbon.
  MirrorSpec('receivables', orderKey: 'id', storeScoped: true),
  // Phase 8: this store's dining tables (F&B).
  MirrorSpec(
    'dining_tables',
    orderKey: 'id',
    storeScoped: true,
    jsonKey: ['id'],
  ),
];

MirrorSpec? mirrorSpecFor(String table) {
  for (final spec in mirrorSpecs) {
    if (spec.table == table) return spec;
  }
  return null;
}

/// A server-side hard delete (public.sync_tombstones).
class Tombstone {
  const new({
    required this.id,
    required this.table,
    required this.rowPk,
    this.storeId,
  });

  factory fromJson(Map<String, dynamic> json) => Tombstone(
    id: (json['id'] as num).toInt(),
    table: json['table_name'] as String,
    rowPk: (json['row_pk'] as Map).cast<String, dynamic>(),
    storeId: json['store_id'] as String?,
  );

  final int id;
  final String table;
  final Map<String, dynamic> rowPk;
  final String? storeId;
}

abstract interface class CatalogSource {
  /// Rows of [spec] with updated_at >= [since], ordered by updated_at.
  Future<List<Map<String, dynamic>>> fetchChanged(
    MirrorSpec spec, {
    required DateTime since,
    required String storeId,
    required int offset,
    required int limit,
  });

  /// Tombstones with id > [afterId], oldest first.
  Future<List<Tombstone>> fetchTombstones({required int afterId, int limit});
}

class SupabaseCatalogSource implements CatalogSource {
  new(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Map<String, dynamic>>> fetchChanged(
    MirrorSpec spec, {
    required DateTime since,
    required String storeId,
    required int offset,
    required int limit,
  }) async {
    var query = _client
        .from(spec.table)
        .select()
        .gte('updated_at', since.toUtc().toIso8601String());
    if (spec.storeScoped) query = query.eq('store_id', storeId);
    final rows = await query
        .order('updated_at', ascending: true)
        .order(spec.orderKey, ascending: true)
        .range(offset, offset + limit - 1);
    return rows;
  }

  @override
  Future<List<Tombstone>> fetchTombstones({
    required int afterId,
    int limit = 1000,
  }) async {
    final rows = await _client
        .from('sync_tombstones')
        .select()
        .gt('id', afterId)
        .order('id', ascending: true)
        .limit(limit);
    return rows.map(Tombstone.fromJson).toList();
  }
}
