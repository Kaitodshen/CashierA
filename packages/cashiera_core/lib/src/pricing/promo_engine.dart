import 'package:cashiera_core/src/money.dart';
import 'package:cashiera_core/src/pricing/allocation.dart';
import 'package:cashiera_core/src/pricing/discount.dart';
import 'package:cashiera_core/src/pricing/pricing_line.dart';
import 'package:cashiera_core/src/pricing/promotion.dart';

/// Working state of one line while item-level promotions are applied.
class PromoLineState {
  new(this.line) : remaining = line.gross.rupiah;

  final PricingLine line;

  /// Gross minus the item discounts given so far.
  int remaining;

  /// A promotion gave this line a discount.
  bool touched = false;

  /// A non-stackable promotion gave this line a discount.
  bool locked = false;
}

/// One promotion's discount on one line.
class PromoLineDiscount {
  const new({
    required this.promotion,
    required this.lineId,
    required this.amount,
  });

  final Promotion promotion;
  final String lineId;
  final int amount;
}

/// Applies item-level promotions in priority order (then id, so the result
/// never depends on list order) and returns the discounts in that order.
/// Bill-level promotions are left to the bill calculator.
List<PromoLineDiscount> applyItemPromotions(
  List<PromoLineState> states,
  List<Promotion> promotions,
) {
  final ordered = promotions.where((p) => !p.type.isBillLevel).toList()
    ..sort((a, b) {
      final byPriority = a.priority.compareTo(b.priority);
      return byPriority != 0 ? byPriority : a.id.compareTo(b.id);
    });
  final result = <PromoLineDiscount>[];

  for (final promo in ordered) {
    final eligible = states
        .where((s) => !s.locked && (promo.isStackable || !s.touched))
        .where((s) => s.remaining > 0)
        .toList();
    if (eligible.isEmpty) continue;

    final amounts = switch (promo.rules) {
      HappyHourRules(:final scope, :final discount) => _perLine(
        eligible.where((s) => scope.matches(s.line)),
        discount,
      ),
      final TieredQtyRules r => _tiered(eligible, r),
      final BuyXGetYRules r => _buyXGetY(eligible, r),
      final BundleRules r => _bundle(eligible, r),
      MinPurchaseRules() => const <PromoLineState, int>{},
    };

    for (final state in eligible) {
      final amount = (amounts[state] ?? 0).clamp(0, state.remaining);
      if (amount == 0) continue;
      state
        ..remaining -= amount
        ..touched = true
        ..locked = state.locked || !promo.isStackable;
      result.add(
        PromoLineDiscount(
          promotion: promo,
          lineId: state.line.id,
          amount: amount,
        ),
      );
    }
  }
  return result;
}

/// Percent of what is left of each line, or a fixed amount per unit.
Map<PromoLineState, int> _perLine(
  Iterable<PromoLineState> lines,
  DiscountSpec discount,
) => {
  for (final s in lines)
    s: switch (discount) {
      PercentDiscount() => discount.percentOf(s.remaining),
      FixedDiscount(:final amount) =>
        s.line.quantity.times(Money(amount)).rupiah,
    },
};

Map<PromoLineState, int> _tiered(
  List<PromoLineState> eligible,
  TieredQtyRules rules,
) {
  final inScope = eligible.where((s) => rules.scope.matches(s.line)).toList();
  final milli = inScope.fold(0, (a, s) => a + s.line.quantity.milli);
  QtyTier? reached;
  for (final tier in rules.tiers) {
    if (milli >= tier.minQuantity * 1000) reached = tier;
  }
  if (reached == null) return const {};
  return _perLine(inScope, reached.discount);
}

/// One sellable unit of a line, for promotions that count items.
class _Unit {
  const new(this.state, this.index);

  final PromoLineState state;
  final int index;

  int get price => state.line.unitGross.rupiah;
}

List<_Unit> _units(Iterable<PromoLineState> lines) => [
  for (final s in lines)
    for (var i = 0; i < s.line.wholeUnits; i++) _Unit(s, i),
];

int _byPriceThenOrder(_Unit a, _Unit b, List<PromoLineState> order) {
  final byPrice = a.price.compareTo(b.price);
  if (byPrice != 0) return byPrice;
  final byLine = order.indexOf(a.state).compareTo(order.indexOf(b.state));
  return byLine != 0 ? byLine : a.index.compareTo(b.index);
}

/// Each application takes the cheapest "get" units, then the dearest "buy"
/// units among the rest; a unit is used once.
Map<PromoLineState, int> _buyXGetY(
  List<PromoLineState> eligible,
  BuyXGetYRules rules,
) {
  final getPool = _units(eligible.where((s) => rules.getScope.matches(s.line)))
    ..sort((a, b) => _byPriceThenOrder(a, b, eligible));
  final buyPool = _units(eligible.where((s) => rules.buyScope.matches(s.line)))
    ..sort((a, b) => _byPriceThenOrder(b, a, eligible));
  final used = <(PromoLineState, int)>{};
  final amounts = <PromoLineState, int>{};
  var applications = 0;

  while (rules.maxApplications == null ||
      applications < rules.maxApplications!) {
    final gets = getPool
        .where((u) => !used.contains((u.state, u.index)))
        .take(rules.getQuantity)
        .toList();
    if (gets.length < rules.getQuantity) break;
    final getKeys = {for (final u in gets) (u.state, u.index)};
    final buys = buyPool
        .where((u) => !used.contains((u.state, u.index)))
        .where((u) => !getKeys.contains((u.state, u.index)))
        .take(rules.buyQuantity)
        .toList();
    if (buys.length < rules.buyQuantity) break;

    for (final u in [...gets, ...buys]) {
      used.add((u.state, u.index));
    }
    for (final u in gets) {
      amounts[u.state] =
          (amounts[u.state] ?? 0) + rules.getDiscount.percentOf(u.price);
    }
    applications++;
  }
  return amounts;
}

/// Each application takes the dearest units for every component in turn and
/// gives away the difference to the bundle price, spread by unit value.
Map<PromoLineState, int> _bundle(
  List<PromoLineState> eligible,
  BundleRules rules,
) {
  final pools = [
    for (final c in rules.components)
      _units(eligible.where((s) => c.scope.matches(s.line)))
        ..sort((a, b) => _byPriceThenOrder(b, a, eligible)),
  ];
  final used = <(PromoLineState, int)>{};
  final amounts = <PromoLineState, int>{};
  var applications = 0;

  while (rules.maxApplications == null ||
      applications < rules.maxApplications!) {
    final picked = <_Unit>[];
    final pickedKeys = <(PromoLineState, int)>{};
    var complete = true;
    for (var c = 0; c < rules.components.length; c++) {
      final take = pools[c]
          .where((u) => !used.contains((u.state, u.index)))
          .where((u) => !pickedKeys.contains((u.state, u.index)))
          .take(rules.components[c].quantity)
          .toList();
      if (take.length < rules.components[c].quantity) {
        complete = false;
        break;
      }
      picked.addAll(take);
      pickedKeys.addAll(take.map((u) => (u.state, u.index)));
    }
    if (!complete) break;
    final value = picked.fold(0, (a, u) => a + u.price);
    final saving = value - rules.bundlePrice;
    if (saving <= 0) break;

    used.addAll(pickedKeys);
    final shares = allocateLargestRemainder(saving, [
      for (final u in picked) u.price,
    ]);
    for (var i = 0; i < picked.length; i++) {
      amounts[picked[i].state] = (amounts[picked[i].state] ?? 0) + shares[i];
    }
    applications++;
  }
  return amounts;
}
