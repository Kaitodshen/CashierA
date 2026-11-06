import 'package:cashiera_core/src/money.dart';
import 'package:cashiera_core/src/pricing/discount.dart';
import 'package:cashiera_core/src/qty.dart';

/// One cart line as the pricing engine sees it.
class PricingLine {
  const new({
    required this.id,
    required this.productId,
    required this.variantId,
    required this.unitPrice,
    required this.quantity,
    this.categoryId,
    this.modifiersUnitTotal = Money.zero,
    this.isTaxable = true,
    this.manualDiscount,
  });

  final String id;
  final String productId;
  final String variantId;
  final String? categoryId;
  final Money unitPrice;

  /// Sum of the chosen modifiers' price deltas, per unit.
  final Money modifiersUnitTotal;
  final Qty quantity;
  final bool isTaxable;

  /// The cashier's discount on this line, applied after promotions.
  final DiscountSpec? manualDiscount;

  /// Unit price including modifiers.
  Money get unitGross => unitPrice + modifiersUnitTotal;

  /// `round((unit price + modifiers) × quantity)`, the database's line check.
  Money get gross => quantity.times(unitGross);

  /// Whole units only: promotions that count items (buy X get Y, bundles)
  /// ignore the fraction of a weighed item.
  int get wholeUnits => quantity.milli ~/ 1000;
}

enum RoundingMode {
  none,
  nearest,
  up,
  down;

  static RoundingMode fromCode(String code) =>
      values.firstWhere((m) => m.name == code, orElse: () => none);
}

/// The store settings that change a bill (mirrors `store_settings`).
class PricingSettings {
  const new({
    required this.taxRateBps,
    this.taxInclusive = true,
    this.serviceChargeBps = 0,
    this.serviceChargeTaxable = true,
    this.roundingMode = RoundingMode.none,
    this.roundingUnit = 100,
  });

  /// Effective tax rate; pass 0 when tax is switched off for the store.
  final int taxRateBps;
  final bool taxInclusive;

  /// Pass 0 when the service charge is switched off.
  final int serviceChargeBps;
  final bool serviceChargeTaxable;
  final RoundingMode roundingMode;

  /// 50, 100, 500 or 1000 rupiah.
  final int roundingUnit;
}

enum VoucherProblem { inactive, notStarted, expired, usedUp, belowMinimum }

/// A voucher code from `public.vouchers`.
class Voucher {
  const new({
    required this.id,
    required this.code,
    required this.discount,
    this.maxDiscount,
    this.minSubtotal = Money.zero,
    this.maxUses,
    this.usedCount = 0,
    this.startsAt,
    this.endsAt,
    this.isActive = true,
  });

  factory fromJson(Map<String, dynamic> json) {
    final value = (json['discount_value'] as num).toInt();
    DateTime? at(String key) {
      final raw = json[key] as String?;
      return raw == null ? null : DateTime.parse(raw);
    }

    return Voucher(
      id: json['id'] as String,
      code: json['code'] as String,
      discount: json['discount_type'] == 'percent'
          ? PercentDiscount(value)
          : FixedDiscount(value),
      maxDiscount: json['max_discount'] == null
          ? null
          : Money((json['max_discount'] as num).toInt()),
      minSubtotal: Money((json['min_subtotal'] as num? ?? 0).toInt()),
      maxUses: (json['max_uses'] as num?)?.toInt(),
      usedCount: (json['used_count'] as num? ?? 0).toInt(),
      startsAt: at('starts_at'),
      endsAt: at('ends_at'),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  final String id;
  final String code;
  final DiscountSpec discount;
  final Money? maxDiscount;
  final Money minSubtotal;
  final int? maxUses;

  /// As last synced; another terminal may have used it since.
  final int usedCount;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool isActive;

  /// Why the voucher cannot be used now on [subtotal], or null when it can.
  VoucherProblem? check(DateTime now, Money subtotal) {
    if (!isActive) return VoucherProblem.inactive;
    if (startsAt != null && now.isBefore(startsAt!)) {
      return VoucherProblem.notStarted;
    }
    if (endsAt != null && !now.isBefore(endsAt!)) {
      return VoucherProblem.expired;
    }
    if (maxUses != null && usedCount >= maxUses!) return VoucherProblem.usedUp;
    if (subtotal.rupiah < minSubtotal.rupiah) {
      return VoucherProblem.belowMinimum;
    }
    return null;
  }

  /// The discount on [subtotal], with the voucher's ceiling.
  int amountOn(int subtotal) {
    final raw = discount.percentOf(subtotal);
    final cap = maxDiscount?.rupiah;
    return cap != null && raw > cap ? cap : raw;
  }
}

/// Loyalty points the customer spends on this bill.
class PointsRedemption {
  const new({required this.points, required this.pointValue});

  final int points;

  /// Rupiah per point (business_profile.loyalty_point_value).
  final Money pointValue;
}
