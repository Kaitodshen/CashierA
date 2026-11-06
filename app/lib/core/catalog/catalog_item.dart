import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/foundation.dart';

@immutable
class CatalogCategory {
  const new({required this.id, required this.name, this.color});

  final String id;
  final String name;

  /// `#RRGGBB`, or null.
  final String? color;
}

/// A sellable variant as the terminal shows it: store price first, local
/// stock, low-stock flag.
@immutable
class CatalogItem {
  const new({
    required this.variantId,
    required this.productId,
    required this.productName,
    required this.variantName,
    required this.sku,
    required this.barcode,
    required this.categoryId,
    required this.unitCode,
    required this.allowDecimal,
    required this.basePrice,
    required this.priceOverride,
    required this.isTaxable,
    required this.trackStock,
    required this.stock,
    required this.reorderPoint,
    required this.isAvailable,
    this.cost = Money.zero,
    this.favoriteOrder,
    this.hasModifiers = false,
  });

  final String variantId;
  final String productId;
  final String productName;
  final String variantName;
  final String sku;
  final String? barcode;
  final String? categoryId;
  final String unitCode;
  final bool allowDecimal;
  final Money basePrice;
  final Money? priceOverride;
  final bool isTaxable;
  final bool trackStock;
  final Qty stock;
  final Qty? reorderPoint;
  final bool isAvailable;

  /// Purchase cost (HPP) per unit, for the order's cost snapshot.
  final Money cost;

  /// Position among the store's favorites, or null.
  final int? favoriteOrder;

  /// The product has modifier groups to choose from.
  final bool hasModifiers;

  /// The price this store charges.
  Money get price => priceOverride ?? basePrice;

  bool get isLow =>
      trackStock && reorderPoint != null && stock.milli <= reorderPoint!.milli;

  String get displayName =>
      variantName == 'Default' ? productName : '$productName · $variantName';
}

/// A modifier choice on the cashier screen.
@immutable
class ModifierOption {
  const new({required this.id, required this.name, required this.priceDelta});

  final String id;
  final String name;
  final Money priceDelta;
}

/// A product's modifier group with its rules (min/max picks).
@immutable
class ModifierGroupOption {
  const new({
    required this.id,
    required this.name,
    required this.minSelect,
    required this.maxSelect,
    required this.options,
  });

  final String id;
  final String name;
  final int minSelect;
  final int maxSelect;
  final List<ModifierOption> options;
}
