import 'package:cashiera_core/src/money.dart';
import 'package:cashiera_core/src/qty.dart';
import 'package:cashiera_core/src/rounding.dart';
import 'package:meta/meta.dart';

/// X = snapshot of an open shift, Z = the closing report.
enum ShiftReportKind { x, z }

/// The cash a drawer should hold, with the same terms as the server's
/// `app.shift_expected_cash`.
@immutable
class ShiftCash {
  const new({
    required this.openingCash,
    required this.cashSales,
    required this.voidedCash,
    required this.cashRefunds,
    required this.kasbonCash,
    required this.cashIn,
    required this.cashOut,
    this.countedCash,
  });

  /// Kas awal.
  final Money openingCash;

  /// Cash payments of the shift's sales, voided ones included.
  final Money cashSales;

  /// Cash of orders voided during this shift (sold here or earlier).
  final Money voidedCash;
  final Money cashRefunds;

  /// Kasbon repayments taken in cash.
  final Money kasbonCash;
  final Money cashIn;
  final Money cashOut;
  final Money? countedCash;

  Money get expected =>
      openingCash -
      voidedCash -
      cashRefunds -
      cashOut +
      cashSales +
      kasbonCash +
      cashIn;

  /// Selisih: counted minus expected, once counted.
  Money? get difference {
    final counted = countedCash;
    return counted == null ? null : counted - expected;
  }

  ShiftCash copyWith({required Money? countedCash}) => ShiftCash(
    openingCash: openingCash,
    cashSales: cashSales,
    voidedCash: voidedCash,
    cashRefunds: cashRefunds,
    kasbonCash: kasbonCash,
    cashIn: cashIn,
    cashOut: cashOut,
    countedCash: countedCash,
  );
}

@immutable
class SalesTotals {
  const new({
    required this.orders,
    required this.gross,
    required this.discount,
    required this.net,
    required this.serviceCharge,
    required this.tax,
    required this.rounding,
    required this.grand,
    required this.averageBasket,
  });

  final int orders;
  final Money gross;

  /// Item, bill and points discounts together.
  final Money discount;
  final Money net;
  final Money serviceCharge;
  final Money tax;
  final Money rounding;
  final Money grand;
  final Money averageBasket;
}

@immutable
class PaymentTotal {
  const new({
    required this.methodId,
    required this.name,
    required this.methodType,
    required this.count,
    required this.amount,
  });

  final String methodId;
  final String name;
  final String methodType;
  final int count;
  final Money amount;
}

@immutable
class TopItem {
  const new({
    required this.variantId,
    required this.name,
    required this.quantity,
    required this.net,
  });

  final String variantId;
  final String name;
  final Qty quantity;
  final Money net;
}

typedef VoidTotals = ({int orders, Money total});
typedef RefundTotals = ({int count, Money amount, Money cash});
typedef KasbonTotals = ({Money issued, Money repaid, Money repaidCash});

/// Name and order of a payment method, for grouping payments.
@immutable
class PaymentMethodInfo {
  const new({required this.name, required this.sortOrder});
  final String name;
  final int sortOrder;
}

/// The shift itself, as the terminal knows it.
@immutable
class ShiftInfo {
  const new({
    required this.id,
    required this.openingCash,
    required this.openedAt,
    this.closedAt,
    this.deviceCode,
    this.openedByName,
    this.closedByName,
    this.businessDate,
    this.countedCash,
  });

  final String id;
  final Money openingCash;

  /// ISO-8601 instants.
  final String openedAt;
  final String? closedAt;
  final String? deviceCode;
  final String? openedByName;
  final String? closedByName;

  /// `yyyy-MM-dd` in the store's time zone.
  final String? businessDate;
  final Money? countedCash;

  ShiftInfo copyWith({
    String? closedAt,
    String? closedByName,
    Money? countedCash,
    String? businessDate,
  }) => ShiftInfo(
    id: id,
    openingCash: openingCash,
    openedAt: openedAt,
    closedAt: closedAt ?? this.closedAt,
    deviceCode: deviceCode,
    openedByName: openedByName,
    closedByName: closedByName ?? this.closedByName,
    businessDate: businessDate ?? this.businessDate,
    countedCash: countedCash ?? this.countedCash,
  );
}

@immutable
class ShiftPayment {
  const new({
    required this.methodId,
    required this.methodType,
    required this.amount,
  });

  final String methodId;
  final String methodType;

  /// The amount booked (for cash: without the change).
  final Money amount;
}

@immutable
class ShiftItem {
  const new({
    required this.variantId,
    required this.name,
    required this.quantity,
    required this.net,
  });

  final String variantId;

  /// Product name plus the variant name unless it is `Default`.
  final String name;

  /// Sold minus refunded.
  final Qty quantity;
  final Money net;
}

/// One terminal order as far as the shift report cares.
@immutable
class ShiftOrder {
  const new({
    required this.status,
    required this.gross,
    required this.discount,
    required this.net,
    required this.serviceCharge,
    required this.tax,
    required this.rounding,
    required this.grand,
    this.shiftId,
    this.voidedShiftId,
    this.payments = const [],
    this.items = const [],
  });

  /// Reads an `order.upsert` payload. [refundedQuantities] maps order item
  /// ids to the quantity refunded so far.
  factory fromPayload(
    Map<String, dynamic> payload, {
    required String status,
    String? shiftId,
    String? voidedShiftId,
    Map<String, Qty> refundedQuantities = const {},
  }) {
    Money m(String key) => Money((payload[key] as num? ?? 0).toInt());
    return ShiftOrder(
      status: status,
      shiftId: shiftId,
      voidedShiftId: voidedShiftId,
      gross: m('gross_total'),
      discount:
          m('item_discount_total') +
          m('bill_discount_total') +
          m('points_discount'),
      net: m('net_total'),
      serviceCharge: m('service_charge_total'),
      tax: m('tax_total'),
      rounding: m('rounding_amount'),
      grand: m('grand_total'),
      payments: [
        for (final raw in payload['payments'] as List? ?? const [])
          if ((raw as Map)['status'] == null || raw['status'] == 'paid')
            ShiftPayment(
              methodId: raw['payment_method_id'] as String,
              methodType: raw['method_type'] as String,
              amount: Money((raw['amount'] as num).toInt()),
            ),
      ],
      items: [
        for (final raw in payload['items'] as List? ?? const [])
          () {
            final i = (raw as Map).cast<String, dynamic>();
            final variant = i['variant_name'] as String?;
            final sold = Qty.parse(i['quantity'] as String);
            final refunded = refundedQuantities[i['id']] ?? Qty.zero;
            return ShiftItem(
              variantId: i['variant_id'] as String,
              name: variant == null || variant == 'Default'
                  ? i['product_name'] as String
                  : '${i['product_name']} $variant',
              quantity: Qty(sold.milli - refunded.milli),
              net: Money((i['net_amount'] as num).toInt()),
            );
          }(),
      ],
    );
  }

  /// `held`, `completed`, `cancelled` or `voided`.
  final String status;
  final String? shiftId;
  final String? voidedShiftId;
  final Money gross;
  final Money discount;
  final Money net;
  final Money serviceCharge;
  final Money tax;
  final Money rounding;
  final Money grand;
  final List<ShiftPayment> payments;
  final List<ShiftItem> items;
}

@immutable
class ShiftRefund {
  const new({
    required this.shiftId,
    required this.amount,
    required this.methodType,
  });

  final String? shiftId;
  final Money amount;
  final String methodType;
}

@immutable
class ShiftCashMovement {
  const new({required this.shiftId, required this.isIn, required this.amount});

  final String shiftId;
  final bool isIn;
  final Money amount;
}

/// The X or Z report. The back office reads it from `shift_summary`, the
/// terminal builds it from its own rows with [ShiftReport.build]; both give
/// the same numbers for the same shift.
@immutable
class ShiftReport {
  const new({
    required this.kind,
    required this.shiftId,
    required this.openedAt,
    required this.sales,
    required this.voids,
    required this.cancelledOrders,
    required this.payments,
    required this.refunds,
    required this.kasbon,
    required this.cash,
    required this.topItems,
    this.closedAt,
    this.deviceCode,
    this.openedByName,
    this.closedByName,
    this.businessDate,
    this.storeId,
    this.storeName,
  });

  /// The JSON of `public.shift_summary(shift_id)`.
  factory fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> obj(Object? v) =>
        (v as Map? ?? const {}).cast<String, dynamic>();
    Money m(Map<String, dynamic> o, String key) =>
        Money((o[key] as num? ?? 0).toInt());
    final shift = obj(json['shift']);
    final sales = obj(json['sales']);
    final voids = obj(json['voids']);
    final refunds = obj(json['refunds']);
    final kasbon = obj(json['kasbon']);
    final cash = obj(json['cash']);
    final counted = cash['counted_cash'] as num?;
    return ShiftReport(
      kind: json['report'] == 'Z' ? ShiftReportKind.z : ShiftReportKind.x,
      shiftId: shift['id'] as String,
      openedAt: shift['opened_at'] as String,
      closedAt: shift['closed_at'] as String?,
      deviceCode: shift['device_code'] as String?,
      openedByName: shift['opened_by_name'] as String?,
      closedByName: shift['closed_by_name'] as String?,
      businessDate: shift['business_date'] as String?,
      storeId: shift['store_id'] as String?,
      storeName: shift['store_name'] as String?,
      sales: SalesTotals(
        orders: (sales['orders'] as num? ?? 0).toInt(),
        gross: m(sales, 'gross_total'),
        discount: m(sales, 'discount_total'),
        net: m(sales, 'net_total'),
        serviceCharge: m(sales, 'service_charge_total'),
        tax: m(sales, 'tax_total'),
        rounding: m(sales, 'rounding_total'),
        grand: m(sales, 'grand_total'),
        averageBasket: m(sales, 'average_basket'),
      ),
      voids: (
        orders: (voids['orders'] as num? ?? 0).toInt(),
        total: m(voids, 'grand_total'),
      ),
      cancelledOrders: (json['cancelled_orders'] as num? ?? 0).toInt(),
      payments: [
        for (final raw in json['payments'] as List? ?? const [])
          () {
            final p = obj(raw);
            return PaymentTotal(
              methodId: p['payment_method_id'] as String,
              name: p['name'] as String,
              methodType: p['method_type'] as String,
              count: (p['count'] as num).toInt(),
              amount: m(p, 'amount'),
            );
          }(),
      ],
      refunds: (
        count: (refunds['count'] as num? ?? 0).toInt(),
        amount: m(refunds, 'amount'),
        cash: m(refunds, 'cash_amount'),
      ),
      kasbon: (
        issued: m(kasbon, 'issued'),
        repaid: m(kasbon, 'repaid'),
        repaidCash: m(kasbon, 'repaid_cash'),
      ),
      cash: ShiftCash(
        openingCash: m(cash, 'opening_cash'),
        cashSales: m(cash, 'cash_sales'),
        voidedCash: m(cash, 'voided_cash'),
        cashRefunds: m(cash, 'cash_refunds'),
        kasbonCash: m(cash, 'kasbon_cash'),
        cashIn: m(cash, 'cash_in'),
        cashOut: m(cash, 'cash_out'),
        countedCash: counted == null ? null : Money(counted.toInt()),
      ),
      topItems: [
        for (final raw in json['top_items'] as List? ?? const [])
          () {
            final t = obj(raw);
            return TopItem(
              variantId: t['variant_id'] as String,
              name: t['name'] as String,
              quantity: Qty(((t['quantity'] as num) * 1000).round()),
              net: m(t, 'net_amount'),
            );
          }(),
      ],
    );
  }

  /// Builds the report from the terminal's rows, the way `shift_summary`
  /// does on the server. [orders] may include other shifts' orders; only
  /// those that belong to [shift] count. Kasbon repayments arrive in
  /// Phase 6, so [kasbonCash] and [kasbonRepaid] default to zero.
  factory build({
    required ShiftInfo shift,
    required List<ShiftOrder> orders,
    required List<ShiftRefund> refunds,
    required List<ShiftCashMovement> movements,
    required Map<String, PaymentMethodInfo> methods,
    Money kasbonRepaid = Money.zero,
    Money kasbonCash = Money.zero,
    int topItemCount = 10,
  }) {
    final id = shift.id;
    final completed = [
      for (final o in orders)
        if (o.shiftId == id && o.status == 'completed') o,
    ];
    final voided = [
      for (final o in orders)
        if (o.voidedShiftId == id && o.status == 'voided') o,
    ];
    Money sum(Iterable<Money> xs) => xs.fold(Money.zero, (a, b) => a + b);
    final grand = sum(completed.map((o) => o.grand));

    final byMethod = <String, ({String type, int count, Money amount})>{};
    for (final p in completed.expand((o) => o.payments)) {
      final prev = byMethod[p.methodId];
      byMethod[p.methodId] = (
        type: p.methodType,
        count: (prev?.count ?? 0) + 1,
        amount: (prev?.amount ?? Money.zero) + p.amount,
      );
    }
    final methodIds = byMethod.keys.toList()
      ..sort((a, b) {
        final byOrder = (methods[a]?.sortOrder ?? 1 << 30).compareTo(
          methods[b]?.sortOrder ?? 1 << 30,
        );
        return byOrder != 0 ? byOrder : a.compareTo(b);
      });

    final shiftRefunds = [
      for (final r in refunds)
        if (r.shiftId == id) r,
    ];
    final shiftMoves = [
      for (final c in movements)
        if (c.shiftId == id) c,
    ];
    Money cashOf(Iterable<ShiftOrder> os) => sum(
      os
          .expand((o) => o.payments)
          .where((p) => p.methodType == 'cash')
          .map((p) => p.amount),
    );

    final items = <String, ({String name, int milli, Money net})>{};
    for (final i in completed.expand((o) => o.items)) {
      final prev = items[i.variantId];
      final name = prev == null || i.name.compareTo(prev.name) < 0
          ? i.name
          : prev.name;
      items[i.variantId] = (
        name: name,
        milli: (prev?.milli ?? 0) + i.quantity.milli,
        net: (prev?.net ?? Money.zero) + i.net,
      );
    }
    final top =
        [
          for (final MapEntry(key: variant, value: v) in items.entries)
            TopItem(
              variantId: variant,
              name: v.name,
              quantity: Qty(v.milli),
              net: v.net,
            ),
        ]..sort((a, b) {
          final byQty = b.quantity.milli.compareTo(a.quantity.milli);
          return byQty != 0 ? byQty : a.name.compareTo(b.name);
        });

    return ShiftReport(
      kind: shift.closedAt == null ? ShiftReportKind.x : ShiftReportKind.z,
      shiftId: id,
      openedAt: shift.openedAt,
      closedAt: shift.closedAt,
      deviceCode: shift.deviceCode,
      openedByName: shift.openedByName,
      closedByName: shift.closedByName,
      businessDate: shift.businessDate,
      sales: SalesTotals(
        orders: completed.length,
        gross: sum(completed.map((o) => o.gross)),
        discount: sum(completed.map((o) => o.discount)),
        net: sum(completed.map((o) => o.net)),
        serviceCharge: sum(completed.map((o) => o.serviceCharge)),
        tax: sum(completed.map((o) => o.tax)),
        rounding: sum(completed.map((o) => o.rounding)),
        grand: grand,
        averageBasket: completed.isEmpty
            ? Money.zero
            : Money(divRoundHalfUp(grand.rupiah, completed.length)),
      ),
      voids: (orders: voided.length, total: sum(voided.map((o) => o.grand))),
      cancelledOrders: orders
          .where((o) => o.shiftId == id && o.status == 'cancelled')
          .length,
      payments: [
        for (final methodId in methodIds)
          PaymentTotal(
            methodId: methodId,
            name: methods[methodId]?.name ?? byMethod[methodId]!.type,
            methodType: byMethod[methodId]!.type,
            count: byMethod[methodId]!.count,
            amount: byMethod[methodId]!.amount,
          ),
      ],
      refunds: (
        count: shiftRefunds.length,
        amount: sum(shiftRefunds.map((r) => r.amount)),
        cash: sum(
          shiftRefunds
              .where((r) => r.methodType == 'cash')
              .map((r) => r.amount),
        ),
      ),
      kasbon: (
        issued: sum(
          completed
              .expand((o) => o.payments)
              .where((p) => p.methodType == 'kasbon')
              .map((p) => p.amount),
        ),
        repaid: kasbonRepaid,
        repaidCash: kasbonCash,
      ),
      cash: ShiftCash(
        openingCash: shift.openingCash,
        // Every cash payment booked in this shift, including orders voided
        // later: the void takes it off again below.
        cashSales: cashOf(
          orders.where(
            (o) =>
                o.shiftId == id &&
                (o.status == 'completed' || o.status == 'voided'),
          ),
        ),
        voidedCash: cashOf(voided),
        cashRefunds: sum(
          shiftRefunds
              .where((r) => r.methodType == 'cash')
              .map((r) => r.amount),
        ),
        kasbonCash: kasbonCash,
        cashIn: sum(shiftMoves.where((c) => c.isIn).map((c) => c.amount)),
        cashOut: sum(shiftMoves.where((c) => !c.isIn).map((c) => c.amount)),
        countedCash: shift.countedCash,
      ),
      topItems: top.take(topItemCount).toList(),
    );
  }

  final ShiftReportKind kind;
  final String shiftId;
  final String openedAt;
  final String? closedAt;
  final String? deviceCode;
  final String? openedByName;
  final String? closedByName;
  final String? businessDate;

  /// Set when read from the server.
  final String? storeId;
  final String? storeName;
  final SalesTotals sales;
  final VoidTotals voids;
  final int cancelledOrders;
  final List<PaymentTotal> payments;
  final RefundTotals refunds;
  final KasbonTotals kasbon;
  final ShiftCash cash;
  final List<TopItem> topItems;
}

/// Counting the drawer by denomination.
@immutable
class CashCount {
  /// [pieces] maps a denomination to how many there are.
  new(Map<int, int> pieces) : pieces = Map.unmodifiable(pieces) {
    for (final MapEntry(key: value, value: count) in pieces.entries) {
      if (!denominations.contains(value)) {
        throw ArgumentError.value(value, 'denomination');
      }
      if (count < 0) throw ArgumentError.value(count, 'count');
    }
  }

  /// Rupiah notes and coins in circulation, largest first.
  static const denominations = [
    100000,
    50000,
    20000,
    10000,
    5000,
    2000,
    1000,
    500,
    200,
    100,
  ];

  final Map<int, int> pieces;

  Money get total =>
      Money(pieces.entries.fold(0, (a, e) => a + e.key * e.value));
}
