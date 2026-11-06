import 'package:cashiera_core/src/rounding.dart';
import 'package:meta/meta.dart';

/// A discount as the promo rules and the cashier express it: a percentage in
/// basis points (`1000` = 10%) or a fixed rupiah amount. JSON shape matches
/// `app.promo_discount_valid`: `{"type":"percent","bps":1000}` or
/// `{"type":"fixed","amount":5000}`.
sealed class DiscountSpec {
  const new();

  const factory percent(int bps) = PercentDiscount;
  const factory fixed(int amount) = FixedDiscount;

  factory fromJson(Map<String, dynamic> json) => switch (json['type']) {
    'percent' => PercentDiscount((json['bps'] as num).toInt()),
    'fixed' => FixedDiscount((json['amount'] as num).toInt()),
    final other => throw FormatException('Unknown discount type', other),
  };

  Map<String, dynamic> toJson();

  /// Percentage of [base] (rounded half up), capped at [base].
  int percentOf(int base);

  /// The percentage in basis points, or null for a fixed amount.
  int? get bps;
}

@immutable
final class PercentDiscount extends DiscountSpec {
  const new(this.bps) : assert(bps >= 0 && bps <= 10000, 'bps is 0 to 10000');

  @override
  final int bps;

  @override
  int percentOf(int base) =>
      base <= 0 ? 0 : divRoundHalfUp(base * bps, 10000).clamp(0, base);

  @override
  Map<String, dynamic> toJson() => {'type': 'percent', 'bps': bps};

  @override
  bool operator ==(Object other) =>
      other is PercentDiscount && other.bps == bps;

  @override
  int get hashCode => Object.hash('percent', bps);

  @override
  String toString() => 'PercentDiscount($bps)';
}

@immutable
final class FixedDiscount extends DiscountSpec {
  const new(this.amount) : assert(amount >= 0, 'amount >= 0');

  final int amount;

  /// A fixed discount does not depend on the base, but never exceeds it.
  @override
  int percentOf(int base) => base <= 0 ? 0 : amount.clamp(0, base);

  @override
  int? get bps => null;

  @override
  Map<String, dynamic> toJson() => {'type': 'fixed', 'amount': amount};

  @override
  bool operator ==(Object other) =>
      other is FixedDiscount && other.amount == amount;

  @override
  int get hashCode => Object.hash('fixed', amount);

  @override
  String toString() => 'FixedDiscount($amount)';
}

/// The size of a manual discount the way the server measures it for the
/// approval rule: `max(ceil(amount × 10000 / base), bps)`, or 10000 when the
/// base is zero.
int effectiveDiscountBps(int amount, int base, {int? bps}) {
  final measured = base <= 0 ? 10000 : (amount * 10000 + base - 1) ~/ base;
  return bps == null || bps < measured ? measured : bps;
}
