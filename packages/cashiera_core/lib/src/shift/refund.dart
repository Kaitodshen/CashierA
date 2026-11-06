import 'package:cashiera_core/src/money.dart';
import 'package:cashiera_core/src/qty.dart';
import 'package:cashiera_core/src/rounding.dart';
import 'package:meta/meta.dart';

/// A sold line and what has been refunded from it so far.
@immutable
class RefundableLine {
  const new({
    required this.id,
    required this.net,
    required this.quantity,
    this.refundedQuantity = Qty.zero,
    this.refundedAmount = Money.zero,
  });

  /// The order item id.
  final String id;

  /// What the customer paid for the whole line (after all discounts).
  final Money net;
  final Qty quantity;
  final Qty refundedQuantity;
  final Money refundedAmount;

  Qty get remainingQuantity => Qty(quantity.milli - refundedQuantity.milli);
  Money get remainingAmount => net - refundedAmount;

  /// This line after refunding [qty] for [amount].
  RefundableLine afterRefund(Qty qty, Money amount) => RefundableLine(
    id: id,
    net: net,
    quantity: quantity,
    refundedQuantity: Qty(refundedQuantity.milli + qty.milli),
    refundedAmount: refundedAmount + amount,
  );

  /// The part of [net] that [qty] units are worth, rounded half up. The
  /// refund that empties the line takes whatever is left, so partial
  /// refunds always add up to [net] exactly.
  Money amountFor(Qty qty) {
    if (qty.milli <= 0) return Money.zero;
    if (qty.milli > remainingQuantity.milli) {
      throw ArgumentError.value(qty, 'qty', 'more than is left to refund');
    }
    if (qty.milli == remainingQuantity.milli) return remainingAmount;
    final share = Money(divRoundHalfUp(net.rupiah * qty.milli, quantity.milli));
    return share.rupiah > remainingAmount.rupiah ? remainingAmount : share;
  }
}

enum RefundProblem {
  /// Nothing picked.
  empty,

  /// More than was sold (or is left) on a line.
  quantity,

  /// More than the customer actually paid (kasbon is not paid yet).
  exceedsPaid,

  /// The picked items were free.
  zero,
}

@immutable
class RefundPlanItem {
  const new({
    required this.lineId,
    required this.quantity,
    required this.amount,
  });

  final String lineId;
  final Qty quantity;
  final Money amount;
}

@immutable
class RefundPlan {
  const new({required this.items, required this.total, this.problem});

  final List<RefundPlanItem> items;
  final Money total;
  final RefundProblem? problem;
}

/// What a refund of [quantities] (order item id → quantity) gives back.
/// [refundable] is the money received for the order and not refunded yet:
/// the non-kasbon payments minus earlier refunds.
RefundPlan planRefund({
  required List<RefundableLine> lines,
  required Map<String, Qty> quantities,
  required Money refundable,
}) {
  final byId = {for (final l in lines) l.id: l};
  for (final id in quantities.keys) {
    if (!byId.containsKey(id)) throw ArgumentError.value(id, 'quantities');
  }
  final items = <RefundPlanItem>[];
  RefundProblem? problem;
  for (final line in lines) {
    final qty = quantities[line.id];
    if (qty == null || qty.milli <= 0) continue;
    if (qty.milli > line.remainingQuantity.milli) {
      problem ??= RefundProblem.quantity;
      continue;
    }
    items.add(
      RefundPlanItem(
        lineId: line.id,
        quantity: qty,
        amount: line.amountFor(qty),
      ),
    );
  }
  final total = items.fold(Money.zero, (a, i) => a + i.amount);
  if (problem == null) {
    if (items.isEmpty) {
      problem = RefundProblem.empty;
    } else if (total.rupiah == 0) {
      problem = RefundProblem.zero;
    } else if (total.rupiah > refundable.rupiah) {
      problem = RefundProblem.exceedsPaid;
    }
  }
  return RefundPlan(items: items, total: total, problem: problem);
}
