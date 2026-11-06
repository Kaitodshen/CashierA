import 'package:cashiera_core/src/money.dart';
import 'package:meta/meta.dart';

/// Why points can't be redeemed.
enum RedeemProblem { disabled, belowMinimum, notEnough }

/// The company's loyalty settings (`business_profile`): 1 point per
/// [earnAmount] of net spend, each redeemed point worth [pointValue].
@immutable
class LoyaltyRules {
  const new({
    required this.earnAmount,
    required this.pointValue,
    this.enabled = true,
    this.minRedeemPoints = 0,
  });

  final bool enabled;
  final Money earnAmount;
  final Money pointValue;
  final int minRedeemPoints;

  /// ⌊net / earnAmount⌋, the same rule the server checks.
  int pointsEarned(Money net) {
    if (!enabled || net.rupiah <= 0 || earnAmount.rupiah <= 0) return 0;
    return net.rupiah ~/ earnAmount.rupiah;
  }

  /// The most points that can go on a bill with [payable] left to pay,
  /// given a [balance]. Zero when that would be below the minimum.
  int redeemable({required int balance, required Money payable}) {
    if (!enabled || balance <= 0 || pointValue.rupiah <= 0) return 0;
    final byBill = payable.rupiah <= 0
        ? 0
        : payable.rupiah ~/ pointValue.rupiah;
    final most = balance < byBill ? balance : byBill;
    return most < minRedeemPoints ? 0 : most;
  }

  /// Null when [points] can be redeemed from [balance] (0 is always fine).
  RedeemProblem? check({required int points, required int balance}) {
    if (points <= 0) return null;
    if (!enabled) return RedeemProblem.disabled;
    if (points < minRedeemPoints) return RedeemProblem.belowMinimum;
    if (points > balance) return RedeemProblem.notEnough;
    return null;
  }
}
