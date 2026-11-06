import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/foundation.dart';

/// A chosen modifier on a cart line (`order_item_modifiers`).
@immutable
class CartModifier {
  const new({
    required this.modifierId,
    required this.groupName,
    required this.name,
    required this.priceDelta,
  });

  factory fromJson(Map<String, dynamic> j) => CartModifier(
    modifierId: j['modifier_id'] as String,
    groupName: j['group_name'] as String,
    name: j['name'] as String,
    priceDelta: Money((j['price_delta'] as num).toInt()),
  );

  final String modifierId;
  final String groupName;
  final String name;
  final Money priceDelta;

  Map<String, dynamic> toJson() => {
    'modifier_id': modifierId,
    'group_name': groupName,
    'name': name,
    'price_delta': priceDelta.rupiah,
  };
}

/// One line of the bill. Snapshots the names and prices at the time it was
/// added, so a catalog refresh never changes a bill in progress.
@immutable
class CartLine {
  const new({
    required this.id,
    required this.variantId,
    required this.productId,
    required this.productName,
    required this.variantName,
    required this.sku,
    required this.unitCode,
    required this.allowDecimal,
    required this.unitPrice,
    required this.unitCost,
    required this.isTaxable,
    required this.trackStock,
    required this.quantity,
    this.categoryId,
    this.modifiers = const [],
    this.manualDiscount,
    this.note,
  });

  factory fromJson(Map<String, dynamic> j) => CartLine(
    id: j['id'] as String,
    variantId: j['variant_id'] as String,
    productId: j['product_id'] as String,
    categoryId: j['category_id'] as String?,
    productName: j['product_name'] as String,
    variantName: j['variant_name'] as String,
    sku: j['sku'] as String,
    unitCode: j['unit_code'] as String,
    allowDecimal: j['allow_decimal'] as bool,
    unitPrice: Money((j['unit_price'] as num).toInt()),
    unitCost: Money((j['unit_cost'] as num).toInt()),
    isTaxable: j['is_taxable'] as bool,
    trackStock: j['track_stock'] as bool,
    quantity: Qty.parse(j['quantity'] as String),
    modifiers: [
      for (final m in (j['modifiers'] as List? ?? const []))
        CartModifier.fromJson((m as Map).cast<String, dynamic>()),
    ],
    manualDiscount: j['manual_discount'] == null
        ? null
        : DiscountSpec.fromJson(
            (j['manual_discount'] as Map).cast<String, dynamic>(),
          ),
    note: j['note'] as String?,
  );

  final String id;
  final String variantId;
  final String productId;
  final String? categoryId;
  final String productName;
  final String variantName;
  final String sku;
  final String unitCode;
  final bool allowDecimal;
  final Money unitPrice;
  final Money unitCost;
  final bool isTaxable;
  final bool trackStock;
  final Qty quantity;
  final List<CartModifier> modifiers;
  final DiscountSpec? manualDiscount;
  final String? note;

  String get displayName =>
      variantName == 'Default' ? productName : '$productName · $variantName';

  Money get modifiersUnitTotal =>
      modifiers.fold(Money.zero, (a, m) => a + m.priceDelta);

  /// Same product, variant and modifiers: scanning it again adds quantity.
  bool sameItemAs(CartLine other) =>
      variantId == other.variantId &&
      manualDiscount == null &&
      other.manualDiscount == null &&
      note == other.note &&
      listEquals(
        modifiers.map((m) => m.modifierId).toList(),
        other.modifiers.map((m) => m.modifierId).toList(),
      );

  PricingLine toPricing() => PricingLine(
    id: id,
    productId: productId,
    variantId: variantId,
    categoryId: categoryId,
    unitPrice: unitPrice,
    modifiersUnitTotal: modifiersUnitTotal,
    quantity: quantity,
    isTaxable: isTaxable,
    manualDiscount: manualDiscount,
  );

  CartLine copyWith({
    Qty? quantity,
    DiscountSpec? manualDiscount,
    bool clearDiscount = false,
    String? note,
    bool clearNote = false,
  }) => CartLine(
    id: id,
    variantId: variantId,
    productId: productId,
    categoryId: categoryId,
    productName: productName,
    variantName: variantName,
    sku: sku,
    unitCode: unitCode,
    allowDecimal: allowDecimal,
    unitPrice: unitPrice,
    unitCost: unitCost,
    isTaxable: isTaxable,
    trackStock: trackStock,
    quantity: quantity ?? this.quantity,
    modifiers: modifiers,
    manualDiscount: clearDiscount
        ? null
        : manualDiscount ?? this.manualDiscount,
    note: clearNote ? null : note ?? this.note,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'variant_id': variantId,
    'product_id': productId,
    'category_id': categoryId,
    'product_name': productName,
    'variant_name': variantName,
    'sku': sku,
    'unit_code': unitCode,
    'allow_decimal': allowDecimal,
    'unit_price': unitPrice.rupiah,
    'unit_cost': unitCost.rupiah,
    'is_taxable': isTaxable,
    'track_stock': trackStock,
    'quantity': quantity.toPayload(),
    'modifiers': [for (final m in modifiers) m.toJson()],
    'manual_discount': manualDiscount?.toJson(),
    'note': note,
  };
}

@immutable
class CartCustomer {
  const new({required this.id, required this.name, this.phone});

  factory fromJson(Map<String, dynamic> j) => CartCustomer(
    id: j['id'] as String,
    name: j['name'] as String,
    phone: j['phone'] as String?,
  );

  final String id;
  final String name;
  final String? phone;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'phone': phone};
}

/// The bill being rung up. [orderId] is fixed from the first item, so
/// holding and finishing the bill update the same server order.
@immutable
class Cart {
  const new({
    required this.orderId,
    required this.startedAt,
    this.orderNumber,
    this.version = 0,
    this.lines = const [],
    this.customer,
    this.billDiscount,
    this.approvedBy,
    this.voucherCode,
    this.note,
  });

  factory fromJson(Map<String, dynamic> j) => Cart(
    orderId: j['order_id'] as String,
    orderNumber: j['order_number'] as String?,
    version: (j['version'] as num? ?? 0).toInt(),
    startedAt: DateTime.parse(j['started_at'] as String),
    lines: [
      for (final l in j['lines'] as List)
        CartLine.fromJson((l as Map).cast<String, dynamic>()),
    ],
    customer: j['customer'] == null
        ? null
        : CartCustomer.fromJson((j['customer'] as Map).cast<String, dynamic>()),
    billDiscount: j['bill_discount'] == null
        ? null
        : DiscountSpec.fromJson(
            (j['bill_discount'] as Map).cast<String, dynamic>(),
          ),
    approvedBy: j['approved_by'] as String?,
    voucherCode: j['voucher_code'] as String?,
    note: j['note'] as String?,
  );

  final String orderId;

  /// Assigned on the first hold or on completion.
  final String? orderNumber;

  /// Version of the last snapshot sent (0 = never sent).
  final int version;
  final DateTime startedAt;
  final List<CartLine> lines;
  final CartCustomer? customer;
  final DiscountSpec? billDiscount;

  /// Employee who approved manual discounts above the store threshold.
  final String? approvedBy;
  final String? voucherCode;
  final String? note;

  bool get isEmpty => lines.isEmpty;

  /// Number of units, counting a weighed line as one.
  int get itemCount => lines.fold(
    0,
    (a, l) => a + (l.allowDecimal ? 1 : l.quantity.milli ~/ 1000),
  );

  Cart copyWith({
    String? orderNumber,
    int? version,
    List<CartLine>? lines,
    CartCustomer? customer,
    bool clearCustomer = false,
    DiscountSpec? billDiscount,
    bool clearBillDiscount = false,
    String? approvedBy,
    bool clearApproval = false,
    String? voucherCode,
    bool clearVoucher = false,
    String? note,
  }) => Cart(
    orderId: orderId,
    startedAt: startedAt,
    orderNumber: orderNumber ?? this.orderNumber,
    version: version ?? this.version,
    lines: lines ?? this.lines,
    customer: clearCustomer ? null : customer ?? this.customer,
    billDiscount: clearBillDiscount ? null : billDiscount ?? this.billDiscount,
    approvedBy: clearApproval ? null : approvedBy ?? this.approvedBy,
    voucherCode: clearVoucher ? null : voucherCode ?? this.voucherCode,
    note: note ?? this.note,
  );

  Map<String, dynamic> toJson() => {
    'order_id': orderId,
    'order_number': orderNumber,
    'version': version,
    'started_at': startedAt.toUtc().toIso8601String(),
    'lines': [for (final l in lines) l.toJson()],
    'customer': customer?.toJson(),
    'bill_discount': billDiscount?.toJson(),
    'approved_by': approvedBy,
    'voucher_code': voucherCode,
    'note': note,
  };
}
