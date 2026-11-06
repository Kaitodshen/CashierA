import 'package:cashiera_core/src/money.dart';
import 'package:meta/meta.dart';

/// One kasbon (receivable) of a customer, keyed by the sale that opened it.
@immutable
class KasbonDebt {
  const new({
    required this.orderId,
    required this.amount,
    required this.paid,
    required this.dueDate,
  });

  final String orderId;
  final Money amount;
  final Money paid;

  /// Store-local due date (midnight UTC of that day).
  final DateTime dueDate;

  Money get remaining =>
      paid.rupiah >= amount.rupiah ? Money.zero : amount - paid;

  bool get isSettled => remaining.rupiah == 0;

  /// Whole days after the due date on [today] (0 when not late yet).
  int daysLate(DateTime today) {
    final due = DateTime.utc(dueDate.year, dueDate.month, dueDate.day);
    final day = DateTime.utc(today.year, today.month, today.day);
    final days = day.difference(due).inDays;
    return days > 0 ? days : 0;
  }
}

Money totalOutstanding(Iterable<KasbonDebt> debts) =>
    debts.fold(Money.zero, (a, d) => a + d.remaining);

enum RepaymentProblem { invalidAmount, nothingOwed, exceedsBalance }

@immutable
class RepaymentPart {
  const new({required this.orderId, required this.amount});
  final String orderId;
  final Money amount;
}

@immutable
class RepaymentPlan {
  const new({
    required this.parts,
    required this.balanceBefore,
    required this.balanceAfter,
    this.problem,
  });

  final List<RepaymentPart> parts;
  final Money balanceBefore;
  final Money balanceAfter;
  final RepaymentProblem? problem;
}

/// Spreads [amount] over the open debts, the oldest due date first (then
/// the order id, so it is stable). Never pays a debt beyond what is owed.
RepaymentPlan allocateRepayment(List<KasbonDebt> debts, Money amount) {
  final open =
      [
        for (final d in debts)
          if (!d.isSettled) d,
      ]..sort((a, b) {
        final byDue = a.dueDate.compareTo(b.dueDate);
        return byDue != 0 ? byDue : a.orderId.compareTo(b.orderId);
      });
  final before = totalOutstanding(open);
  RepaymentPlan refuse(RepaymentProblem p) => RepaymentPlan(
    parts: const [],
    balanceBefore: before,
    balanceAfter: before,
    problem: p,
  );
  if (amount.rupiah <= 0) return refuse(RepaymentProblem.invalidAmount);
  if (before.rupiah == 0) return refuse(RepaymentProblem.nothingOwed);
  if (amount.rupiah > before.rupiah) {
    return refuse(RepaymentProblem.exceedsBalance);
  }
  var left = amount.rupiah;
  final parts = <RepaymentPart>[];
  for (final d in open) {
    if (left == 0) break;
    final take = left < d.remaining.rupiah ? left : d.remaining.rupiah;
    parts.add(RepaymentPart(orderId: d.orderId, amount: Money(take)));
    left -= take;
  }
  return RepaymentPlan(
    parts: parts,
    balanceBefore: before,
    balanceAfter: before - amount,
  );
}

/// Outstanding kasbon by how late it is.
@immutable
class KasbonAging {
  const new({
    required this.current,
    required this.late30,
    required this.late60,
    required this.over60,
  });

  /// Not due yet, or due today.
  final Money current;

  /// 1 to 30 days late.
  final Money late30;

  /// 31 to 60 days late.
  final Money late60;

  /// More than 60 days late.
  final Money over60;

  Money get total => current + late30 + late60 + over60;
}

KasbonAging kasbonAging(Iterable<KasbonDebt> debts, {required DateTime today}) {
  var current = 0;
  var late30 = 0;
  var late60 = 0;
  var over60 = 0;
  for (final d in debts) {
    final r = d.remaining.rupiah;
    if (r == 0) continue;
    final days = d.daysLate(today);
    if (days == 0) {
      current += r;
    } else if (days <= 30) {
      late30 += r;
    } else if (days <= 60) {
      late60 += r;
    } else {
      over60 += r;
    }
  }
  return KasbonAging(
    current: Money(current),
    late30: Money(late30),
    late60: Money(late60),
    over60: Money(over60),
  );
}
