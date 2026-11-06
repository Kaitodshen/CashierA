import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Editable copy of `store_settings`.
class StoreSettingsDraft {
  new fromJson(Map<String, dynamic> j)
    : storeId = j['store_id'] as String,
      taxEnabled = j['tax_enabled'] as bool,
      taxName = j['tax_name'] as String,
      taxRateBps = (j['tax_rate_bps'] as num).toInt(),
      taxInclusive = j['tax_inclusive'] as bool,
      serviceChargeEnabled = j['service_charge_enabled'] as bool,
      serviceChargeBps = (j['service_charge_bps'] as num).toInt(),
      serviceChargeTaxable = j['service_charge_taxable'] as bool,
      roundingMode = j['rounding_mode'] as String,
      roundingUnit = (j['rounding_unit'] as num).toInt(),
      discountApprovalBps = (j['discount_approval_bps'] as num).toInt(),
      kasbonEnabled = j['kasbon_enabled'] as bool,
      receiptHeader = j['receipt_header'] as String?,
      receiptFooter = j['receipt_footer'] as String,
      receiptPaperMm = (j['receipt_paper_mm'] as num).toInt();

  final String storeId;
  bool taxEnabled;
  String taxName;
  int taxRateBps;
  bool taxInclusive;
  bool serviceChargeEnabled;
  int serviceChargeBps;
  bool serviceChargeTaxable;
  String roundingMode;
  int roundingUnit;
  int discountApprovalBps;
  bool kasbonEnabled;
  String? receiptHeader;
  String receiptFooter;
  int receiptPaperMm;

  Map<String, dynamic> toJson() => {
    'tax_enabled': taxEnabled,
    'tax_name': taxName.trim(),
    'tax_rate_bps': taxRateBps,
    'tax_inclusive': taxInclusive,
    'service_charge_enabled': serviceChargeEnabled,
    'service_charge_bps': serviceChargeBps,
    'service_charge_taxable': serviceChargeTaxable,
    'rounding_mode': roundingMode,
    'rounding_unit': roundingUnit,
    'discount_approval_bps': discountApprovalBps,
    'kasbon_enabled': kasbonEnabled,
    'receipt_header': receiptHeader?.trim().isEmpty ?? true
        ? null
        : receiptHeader!.trim(),
    'receipt_footer': receiptFooter.trim(),
    'receipt_paper_mm': receiptPaperMm,
  };
}

/// A company payment method and whether one store accepts it.
class StorePaymentMethod {
  const new({
    required this.id,
    required this.code,
    required this.name,
    required this.methodType,
    required this.requiresReference,
    required this.enabled,
    required this.sortOrder,
  });

  final String id;
  final String code;
  final String name;
  final String methodType;
  final bool requiresReference;
  final bool enabled;
  final int sortOrder;
}

/// A row of `public.vouchers` for the editor.
class AdminVoucher {
  new({
    required this.code,
    required this.discountType,
    required this.discountValue,
    this.id,
    this.description,
    this.maxDiscount,
    this.minSubtotal = 0,
    this.maxUses,
    this.usedCount = 0,
    this.perCustomerLimit,
    this.startsAt,
    this.endsAt,
    this.isActive = true,
  });

  factory fromJson(Map<String, dynamic> j) {
    DateTime? at(String k) =>
        j[k] == null ? null : DateTime.parse(j[k] as String);
    return AdminVoucher(
      id: j['id'] as String,
      code: j['code'] as String,
      description: j['description'] as String?,
      discountType: j['discount_type'] as String,
      discountValue: (j['discount_value'] as num).toInt(),
      maxDiscount: (j['max_discount'] as num?)?.toInt(),
      minSubtotal: (j['min_subtotal'] as num).toInt(),
      maxUses: (j['max_uses'] as num?)?.toInt(),
      usedCount: (j['used_count'] as num).toInt(),
      perCustomerLimit: (j['per_customer_limit'] as num?)?.toInt(),
      startsAt: at('starts_at'),
      endsAt: at('ends_at'),
      isActive: j['is_active'] as bool,
    );
  }

  String? id;
  String code;
  String? description;

  /// `percent` (value in bps) or `fixed` (rupiah).
  String discountType;
  int discountValue;
  int? maxDiscount;
  int minSubtotal;
  int? maxUses;
  final int usedCount;
  int? perCustomerLimit;
  DateTime? startsAt;
  DateTime? endsAt;
  bool isActive;

  /// Writable columns only (used_count is kept by the database).
  Map<String, dynamic> toJson() => {
    'code': code.trim().toUpperCase(),
    'description': description?.trim().isEmpty ?? true
        ? null
        : description!.trim(),
    'discount_type': discountType,
    'discount_value': discountValue,
    'max_discount': maxDiscount,
    'min_subtotal': minSubtotal,
    'max_uses': maxUses,
    'per_customer_limit': perCustomerLimit,
    'starts_at': startsAt?.toUtc().toIso8601String(),
    'ends_at': endsAt?.toUtc().toIso8601String(),
    'is_active': isActive,
  };
}

/// Something a promotion can target, for the scope picker.
class ScopeOption {
  const new({required this.id, required this.label, this.detail});

  final String id;
  final String label;
  final String? detail;
}

class ScopeOptions {
  const new({
    required this.categories,
    required this.products,
    required this.variants,
  });

  final List<ScopeOption> categories;
  final List<ScopeOption> products;
  final List<ScopeOption> variants;
}

/// Store settings, payment methods, promotions and vouchers (online).
class PosAdminRepository {
  new(this._client);

  final SupabaseClient _client;

  Future<StoreSettingsDraft> storeSettings(String storeId) => _guard(() async {
    final row = await _client
        .from('store_settings')
        .select()
        .eq('store_id', storeId)
        .single();
    return StoreSettingsDraft.fromJson(row);
  });

  Future<void> saveStoreSettings(StoreSettingsDraft draft) => _guard(() async {
    await _client
        .from('store_settings')
        .update(draft.toJson())
        .eq('store_id', draft.storeId);
  });

  Future<List<StorePaymentMethod>> paymentMethods(String storeId) => _guard(
    () async {
      final methods = await _client
          .from('payment_methods')
          .select('id, code, name, method_type, requires_reference, sort_order')
          .eq('is_active', true)
          .order('sort_order');
      final settings = {
        for (final r
            in await _client
                .from('store_payment_methods')
                .select('payment_method_id, is_enabled, sort_order')
                .eq('store_id', storeId))
          r['payment_method_id'] as String: r,
      };
      return [
        for (final m in methods)
          StorePaymentMethod(
            id: m['id'] as String,
            code: m['code'] as String,
            name: m['name'] as String,
            methodType: m['method_type'] as String,
            requiresReference: m['requires_reference'] as bool,
            enabled: settings[m['id']]?['is_enabled'] as bool? ?? false,
            sortOrder:
                ((settings[m['id']]?['sort_order'] ?? m['sort_order']) as num)
                    .toInt(),
          ),
      ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    },
  );

  Future<void> setPaymentMethod(
    String storeId,
    StorePaymentMethod method, {
    required bool enabled,
  }) => _guard(() async {
    await _client.from('store_payment_methods').upsert({
      'store_id': storeId,
      'payment_method_id': method.id,
      'is_enabled': enabled,
      'sort_order': method.sortOrder,
    });
  });

  Future<List<Promotion>> promotions() => _guard(() async {
    final rows = await _client
        .from('promotions')
        .select('*, promotion_stores(store_id)')
        .order('priority')
        .order('name');
    return [
      for (final r in rows)
        Promotion.fromJson(
          r,
          storeIds: {
            for (final s in (r['promotion_stores'] as List? ?? const []))
              (s as Map)['store_id'] as String,
          },
        ),
    ];
  });

  Future<void> savePromotion(Promotion promotion) => _guard(() async {
    await _client.rpc<dynamic>(
      'save_promotion',
      params: {
        'p': {...promotion.toJson(), 'store_ids': promotion.storeIds.toList()},
      },
    );
  });

  Future<List<AdminVoucher>> vouchers() => _guard(() async {
    final rows = await _client.from('vouchers').select().order('code');
    return rows.map(AdminVoucher.fromJson).toList();
  });

  /// New vouchers are inserted; existing ones updated (the id column is not
  /// updatable).
  Future<void> saveVoucher(AdminVoucher voucher) => _guard(() async {
    if (voucher.id == null) {
      await _client.from('vouchers').insert(voucher.toJson());
    } else {
      await _client
          .from('vouchers')
          .update(voucher.toJson())
          .eq('id', voucher.id!);
    }
  });

  /// Categories, products and variants a promotion can be limited to.
  Future<ScopeOptions> scopeOptions() => _guard(() async {
    final categories = await _client
        .from('categories')
        .select('id, name')
        .eq('is_active', true)
        .order('sort_order');
    final products = await _client
        .from('products')
        .select('id, name, product_variants(id, name, sku, is_active)')
        .eq('is_active', true)
        .order('name');
    return ScopeOptions(
      categories: [
        for (final c in categories)
          ScopeOption(id: c['id'] as String, label: c['name'] as String),
      ],
      products: [
        for (final p in products)
          ScopeOption(id: p['id'] as String, label: p['name'] as String),
      ],
      variants: [
        for (final p in products)
          for (final v in (p['product_variants'] as List? ?? const []))
            if ((v as Map)['is_active'] == true)
              ScopeOption(
                id: v['id'] as String,
                label: v['name'] == 'Default'
                    ? p['name'] as String
                    : '${p['name']} · ${v['name']}',
                detail: v['sku'] as String,
              ),
      ],
    );
  });
}

Future<T> _guard<T>(Future<T> Function() body) async {
  try {
    return await body();
  } on PostgrestException catch (e) {
    throw BackendException.fromMessage(e.message);
  }
}
