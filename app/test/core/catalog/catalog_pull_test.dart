import 'dart:convert';

import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/catalog/catalog_pull_service.dart';
import 'package:cashiera/core/catalog/catalog_source.dart';
import 'package:cashiera/core/catalog/stock_service.dart';
import 'package:cashiera/core/catalog/terminal_catalog_repository.dart';
import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const store = 'store-pst';

/// In-memory server: rows per table, tombstones, and a log of requests.
class FakeSource implements CatalogSource {
  final tables = <String, List<Map<String, dynamic>>>{};
  final tombstones = <Tombstone>[];
  final requests = <String>[];

  void put(String table, Map<String, dynamic> row) {
    final rows = tables.putIfAbsent(table, () => []);
    final key = row['id'] ?? row['variant_id'] ?? row['product_id'];
    rows
      ..removeWhere(
        (r) => (r['id'] ?? r['variant_id'] ?? r['product_id']) == key,
      )
      ..add(row);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchChanged(
    MirrorSpec spec, {
    required DateTime since,
    required String storeId,
    required int offset,
    required int limit,
  }) async {
    requests.add('${spec.table}@${since.toUtc().toIso8601String()}+$offset');
    final rows =
        (tables[spec.table] ?? [])
            .where(
              (r) => !DateTime.parse(r['updated_at'] as String).isBefore(since),
            )
            .where((r) => !spec.storeScoped || r['store_id'] == storeId)
            .toList()
          ..sort(
            (a, b) => (a['updated_at'] as String).compareTo(
              b['updated_at'] as String,
            ),
          );
    return rows.skip(offset).take(limit).toList();
  }

  @override
  Future<List<Tombstone>> fetchTombstones({
    required int afterId,
    int limit = 1000,
  }) async => tombstones.where((t) => t.id > afterId).toList();
}

String ts(int minute) => DateTime.utc(2026, 11, 5, 3, minute).toIso8601String();

void seed(FakeSource s) {
  s
    ..put('units', {
      'id': 'u-pcs', 'code': 'pcs', 'name': 'Pcs', 'allow_decimal': false, //
      'updated_at': ts(0),
    })
    ..put('units', {
      'id': 'u-kg', 'code': 'kg', 'name': 'Kg', 'allow_decimal': true, //
      'updated_at': ts(0),
    })
    ..put('categories', {
      'id': 'c-drink',
      'parent_id': null,
      'name': 'Minuman',
      'sort_order': 10,
      'color': '#0EA5E9',
      'icon': null,
      'kitchen_station': null,
      'is_active': true,
      'updated_at': ts(1),
    })
    ..put('products', {
      'id': 'p-air',
      'category_id': 'c-drink',
      'unit_id': 'u-pcs',
      'name': 'Air Mineral',
      'description': null,
      'product_type': 'standard',
      'track_stock': true,
      'is_taxable': true,
      'kitchen_station': null,
      'image_path': null,
      'is_active': true,
      'updated_at': ts(2),
    })
    ..put('products', {
      'id': 'p-bawang',
      'category_id': null,
      'unit_id': 'u-kg',
      'name': 'Bawang Merah',
      'description': null,
      'product_type': 'standard',
      'track_stock': true,
      'is_taxable': false,
      'kitchen_station': null,
      'image_path': null,
      'is_active': true,
      'updated_at': ts(2),
    })
    ..put('product_variants', {
      'id': 'v-600',
      'product_id': 'p-air',
      'name': '600 ml',
      'sku': 'MNM-AIR-600',
      'barcode': '2000000000015',
      'price': 4000,
      'cost': 2600,
      'sort_order': 1,
      'is_active': true,
      'updated_at': ts(3),
    })
    ..put('product_variants', {
      'id': 'v-bawang',
      'product_id': 'p-bawang',
      'name': 'Per kg',
      'sku': 'SYR-BWM-KG',
      'barcode': null,
      'price': 42000,
      'cost': 34000,
      'sort_order': 1,
      'is_active': true,
      'updated_at': ts(3),
    })
    ..put('store_variant_settings', {
      'store_id': store,
      'variant_id': 'v-600',
      'price_override': 4500,
      'reorder_point': 10,
      'reorder_qty': 24,
      'is_available': true,
      'updated_at': ts(4),
    })
    ..put('store_variant_settings', {
      'store_id': 'store-other',
      'variant_id': 'v-bawang',
      'price_override': 1,
      'reorder_point': 1,
      'reorder_qty': null,
      'is_available': true,
      'updated_at': ts(4),
    })
    ..put('stock_levels', {
      'store_id': store,
      'variant_id': 'v-600',
      'quantity': 12,
      'updated_at': ts(5),
    })
    ..put('stock_levels', {
      'store_id': store,
      'variant_id': 'v-bawang',
      'quantity': 12.5,
      'updated_at': ts(5),
    });
}

const manager = StaffMember(
  employeeId: 'e-budi',
  fullName: 'Budi Santoso',
  roleCode: 'manager',
  permissions: {'inventory.adjust', 'inventory.opname'},
  pinHash: null,
);

void main() {
  late AppDatabase db;
  late FakeSource source;
  late CatalogPullService service;
  late TerminalCatalogRepository catalog;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    source = FakeSource();
    seed(source);
    service = CatalogPullService(
      db: db,
      source: source,
      storeId: store,
      pageSize: 2,
    );
    catalog = TerminalCatalogRepository(db);
  });

  tearDown(() => db.close());

  Future<List<String>> names() async =>
      (await catalog.watchItems().first).map((i) => i.displayName).toList();

  test('first pull loads everything, across pages', () async {
    final summary = await service.pull();
    // 2 units + 1 category + 2 products + 2 variants + 1 own-store setting
    // + 2 stock rows, read 2 per page.
    expect(summary.rows, 10);
    expect(await names(), ['Air Mineral · 600 ml', 'Bawang Merah · Per kg']);
    final air = (await catalog.findByCode('2000000000015'))!;
    expect(air.price, const Money(4500), reason: 'store override wins');
    expect(air.basePrice, const Money(4000));
    expect(air.stock, Qty.parse('12'));
    expect(air.isLow, isFalse);
    final bawang = (await catalog.findByCode('syr-bwm-kg'))!;
    expect(bawang.stock, Qty.parse('12.5'), reason: 'numeric → thousandths');
    expect(bawang.allowDecimal, isTrue);
    expect(bawang.priceOverride, isNull, reason: 'other store ignored');
  });

  test('JSON numerics become thousandths', () {
    expect(toMilli(12), 12000);
    expect(toMilli(12.5), 12500);
    expect(toMilli('0.125'), 125);
    expect(toMilli(null), isNull);
  });

  test('second pull reads from cursor minus 5 minutes, idempotent', () async {
    await service.pull();
    source.requests.clear();
    final again = await service.pull();
    // Newest variant row was 03:03, so the next pull starts at 02:58.
    expect(source.requests, contains('product_variants@${ts(-2)}+0'));
    expect(again.rows, greaterThan(0), reason: 'overlap re-reads rows');
    expect(await names(), hasLength(2), reason: 'no duplicates');
  });

  test('changes on the server arrive on the next pull', () async {
    await service.pull();
    source
      ..put('product_variants', {
        'id': 'v-600',
        'product_id': 'p-air',
        'name': '600 ml',
        'sku': 'MNM-AIR-600',
        'barcode': '2000000000015',
        'price': 4200,
        'cost': 2600,
        'sort_order': 1,
        'is_active': true,
        'updated_at': ts(30),
      })
      ..put('stock_levels', {
        'store_id': store,
        'variant_id': 'v-600',
        'quantity': 3,
        'updated_at': ts(31),
      });
    await service.pull();
    final air = (await catalog.findByCode('MNM-AIR-600'))!;
    expect(air.basePrice, const Money(4200));
    expect(air.stock, Qty.parse('3'));
    expect(air.isLow, isTrue, reason: 'reorder point 10');
  });

  test('a tombstone removes the row locally', () async {
    await service.pull();
    source.tombstones.add(
      const Tombstone(
        id: 7,
        table: 'product_variants',
        rowPk: {'id': 'v-bawang'},
      ),
    );
    final summary = await service.pull();
    expect(summary.deleted, 1);
    expect(await names(), ['Air Mineral · 600 ml']);
    // The tombstone cursor moved: the same delete is not fetched again.
    expect((await service.pull()).deleted, 0);
  });

  test(
    'stock is not overwritten while a local stock change is queued',
    () async {
      await service.pull();
      await StockService(db).adjust(
        storeId: store,
        deviceCode: 'T1',
        staff: manager,
        variantId: 'v-600',
        quantity: Qty.parse('24'),
        reason: StockReason.stockIn,
      );
      expect((await catalog.findByCode('MNM-AIR-600'))!.stock, Qty.parse('36'));

      // The server has not seen the adjustment yet and still says 12.
      source.put('stock_levels', {
        'store_id': store,
        'variant_id': 'v-600',
        'quantity': 12,
        'updated_at': ts(40),
      });
      final summary = await service.pull();
      expect(summary.stockSkipped, isTrue);
      expect((await catalog.findByCode('MNM-AIR-600'))!.stock, Qty.parse('36'));
    },
  );

  group('StockService', () {
    setUp(() => service.pull());

    test('stock out and the queued payload', () async {
      await StockService(db).adjust(
        storeId: store,
        deviceCode: 'T1',
        staff: manager,
        variantId: 'v-bawang',
        quantity: Qty.parse('0.75'),
        reason: StockReason.damaged,
        note: 'Busuk',
      );
      expect(
        (await catalog.findByCode('SYR-BWM-KG'))!.stock,
        Qty.parse('11.75'),
      );
      final item = (await db.select(db.syncQueue).get()).single;
      expect(item.entity, 'stock_adjustment');
      final payload = jsonDecode(item.payload) as Map<String, dynamic>;
      expect(payload['reason'], 'damaged');
      expect(payload['employee_id'], 'e-budi');
      expect(payload['adjustment_number'], startsWith('ADJ-T1-'));
      expect(
        (payload['items'] as List).single,
        containsPair('quantity_delta', '-0.750'),
      );
    });

    test('opname sets local stock to the counts', () async {
      await StockService(db).submitOpname(
        storeId: store,
        deviceCode: 'T1',
        staff: manager,
        counts: {'v-600': Qty.parse('5'), 'v-bawang': Qty.parse('10.25')},
      );
      expect((await catalog.findByCode('MNM-AIR-600'))!.stock, Qty.parse('5'));
      final payload = jsonDecode(
        (await db.select(db.syncQueue).get()).single.payload,
      ) as Map<String, dynamic>;
      expect(payload['items'], [
        {'variant_id': 'v-600', 'counted_qty': '5.000'},
        {'variant_id': 'v-bawang', 'counted_qty': '10.250'},
      ]);
    });

    test('cashiers without inventory permissions are refused', () {
      const cashier = StaffMember(
        employeeId: 'e-eko',
        fullName: 'Eko',
        roleCode: 'cashier',
        permissions: {'pos.sell'},
        pinHash: null,
      );
      expect(
        () => StockService(db).adjust(
          storeId: store,
          deviceCode: 'T1',
          staff: cashier,
          variantId: 'v-600',
          quantity: Qty.parse('1'),
          reason: StockReason.stockIn,
        ),
        throwsA(isA<StockPermissionException>()),
      );
    });
  });
}
