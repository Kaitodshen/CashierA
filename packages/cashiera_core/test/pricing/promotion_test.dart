import 'package:cashiera_core/cashiera_core.dart';
import 'package:test/test.dart';

const store = 'store-pst';
const int wib = 7 * 60;

Promotion happyHour({
  List<int>? days = const [1, 2, 3, 4, 5],
  String? start = '14:00:00',
  String? end = '16:00:00',
  String? startsAt,
  String? endsAt,
  bool active = true,
  Set<String> stores = const {},
}) => Promotion.fromJson({
  'id': 'p-hh',
  'name': 'Happy Hour',
  'promo_type': 'happy_hour',
  'rules': {
    'scope': {
      'category_ids': ['c-drink'],
    },
    'discount': {'type': 'percent', 'bps': 1000},
  },
  'priority': 50,
  'is_stackable': false,
  'starts_at': startsAt,
  'ends_at': endsAt,
  'days_of_week': days,
  'start_time': start,
  'end_time': end,
  'is_active': active,
}, storeIds: stores);

/// 2026-11-05 is a Thursday (ISO day 4).
DateTime utc(int day, int hour, [int minute = 0]) =>
    DateTime.utc(2026, 11, day, hour, minute);

void main() {
  group('window', () {
    final promo = happyHour();
    bool at(DateTime t) =>
        promo.isActiveAt(t, utcOffsetMinutes: wib, storeId: store);

    test('inside the daily window on a weekday', () {
      expect(at(utc(5, 7, 30)), isTrue, reason: '14:30 WIB Thursday');
      expect(at(utc(5, 7)), isTrue, reason: '14:00 is inside');
    });

    test('outside the window or on the weekend', () {
      expect(at(utc(5, 9)), isFalse, reason: '16:00 WIB is the end');
      expect(at(utc(5, 6, 59)), isFalse, reason: '13:59 WIB');
      expect(at(utc(7, 8)), isFalse, reason: 'Saturday 15:00 WIB');
    });

    test('the store offset decides the local time', () {
      // 06:30 UTC is 13:30 in Jakarta but 14:30 in Makassar (WITA).
      expect(
        promo.isActiveAt(utc(5, 6, 30), utcOffsetMinutes: wib, storeId: store),
        isFalse,
      );
      expect(
        promo.isActiveAt(
          utc(5, 6, 30),
          utcOffsetMinutes: 8 * 60,
          storeId: store,
        ),
        isTrue,
      );
    });
  });

  test('a window past midnight belongs to the day it started', () {
    final late = happyHour(days: [5], start: '22:00', end: '02:00');
    bool at(DateTime t) =>
        late.isActiveAt(t, utcOffsetMinutes: wib, storeId: store);
    expect(at(utc(6, 16)), isTrue, reason: 'Friday 23:00 WIB');
    expect(at(utc(6, 18)), isTrue, reason: 'Saturday 01:00 WIB, Friday night');
    expect(at(utc(6, 20)), isFalse, reason: 'Saturday 03:00 WIB');
    expect(at(utc(5, 18)), isFalse, reason: 'Friday 01:00 is Thursday night');
  });

  test('no window and no days means always', () {
    final always = happyHour(days: null, start: null, end: null);
    expect(
      always.isActiveAt(utc(7, 2), utcOffsetMinutes: wib, storeId: store),
      isTrue,
    );
  });

  test('period, active flag and store list', () {
    final t = utc(5, 7, 30);
    bool on(Promotion p, [String s = store]) =>
        p.isActiveAt(t, utcOffsetMinutes: wib, storeId: s);
    expect(on(happyHour(startsAt: '2026-11-06T00:00:00+07:00')), isFalse);
    expect(on(happyHour(endsAt: '2026-11-05T14:00:00+07:00')), isFalse);
    expect(on(happyHour(endsAt: '2026-11-05T15:00:00+07:00')), isTrue);
    expect(on(happyHour(active: false)), isFalse);
    expect(on(happyHour(stores: {'store-bks'})), isFalse);
    expect(on(happyHour(stores: {'store-bks', store})), isTrue);
  });

  test('parses every rule shape the database accepts', () {
    final b2g1 = Promotion.fromJson({
      'id': 'p-b2g1',
      'name': 'B2G1',
      'promo_type': 'buy_x_get_y',
      'rules': {
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
      },
      'priority': 60,
      'is_stackable': false,
      'is_active': true,
    });
    expect(b2g1.rules, isA<BuyXGetYRules>());
    final r = b2g1.rules as BuyXGetYRules;
    expect(r.buyQuantity, 2);
    expect(r.getDiscount, const PercentDiscount(10000));
    expect(r.maxApplications, isNull);

    final tiers = Promotion.fromJson({
      'id': 'p-tier',
      'name': 'Grosir',
      'promo_type': 'tiered_qty',
      'rules': {
        'scope': {'all': true},
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
      },
      'priority': 80,
      'is_stackable': true,
      'is_active': true,
    });
    expect(
      (tiers.rules as TieredQtyRules).tiers.last.discount,
      const FixedDiscount(300),
    );
    expect(tiers.toJson()['rules'], {
      'scope': {'all': true},
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
    });
  });
}
