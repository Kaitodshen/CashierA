import 'package:cashiera_core/src/pricing/discount.dart';
import 'package:cashiera_core/src/pricing/pricing_line.dart';

enum PromoType {
  happyHour('happy_hour'),
  buyXGetY('buy_x_get_y'),
  bundle('bundle'),
  tieredQty('tiered_qty'),
  minPurchase('min_purchase');

  new(this.code);
  final String code;

  static PromoType fromCode(String code) => values.firstWhere(
    (t) => t.code == code,
    orElse: () => throw FormatException('Unknown promotion type', code),
  );

  /// Bill-level promotions look at the subtotal, not at lines.
  bool get isBillLevel => this == minPurchase;
}

/// Which lines a rule applies to: everything, or any of the listed
/// categories, products or variants.
class PromoScope {
  const new({
    this.categoryIds = const {},
    this.productIds = const {},
    this.variantIds = const {},
  }) : all = false;
  const new all()
    : all = true,
      categoryIds = const {},
      productIds = const {},
      variantIds = const {};

  factory fromJson(Map<String, dynamic> json) {
    if (json['all'] == true) return const PromoScope.all();
    Set<String> ids(String key) =>
        ((json[key] as List?) ?? const []).cast<String>().toSet();
    return PromoScope(
      categoryIds: ids('category_ids'),
      productIds: ids('product_ids'),
      variantIds: ids('variant_ids'),
    );
  }

  final bool all;
  final Set<String> categoryIds;
  final Set<String> productIds;
  final Set<String> variantIds;

  bool matches(PricingLine line) =>
      all ||
      variantIds.contains(line.variantId) ||
      productIds.contains(line.productId) ||
      (line.categoryId != null && categoryIds.contains(line.categoryId));

  Map<String, dynamic> toJson() => all
      ? {'all': true}
      : {
          if (categoryIds.isNotEmpty) 'category_ids': categoryIds.toList(),
          if (productIds.isNotEmpty) 'product_ids': productIds.toList(),
          if (variantIds.isNotEmpty) 'variant_ids': variantIds.toList(),
        };
}

/// Rules per promotion type; shapes are documented in migration 0500.
sealed class PromoRules {
  const new();

  factory fromJson(PromoType type, Map<String, dynamic> json) {
    PromoScope scope(Object? raw) =>
        PromoScope.fromJson((raw! as Map).cast<String, dynamic>());
    DiscountSpec discount(Object? raw) =>
        DiscountSpec.fromJson((raw! as Map).cast<String, dynamic>());
    int integer(Object? raw) => (raw! as num).toInt();
    int? optional(Object? raw) => (raw as num?)?.toInt();
    Map<String, dynamic> map(Object? raw) =>
        (raw! as Map).cast<String, dynamic>();

    return switch (type) {
      PromoType.happyHour => HappyHourRules(
        scope: scope(json['scope']),
        discount: discount(json['discount']),
      ),
      PromoType.buyXGetY => BuyXGetYRules(
        buyScope: scope(map(json['buy'])['scope']),
        buyQuantity: integer(map(json['buy'])['quantity']),
        getScope: scope(map(json['get'])['scope']),
        getQuantity: integer(map(json['get'])['quantity']),
        getDiscount: discount(map(json['get'])['discount']),
        maxApplications: optional(json['max_applications']),
      ),
      PromoType.bundle => BundleRules(
        components: [
          for (final c in (json['components'] as List).map(map))
            BundleComponent(
              scope: scope(c['scope']),
              quantity: integer(c['quantity']),
            ),
        ],
        bundlePrice: integer(json['bundle_price']),
        maxApplications: optional(json['max_applications']),
      ),
      PromoType.tieredQty => TieredQtyRules(
        scope: scope(json['scope']),
        tiers: [
          for (final t in (json['tiers'] as List).map(map))
            QtyTier(
              minQuantity: integer(t['min_quantity']),
              discount: discount(t['discount']),
            ),
        ],
      ),
      PromoType.minPurchase => MinPurchaseRules(
        minSubtotal: integer(json['min_subtotal']),
        discount: discount(json['discount']),
        maxDiscount: optional(json['max_discount']),
      ),
    };
  }

  Map<String, dynamic> toJson();
}

/// A discount on every line in scope during the promotion's time window.
final class HappyHourRules extends PromoRules {
  const new({required this.scope, required this.discount});

  final PromoScope scope;

  /// Percent of the line, or a fixed amount per unit.
  final DiscountSpec discount;

  @override
  Map<String, dynamic> toJson() => {
    'scope': scope.toJson(),
    'discount': discount.toJson(),
  };
}

final class BuyXGetYRules extends PromoRules {
  const new({
    required this.buyScope,
    required this.buyQuantity,
    required this.getScope,
    required this.getQuantity,
    required this.getDiscount,
    this.maxApplications,
  });

  final PromoScope buyScope;
  final int buyQuantity;
  final PromoScope getScope;
  final int getQuantity;

  /// Applied to each "get" unit (percent of its price, or a fixed amount).
  final DiscountSpec getDiscount;
  final int? maxApplications;

  @override
  Map<String, dynamic> toJson() => {
    'buy': {'scope': buyScope.toJson(), 'quantity': buyQuantity},
    'get': {
      'scope': getScope.toJson(),
      'quantity': getQuantity,
      'discount': getDiscount.toJson(),
    },
    'max_applications': maxApplications,
  };
}

class BundleComponent {
  const new({required this.scope, required this.quantity});

  final PromoScope scope;
  final int quantity;
}

final class BundleRules extends PromoRules {
  const new({
    required this.components,
    required this.bundlePrice,
    this.maxApplications,
  });

  final List<BundleComponent> components;
  final int bundlePrice;
  final int? maxApplications;

  @override
  Map<String, dynamic> toJson() => {
    'components': [
      for (final c in components)
        {'scope': c.scope.toJson(), 'quantity': c.quantity},
    ],
    'bundle_price': bundlePrice,
    'max_applications': maxApplications,
  };
}

class QtyTier {
  const new({required this.minQuantity, required this.discount});

  final int minQuantity;
  final DiscountSpec discount;
}

final class TieredQtyRules extends PromoRules {
  const new({required this.scope, required this.tiers});

  final PromoScope scope;

  /// Ascending by [QtyTier.minQuantity].
  final List<QtyTier> tiers;

  @override
  Map<String, dynamic> toJson() => {
    'scope': scope.toJson(),
    'tiers': [
      for (final t in tiers)
        {'min_quantity': t.minQuantity, 'discount': t.discount.toJson()},
    ],
  };
}

final class MinPurchaseRules extends PromoRules {
  const new({
    required this.minSubtotal,
    required this.discount,
    this.maxDiscount,
  });

  final int minSubtotal;
  final DiscountSpec discount;
  final int? maxDiscount;

  @override
  Map<String, dynamic> toJson() => {
    'min_subtotal': minSubtotal,
    'discount': discount.toJson(),
    'max_discount': maxDiscount,
  };
}

/// A row of `public.promotions` plus its store list.
class Promotion {
  const new({
    required this.id,
    required this.name,
    required this.type,
    required this.rules,
    this.description,
    this.priority = 100,
    this.isStackable = false,
    this.startsAt,
    this.endsAt,
    this.daysOfWeek,
    this.startMinute,
    this.endMinute,
    this.isActive = true,
    this.storeIds = const {},
  });

  /// [storeIds] comes from `promotion_stores`; empty means every store.
  factory fromJson(
    Map<String, dynamic> json, {
    Set<String> storeIds = const {},
  }) {
    final type = PromoType.fromCode(json['promo_type'] as String);
    DateTime? at(String key) {
      final raw = json[key] as String?;
      return raw == null ? null : DateTime.parse(raw);
    }

    return Promotion(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      type: type,
      rules: PromoRules.fromJson(
        type,
        (json['rules'] as Map).cast<String, dynamic>(),
      ),
      priority: (json['priority'] as num? ?? 100).toInt(),
      isStackable: json['is_stackable'] as bool? ?? false,
      startsAt: at('starts_at'),
      endsAt: at('ends_at'),
      daysOfWeek: (json['days_of_week'] as List?)
          ?.map((d) => (d as num).toInt())
          .toList(),
      startMinute: parseMinuteOfDay(json['start_time'] as String?),
      endMinute: parseMinuteOfDay(json['end_time'] as String?),
      isActive: json['is_active'] as bool? ?? true,
      storeIds: storeIds,
    );
  }

  final String id;
  final String name;
  final String? description;
  final PromoType type;
  final PromoRules rules;

  /// Lower runs first.
  final int priority;

  /// A non-stackable promotion only takes lines no promotion has touched yet,
  /// and closes them to the promotions after it.
  final bool isStackable;
  final DateTime? startsAt;
  final DateTime? endsAt;

  /// ISO weekdays, 1 = Monday … 7 = Sunday, in store time; null = every day.
  final List<int>? daysOfWeek;

  /// Daily window in store-local minutes after midnight. An end before the
  /// start wraps past midnight and belongs to the day it started.
  final int? startMinute;
  final int? endMinute;
  final bool isActive;
  final Set<String> storeIds;

  bool isActiveAt(
    DateTime instant, {
    required int utcOffsetMinutes,
    required String storeId,
  }) {
    if (!isActive) return false;
    if (storeIds.isNotEmpty && !storeIds.contains(storeId)) return false;
    if (startsAt != null && instant.isBefore(startsAt!)) return false;
    if (endsAt != null && !instant.isBefore(endsAt!)) return false;

    final local = instant.toUtc().add(Duration(minutes: utcOffsetMinutes));
    final minute = local.hour * 60 + local.minute;
    var day = local.weekday;
    final start = startMinute;
    final end = endMinute;
    if (start != null && end != null && start != end) {
      if (start < end) {
        if (minute < start || minute >= end) return false;
      } else if (minute < end) {
        day = day == 1 ? 7 : day - 1;
      } else if (minute < start) {
        return false;
      }
    }
    final days = daysOfWeek;
    return days == null || days.isEmpty || days.contains(day);
  }

  /// The `public.promotions` columns (store list is saved separately).
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'promo_type': type.code,
    'rules': rules.toJson(),
    'priority': priority,
    'is_stackable': isStackable,
    'starts_at': startsAt?.toUtc().toIso8601String(),
    'ends_at': endsAt?.toUtc().toIso8601String(),
    'days_of_week': daysOfWeek,
    'start_time': formatMinuteOfDay(startMinute),
    'end_time': formatMinuteOfDay(endMinute),
    'is_active': isActive,
  };
}

/// `"14:00"` or `"14:00:00"` → 840.
int? parseMinuteOfDay(String? text) {
  if (text == null || text.isEmpty) return null;
  final parts = text.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

/// 840 → `"14:00"`.
String? formatMinuteOfDay(int? minute) => minute == null
    ? null
    : '${(minute ~/ 60).toString().padLeft(2, '0')}:'
          '${(minute % 60).toString().padLeft(2, '0')}';
