import 'package:cashiera_core/cashiera_core.dart';
import 'package:test/test.dart';

/// The same sale as supabase/tests/database/130_pos.test.sql. If this test
/// changes, that fixture must change with it (and the server must accept it).
void main() {
  test('engine output equals the pgTAP 130 fixture', () {
    final b2g1 = Promotion.fromJson({
      'id': 'b2g1',
      'name': 'Beli 2 Gratis 1 Mie Goreng',
      'promo_type': 'buy_x_get_y',
      'rules': {
        'buy': {
          'scope': {
            'product_ids': ['mie-goreng'],
          },
          'quantity': 2,
        },
        'get': {
          'scope': {
            'product_ids': ['mie-goreng'],
          },
          'quantity': 1,
          'discount': {'type': 'percent', 'bps': 10000},
        },
        'max_applications': null,
      },
      'priority': 60,
      'is_stackable': false,
      'is_active': true,
    });
    final bill = calculateBill(
      lines: [
        PricingLine(
          id: 'mie',
          productId: 'mie-goreng',
          variantId: 'MIE-GRG-ORI',
          unitPrice: const Money(3500),
          quantity: Qty.parse('3'),
        ),
        const PricingLine(
          id: 'beras',
          productId: 'beras-premium',
          variantId: 'SMB-BRS-5KG',
          unitPrice: Money(78000),
          quantity: Qty.one,
          isTaxable: false,
        ),
      ],
      settings: const PricingSettings(taxRateBps: 1100),
      promotions: [b2g1],
      billDiscount: const DiscountSpec.fixed(5000),
    );

    expect(bill.gross, const Money(88500));
    expect(bill.itemDiscount, const Money(3500));
    expect(bill.billDiscount, const Money(5000));
    expect(bill.lines.map((l) => l.billDiscount.rupiah), [412, 4588]);
    expect(bill.lines.map((l) => l.net.rupiah), [6588, 73412]);
    expect(bill.lines.map((l) => l.tax.rupiah), [653, 0]);
    expect(bill.tax, const Money(653));
    expect(bill.grandTotal, const Money(80000));
    expect(bill.needsApproval(2000), isFalse);

    final s = settle(bill.grandTotal, const [
      Tender(
        id: 'debit',
        methodId: 'debit_card',
        kind: TenderKind.card,
        amount: Money(50000),
        reference: 'APR-1188',
      ),
      Tender(
        id: 'cash',
        methodId: 'cash',
        kind: TenderKind.cash,
        amount: Money(50000),
      ),
    ]);
    expect(s.isComplete, isTrue);
    expect(s.payments.map((p) => p.amount.rupiah), [50000, 30000]);
    expect(s.changeTotal, const Money(20000));
    expect(s.paidTotal, const Money(80000));
  });
}
