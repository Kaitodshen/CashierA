import 'package:cashiera_core/cashiera_core.dart';
import 'package:test/test.dart';

Map<String, dynamic> payload({
  required String id,
  required int grand,
  required List<Map<String, dynamic>> payments,
  int gross = 0,
  int itemDiscount = 0,
  int billDiscount = 0,
  int points = 0,
  int service = 0,
  int tax = 0,
  int rounding = 0,
  List<Map<String, dynamic>> items = const [],
}) => {
  'id': id,
  'gross_total': gross == 0 ? grand : gross,
  'item_discount_total': itemDiscount,
  'bill_discount_total': billDiscount,
  'points_discount': points,
  'net_total':
      (gross == 0 ? grand : gross) - itemDiscount - billDiscount - points,
  'service_charge_total': service,
  'tax_total': tax,
  'rounding_amount': rounding,
  'grand_total': grand,
  'items': items,
  'payments': payments,
};

Map<String, dynamic> pay(String method, String type, int amount) => {
  'payment_method_id': method,
  'method_type': type,
  'amount': amount,
  'status': 'paid',
};

Map<String, dynamic> item(
  String id,
  String variant,
  String name,
  String qty,
  int net, {
  String? variantName,
}) => {
  'id': id,
  'variant_id': variant,
  'product_name': name,
  'variant_name': variantName ?? 'Default',
  'quantity': qty,
  'net_amount': net,
};

const methods = {
  'm-cash': PaymentMethodInfo(name: 'Tunai', sortOrder: 1),
  'm-card': PaymentMethodInfo(name: 'Kartu Debit', sortOrder: 2),
  'm-kasbon': PaymentMethodInfo(name: 'Kasbon', sortOrder: 9),
};

void main() {
  group('ShiftCash', () {
    test('expected cash follows app.shift_expected_cash', () {
      const cash = ShiftCash(
        openingCash: Money(200000),
        cashSales: Money(150000),
        voidedCash: Money(20000),
        cashRefunds: Money(5000),
        kasbonCash: Money(10000),
        cashIn: Money(50000),
        cashOut: Money(30000),
        countedCash: Money(354000),
      );
      expect(cash.expected, const Money(355000));
      expect(cash.difference, const Money(-1000));
      expect(cash.copyWith(countedCash: null).difference, isNull);
    });
  });

  group('ShiftReport.build', () {
    const shift = ShiftInfo(
      id: 's-2',
      openingCash: Money(100000),
      openedAt: '2026-11-06T01:00:00Z',
      deviceCode: 'T1',
      openedByName: 'Sari',
    );

    final orders = [
      ShiftOrder.fromPayload(
        payload(
          id: 'o-1',
          grand: 30000,
          gross: 32000,
          itemDiscount: 2000,
          tax: 2973,
          payments: [pay('m-cash', 'cash', 30000)],
          items: [
            item('i-1', 'v-mie', 'Mie Goreng', '3.000', 9000),
            item('i-2', 'v-air', 'Air', '2.000', 21000, variantName: '600 ml'),
          ],
        ),
        status: 'completed',
        shiftId: 's-2',
      ),
      ShiftOrder.fromPayload(
        payload(
          id: 'o-2',
          grand: 50000,
          payments: [
            pay('m-card', 'card', 40000),
            pay('m-cash', 'cash', 10000),
          ],
          items: [item('i-3', 'v-mie', 'Mie Goreng', '5.000', 50000)],
        ),
        status: 'completed',
        shiftId: 's-2',
        refundedQuantities: const {'i-3': Qty.one},
      ),
      // Kasbon sale: issued, but no cash.
      ShiftOrder.fromPayload(
        payload(
          id: 'o-3',
          grand: 15000,
          payments: [
            pay('m-cash', 'cash', 5000),
            pay('m-kasbon', 'kasbon', 10000),
          ],
        ),
        status: 'completed',
        shiftId: 's-2',
      ),
      // Sold in this shift, voided in this shift: counted in cash sales and
      // taken off again as voided cash.
      ShiftOrder.fromPayload(
        payload(
          id: 'o-4',
          grand: 12000,
          payments: [pay('m-cash', 'cash', 12000)],
        ),
        status: 'voided',
        shiftId: 's-2',
        voidedShiftId: 's-2',
      ),
      // Sold in the earlier shift s-1, voided now: the money leaves this
      // drawer, so it comes off this shift.
      ShiftOrder.fromPayload(
        payload(
          id: 'o-5',
          grand: 8000,
          payments: [pay('m-cash', 'cash', 8000)],
        ),
        status: 'voided',
        shiftId: 's-1',
        voidedShiftId: 's-2',
      ),
      // Sold in s-1 and still valid: not part of this shift at all.
      ShiftOrder.fromPayload(
        payload(
          id: 'o-6',
          grand: 99000,
          payments: [pay('m-cash', 'cash', 99000)],
        ),
        status: 'completed',
        shiftId: 's-1',
      ),
      ShiftOrder.fromPayload(
        payload(id: 'o-7', grand: 7000, payments: const []),
        status: 'cancelled',
        shiftId: 's-2',
      ),
      ShiftOrder.fromPayload(
        payload(id: 'o-8', grand: 7000, payments: const []),
        status: 'held',
        shiftId: 's-2',
      ),
    ];

    final report = ShiftReport.build(
      shift: shift,
      orders: orders,
      refunds: const [
        ShiftRefund(shiftId: 's-2', amount: Money(10000), methodType: 'cash'),
        ShiftRefund(shiftId: 's-2', amount: Money(4000), methodType: 'card'),
        ShiftRefund(shiftId: 's-1', amount: Money(1000), methodType: 'cash'),
      ],
      movements: const [
        ShiftCashMovement(shiftId: 's-2', isIn: true, amount: Money(50000)),
        ShiftCashMovement(shiftId: 's-2', isIn: false, amount: Money(20000)),
        ShiftCashMovement(shiftId: 's-1', isIn: false, amount: Money(1)),
      ],
      methods: methods,
    );

    test('an open shift gives an X report', () {
      expect(report.kind, ShiftReportKind.x);
      expect(report.deviceCode, 'T1');
      expect(report.openedByName, 'Sari');
    });

    test('sales count only completed orders of this shift', () {
      final s = report.sales;
      expect(s.orders, 3);
      expect(s.gross, const Money(97000));
      expect(s.discount, const Money(2000));
      expect(s.net, const Money(95000));
      expect(s.tax, const Money(2973));
      expect(s.grand, const Money(95000));
      expect(s.averageBasket, const Money(31667));
      expect(report.cancelledOrders, 1);
    });

    test(
      'voids count orders voided in this shift, wherever they were sold',
      () {
        expect(report.voids.orders, 2);
        expect(report.voids.total, const Money(20000));
      },
    );

    test('payments are grouped by method in the method order', () {
      expect(report.payments.map((p) => (p.name, p.count, p.amount.rupiah)), [
        ('Tunai', 3, 45000),
        ('Kartu Debit', 1, 40000),
        ('Kasbon', 1, 10000),
      ]);
      expect(report.kasbon.issued, const Money(10000));
      expect(report.kasbon.repaid, Money.zero);
    });

    test('refunds and cash', () {
      expect(report.refunds.count, 2);
      expect(report.refunds.amount, const Money(14000));
      expect(report.refunds.cash, const Money(10000));
      final c = report.cash;
      // Cash payments of this shift, voided ones included: 30000 + 10000 +
      // 5000 + 12000.
      expect(c.cashSales, const Money(57000));
      expect(c.voidedCash, const Money(20000));
      expect(c.cashIn, const Money(50000));
      expect(c.cashOut, const Money(20000));
      // 100000 + 57000 - 20000 - 10000 + 0 + 50000 - 20000
      expect(c.expected, const Money(157000));
      expect(c.countedCash, isNull);
    });

    test('top items net of refunded quantity, biggest first', () {
      expect(
        report.topItems.map(
          (t) => (t.name, t.quantity.toPlain(), t.net.rupiah),
        ),
        [('Mie Goreng', '7', 59000), ('Air 600 ml', '2', 21000)],
      );
    });

    test('a closed shift gives a Z report with the difference', () {
      final z = ShiftReport.build(
        shift: shift.copyWith(
          closedAt: '2026-11-06T10:00:00Z',
          closedByName: 'Budi',
          countedCash: const Money(156500),
        ),
        orders: orders,
        refunds: const [],
        movements: const [],
        methods: methods,
      );
      expect(z.kind, ShiftReportKind.z);
      expect(z.closedByName, 'Budi');
      expect(z.cash.expected, const Money(137000));
      expect(z.cash.difference, const Money(19500));
    });
  });

  test('fromJson reads the shift_summary shape', () {
    final r = ShiftReport.fromJson(const {
      'report': 'Z',
      'shift': {
        'id': 's-1',
        'store_id': 'store-pst',
        'store_name': 'Pusat',
        'status': 'closed',
        'business_date': '2026-11-06',
        'opened_at': '2026-11-06T01:00:00+00:00',
        'closed_at': '2026-11-06T10:00:00+00:00',
        'device_code': 'T1',
        'opened_by_name': 'Sari',
        'closed_by_name': 'Budi',
      },
      'sales': {
        'orders': 2,
        'gross_total': 80000,
        'discount_total': 2000,
        'net_total': 78000,
        'service_charge_total': 0,
        'tax_total': 7730,
        'rounding_total': 0,
        'grand_total': 78000,
        'average_basket': 39000,
      },
      'voids': {'orders': 1, 'grand_total': 12000},
      'cancelled_orders': 3,
      'payments': [
        {
          'payment_method_id': 'm-cash',
          'name': 'Tunai',
          'method_type': 'cash',
          'count': 2,
          'amount': 78000,
        },
      ],
      'refunds': {'count': 1, 'amount': 5000, 'cash_amount': 5000},
      'kasbon': {'issued': 0, 'repaid': 3000, 'repaid_cash': 3000},
      'cash': {
        'opening_cash': 100000,
        'cash_sales': 90000,
        'voided_cash': 12000,
        'cash_refunds': 5000,
        'kasbon_cash': 3000,
        'cash_in': 0,
        'cash_out': 10000,
        'expected_cash': 166000,
        'counted_cash': 165000,
        'cash_difference': -1000,
      },
      'top_items': [
        {
          'variant_id': 'v-1',
          'name': 'Mie Goreng',
          'quantity': 7.5,
          'net_amount': 59000,
        },
      ],
    });
    expect(r.kind, ShiftReportKind.z);
    expect(r.businessDate, '2026-11-06');
    expect(r.closedByName, 'Budi');
    expect((r.storeId, r.storeName), ('store-pst', 'Pusat'));
    expect(r.sales.grand, const Money(78000));
    expect(r.voids.total, const Money(12000));
    expect(r.cancelledOrders, 3);
    expect(r.payments.single.methodType, 'cash');
    expect(r.kasbon.repaidCash, const Money(3000));
    expect(r.cash.expected, const Money(166000));
    expect(r.cash.difference, const Money(-1000));
    expect(r.topItems.single.quantity, const Qty(7500));
  });

  test('CashCount adds up the notes and coins', () {
    final count = CashCount(const {100000: 2, 50000: 1, 2000: 3, 500: 4});
    expect(count.total, const Money(258000));
    expect(CashCount.denominations.first, 100000);
    expect(CashCount.denominations.last, 100);
    expect(() => CashCount(const {300: 1}), throwsArgumentError);
    expect(() => CashCount(const {1000: -1}), throwsArgumentError);
  });
}
