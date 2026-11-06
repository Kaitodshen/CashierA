import 'package:cashiera_core/cashiera_core.dart';
import 'package:test/test.dart';

/// Shift B of supabase/tests/database/140_shift_audit.test.sql, built from
/// the terminal's side. Both must give the same report.
void main() {
  Map<String, dynamic> order(
    String id,
    int qty,
    List<Map<String, dynamic>> payments,
  ) => {
    'id': id,
    'gross_total': qty * 3500,
    'item_discount_total': 0,
    'bill_discount_total': 0,
    'points_discount': 0,
    'net_total': qty * 3500,
    'service_charge_total': 0,
    'tax_total': 0,
    'rounding_amount': 0,
    'grand_total': qty * 3500,
    'items': [
      {
        'id': '$id:item:1',
        'variant_id': 'v-mie',
        'product_name': 'Mie Goreng Instan',
        'variant_name': 'Original',
        'quantity': '$qty.000',
        'net_amount': qty * 3500,
      },
    ],
    'payments': payments,
  };

  test('shift B: void from shift A, split sale, cash refund, cash in/out', () {
    final report = ShiftReport.build(
      shift: const ShiftInfo(
        id: 'b',
        openingCash: Money(50000),
        openedAt: '2026-11-06T02:00:00Z',
        deviceCode: 'T1',
        openedByName: 'Eko Saputra',
        closedAt: '2026-11-06T10:00:00Z',
        countedCash: Money(70000),
      ),
      orders: [
        ShiftOrder.fromPayload(
          order('o1', 2, [
            {
              'payment_method_id': 'cash',
              'method_type': 'cash',
              'amount': 7000,
            },
          ]),
          status: 'voided',
          shiftId: 'a',
          voidedShiftId: 'b',
        ),
        ShiftOrder.fromPayload(
          order('o2', 4, [
            {
              'payment_method_id': 'debit',
              'method_type': 'card',
              'amount': 4000,
            },
            {
              'payment_method_id': 'cash',
              'method_type': 'cash',
              'amount': 10000,
            },
          ]),
          status: 'completed',
          shiftId: 'b',
          refundedQuantities: const {'o2:item:1': Qty.one},
        ),
      ],
      refunds: const [
        ShiftRefund(shiftId: 'b', amount: Money(3500), methodType: 'cash'),
      ],
      movements: const [
        ShiftCashMovement(shiftId: 'b', isIn: true, amount: Money(25000)),
        ShiftCashMovement(shiftId: 'b', isIn: false, amount: Money(5000)),
      ],
      methods: const {
        'cash': PaymentMethodInfo(name: 'Tunai', sortOrder: 10),
        'debit': PaymentMethodInfo(name: 'Kartu Debit', sortOrder: 30),
      },
    );

    expect(report.cash.expected, const Money(69500));
    expect(report.cash.difference, const Money(500));
    expect(report.voids, (orders: 1, total: const Money(7000)));
    expect(report.refunds, (
      count: 1,
      amount: const Money(3500),
      cash: const Money(3500),
    ));
    expect(report.payments.map((p) => (p.name, p.count, p.amount.rupiah)), [
      ('Tunai', 1, 10000),
      ('Kartu Debit', 1, 4000),
    ]);
    expect(report.sales.orders, 1);
    expect(report.sales.grand, const Money(14000));
    expect(report.topItems.single.quantity, const Qty(3000));
    expect(report.topItems.single.name, 'Mie Goreng Instan Original');
  });
}
