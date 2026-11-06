import 'package:cashiera_core/cashiera_core.dart';
import 'package:test/test.dart';

Tender cash(int amount, [String id = 'cash']) => Tender(
  id: id,
  methodId: 'm-cash',
  kind: TenderKind.cash,
  amount: Money(amount),
);
Tender card(int amount) => Tender(
  id: 'card',
  methodId: 'm-card',
  kind: TenderKind.card,
  amount: Money(amount),
  reference: 'APPR123',
);
Tender kasbon(int amount, [String id = 'kasbon']) => Tender(
  id: id,
  methodId: 'm-kasbon',
  kind: TenderKind.kasbon,
  amount: Money(amount),
);

void main() {
  test('cash with change', () {
    final s = settle(const Money(25000), [cash(50000)]);
    expect(s.isComplete, isTrue);
    final p = s.payments.single;
    expect(p.amount, const Money(25000));
    expect(p.tendered, const Money(50000));
    expect(p.change, const Money(25000));
    expect(s.paidTotal, const Money(25000));
    expect(s.changeTotal, const Money(25000));
  });

  test('card plus exact cash', () {
    final s = settle(const Money(25000), [card(15000), cash(10000)]);
    expect(s.isComplete, isTrue);
    expect(s.payments.map((p) => p.amount.rupiah), [15000, 10000]);
    expect(s.changeTotal, Money.zero);
  });

  test('card plus cash with change: change only comes from cash', () {
    final s = settle(const Money(25000), [card(15000), cash(20000)]);
    expect(s.isComplete, isTrue);
    expect(s.payments.last.amount, const Money(10000));
    expect(s.payments.last.change, const Money(10000));
    expect(s.payments.first.change, Money.zero);
    expect(s.payments.first.tendered, isNull);
  });

  test('a non-cash tender above the amount due is refused', () {
    final s = settle(const Money(25000), [card(30000)]);
    expect(s.isComplete, isFalse);
    expect(s.problem, SettlementProblem.nonCashExceedsDue);
  });

  test('short payment leaves a remainder', () {
    final s = settle(const Money(25000), [cash(20000)]);
    expect(s.isComplete, isFalse);
    expect(s.problem, isNull);
    expect(s.remaining, const Money(5000));
  });

  test('kasbon for the whole bill or the rest', () {
    final all = settle(const Money(25000), [kasbon(25000)]);
    expect(all.isComplete, isTrue);
    expect(all.paidTotal, Money.zero);
    expect(all.kasbonAmount, const Money(25000));

    final part = settle(const Money(25000), [cash(10000), kasbon(15000)]);
    expect(part.isComplete, isTrue);
    expect(part.paidTotal, const Money(10000));
    expect(part.kasbonAmount, const Money(15000));
  });

  test('kasbon only once', () {
    final s = settle(const Money(25000), [kasbon(10000), kasbon(15000, 'k2')]);
    expect(s.problem, SettlementProblem.multipleKasbon);
  });

  test('a free bill needs no payment', () {
    final s = settle(Money.zero, const []);
    expect(s.isComplete, isTrue);
    expect(s.payments, isEmpty);
  });

  test('a cash tender that is not needed is refused', () {
    final s = settle(const Money(25000), [card(25000), cash(10000)]);
    expect(s.problem, SettlementProblem.unneededTender);
  });

  test('zero or negative tenders are refused', () {
    expect(
      settle(const Money(25000), [cash(0)]).problem,
      SettlementProblem.invalidAmount,
    );
  });

  test('two cash tenders: change comes off the last one', () {
    final s = settle(const Money(70000), [
      cash(50000, 'c1'),
      cash(50000, 'c2'),
    ]);
    expect(s.isComplete, isTrue);
    expect(s.payments.map((p) => p.amount.rupiah), [50000, 20000]);
    expect(s.payments.map((p) => p.change.rupiah), [0, 30000]);
  });
}
