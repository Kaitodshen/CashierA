import 'package:cashiera/core/catalog/catalog_pull_service.dart';
import 'package:cashiera/core/catalog/catalog_source.dart';
import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/pos/pos_config.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const store = 'store-pst';
const at = '2026-11-06T01:00:00.000Z';

class FakeSource implements CatalogSource {
  final tables = <String, List<Map<String, dynamic>>>{};
  final tombstones = <Tombstone>[];

  @override
  Future<List<Map<String, dynamic>>> fetchChanged(
    MirrorSpec spec, {
    required DateTime since,
    required String storeId,
    required int offset,
    required int limit,
  }) async {
    final rows = (tables[spec.table] ?? [])
        .where((r) => !spec.storeScoped || r['store_id'] == storeId)
        .toList();
    return rows.skip(offset).take(limit).toList();
  }

  @override
  Future<List<Tombstone>> fetchTombstones({
    required int afterId,
    int limit = 1000,
  }) async => tombstones.where((t) => t.id > afterId).toList();
}

Map<String, dynamic> method(
  String id,
  String code,
  String type,
  int order, {
  bool reference = false,
}) => {
  'id': id,
  'code': code,
  'name': code.toUpperCase(),
  'method_type': type,
  'requires_reference': reference,
  'sort_order': order,
  'is_active': true,
  'updated_at': at,
};

Map<String, dynamic> promo(String id, {bool active = true}) => {
  'id': id,
  'name': 'Promo $id',
  'promo_type': 'happy_hour',
  'rules': {
    'scope': {'all': true},
    'discount': {'type': 'percent', 'bps': 500},
  },
  'priority': 10,
  'is_stackable': false,
  'is_active': active,
  'updated_at': at,
};

void main() {
  late AppDatabase db;
  late FakeSource source;
  late PosConfigRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    source = FakeSource()
      ..tables.addAll({
        'stores': [
          {
            'id': store,
            'code': 'PST',
            'name': 'CashierA Pusat',
            'address': 'Jl. Merdeka 1',
            'phone': null,
            'timezone': 'Asia/Makassar',
            'fnb_mode': false,
            'updated_at': at,
          },
        ],
        'store_settings': [
          {
            'store_id': store,
            'tax_enabled': true,
            'tax_name': 'PPN',
            'tax_rate_bps': 1100,
            'tax_inclusive': true,
            'service_charge_enabled': false,
            'service_charge_bps': 500,
            'service_charge_taxable': true,
            'rounding_mode': 'nearest',
            'rounding_unit': 100,
            'discount_approval_bps': 2000,
            'kasbon_enabled': true,
            'receipt_header': 'CashierA Pusat',
            'receipt_footer': 'Terima kasih',
            'receipt_paper_mm': 58,
            'updated_at': at,
          },
        ],
        'business_profile': [
          {
            'id': 1,
            'name': 'CashierA',
            'npwp': '01.234.567.8-901.000',
            'kasbon_default_due_days': 14,
            'updated_at': at,
          },
        ],
        'payment_methods': [
          method('m-cash', 'cash', 'cash', 10),
          method('m-qris', 'qris', 'qris', 20),
          method('m-debit', 'debit_card', 'card', 30, reference: true),
        ],
        'store_payment_methods': [
          {
            'store_id': store,
            'payment_method_id': 'm-cash',
            'is_enabled': true,
            'sort_order': 20,
            'updated_at': at,
          },
          {
            'store_id': store,
            'payment_method_id': 'm-qris',
            'is_enabled': false,
            'sort_order': 10,
            'updated_at': at,
          },
          {
            'store_id': store,
            'payment_method_id': 'm-debit',
            'is_enabled': true,
            'sort_order': 5,
            'updated_at': at,
          },
        ],
        'promotions': [
          promo('p-all'),
          promo('p-bks'),
          promo('p-off', active: false),
        ],
        'promotion_stores': [
          {'promotion_id': 'p-bks', 'store_id': 'store-bks', 'updated_at': at},
        ],
        'vouchers': [
          {
            'id': 'vc-1',
            'code': 'HEMAT10',
            'discount_type': 'percent',
            'discount_value': 1000,
            'max_discount': 20000,
            'min_subtotal': 50000,
            'max_uses': 100,
            'used_count': 3,
            'starts_at': null,
            'ends_at': null,
            'is_active': true,
            'updated_at': at,
          },
        ],
        'customers': [
          {
            'id': 'c-1',
            'code': 'C000001',
            'name': 'Sari Wulandari',
            'phone': '081299990001',
            'points_balance': 120,
            'kasbon_limit': 500000,
            'is_active': true,
            'updated_at': at,
          },
        ],
      });
    repo = PosConfigRepository(db);
  });

  tearDown(() => db.close());

  Future<void> pull() =>
      CatalogPullService(db: db, source: source, storeId: store).pull();

  test('the till configuration comes from the mirrors', () async {
    await pull();
    final config = (await repo.load(store))!;
    expect(config.storeCode, 'PST');
    expect(config.utcOffsetMinutes, 8 * 60, reason: 'WITA');
    expect(config.pricing.taxRateBps, 1100);
    expect(config.pricing.serviceChargeBps, 0, reason: 'switched off');
    expect(config.pricing.roundingMode, RoundingMode.nearest);
    expect(config.business.npwp, '01.234.567.8-901.000');
    expect(config.business.kasbonDueDays, 14);
    expect(config.paymentOptions.map((o) => o.code), [
      'debit_card',
      'cash',
    ], reason: 'store order; QRIS is switched off here');
    expect(config.paymentOptions.first.requiresReference, isTrue);
    expect(config.paymentOptions.first.kind, TenderKind.card);
  });

  test('promotions keep their store lists', () async {
    await pull();
    final promos = {for (final p in await repo.promotions()) p.id: p};
    final now = DateTime.utc(2026, 11, 6, 5);
    bool active(String id) =>
        promos[id]!.isActiveAt(now, utcOffsetMinutes: 420, storeId: store);
    expect(active('p-all'), isTrue);
    expect(active('p-bks'), isFalse, reason: 'only for Bekasi');
    expect(active('p-off'), isFalse);
  });

  test('vouchers are found in any case; customers by name or phone', () async {
    await pull();
    final v = (await repo.findVoucher(' hemat10 '))!;
    expect(v.code, 'HEMAT10');
    expect(v.usedCount, 3);
    expect(await repo.findVoucher('NOPE'), isNull);
    expect((await repo.searchCustomers('wulan').first).single.id, 'c-1');
    expect(
      (await repo.searchCustomers('9999').first).single.pointsBalance,
      120,
    );
  });

  test(
    'a deleted store list row from another store is still removed',
    () async {
      await pull();
      source.tombstones.add(
        const Tombstone(
          id: 1,
          table: 'promotion_stores',
          rowPk: {'promotion_id': 'p-bks', 'store_id': 'store-bks'},
          storeId: 'store-bks',
        ),
      );
      source.tables['promotion_stores']!.clear();
      await pull();
      final promos = {for (final p in await repo.promotions()) p.id: p};
      expect(
        promos['p-bks']!.isActiveAt(
          DateTime.utc(2026, 11, 6, 5),
          utcOffsetMinutes: 420,
          storeId: store,
        ),
        isTrue,
        reason: 'no store rows left means every store',
      );
    },
  );
}
