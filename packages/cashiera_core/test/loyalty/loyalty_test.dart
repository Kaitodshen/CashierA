import 'package:cashiera_core/cashiera_core.dart';
import 'package:test/test.dart';

void main() {
  const rules = LoyaltyRules(
    earnAmount: Money(10000),
    pointValue: Money(100),
    minRedeemPoints: 20,
  );

  group('earning', () {
    test('one point per full Rp 10.000 of net spend', () {
      expect(rules.pointsEarned(const Money(9999)), 0);
      expect(rules.pointsEarned(const Money(10000)), 1);
      expect(rules.pointsEarned(const Money(84000)), 8);
      expect(rules.pointsEarned(Money.zero), 0);
      expect(rules.pointsEarned(const Money(-500)), 0);
    });

    test('nothing when loyalty is off', () {
      const off = LoyaltyRules(
        enabled: false,
        earnAmount: Money(10000),
        pointValue: Money(100),
      );
      expect(off.pointsEarned(const Money(500000)), 0);
      expect(off.redeemable(balance: 500, payable: const Money(50000)), 0);
    });
  });

  group('redeeming', () {
    test('capped by the balance and by what is left to pay', () {
      expect(rules.redeemable(balance: 71, payable: const Money(50000)), 71);
      // Rp 3.450 left: at most 34 points (Rp 3.400).
      expect(rules.redeemable(balance: 71, payable: const Money(3450)), 34);
    });

    test('below the minimum nothing can be redeemed', () {
      expect(rules.redeemable(balance: 19, payable: const Money(50000)), 0);
      expect(rules.redeemable(balance: 71, payable: const Money(1900)), 0);
    });

    test('a negative balance redeems nothing', () {
      expect(rules.redeemable(balance: -5, payable: const Money(50000)), 0);
    });

    test('check names the problem', () {
      expect(rules.check(points: 30, balance: 71), isNull);
      expect(rules.check(points: 0, balance: 71), isNull);
      expect(rules.check(points: 10, balance: 71), RedeemProblem.belowMinimum);
      expect(rules.check(points: 80, balance: 71), RedeemProblem.notEnough);
      expect(
        const LoyaltyRules(
          enabled: false,
          earnAmount: Money(10000),
          pointValue: Money(100),
        ).check(points: 30, balance: 71),
        RedeemProblem.disabled,
      );
    });
  });

  group('kasbon', () {
    final debts = [
      KasbonDebt(
        orderId: 'o-2',
        amount: const Money(26000),
        paid: Money.zero,
        dueDate: DateTime.utc(2026, 12, 6),
      ),
      KasbonDebt(
        orderId: 'o-1',
        amount: const Money(84000),
        paid: const Money(30000),
        dueDate: DateTime.utc(2026, 12),
      ),
      KasbonDebt(
        orderId: 'o-0',
        amount: const Money(5000),
        paid: const Money(5000),
        dueDate: DateTime.utc(2026, 11),
      ),
    ];

    test('remaining and total outstanding', () {
      expect(debts[1].remaining, const Money(54000));
      expect(debts[2].isSettled, isTrue);
      expect(totalOutstanding(debts), const Money(80000));
    });

    test('a repayment goes to the oldest due first', () {
      final plan = allocateRepayment(debts, const Money(60000));
      expect(plan.problem, isNull);
      expect(plan.parts.map((p) => (p.orderId, p.amount.rupiah)), [
        ('o-1', 54000),
        ('o-2', 6000),
      ]);
      expect(plan.balanceAfter, const Money(20000));
    });

    test('paying everything settles every kasbon', () {
      final plan = allocateRepayment(debts, const Money(80000));
      expect(plan.parts, hasLength(2));
      expect(plan.balanceAfter, Money.zero);
    });

    test('more than is owed, nothing, or nothing owed is refused', () {
      expect(
        allocateRepayment(debts, const Money(80001)).problem,
        RepaymentProblem.exceedsBalance,
      );
      expect(
        allocateRepayment(debts, Money.zero).problem,
        RepaymentProblem.invalidAmount,
      );
      expect(
        allocateRepayment([debts[2]], const Money(1000)).problem,
        RepaymentProblem.nothingOwed,
      );
    });

    test('aging by days past due', () {
      final buckets = kasbonAging([
        ...debts,
        KasbonDebt(
          orderId: 'o-old',
          amount: const Money(7000),
          paid: Money.zero,
          dueDate: DateTime.utc(2026, 9),
        ),
      ], today: DateTime.utc(2026, 12, 15));
      // o-2 is 9 days late, o-1 14 days late, o-old 105 days late.
      expect(buckets.current, Money.zero);
      expect(buckets.late30, const Money(80000));
      expect(buckets.late60, Money.zero);
      expect(buckets.over60, const Money(7000));
      expect(buckets.total, const Money(87000));

      final early = kasbonAging(debts, today: DateTime.utc(2026, 11, 20));
      expect(early.current, const Money(80000));
      expect(debts[1].daysLate(DateTime.utc(2026, 11, 20)), 0);
      expect(debts[1].daysLate(DateTime.utc(2026, 12, 3)), 2);
    });
  });
}
