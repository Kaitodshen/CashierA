import 'package:cashiera_core/cashiera_core.dart';
import 'package:test/test.dart';

const settings = PricingSettings(taxRateBps: 1100);

PricingLine line(
  String id,
  int price, {
  String qty = '1',
  String product = 'p-other',
  String? variant,
  String? category,
  DiscountSpec? manual,
}) => PricingLine(
  id: id,
  productId: product,
  variantId: variant ?? 'v-$id',
  categoryId: category,
  unitPrice: Money(price),
  quantity: Qty.parse(qty),
  manualDiscount: manual,
);

Promotion promo(
  String type,
  Map<String, dynamic> rules, {
  String id = 'promo',
  int priority = 100,
  bool stackable = false,
}) => Promotion.fromJson({
  'id': id,
  'name': 'Promo $id',
  'promo_type': type,
  'rules': rules,
  'priority': priority,
  'is_stackable': stackable,
  'is_active': true,
});

Map<String, dynamic> scope(String key, String id) => {
  key: [id],
};

Map<String, dynamic> percent(int bps) => {'type': 'percent', 'bps': bps};
Map<String, dynamic> fixed(int amount) => {'type': 'fixed', 'amount': amount};

Bill bill(List<PricingLine> lines, List<Promotion> promotions) =>
    calculateBill(lines: lines, settings: settings, promotions: promotions);

List<int> itemDiscounts(Bill b) =>
    b.lines.map((l) => l.itemDiscount.rupiah).toList();

void main() {
  group('happy hour', () {
    test('percent off the lines in scope only', () {
      final b = bill(
        [line('teh', 4000, qty: '3', category: 'c-drink'), line('roti', 10000)],
        [
          promo('happy_hour', {
            'scope': scope('category_ids', 'c-drink'),
            'discount': percent(1000),
          }),
        ],
      );
      expect(itemDiscounts(b), [1200, 0]);
      final row = b.discounts.single;
      expect(row.source, DiscountSource.promotion);
      expect(row.promotionId, 'promo');
      expect(row.lineId, 'teh');
      expect(row.description, 'Promo promo');
      expect(row.bps, 1000);
    });

    test('a fixed amount is per unit, also for kg', () {
      final b = bill(
        [line('bawang', 42000, qty: '1.500', product: 'p-bawang')],
        [
          promo('happy_hour', {
            'scope': scope('product_ids', 'p-bawang'),
            'discount': fixed(500),
          }),
        ],
      );
      expect(itemDiscounts(b), [750]);
    });

    test('a fixed amount above the price stops at zero', () {
      final b = bill(
        [line('teh', 4000, qty: '2', category: 'c-drink')],
        [
          promo('happy_hour', {
            'scope': {'all': true},
            'discount': fixed(5000),
          }),
        ],
      );
      expect(itemDiscounts(b), [8000]);
      expect(b.net, Money.zero);
    });
  });

  group('buy X get Y', () {
    Promotion b2g1({int? max}) => promo('buy_x_get_y', {
      'buy': {'scope': scope('product_ids', 'p-mie'), 'quantity': 2},
      'get': {
        'scope': scope('product_ids', 'p-mie'),
        'quantity': 1,
        'discount': percent(10000),
      },
      'max_applications': max,
    });

    int discountFor(String qty, {int? max}) => bill(
      [line('mie', 3500, qty: qty, product: 'p-mie')],
      [b2g1(max: max)],
    ).itemDiscount.rupiah;

    test('every third one is free', () {
      expect(discountFor('2'), 0);
      expect(discountFor('3'), 3500);
      expect(discountFor('5'), 3500);
      expect(discountFor('6'), 7000);
    });

    test('max applications', () {
      expect(discountFor('6', max: 1), 3500);
    });

    test('the cheapest unit is the free one', () {
      final b = bill(
        [
          line('mie', 3500, qty: '2', product: 'p-mie'),
          line('jumbo', 5000, product: 'p-mie'),
        ],
        [b2g1()],
      );
      expect(itemDiscounts(b), [3500, 0]);
    });

    test('only whole units count for items sold by weight', () {
      final b = bill(
        [line('mie', 3500, qty: '2.900', product: 'p-mie')],
        [b2g1()],
      );
      expect(b.itemDiscount, Money.zero);
    });

    test('buy one thing, get another half price', () {
      final b = bill(
        [
          line('shampoo', 25000, product: 'p-shampoo'),
          line('sabun', 6000, qty: '2', product: 'p-sabun'),
        ],
        [
          promo('buy_x_get_y', {
            'buy': {'scope': scope('product_ids', 'p-shampoo'), 'quantity': 1},
            'get': {
              'scope': scope('product_ids', 'p-sabun'),
              'quantity': 1,
              'discount': percent(5000),
            },
          }),
        ],
      );
      expect(itemDiscounts(b), [0, 3000]);
    });
  });

  group('bundle', () {
    Promotion paket({int? max}) => promo('bundle', {
      'components': [
        {'scope': scope('product_ids', 'p-mie'), 'quantity': 2},
        {'scope': scope('variant_ids', 'v-telur'), 'quantity': 1},
      ],
      'bundle_price': 34000,
      'max_applications': max,
    });

    test('the saving is spread over the bundled units', () {
      final b = bill(
        [
          line('mie', 3500, qty: '2', product: 'p-mie'),
          line('telur', 28000, variant: 'v-telur'),
        ],
        [paket()],
      );
      // 35.000 worth for 34.000: 1.000 off, by value 100 + 100 + 800.
      expect(itemDiscounts(b), [200, 800]);
      expect(b.discounts, hasLength(2));
    });

    test('incomplete bundles and bundles that cost more do nothing', () {
      expect(
        bill(
          [line('mie', 3500, qty: '2', product: 'p-mie')],
          [paket()],
        ).itemDiscount,
        Money.zero,
      );
      expect(
        bill(
          [
            line('mie', 3000, qty: '2', product: 'p-mie'),
            line('telur', 24000, variant: 'v-telur'),
          ],
          [paket()],
        ).itemDiscount,
        Money.zero,
        reason: '30.000 is already below the bundle price',
      );
    });

    test('applies as many times as complete sets exist', () {
      final b = bill(
        [
          line('mie', 3500, qty: '5', product: 'p-mie'),
          line('telur', 28000, qty: '2', variant: 'v-telur'),
        ],
        [paket()],
      );
      expect(b.itemDiscount, const Money(2000));
      expect(
        bill(
          [
            line('mie', 3500, qty: '4', product: 'p-mie'),
            line('telur', 28000, qty: '2', variant: 'v-telur'),
          ],
          [paket(max: 1)],
        ).itemDiscount,
        const Money(1000),
      );
    });
  });

  group('tiered quantity', () {
    final grosir = promo('tiered_qty', {
      'scope': scope('variant_ids', 'v-air'),
      'tiers': [
        {'min_quantity': 12, 'discount': percent(500)},
        {'min_quantity': 24, 'discount': percent(1000)},
      ],
    });

    int discountFor(String qty) => bill(
      [line('air', 4000, qty: qty, variant: 'v-air')],
      [grosir],
    ).itemDiscount.rupiah;

    test('the highest tier reached applies to the whole quantity', () {
      expect(discountFor('11'), 0);
      expect(discountFor('12'), 2400);
      expect(discountFor('24'), 9600);
    });

    test('several lines count together, decimals included', () {
      final b = bill(
        [
          line('a', 10000, qty: '7.5', product: 'p-gula', variant: 'v-g1'),
          line('b', 12000, qty: '4.5', product: 'p-gula', variant: 'v-g2'),
        ],
        [
          promo('tiered_qty', {
            'scope': scope('product_ids', 'p-gula'),
            'tiers': [
              {'min_quantity': 12, 'discount': percent(1000)},
            ],
          }),
        ],
      );
      expect(itemDiscounts(b), [7500, 5400]);
    });
  });

  group('minimum purchase', () {
    Promotion min150({Map<String, dynamic>? discount, int? maxDiscount}) =>
        promo('min_purchase', {
          'min_subtotal': 150000,
          'discount': discount ?? fixed(10000),
          'max_discount': maxDiscount,
        }, stackable: true);

    test('a bill discount once the subtotal is reached', () {
      final b = bill([line('a', 100000), line('b', 60000)], [min150()]);
      expect(b.billDiscount, const Money(10000));
      expect(b.itemDiscount, Money.zero);
      final row = b.discounts.single;
      expect(row.lineId, isNull);
      expect(row.promotionId, 'promo');
      expect(bill([line('a', 149999)], [min150()]).billDiscount, Money.zero);
    });

    test('percent with a ceiling', () {
      final b = bill(
        [line('a', 200000)],
        [min150(discount: percent(1000), maxDiscount: 5000)],
      );
      expect(b.billDiscount, const Money(5000));
    });

    test('the subtotal is counted after item promos', () {
      final b = bill(
        [line('teh', 160000, category: 'c-drink')],
        [
          promo(
            'happy_hour',
            {
              'scope': scope('category_ids', 'c-drink'),
              'discount': percent(1000),
            },
            id: 'hh',
            priority: 10,
          ),
          min150(),
        ],
      );
      expect(b.itemDiscount, const Money(16000));
      expect(b.billDiscount, Money.zero, reason: '144.000 is below 150.000');
    });
  });

  group('priority and stacking', () {
    final tenOff = {
      'scope': scope('category_ids', 'c'),
      'discount': percent(1000),
    };
    final fiveOff = {
      'scope': scope('category_ids', 'c'),
      'discount': percent(500),
    };

    test('a non-stackable promo blocks the ones after it', () {
      final b = bill(
        [line('x', 10000, category: 'c')],
        [
          promo(
            'happy_hour',
            fiveOff,
            id: 'late',
            priority: 20,
            stackable: true,
          ),
          promo('happy_hour', tenOff, id: 'first', priority: 10),
        ],
      );
      expect(b.itemDiscount, const Money(1000));
      expect(b.discounts.single.promotionId, 'first');
    });

    test('stackable promos apply one after another', () {
      final b = bill(
        [line('x', 10000, category: 'c')],
        [
          promo('happy_hour', tenOff, id: 'a', priority: 10, stackable: true),
          promo('happy_hour', fiveOff, id: 'b', priority: 20, stackable: true),
        ],
      );
      expect(b.itemDiscount, const Money(1450), reason: '1.000 + 5% of 9.000');
    });

    test('a non-stackable promo skips lines that already have one', () {
      final b = bill(
        [line('x', 10000, category: 'c'), line('y', 10000, category: 'c')],
        [
          promo(
            'happy_hour',
            {
              'scope': {
                'variant_ids': ['v-x'],
              },
              'discount': percent(1000),
            },
            id: 'a',
            priority: 10,
            stackable: true,
          ),
          promo('happy_hour', fiveOff, id: 'b', priority: 20),
        ],
      );
      expect(itemDiscounts(b), [1000, 500]);
    });

    test('manual discounts come after promos, on what is left', () {
      final b = bill(
        [
          line(
            'x',
            10000,
            category: 'c',
            manual: const DiscountSpec.fixed(2000),
          ),
        ],
        [promo('happy_hour', tenOff)],
      );
      expect(b.itemDiscount, const Money(3000));
      expect(b.net, const Money(7000));
      expect(b.maxManualBps, 2000, reason: 'measured against the line gross');
      expect(b.discounts.map((d) => d.source), [
        DiscountSource.promotion,
        DiscountSource.manual,
      ]);
    });
  });
}
