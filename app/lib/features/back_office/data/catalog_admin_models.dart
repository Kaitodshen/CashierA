import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/foundation.dart';

@immutable
class AdminCategory {
  const new({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.isActive,
    this.color,
  });

  factory fromJson(Map<String, dynamic> j) => AdminCategory(
    id: j['id'] as String,
    name: j['name'] as String,
    sortOrder: (j['sort_order'] as num).toInt(),
    isActive: j['is_active'] as bool,
    color: j['color'] as String?,
  );

  final String id;
  final String name;
  final int sortOrder;
  final bool isActive;
  final String? color;
}

@immutable
class AdminUnit {
  const new({
    required this.id,
    required this.code,
    required this.name,
    required this.allowDecimal,
  });

  factory fromJson(Map<String, dynamic> j) => AdminUnit(
    id: j['id'] as String,
    code: j['code'] as String,
    name: j['name'] as String,
    allowDecimal: j['allow_decimal'] as bool,
  );

  final String id;
  final String code;
  final String name;
  final bool allowDecimal;
}

@immutable
class AdminSupplier {
  const new({
    required this.name,
    this.id,
    this.contactName,
    this.phone,
    this.email,
    this.address,
    this.isActive = true,
  });

  factory fromJson(Map<String, dynamic> j) => AdminSupplier(
    id: j['id'] as String,
    name: j['name'] as String,
    contactName: j['contact_name'] as String?,
    phone: j['phone'] as String?,
    email: j['email'] as String?,
    address: j['address'] as String?,
    isActive: j['is_active'] as bool,
  );

  final String? id;
  final String name;
  final String? contactName;
  final String? phone;
  final String? email;
  final String? address;
  final bool isActive;

  Map<String, dynamic> toJson() => {
    'id': ?id,
    'name': name,
    'contact_name': contactName,
    'phone': phone,
    'email': email,
    'address': address,
    'is_active': isActive,
  };
}

@immutable
class ProductSummary {
  const new({
    required this.id,
    required this.name,
    required this.unitCode,
    required this.variantCount,
    required this.minPrice,
    required this.maxPrice,
    required this.isActive,
    this.categoryName,
  });

  factory fromJson(Map<String, dynamic> j) {
    final variants = [
      for (final v in j['variants'] as List)
        if ((v as Map)['is_active'] as bool) (v['price'] as num).toInt(),
    ]..sort();
    return ProductSummary(
      id: j['id'] as String,
      name: j['name'] as String,
      categoryName: (j['category'] as Map?)?['name'] as String?,
      unitCode: (j['unit'] as Map)['code'] as String,
      variantCount: variants.length,
      minPrice: Money(variants.isEmpty ? 0 : variants.first),
      maxPrice: Money(variants.isEmpty ? 0 : variants.last),
      isActive: j['is_active'] as bool,
    );
  }

  final String id;
  final String name;
  final String? categoryName;
  final String unitCode;
  final int variantCount;
  final Money minPrice;
  final Money maxPrice;
  final bool isActive;
}

/// Editable variant in the product editor.
class VariantDraft {
  new({
    required this.id,
    this.name = 'Default',
    this.sku = '',
    this.barcode,
    this.price = 0,
    this.cost = 0,
    this.isActive = true,
  });

  factory fromJson(Map<String, dynamic> j) => VariantDraft(
    id: j['id'] as String,
    name: j['name'] as String,
    sku: j['sku'] as String,
    barcode: j['barcode'] as String?,
    price: (j['price'] as num).toInt(),
    cost: (j['cost'] as num).toInt(),
    isActive: j['is_active'] as bool,
  );

  final String id;
  String name;
  String sku;
  String? barcode;
  int price;
  int cost;
  bool isActive;
}

/// Per-store price override and reorder point for one variant.
class StoreSettingDraft {
  new({
    required this.storeId,
    required this.variantId,
    this.priceOverride,
    this.reorderPoint,
    this.isAvailable = true,
  });

  factory fromJson(Map<String, dynamic> j) => StoreSettingDraft(
    storeId: j['store_id'] as String,
    variantId: j['variant_id'] as String,
    priceOverride: (j['price_override'] as num?)?.toInt(),
    reorderPoint: j['reorder_point'] == null
        ? null
        : Qty.parse('${j['reorder_point']}'),
    isAvailable: j['is_available'] as bool? ?? true,
  );

  final String storeId;
  final String variantId;
  int? priceOverride;
  Qty? reorderPoint;
  bool isAvailable;

  bool get isEmpty => priceOverride == null && reorderPoint == null;
}

/// Everything the product editor saves in one `save_product` call.
class ProductDraft {
  new({
    required this.id,
    required this.unitId,
    required this.variants,
    this.name = '',
    this.categoryId,
    this.isTaxable = true,
    this.trackStock = true,
    this.isActive = true,
    List<StoreSettingDraft>? storeSettings,
  }) : storeSettings = storeSettings ?? [];

  final String id;
  String name;
  String? categoryId;
  String unitId;
  bool isTaxable;
  bool trackStock;
  bool isActive;
  final List<VariantDraft> variants;
  final List<StoreSettingDraft> storeSettings;

  StoreSettingDraft settingFor(String storeId, String variantId) =>
      storeSettings.firstWhere(
        (s) => s.storeId == storeId && s.variantId == variantId,
        orElse: () {
          final created = StoreSettingDraft(
            storeId: storeId,
            variantId: variantId,
          );
          storeSettings.add(created);
          return created;
        },
      );

  Map<String, dynamic> toJson() {
    final variantIds = variants.map((v) => v.id).toSet();
    return {
      'id': id,
      'name': name.trim(),
      'category_id': categoryId,
      'unit_id': unitId,
      'is_taxable': isTaxable,
      'track_stock': trackStock,
      'is_active': isActive,
      'variants': [
        for (final (i, v) in variants.indexed)
          {
            'id': v.id,
            'name': v.name.trim().isEmpty ? 'Default' : v.name.trim(),
            'sku': v.sku.trim(),
            'barcode': (v.barcode?.trim().isEmpty ?? true)
                ? null
                : v.barcode!.trim(),
            'price': v.price,
            'cost': v.cost,
            'sort_order': i,
            'is_active': v.isActive,
          },
      ],
      'store_settings': [
        for (final s in storeSettings)
          if (variantIds.contains(s.variantId))
            {
              'store_id': s.storeId,
              'variant_id': s.variantId,
              'price_override': s.priceOverride,
              'reorder_point': s.reorderPoint?.toPayload(),
              'is_available': s.isAvailable,
            },
      ],
    };
  }
}

@immutable
class StockRow {
  const new({
    required this.variantId,
    required this.productName,
    required this.variantName,
    required this.sku,
    required this.unitCode,
    required this.quantity,
    required this.reorderPoint,
    required this.isLow,
    this.categoryName,
  });

  factory fromJson(Map<String, dynamic> j) => StockRow(
    variantId: j['variant_id'] as String,
    productName: j['product_name'] as String,
    variantName: j['variant_name'] as String,
    sku: j['sku'] as String,
    unitCode: j['unit_code'] as String,
    categoryName: j['category_name'] as String?,
    quantity: Qty.parse('${j['quantity']}'),
    reorderPoint: j['reorder_point'] == null
        ? null
        : Qty.parse('${j['reorder_point']}'),
    isLow: j['is_low'] as bool,
  );

  final String variantId;
  final String productName;
  final String variantName;
  final String sku;
  final String unitCode;
  final String? categoryName;
  final Qty quantity;
  final Qty? reorderPoint;
  final bool isLow;

  String get displayName =>
      variantName == 'Default' ? productName : '$productName · $variantName';
}

@immutable
class MovementRow {
  const new({
    required this.createdAt,
    required this.type,
    required this.delta,
    required this.balance,
    this.note,
  });

  factory fromJson(Map<String, dynamic> j) => MovementRow(
    createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
    type: j['movement_type'] as String,
    delta: Qty.parse('${j['quantity_delta']}'),
    balance: Qty.parse('${j['balance_after']}'),
    note: j['note'] as String?,
  );

  final DateTime createdAt;
  final String type;
  final Qty delta;
  final Qty balance;
  final String? note;
}

@immutable
class AlertRow {
  const new({
    required this.id,
    required this.type,
    required this.message,
    required this.createdAt,
  });

  factory fromJson(Map<String, dynamic> j) => AlertRow(
    id: j['id'] as String,
    type: j['alert_type'] as String,
    message: j['message'] as String,
    createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
  );

  final String id;
  final String type;
  final String message;
  final DateTime createdAt;
}

@immutable
class ImportSummary {
  const new(this.json);

  final Map<String, dynamic> json;

  int count(String key) => (json[key] as num?)?.toInt() ?? 0;
}
