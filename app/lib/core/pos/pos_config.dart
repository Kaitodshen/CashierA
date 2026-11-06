import 'dart:convert';

import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

/// Indonesian store time zones have fixed offsets (no daylight saving).
int utcOffsetMinutesFor(String timezone) => switch (timezone) {
  'Asia/Makassar' => 8 * 60,
  'Asia/Jayapura' => 9 * 60,
  _ => 7 * 60,
};

/// A payment method this store accepts.
@immutable
class PaymentOption {
  const new({
    required this.id,
    required this.code,
    required this.name,
    required this.kind,
    required this.requiresReference,
  });

  final String id;
  final String code;
  final String name;
  final TenderKind kind;
  final bool requiresReference;
}

/// Company profile fields the till uses.
@immutable
class BusinessInfo {
  const new({
    required this.name,
    this.legalName,
    this.npwp,
    this.address,
    this.phone,
    this.kasbonDueDays = 30,
    this.loyalty = const LoyaltyRules(
      earnAmount: Money(10000),
      pointValue: Money(100),
    ),
  });

  factory fromJson(Map<String, dynamic> j) => BusinessInfo(
    name: j['name'] as String,
    legalName: j['legal_name'] as String?,
    npwp: j['npwp'] as String?,
    address: j['address'] as String?,
    phone: j['phone'] as String?,
    kasbonDueDays: (j['kasbon_default_due_days'] as num? ?? 30).toInt(),
    loyalty: LoyaltyRules(
      enabled: j['loyalty_enabled'] as bool? ?? true,
      earnAmount: Money((j['loyalty_earn_amount'] as num? ?? 10000).toInt()),
      pointValue: Money((j['loyalty_point_value'] as num? ?? 100).toInt()),
      minRedeemPoints: (j['loyalty_min_redeem_points'] as num? ?? 0).toInt(),
    ),
  );

  final String name;
  final String? legalName;
  final String? npwp;
  final String? address;
  final String? phone;
  final int kasbonDueDays;

  /// Company loyalty settings (A6).
  final LoyaltyRules loyalty;
}

/// Everything about the store that changes how a sale is rung up.
@immutable
class PosConfig {
  const new({
    required this.storeId,
    required this.storeCode,
    required this.storeName,
    required this.utcOffsetMinutes,
    required this.pricing,
    required this.taxName,
    required this.taxEnabled,
    required this.discountApprovalBps,
    required this.kasbonEnabled,
    required this.receiptFooter,
    required this.paperMm,
    required this.business,
    required this.paymentOptions,
    this.storeAddress,
    this.storePhone,
    this.receiptHeader,
  });

  final String storeId;
  final String storeCode;
  final String storeName;
  final String? storeAddress;
  final String? storePhone;
  final int utcOffsetMinutes;
  final PricingSettings pricing;
  final String taxName;
  final bool taxEnabled;
  final int discountApprovalBps;
  final bool kasbonEnabled;
  final String? receiptHeader;
  final String receiptFooter;
  final int paperMm;
  final BusinessInfo business;
  final List<PaymentOption> paymentOptions;

  /// Store-local wall-clock time of [instant].
  DateTime localTime(DateTime instant) =>
      instant.toUtc().add(Duration(minutes: utcOffsetMinutes));

  /// The store-local date (`business_date`) of [instant].
  DateTime businessDate(DateTime instant) {
    final local = localTime(instant);
    return DateTime.utc(local.year, local.month, local.day);
  }
}

/// Reads the till configuration and promotions from the local mirrors.
class PosConfigRepository {
  new(this._db);

  final AppDatabase _db;

  Future<List<Map<String, dynamic>>> _records(String table) async {
    final rows = await (_db.select(
      _db.mirrorRecords,
    )..where((r) => r.sourceTable.equals(table))).get();
    return [
      for (final r in rows) (jsonDecode(r.data) as Map).cast<String, dynamic>(),
    ];
  }

  Future<PosConfig?> load(String storeId) async {
    final store = await (_db.select(
      _db.localStores,
    )..where((s) => s.id.equals(storeId))).getSingleOrNull();
    final s = await (_db.select(
      _db.localStoreSettings,
    )..where((x) => x.storeId.equals(storeId))).getSingleOrNull();
    if (store == null || s == null) return null;

    final profiles = await _records('business_profile');
    final methods = await _records('payment_methods');
    final storeMethods = {
      for (final m in await _records('store_payment_methods'))
        if (m['store_id'] == storeId) m['payment_method_id'] as String: m,
    };
    int order(Map<String, dynamic> m) =>
        ((storeMethods[m['id']]?['sort_order'] ?? m['sort_order']) as num)
            .toInt();
    final options =
        methods
            .where((m) => m['is_active'] == true)
            .where(
              (m) =>
                  storeMethods.isEmpty ||
                  storeMethods[m['id']]?['is_enabled'] == true,
            )
            .toList()
          ..sort((a, b) => order(a).compareTo(order(b)));

    return PosConfig(
      storeId: store.id,
      storeCode: store.code,
      storeName: store.name,
      storeAddress: store.address,
      storePhone: store.phone,
      utcOffsetMinutes: utcOffsetMinutesFor(store.timezone),
      pricing: PricingSettings(
        taxRateBps: s.taxEnabled ? s.taxRateBps : 0,
        taxInclusive: s.taxInclusive,
        serviceChargeBps: s.serviceChargeEnabled ? s.serviceChargeBps : 0,
        serviceChargeTaxable: s.serviceChargeTaxable,
        roundingMode: RoundingMode.fromCode(s.roundingMode),
        roundingUnit: s.roundingUnit,
      ),
      taxName: s.taxName,
      taxEnabled: s.taxEnabled && s.taxRateBps > 0,
      discountApprovalBps: s.discountApprovalBps,
      kasbonEnabled: s.kasbonEnabled,
      receiptHeader: s.receiptHeader,
      receiptFooter: s.receiptFooter,
      paperMm: s.receiptPaperMm,
      business: profiles.isEmpty
          ? BusinessInfo(name: store.name)
          : BusinessInfo.fromJson(profiles.first),
      paymentOptions: [
        for (final m in options)
          PaymentOption(
            id: m['id'] as String,
            code: m['code'] as String,
            name: m['name'] as String,
            kind: TenderKind.fromCode(m['method_type'] as String),
            requiresReference: m['requires_reference'] as bool? ?? false,
          ),
      ],
    );
  }

  Stream<PosConfig?> watch(String storeId) => _db
      .customSelect(
        'SELECT 1',
        readsFrom: {_db.localStores, _db.localStoreSettings, _db.mirrorRecords},
      )
      .watch()
      .asyncMap((_) => load(storeId));

  /// Every promotion with its store list; filter with `isActiveAt`.
  Future<List<Promotion>> promotions() async {
    final stores = <String, Set<String>>{};
    for (final r in await _records('promotion_stores')) {
      stores
          .putIfAbsent(r['promotion_id'] as String, () => {})
          .add(r['store_id'] as String);
    }
    final result = <Promotion>[];
    for (final p in await _records('promotions')) {
      try {
        result.add(
          Promotion.fromJson(p, storeIds: stores[p['id']] ?? const {}),
        );
      } on Object catch (e) {
        // A rule shape this app version does not know: skip it rather than
        // break the till. The server keeps validating every order.
        debugPrint('skipped promotion ${p['id']}: $e');
      }
    }
    return result;
  }

  Stream<List<Promotion>> watchPromotions() =>
      (_db.select(_db.mirrorRecords)..where(
            (r) => r.sourceTable.isIn(['promotions', 'promotion_stores']),
          ))
          .watch()
          .asyncMap((_) => promotions());

  /// The voucher with [code] (any case), or null.
  Future<Voucher?> findVoucher(String code) async {
    final wanted = code.trim().toUpperCase();
    for (final v in await _records('vouchers')) {
      if ((v['code'] as String).toUpperCase() == wanted) {
        return Voucher.fromJson(v);
      }
    }
    return null;
  }

  /// Customers whose name or phone contains [query], best matches first.
  Stream<List<CustomerRow>> searchCustomers(String query, {int limit = 30}) {
    final term = query.trim();
    final select = _db.select(_db.localCustomers)
      ..where((c) => c.isActive.equals(true));
    if (term.isNotEmpty) {
      select.where((c) => c.name.like('%$term%') | c.phone.like('%$term%'));
    }
    select
      ..orderBy([(c) => OrderingTerm.asc(c.name)])
      ..limit(limit);
    return select.watch();
  }
}
