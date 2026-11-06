import 'package:cashiera_core/cashiera_core.dart';
import 'package:test/test.dart';

void main() {
  const mie = RefundableLine(id: 'i-1', net: Money(10000), quantity: Qty(3000));

  test('a full refund of a line returns its net amount', () {
    final plan = planRefund(
      lines: [mie],
      quantities: {'i-1': const Qty(3000)},
      refundable: const Money(50000),
    );
    expect(plan.problem, isNull);
    expect(plan.items.single.amount, const Money(10000));
    expect(plan.total, const Money(10000));
  });

  test('1 of 3, then 2 of 3, adds up to exactly the net amount', () {
    final first = planRefund(
      lines: [mie],
      quantities: {'i-1': Qty.one},
      refundable: const Money(50000),
    );
    expect(first.items.single.amount, const Money(3333));

    final after = mie.afterRefund(Qty.one, const Money(3333));
    expect(after.remainingQuantity, const Qty(2000));
    expect(after.remainingAmount, const Money(6667));
    final second = planRefund(
      lines: [after],
      quantities: {'i-1': const Qty(2000)},
      refundable: const Money(50000),
    );
    expect(second.items.single.amount, const Money(6667));
    expect(first.total + second.total, const Money(10000));
  });

  test('rounds half up and never above what is left', () {
    // 2 of 3 of 10000 = 6666.67 -> 6667.
    final plan = planRefund(
      lines: [mie],
      quantities: {'i-1': const Qty(2000)},
      refundable: const Money(50000),
    );
    expect(plan.items.single.amount, const Money(6667));

    // Weighed: 0.5 of 1.25 kg at 52500 = 21000.
    final rice = planRefund(
      lines: const [
        RefundableLine(id: 'r', net: Money(52500), quantity: Qty(1250)),
      ],
      quantities: {'r': const Qty(500)},
      refundable: const Money(52500),
    );
    expect(rice.items.single.amount, const Money(21000));
  });

  test('problems', () {
    expect(
      planRefund(
        lines: [mie],
        quantities: const {},
        refundable: const Money(1),
      ).problem,
      RefundProblem.empty,
    );
    expect(
      planRefund(
        lines: [mie],
        quantities: {'i-1': Qty.zero},
        refundable: const Money(50000),
      ).problem,
      RefundProblem.empty,
    );
    expect(
      planRefund(
        lines: [mie],
        quantities: {'i-1': const Qty(4000)},
        refundable: const Money(50000),
      ).problem,
      RefundProblem.quantity,
    );
    // Part of the bill was kasbon: only the money received comes back.
    expect(
      planRefund(
        lines: [mie],
        quantities: {'i-1': const Qty(3000)},
        refundable: const Money(9000),
      ).problem,
      RefundProblem.exceedsPaid,
    );
    // A free item: nothing to give back.
    expect(
      planRefund(
        lines: const [
          RefundableLine(id: 'f', net: Money.zero, quantity: Qty.one),
        ],
        quantities: {'f': Qty.one},
        refundable: const Money(1000),
      ).problem,
      RefundProblem.zero,
    );
  });

  test('unknown lines are refused', () {
    expect(
      () => planRefund(
        lines: [mie],
        quantities: {'nope': Qty.one},
        refundable: const Money(1),
      ),
      throwsArgumentError,
    );
  });
}
