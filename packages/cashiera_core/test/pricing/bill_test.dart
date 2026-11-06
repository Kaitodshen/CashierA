import 'package:cashiera_core/cashiera_core.dart';
import 'package:test/test.dart';

const inclusive = PricingSettings(taxRateBps: 1100);
const exclusive = PricingSettings(taxRateBps: 1100, taxInclusive: false);

PricingLine line(
  String id,
  int price, {
  String qty = '1',
  bool taxable = true,
  String product = 'p',
  String? category,
  int modifiers = 0,
  DiscountSpec? manual,
}) => PricingLine(
  id: id,
  productId: product,
  variantId: 'v-$id',
  categoryId: category,
  unitPrice: Money(price),
  modifiersUnitTotal: Money(modifiers),
  quantity: Qty.parse(qty),
  isTaxable: taxable,
  manualDiscount: manual,
);

int sum(Iterable<Money> xs) => xs.fold(0, (a, b) => a + b.rupiah);

/// The identities `app.validate_order_totals` checks on the server.
void expectServerIdentities(Bill bill, PricingSettings s) {
  expect(sum(bill.lines.map((l) => l.gross)), bill.gross.rupiah);
  expect(sum(bill.lines.map((l) => l.itemDiscount)), bill.itemDiscount.rupiah);
  expect(
    sum(bill.lines.map((l) => l.billDiscount)),
    bill.billDiscount.rupiah + bill.pointsDiscount.rupiah,
  );
  expect(sum(bill.lines.map((l) => l.net)), bill.net.rupiah);
  expect(
    bill.net.rupiah,
    bill.gross.rupiah -
        bill.itemDiscount.rupiah -
        bill.billDiscount.rupiah -
        bill.pointsDiscount.rupiah,
  );
  expect(
    bill.grandTotal.rupiah,
    bill.net.rupiah +
        bill.serviceCharge.rupiah +
        (s.taxInclusive ? 0 : bill.tax.rupiah) +
        bill.rounding.rupiah,
  );
  final itemRows = bill.discounts.where((d) => d.lineId != null);
  final billRows = bill.discounts.where(
    (d) => d.lineId == null && d.source != DiscountSource.points,
  );
  expect(sum(itemRows.map((d) => d.amount)), bill.itemDiscount.rupiah);
  expect(sum(billRows.map((d) => d.amount)), bill.billDiscount.rupiah);
  for (final l in bill.lines) {
    expect(l.net.isNegative, isFalse);
  }
}

void main() {
  group('tax', () {
    test('docs example: Rp 25.000 with PPN 11% included', () {
      final bill = calculateBill(
        lines: [line('a', 25000)],
        settings: inclusive,
      );
      expect(bill.grandTotal, const Money(25000));
      expect(bill.tax, const Money(2477));
      expect(bill.taxBase - bill.tax, const Money(22523), reason: 'DPP');
      expect(bill.lines.single.tax, const Money(2477));
      expectServerIdentities(bill, inclusive);
    });

    test('PPN added on top', () {
      final bill = calculateBill(
        lines: [line('a', 10000, qty: '3')],
        settings: exclusive,
      );
      expect(bill.net, const Money(30000));
      expect(bill.tax, const Money(3300));
      expect(bill.grandTotal, const Money(33300));
      expectServerIdentities(bill, exclusive);
    });

    test('PPN-exempt lines carry no tax', () {
      final bill = calculateBill(
        lines: [line('a', 25000), line('beras', 15000, taxable: false)],
        settings: inclusive,
      );
      expect(bill.tax, const Money(2477));
      expect(bill.lines.map((l) => l.tax), [const Money(2477), Money.zero]);
      expect(bill.grandTotal, const Money(40000));
    });

    test('a basket of only exempt goods has no tax', () {
      final bill = calculateBill(
        lines: [
          line('beras', 65000, taxable: false),
          line('telur', 28000, taxable: false),
        ],
        settings: exclusive,
      );
      expect(bill.tax, Money.zero);
      expect(bill.grandTotal, const Money(93000));
      expectServerIdentities(bill, exclusive);
    });

    test('tax switched off', () {
      final bill = calculateBill(
        lines: [line('a', 25000)],
        settings: const PricingSettings(taxRateBps: 0),
      );
      expect(bill.tax, Money.zero);
      expect(bill.grandTotal, const Money(25000));
    });

    test('service charge, taxable, PPN on top', () {
      const s = PricingSettings(
        taxRateBps: 1100,
        taxInclusive: false,
        serviceChargeBps: 500,
      );
      final bill = calculateBill(
        lines: [line('a', 50000), line('b', 30000)],
        settings: s,
      );
      expect(bill.serviceCharge, const Money(4000));
      expect(bill.taxBase, const Money(84000));
      expect(bill.tax, const Money(9240));
      expect(bill.grandTotal, const Money(93240));
      expect(bill.lines.map((l) => l.tax.rupiah), [5775, 3465]);
      expectServerIdentities(bill, s);
    });

    test('taxable service on an exempt basket: tax stays on the header', () {
      const s = PricingSettings(
        taxRateBps: 1100,
        taxInclusive: false,
        serviceChargeBps: 1000,
      );
      final bill = calculateBill(
        lines: [line('beras', 50000, taxable: false)],
        settings: s,
      );
      expect(bill.serviceCharge, const Money(5000));
      expect(bill.tax, const Money(550));
      expect(bill.lines.single.tax, Money.zero);
      expect(bill.grandTotal, const Money(55550));
    });
  });

  group('lines', () {
    test('kg quantities and modifiers', () {
      final bill = calculateBill(
        lines: [
          line('bawang', 42000, qty: '1.250'),
          line('kopi', 18000, modifiers: 5000, qty: '2'),
        ],
        settings: inclusive,
      );
      expect(bill.lines.map((l) => l.gross.rupiah), [52500, 46000]);
      expect(bill.gross, const Money(98500));
    });

    test('manual line discount in percent', () {
      final bill = calculateBill(
        lines: [line('a', 25000, manual: const DiscountSpec.percent(1000))],
        settings: inclusive,
      );
      expect(bill.itemDiscount, const Money(2500));
      expect(bill.net, const Money(22500));
      expect(bill.tax, const Money(2230));
      expect(bill.maxManualBps, 1000);
      final row = bill.discounts.single;
      expect(row.source, DiscountSource.manual);
      expect(row.lineId, 'a');
      expect(row.bps, 1000);
      expectServerIdentities(bill, inclusive);
    });

    test('a fixed manual discount above the price is capped at the line', () {
      final bill = calculateBill(
        lines: [line('a', 25000, manual: const DiscountSpec.fixed(30000))],
        settings: inclusive,
      );
      expect(bill.itemDiscount, const Money(25000));
      expect(bill.net, Money.zero);
      expect(bill.grandTotal, Money.zero);
      expect(bill.maxManualBps, 10000);
      expect(bill.needsApproval(2000), isTrue);
    });
  });

  group('bill discounts', () {
    test('manual bill discount is spread by largest remainder', () {
      final bill = calculateBill(
        lines: [line('a', 30000), line('b', 20000)],
        settings: inclusive,
        billDiscount: const DiscountSpec.fixed(5000),
      );
      expect(bill.billDiscount, const Money(5000));
      expect(bill.lines.map((l) => l.billDiscount.rupiah), [3000, 2000]);
      expect(bill.lines.map((l) => l.net.rupiah), [27000, 18000]);
      expect(bill.maxManualBps, 1000);
      expect(bill.discounts.single.lineId, isNull);
      expectServerIdentities(bill, inclusive);
    });

    test('odd amounts still add up exactly', () {
      final bill = calculateBill(
        lines: [line('a', 3333), line('b', 3333), line('c', 3334)],
        settings: exclusive,
        billDiscount: const DiscountSpec.percent(333),
      );
      expect(bill.billDiscount, const Money(333));
      expectServerIdentities(bill, exclusive);
    });

    test('voucher: percent with a cap and a minimum', () {
      const hemat10 = Voucher(
        id: 'vc-1',
        code: 'HEMAT10',
        discount: DiscountSpec.percent(1000),
        maxDiscount: Money(20000),
        minSubtotal: Money(50000),
      );
      Bill withVoucher(int price) => calculateBill(
        lines: [line('a', price)],
        settings: inclusive,
        voucher: hemat10,
        now: DateTime.utc(2026, 11, 5),
      );
      expect(withVoucher(100000).billDiscount, const Money(10000));
      expect(withVoucher(300000).billDiscount, const Money(20000));
      final below = withVoucher(40000);
      expect(below.billDiscount, Money.zero);
      expect(below.voucherProblem, VoucherProblem.belowMinimum);
      final applied = withVoucher(100000).discounts.single;
      expect(applied.source, DiscountSource.voucher);
      expect(applied.voucherId, 'vc-1');
      expect(applied.description, 'Voucher HEMAT10');
    });

    test('voucher validity', () {
      final now = DateTime.utc(2026, 11, 5);
      Voucher v({
        DateTime? startsAt,
        DateTime? endsAt,
        int? maxUses,
        int used = 0,
        bool active = true,
      }) => Voucher(
        id: 'vc',
        code: 'X',
        discount: const DiscountSpec.fixed(5000),
        startsAt: startsAt,
        endsAt: endsAt,
        maxUses: maxUses,
        usedCount: used,
        isActive: active,
      );
      const s = Money(100000);
      expect(v().check(now, s), isNull);
      expect(v(active: false).check(now, s), VoucherProblem.inactive);
      expect(
        v(startsAt: DateTime.utc(2026, 12)).check(now, s),
        VoucherProblem.notStarted,
      );
      expect(
        v(endsAt: DateTime.utc(2026, 11, 4)).check(now, s),
        VoucherProblem.expired,
      );
      expect(v(maxUses: 3, used: 3).check(now, s), VoucherProblem.usedUp);
      expect(v(maxUses: 3, used: 2).check(now, s), isNull);
    });

    test('every bill discount together never exceeds the subtotal', () {
      final bill = calculateBill(
        lines: [line('a', 10000)],
        settings: inclusive,
        billDiscount: const DiscountSpec.fixed(7000),
        voucher: const Voucher(
          id: 'vc',
          code: 'BIG',
          discount: DiscountSpec.fixed(5000),
        ),
        points: const PointsRedemption(points: 30, pointValue: Money(100)),
        now: DateTime.utc(2026, 11, 5),
      );
      expect(bill.billDiscount, const Money(10000), reason: '7.000 + 3.000');
      expect(bill.pointsDiscount, Money.zero);
      expect(bill.pointsRedeemed, 0);
      expect(bill.net, Money.zero);
      expectServerIdentities(bill, inclusive);
    });

    test('points are cut to whole points that fit', () {
      final bill = calculateBill(
        lines: [line('a', 10000)],
        settings: inclusive,
        billDiscount: const DiscountSpec.fixed(7950),
        points: const PointsRedemption(points: 30, pointValue: Money(100)),
      );
      expect(bill.pointsRedeemed, 20);
      expect(bill.pointsDiscount, const Money(2000));
      expect(bill.net, const Money(50));
      expect(bill.discounts.last.source, DiscountSource.points);
      expectServerIdentities(bill, inclusive);
    });
  });

  group('rounding', () {
    Money grand(int price, RoundingMode mode, [int unit = 100]) =>
        calculateBill(
          lines: [line('a', price)],
          settings: PricingSettings(
            taxRateBps: 1100,
            roundingMode: mode,
            roundingUnit: unit,
          ),
        ).grandTotal;

    test('none, nearest, up and down', () {
      expect(grand(24950, RoundingMode.none), const Money(24950));
      expect(grand(24950, RoundingMode.nearest), const Money(25000));
      expect(grand(24949, RoundingMode.nearest), const Money(24900));
      expect(grand(24901, RoundingMode.up), const Money(25000));
      expect(grand(24999, RoundingMode.down), const Money(24900));
      expect(grand(24001, RoundingMode.up, 1000), const Money(25000));
      expect(grand(25000, RoundingMode.up, 1000), const Money(25000));
    });

    test('the rounding amount is on the header only', () {
      final bill = calculateBill(
        lines: [line('a', 24950)],
        settings: const PricingSettings(
          taxRateBps: 1100,
          roundingMode: RoundingMode.nearest,
        ),
      );
      expect(bill.rounding, const Money(50));
      expect(bill.net, const Money(24950));
      expect(bill.tax, const Money(2473), reason: 'tax ignores rounding');
    });
  });
}
