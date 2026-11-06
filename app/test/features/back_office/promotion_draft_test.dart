import 'package:cashiera/core/pos/money_input.dart';
import 'package:cashiera/features/back_office/presentation/promotion_editor_screen.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter_test/flutter_test.dart';

Promotion seedPromo(String type, Map<String, dynamic> rules, {String? start}) =>
    Promotion.fromJson(
      {
        'id': 'p-1',
        'name': 'Seed',
        'promo_type': type,
        'rules': rules,
        'priority': 50,
        'is_stackable': false,
        'days_of_week': [1, 2, 3, 4, 5],
        'start_time': start,
        'end_time': start == null ? null : '16:00:00',
        'is_active': true,
      },
      storeIds: {'store-pst'},
    );

void main() {
  test('every seeded promotion type survives editing unchanged', () {
    final seeds = [
      seedPromo('happy_hour', {
        'scope': {
          'category_ids': ['c-drink'],
        },
        'discount': {'type': 'percent', 'bps': 1000},
      }, start: '14:00:00'),
      seedPromo('buy_x_get_y', {
        'buy': {
          'scope': {
            'product_ids': ['p-mie'],
          },
          'quantity': 2,
        },
        'get': {
          'scope': {
            'product_ids': ['p-mie'],
          },
          'quantity': 1,
          'discount': {'type': 'percent', 'bps': 10000},
        },
        'max_applications': null,
      }),
      seedPromo('bundle', {
        'components': [
          {
            'scope': {
              'product_ids': ['p-mie'],
            },
            'quantity': 2,
          },
          {
            'scope': {
              'variant_ids': ['v-telur'],
            },
            'quantity': 1,
          },
        ],
        'bundle_price': 34000,
        'max_applications': 3,
      }),
      seedPromo('tiered_qty', {
        'scope': {
          'variant_ids': ['v-air'],
        },
        'tiers': [
          {
            'min_quantity': 12,
            'discount': {'type': 'percent', 'bps': 500},
          },
          {
            'min_quantity': 24,
            'discount': {'type': 'fixed', 'amount': 300},
          },
        ],
      }),
      seedPromo('min_purchase', {
        'min_subtotal': 150000,
        'discount': {'type': 'percent', 'bps': 500},
        'max_discount': 10000,
      }),
    ];
    for (final seed in seeds) {
      final (back, problem) = PromotionDraft.from(seed).toPromotion();
      expect(problem, isNull, reason: seed.type.code);
      expect(back!.toJson(), seed.toJson(), reason: seed.type.code);
      expect(back.storeIds, {'store-pst'});
    }
  });

  group('validation names the first problem', () {
    PromotionDraft draft() => PromotionDraft.empty()
      ..name = 'Promo'
      ..startMinute = 14 * 60
      ..endMinute = 16 * 60;

    test('name, window and period', () {
      expect((draft()..name = ' ').toPromotion().$2, PromoProblem.name);
      expect((draft()..endMinute = null).toPromotion().$2, PromoProblem.window);
      expect(
        (draft()
              ..startMinute = null
              ..endMinute = null)
            .toPromotion()
            .$2,
        PromoProblem.happyHourWindow,
      );
      expect(
        (draft()
              ..startsAt = DateTime(2026, 12)
              ..endsAt = DateTime(2026, 11))
            .toPromotion()
            .$2,
        PromoProblem.period,
      );
    });

    test('rules', () {
      final noScope = draft()..scope.all = false;
      expect(noScope.toPromotion().$2, PromoProblem.scope);
      expect(
        (draft()..discount = null).toPromotion().$2,
        PromoProblem.discount,
      );

      final bundle = draft()
        ..type = PromoType.bundle
        ..bundlePrice = 30000;
      bundle.components.removeLast();
      expect(bundle.toPromotion().$2, PromoProblem.components);

      final tiers = draft()..type = PromoType.tieredQty;
      tiers.tiers
        ..clear()
        ..add(TierDraft(24, const PercentDiscount(1000)))
        ..add(TierDraft(12, const PercentDiscount(500)));
      expect(tiers.toPromotion().$2, PromoProblem.tiers);

      expect(
        (draft()..type = PromoType.minPurchase).toPromotion().$2,
        PromoProblem.price,
      );
    });

    test('a fixed bill discount drops the percent ceiling', () {
      final (p, _) =
          (draft()
                ..type = PromoType.minPurchase
                ..minSubtotal = 100000
                ..discount = const FixedDiscount(5000)
                ..maxDiscount = 9000)
              .toPromotion();
      expect((p!.rules as MinPurchaseRules).maxDiscount, isNull);
    });
  });

  test('percent text both ways', () {
    expect(bpsToPercentText(1100), '11');
    expect(bpsToPercentText(1250), '12,5');
    expect(bpsToPercentText(725), '7,25');
    expect(parsePercentOrZero('0'), 0);
    expect(parsePercentOrZero('0,0 %'), 0);
    expect(parsePercentOrZero('20'), 2000);
    expect(parsePercentOrZero('x'), isNull);
  });
}
