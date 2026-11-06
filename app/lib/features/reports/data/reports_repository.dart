import 'package:cashiera_core/cashiera_core.dart';
import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Money _m(Object? v) => Money((v as num? ?? 0).toInt());
int _i(Object? v) => (v as num? ?? 0).toInt();
Qty _q(Object? v) => Qty(((v as num? ?? 0) * 1000).round());
DateTime _d(Object? v) => DateTime.parse('${v}T00:00:00Z');
Map<String, dynamic> _o(Object? v) =>
    (v as Map? ?? const {}).cast<String, dynamic>();
List<Map<String, dynamic>> _l(Object? v) => [
  for (final e in v as List? ?? const []) _o(e),
];

String _date(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Period presets of the report filter.
enum PeriodPreset { today, yesterday, last7, thisMonth, lastMonth, custom }

/// An inclusive range of business dates (UTC midnights).
@immutable
class ReportPeriod {
  const new(this.from, this.to);

  /// [today] is the store-local date; presets are computed from it.
  factory preset(PeriodPreset p, {DateTime? today}) {
    final now = today ?? clock.now();
    final t = DateTime.utc(now.year, now.month, now.day);
    return switch (p) {
      PeriodPreset.today || PeriodPreset.custom => ReportPeriod(t, t),
      PeriodPreset.yesterday => ReportPeriod(
        t.subtract(const Duration(days: 1)),
        t.subtract(const Duration(days: 1)),
      ),
      PeriodPreset.last7 => ReportPeriod(
        t.subtract(const Duration(days: 6)),
        t,
      ),
      PeriodPreset.thisMonth => ReportPeriod(DateTime.utc(t.year, t.month), t),
      PeriodPreset.lastMonth => ReportPeriod(
        DateTime.utc(t.year, t.month - 1),
        DateTime.utc(t.year, t.month).subtract(const Duration(days: 1)),
      ),
    };
  }

  final DateTime from;
  final DateTime to;

  int get days => to.difference(from).inDays + 1;

  @override
  bool operator ==(Object other) =>
      other is ReportPeriod && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

@immutable
class SalesTotals {
  new fromJson(Map<String, dynamic> j)
    : orders = _i(j['orders']),
      items = _q(j['items']),
      gross = _m(j['gross']),
      discounts = _m(j['discounts']),
      net = _m(j['net']),
      service = _m(j['service']),
      tax = _m(j['tax']),
      rounding = _m(j['rounding']),
      grand = _m(j['grand']),
      average = _m(j['average']),
      refundCount = _i(j['refund_count']),
      refunds = _m(j['refunds']),
      netSales = _m(j['net_sales']),
      voidCount = _i(j['void_count']),
      voids = _m(j['voids']);

  final int orders;
  final Qty items;
  final Money gross;
  final Money discounts;
  final Money net;
  final Money service;
  final Money tax;
  final Money rounding;
  final Money grand;
  final Money average;
  final int refundCount;
  final Money refunds;
  final Money netSales;
  final int voidCount;
  final Money voids;
}

@immutable
class DayRow {
  const new({
    required this.date,
    required this.orders,
    required this.grand,
    required this.refunds,
  });

  factory fromJson(Map<String, dynamic> j) => DayRow(
    date: _d(j['date']),
    orders: _i(j['orders']),
    grand: _m(j['grand']),
    refunds: _m(j['refunds']),
  );

  final DateTime date;
  final int orders;
  final Money grand;
  final Money refunds;
}

@immutable
class SalesReport {
  const new({
    required this.totals,
    required this.byDay,
    required this.byHour,
    required this.byStore,
  });

  factory fromJson(Map<String, dynamic> j) => SalesReport(
    totals: SalesTotals.fromJson(_o(j['totals'])),
    byDay: [for (final d in _l(j['by_day'])) DayRow.fromJson(d)],
    byHour: [
      for (final h in _l(j['by_hour']))
        (hour: _i(h['hour']), orders: _i(h['orders']), grand: _m(h['grand'])),
    ],
    byStore: [
      for (final s in _l(j['by_store']))
        (
          code: s['store_code'] as String,
          name: s['store_name'] as String,
          orders: _i(s['orders']),
          grand: _m(s['grand']),
          refunds: _m(s['refunds']),
        ),
    ],
  );

  final SalesTotals totals;
  final List<DayRow> byDay;
  final List<({int hour, int orders, Money grand})> byHour;
  final List<
    ({String code, String name, int orders, Money grand, Money refunds})
  >
  byStore;
}

typedef MethodRow = ({String name, String type, int count, Money amount});

@immutable
class PaymentsReport {
  const new({
    required this.methods,
    required this.refunds,
    required this.kasbonIssued,
    required this.kasbonRepaid,
  });

  factory fromJson(Map<String, dynamic> j) => PaymentsReport(
    methods: [
      for (final m in _l(j['methods']))
        (
          name: m['name'] as String,
          type: m['method_type'] as String,
          count: _i(m['count']),
          amount: _m(m['amount']),
        ),
    ],
    refunds: [
      for (final r in _l(j['refunds']))
        (
          type: r['method_type'] as String,
          count: _i(r['count']),
          amount: _m(r['amount']),
        ),
    ],
    kasbonIssued: _m(_o(j['kasbon'])['issued']),
    kasbonRepaid: _m(_o(j['kasbon'])['repaid']),
  );

  final List<MethodRow> methods;
  final List<({String type, int count, Money amount})> refunds;
  final Money kasbonIssued;
  final Money kasbonRepaid;

  Money get total => methods.fold(Money.zero, (a, m) => a + m.amount);
}

@immutable
class ProductRow {
  const new({
    required this.name,
    required this.quantity,
    required this.refundedQuantity,
    required this.net,
    required this.refunded,
    required this.cost,
    required this.margin,
    this.sku,
    this.category,
  });

  factory fromJson(Map<String, dynamic> j) => ProductRow(
    name: j['name'] as String,
    sku: j['sku'] as String?,
    category: j['category'] as String?,
    quantity: _q(j['quantity']),
    refundedQuantity: _q(j['refunded_quantity']),
    net: _m(j['net']),
    refunded: _m(j['refunded']),
    cost: _m(j['cost']),
    margin: _m(j['margin']),
  );

  final String name;
  final String? sku;
  final String? category;
  final Qty quantity;
  final Qty refundedQuantity;
  final Money net;
  final Money refunded;
  final Money cost;
  final Money margin;
}

@immutable
class ProductsReport {
  const new({
    required this.variants,
    required this.variantCount,
    required this.categories,
    required this.net,
    required this.cost,
    required this.margin,
    required this.refunded,
  });

  factory fromJson(Map<String, dynamic> j) {
    final t = _o(j['totals']);
    return ProductsReport(
      variants: [for (final v in _l(j['variants'])) ProductRow.fromJson(v)],
      variantCount: _i(j['variant_count']),
      categories: [
        for (final c in _l(j['categories']))
          ProductRow.fromJson({
            ...c,
            'name': c['name'],
            'refunded_quantity': 0,
            'refunded': 0,
          }),
      ],
      net: _m(t['net']),
      cost: _m(t['cost']),
      margin: _m(t['margin']),
      refunded: _m(t['refunded']),
    );
  }

  final List<ProductRow> variants;

  /// All variants sold, even beyond the list's limit.
  final int variantCount;
  final List<ProductRow> categories;
  final Money net;
  final Money cost;
  final Money margin;
  final Money refunded;
}

@immutable
class StaffRow {
  new fromJson(Map<String, dynamic> j)
    : name = j['name'] as String,
      orders = _i(j['orders']),
      grand = _m(j['grand']),
      average = _m(j['average']),
      discounts = _m(j['discounts']),
      voidCount = _i(j['void_count']),
      voids = _m(j['voids']),
      refundCount = _i(j['refund_count']),
      refunds = _m(j['refunds']);

  final String name;
  final int orders;
  final Money grand;
  final Money average;
  final Money discounts;
  final int voidCount;
  final Money voids;
  final int refundCount;
  final Money refunds;
}

typedef TaxRow = ({
  DateTime date,
  Money base,
  Money dpp,
  Money tax,
  Money exempt,
});

@immutable
class TaxReport {
  const new({required this.byDay, required this.totals});

  factory fromJson(Map<String, dynamic> j) {
    TaxRow row(Map<String, dynamic> r, DateTime date) => (
      date: date,
      base: _m(r['base']),
      dpp: _m(r['dpp']),
      tax: _m(r['tax']),
      exempt: _m(r['exempt']),
    );
    return TaxReport(
      byDay: [for (final d in _l(j['by_day'])) row(d, _d(d['date']))],
      totals: row(_o(j['totals']), DateTime.utc(1970)),
    );
  }

  final List<TaxRow> byDay;
  final TaxRow totals;
}

typedef StockValueRow = ({
  String storeCode,
  String name,
  String? sku,
  Qty quantity,
  Money cost,
  Money value,
});

@immutable
class StockValueReport {
  const new({
    required this.items,
    required this.value,
    required this.negativeCount,
    required this.lowCount,
  });

  factory fromJson(Map<String, dynamic> j) {
    final t = _o(j['totals']);
    return StockValueReport(
      items: [
        for (final i in _l(j['items']))
          (
            storeCode: i['store_code'] as String,
            name: i['name'] as String,
            sku: i['sku'] as String?,
            quantity: _q(i['quantity']),
            cost: _m(i['cost']),
            value: _m(i['value']),
          ),
      ],
      value: _m(t['value']),
      negativeCount: _i(t['negative_count']),
      lowCount: _i(t['low_count']),
    );
  }

  final List<StockValueRow> items;
  final Money value;
  final int negativeCount;
  final int lowCount;
}

@immutable
class DashboardData {
  const new({
    required this.today,
    required this.yesterday,
    required this.last7,
    required this.topProducts,
    required this.payments,
    required this.openShifts,
    required this.lowStock,
    required this.openAlerts,
    required this.overdueKasbon,
  });

  factory fromJson(Map<String, dynamic> j) => DashboardData(
    today: SalesTotals.fromJson(_o(j['today'])),
    yesterday: SalesTotals.fromJson(_o(j['yesterday'])),
    last7: [for (final d in _l(j['last7'])) DayRow.fromJson(d)],
    topProducts: [
      for (final p in _l(j['top_products'])) ProductRow.fromJson(p),
    ],
    payments: PaymentsReport.fromJson({'methods': j['payments']}).methods,
    openShifts: _i(j['open_shifts']),
    lowStock: _i(j['low_stock']),
    openAlerts: _i(j['open_alerts']),
    overdueKasbon: _m(j['overdue_kasbon']),
  );

  final SalesTotals today;
  final SalesTotals yesterday;
  final List<DayRow> last7;
  final List<ProductRow> topProducts;
  final List<MethodRow> payments;
  final int openShifts;
  final int lowStock;
  final int openAlerts;
  final Money overdueKasbon;
}

/// The report RPCs of migration 1900.
class ReportsRepository {
  new(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>> _call(
    String fn,
    Map<String, Object?> params,
  ) async {
    final json = await _client.rpc<dynamic>(fn, params: params);
    return (json as Map).cast<String, dynamic>();
  }

  Map<String, Object?> _range(String? storeId, ReportPeriod p) => {
    'p_store_id': storeId,
    'p_from': _date(p.from),
    'p_to': _date(p.to),
  };

  Future<SalesReport> sales(String? storeId, ReportPeriod p) async =>
      SalesReport.fromJson(await _call('report_sales', _range(storeId, p)));

  Future<PaymentsReport> payments(String? storeId, ReportPeriod p) async =>
      PaymentsReport.fromJson(
        await _call('report_payments', _range(storeId, p)),
      );

  Future<ProductsReport> products(String? storeId, ReportPeriod p) async =>
      ProductsReport.fromJson(
        await _call('report_products', {..._range(storeId, p), 'p_limit': 500}),
      );

  Future<List<StaffRow>> staff(String? storeId, ReportPeriod p) async {
    final rows = await _client.rpc<List<dynamic>>(
      'report_staff',
      params: _range(storeId, p),
    );
    return [for (final r in rows) StaffRow.fromJson(_o(r))];
  }

  Future<TaxReport> tax(String? storeId, ReportPeriod p) async =>
      TaxReport.fromJson(await _call('report_tax', _range(storeId, p)));

  Future<StockValueReport> stockValue(String? storeId) async =>
      StockValueReport.fromJson(
        await _call('report_stock_value', {'p_store_id': storeId}),
      );

  Future<DashboardData> dashboard(String? storeId, DateTime today) async =>
      DashboardData.fromJson(
        await _call('dashboard_summary', {
          'p_store_id': storeId,
          'p_today': _date(today),
        }),
      );
}
