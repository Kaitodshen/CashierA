import 'package:cashiera_core/src/money.dart';
import 'package:cashiera_core/src/pricing/allocation.dart';
import 'package:cashiera_core/src/pricing/discount.dart';
import 'package:cashiera_core/src/pricing/pricing_line.dart';
import 'package:cashiera_core/src/pricing/promo_engine.dart';
import 'package:cashiera_core/src/pricing/promotion.dart';
import 'package:cashiera_core/src/rounding.dart';
import 'package:meta/meta.dart';

/// `order_discounts.source`.
enum DiscountSource {
  manual,
  promotion,
  voucher,
  points;

  String get code => name;
}

/// One row for `order_discounts`: why a discount was given.
class AppliedDiscount {
  const new({
    required this.source,
    required this.description,
    required this.amount,
    this.lineId,
    this.promotionId,
    this.voucherId,
    this.bps,
  });

  final DiscountSource source;
  final String description;
  final Money amount;

  /// Set for item discounts; null for bill discounts.
  final String? lineId;
  final String? promotionId;
  final String? voucherId;

  /// The percentage, when the discount was given as one.
  final int? bps;
}

/// Descriptions for discounts that have no name of their own. The app passes
/// its translations; the defaults are Indonesian.
@immutable
class DiscountLabels {
  const new({
    this.manualLine = 'Diskon',
    this.manualBill = 'Diskon tagihan',
    this.voucherPrefix = 'Voucher',
    this.points = 'Tukar poin',
  });

  final String manualLine;
  final String manualBill;
  final String voucherPrefix;
  final String points;

  @override
  bool operator ==(Object other) =>
      other is DiscountLabels &&
      other.manualLine == manualLine &&
      other.manualBill == manualBill &&
      other.voucherPrefix == voucherPrefix &&
      other.points == points;

  @override
  int get hashCode =>
      Object.hash(manualLine, manualBill, voucherPrefix, points);
}

/// A priced line, ready for `order_items`.
class BillLine {
  const new({
    required this.id,
    required this.gross,
    required this.itemDiscount,
    required this.billDiscount,
    required this.net,
    required this.tax,
  });

  final String id;
  final Money gross;
  final Money itemDiscount;

  /// This line's share of bill discounts and points.
  final Money billDiscount;
  final Money net;

  /// This line's share of the bill's tax (0 on exempt lines).
  final Money tax;
}

/// Everything `order.upsert` needs about money, computed in the order of
/// docs §4.5 and consistent with `app.validate_order_totals`.
class Bill {
  const new({
    required this.lines,
    required this.discounts,
    required this.gross,
    required this.itemDiscount,
    required this.billDiscount,
    required this.pointsDiscount,
    required this.pointsRedeemed,
    required this.net,
    required this.serviceCharge,
    required this.taxBase,
    required this.tax,
    required this.rounding,
    required this.grandTotal,
    required this.maxManualBps,
    this.voucherProblem,
  });

  final List<BillLine> lines;
  final List<AppliedDiscount> discounts;
  final Money gross;
  final Money itemDiscount;

  /// Bill discounts without points (promotions, manual, voucher).
  final Money billDiscount;
  final Money pointsDiscount;
  final int pointsRedeemed;
  final Money net;
  final Money serviceCharge;

  /// Taxable net plus the service charge when it is taxable. With PPN
  /// included, the DPP is `taxBase - tax`.
  final Money taxBase;
  final Money tax;
  final Money rounding;
  final Money grandTotal;

  /// The largest manual discount, measured like the server does.
  final int maxManualBps;

  /// Set when a voucher was given but cannot be used.
  final VoucherProblem? voucherProblem;

  /// Gross minus item discounts: what bill discounts are measured against.
  Money get subtotal => gross - itemDiscount;

  bool needsApproval(int thresholdBps) => maxManualBps > thresholdBps;
}

/// Prices a cart. [promotions] must already be filtered to the ones active
/// now in this store (see `Promotion.isActiveAt`); [now] is used to check
/// the voucher.
Bill calculateBill({
  required List<PricingLine> lines,
  required PricingSettings settings,
  List<Promotion> promotions = const [],
  DiscountSpec? billDiscount,
  Voucher? voucher,
  PointsRedemption? points,
  DateTime? now,
  DiscountLabels labels = const DiscountLabels(),
}) {
  final discounts = <AppliedDiscount>[];
  var maxManualBps = 0;

  // 1–2. Line gross, then item promotions and manual line discounts.
  final states = [for (final l in lines) PromoLineState(l)];
  for (final d in applyItemPromotions(states, promotions)) {
    discounts.add(
      AppliedDiscount(
        source: DiscountSource.promotion,
        description: d.promotion.name,
        amount: Money(d.amount),
        lineId: d.lineId,
        promotionId: d.promotion.id,
        bps: _promoBps(d.promotion),
      ),
    );
  }
  for (final s in states) {
    final spec = s.line.manualDiscount;
    if (spec == null) continue;
    final amount = spec.percentOf(s.remaining);
    if (amount == 0) continue;
    s.remaining -= amount;
    final bps = effectiveDiscountBps(
      amount,
      s.line.gross.rupiah,
      bps: spec.bps,
    );
    if (bps > maxManualBps) maxManualBps = bps;
    discounts.add(
      AppliedDiscount(
        source: DiscountSource.manual,
        description: labels.manualLine,
        amount: Money(amount),
        lineId: s.line.id,
        bps: spec.bps,
      ),
    );
  }

  final gross = states.fold(0, (a, s) => a + s.line.gross.rupiah);
  final subtotal = states.fold(0, (a, s) => a + s.remaining);
  var left = subtotal;
  var billTotal = 0;

  void addBill(AppliedDiscount Function(int amount) row, int wanted) {
    final amount = wanted.clamp(0, left);
    if (amount == 0) return;
    left -= amount;
    billTotal += amount;
    discounts.add(row(amount));
  }

  // 3. Bill promotions, manual bill discount, voucher, then points.
  final billPromos = promotions.where((p) => p.type.isBillLevel).toList()
    ..sort((a, b) {
      final byPriority = a.priority.compareTo(b.priority);
      return byPriority != 0 ? byPriority : a.id.compareTo(b.id);
    });
  var billPromoApplied = false;
  var billPromoClosed = false;
  for (final p in billPromos) {
    if (billPromoClosed) break;
    if (!p.isStackable && billPromoApplied) continue;
    final rules = p.rules as MinPurchaseRules;
    if (subtotal < rules.minSubtotal) continue;
    var wanted = rules.discount.percentOf(subtotal);
    if (rules.maxDiscount != null && wanted > rules.maxDiscount!) {
      wanted = rules.maxDiscount!;
    }
    final before = billTotal;
    addBill(
      (amount) => AppliedDiscount(
        source: DiscountSource.promotion,
        description: p.name,
        amount: Money(amount),
        promotionId: p.id,
        bps: rules.discount.bps,
      ),
      wanted,
    );
    if (billTotal > before) {
      billPromoApplied = true;
      if (!p.isStackable) billPromoClosed = true;
    }
  }

  if (billDiscount != null) {
    final before = billTotal;
    addBill(
      (amount) => AppliedDiscount(
        source: DiscountSource.manual,
        description: labels.manualBill,
        amount: Money(amount),
        bps: billDiscount.bps,
      ),
      billDiscount.percentOf(subtotal),
    );
    final given = billTotal - before;
    if (given > 0) {
      final bps = effectiveDiscountBps(given, subtotal, bps: billDiscount.bps);
      if (bps > maxManualBps) maxManualBps = bps;
    }
  }

  VoucherProblem? voucherProblem;
  if (voucher != null) {
    voucherProblem = voucher.check(
      now ?? DateTime.now().toUtc(),
      Money(subtotal),
    );
    if (voucherProblem == null) {
      addBill(
        (amount) => AppliedDiscount(
          source: DiscountSource.voucher,
          description: '${labels.voucherPrefix} ${voucher.code}',
          amount: Money(amount),
          voucherId: voucher.id,
          bps: voucher.discount.bps,
        ),
        voucher.amountOn(subtotal),
      );
    }
  }

  var pointsRedeemed = 0;
  var pointsDiscount = 0;
  if (points != null && points.points > 0 && points.pointValue.rupiah > 0) {
    final value = points.pointValue.rupiah;
    pointsRedeemed = points.points * value <= left
        ? points.points
        : left ~/ value;
    pointsDiscount = pointsRedeemed * value;
    if (pointsDiscount > 0) {
      left -= pointsDiscount;
      discounts.add(
        AppliedDiscount(
          source: DiscountSource.points,
          description: labels.points,
          amount: Money(pointsDiscount),
        ),
      );
    }
  }

  // Spread bill discounts and points over the lines by what is left of each.
  final weights = [for (final s in states) s.remaining];
  final billShares = allocateLargestRemainder(
    billTotal + pointsDiscount,
    weights,
  );
  final nets = [
    for (var i = 0; i < states.length; i++) states[i].remaining - billShares[i],
  ];
  final net = nets.fold(0, (a, b) => a + b);

  // 4. Service charge, 5. tax on the bill.
  final service = divRoundHalfUp(net * settings.serviceChargeBps, 10000);
  var taxableNet = 0;
  for (var i = 0; i < states.length; i++) {
    if (states[i].line.isTaxable) taxableNet += nets[i];
  }
  final taxBase = taxableNet + (settings.serviceChargeTaxable ? service : 0);
  final rate = settings.taxRateBps;
  final tax = rate == 0
      ? 0
      : settings.taxInclusive
      ? divRoundHalfUp(taxBase * rate, 10000 + rate)
      : divRoundHalfUp(taxBase * rate, 10000);

  // 6. Rounding of the total.
  final beforeRounding = net + service + (settings.taxInclusive ? 0 : tax);
  final rounded = _round(beforeRounding, settings);

  // 7. Tax back onto the taxable lines (the header keeps it when no taxable
  // line has anything left to carry it).
  final lineTax = taxableNet > 0
      ? allocateLargestRemainder(tax, [
          for (var i = 0; i < states.length; i++)
            if (states[i].line.isTaxable) nets[i] else 0,
        ])
      : List.filled(states.length, 0);

  final itemDiscountTotal = gross - subtotal;
  return Bill(
    lines: [
      for (var i = 0; i < states.length; i++)
        BillLine(
          id: states[i].line.id,
          gross: states[i].line.gross,
          itemDiscount: Money(
            states[i].line.gross.rupiah - states[i].remaining,
          ),
          billDiscount: Money(billShares[i]),
          net: Money(nets[i]),
          tax: Money(lineTax[i]),
        ),
    ],
    discounts: discounts,
    gross: Money(gross),
    itemDiscount: Money(itemDiscountTotal),
    billDiscount: Money(billTotal),
    pointsDiscount: Money(pointsDiscount),
    pointsRedeemed: pointsRedeemed,
    net: Money(net),
    serviceCharge: Money(service),
    taxBase: Money(taxBase),
    tax: Money(tax),
    rounding: Money(rounded - beforeRounding),
    grandTotal: Money(rounded),
    maxManualBps: maxManualBps,
    voucherProblem: voucherProblem,
  );
}

int? _promoBps(Promotion p) => switch (p.rules) {
  HappyHourRules(:final discount) => discount.bps,
  BuyXGetYRules(:final getDiscount) => getDiscount.bps,
  _ => null,
};

int _round(int amount, PricingSettings s) {
  final unit = s.roundingUnit;
  return switch (s.roundingMode) {
    RoundingMode.none => amount,
    RoundingMode.nearest => divRoundHalfUp(amount, unit) * unit,
    RoundingMode.up => (amount + unit - 1) ~/ unit * unit,
    RoundingMode.down => amount ~/ unit * unit,
  };
}
