import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/features/reports/data/report_export.dart';
import 'package:cashiera/features/reports/data/reports_repository.dart';
import 'package:cashiera/features/sell/presentation/refund_screen.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:intl/intl.dart';

final _day = DateFormat('dd/MM/yyyy');
final _short = DateFormat('dd/MM');

/// `Semua toko · 01/10/2026 – 04/10/2026`.
String reportSubtitle(
  AppLocalizations l10n,
  String storeLabel,
  ReportPeriod p,
) => p.from == p.to
    ? '$storeLabel · ${_day.format(p.from)}'
    : '$storeLabel · ${_day.format(p.from)} - ${_day.format(p.to)}';

String shortDay(DateTime d) => _short.format(d);

Money _sum(Iterable<Money> xs) => xs.fold(Money.zero, (a, b) => a + b);

ReportTable salesByDayTable(
  AppLocalizations l10n,
  SalesReport r,
  String subtitle,
) => ReportTable(
  title: l10n.reportTabSales,
  subtitle: subtitle,
  columns: [
    l10n.colDate,
    l10n.colOrders,
    l10n.colSales,
    l10n.colRefunds,
    l10n.colNetSales,
  ],
  rows: [
    for (final d in r.byDay)
      [
        TextCell(_day.format(d.date)),
        CountCell(d.orders),
        MoneyCell(d.grand),
        MoneyCell(d.refunds),
        MoneyCell(d.grand - d.refunds),
      ],
  ],
  totals: [
    TextCell(l10n.totalRow),
    CountCell(r.totals.orders),
    MoneyCell(r.totals.grand),
    MoneyCell(r.totals.refunds),
    MoneyCell(r.totals.netSales),
  ],
);

ReportTable salesByStoreTable(
  AppLocalizations l10n,
  SalesReport r,
  String subtitle,
) => ReportTable(
  title: '${l10n.reportTabSales} · ${l10n.colStore}',
  subtitle: subtitle,
  columns: [
    l10n.colStore,
    l10n.colOrders,
    l10n.colSales,
    l10n.colRefunds,
    l10n.colNetSales,
  ],
  rows: [
    for (final s in r.byStore)
      [
        TextCell('${s.code} · ${s.name}'),
        CountCell(s.orders),
        MoneyCell(s.grand),
        MoneyCell(s.refunds),
        MoneyCell(s.grand - s.refunds),
      ],
  ],
  totals: [
    TextCell(l10n.totalRow),
    CountCell(r.totals.orders),
    MoneyCell(r.totals.grand),
    MoneyCell(r.totals.refunds),
    MoneyCell(r.totals.netSales),
  ],
);

/// The money breakdown of the period, as label/value rows.
ReportTable salesSummaryTable(
  AppLocalizations l10n,
  SalesReport r,
  String subtitle,
) {
  final t = r.totals;
  return ReportTable(
    title: '${l10n.reportTabSales} · ${l10n.reportSummary}',
    subtitle: subtitle,
    columns: [l10n.reportItem, l10n.colAmount],
    rows: [
      for (final (label, value) in [
        (l10n.summaryGross, t.gross),
        (l10n.summaryDiscounts, Money(-t.discounts.rupiah)),
        (l10n.summaryNet, t.net),
        (l10n.summaryService, t.service),
        (l10n.summaryTax, t.tax),
        (l10n.summaryRounding, t.rounding),
        (l10n.colSales, t.grand),
        (l10n.colRefunds, Money(-t.refunds.rupiah)),
        (l10n.colNetSales, t.netSales),
        (l10n.colVoids, t.voids),
      ])
        [TextCell(label), MoneyCell(value)],
    ],
  );
}

ReportTable paymentsTable(
  AppLocalizations l10n,
  PaymentsReport r,
  String subtitle,
) => ReportTable(
  title: l10n.reportTabPayments,
  subtitle: subtitle,
  columns: [l10n.colMethod, l10n.colCount, l10n.colAmount, l10n.colShare],
  rows: [
    for (final m in r.methods)
      [
        TextCell(m.name),
        CountCell(m.count),
        MoneyCell(m.amount),
        TextCell(_share(m.amount, r.total)),
      ],
  ],
  totals: [
    TextCell(l10n.totalRow),
    CountCell(r.methods.fold(0, (a, m) => a + m.count)),
    MoneyCell(r.total),
    const TextCell('100%'),
  ],
);

ReportTable refundsByMethodTable(
  AppLocalizations l10n,
  PaymentsReport r,
  String subtitle,
) => ReportTable(
  title: '${l10n.reportTabPayments} · ${l10n.colRefunds}',
  subtitle: subtitle,
  columns: [l10n.colMethod, l10n.colCount, l10n.colAmount],
  rows: [
    for (final x in r.refunds)
      [
        TextCell(refundMethodLabel(l10n, x.type)),
        CountCell(x.count),
        MoneyCell(x.amount),
      ],
  ],
  totals: [
    TextCell(l10n.totalRow),
    CountCell(r.refunds.fold(0, (a, x) => a + x.count)),
    MoneyCell(_sum(r.refunds.map((x) => x.amount))),
  ],
);

/// `12,3%` (one decimal, Indonesian comma); `0%` when [whole] is 0.
String percentText(int part, int whole) {
  if (whole == 0) return '0%';
  final tenths = (part * 1000 / whole).round();
  final text = (tenths / 10).toStringAsFixed(1).replaceAll('.', ',');
  return '$text%';
}

String _share(Money part, Money whole) =>
    percentText(part.rupiah, whole.rupiah);

ReportTable productsTable(
  AppLocalizations l10n,
  ProductsReport r,
  String subtitle,
) => ReportTable(
  title: l10n.reportTabProducts,
  subtitle: subtitle,
  columns: [
    l10n.colProduct,
    l10n.colSku,
    l10n.colCategory,
    l10n.colQty,
    l10n.colRefundedQty,
    l10n.colNet,
    l10n.colCost,
    l10n.colMargin,
  ],
  rows: [
    for (final p in r.variants)
      [
        TextCell(p.name),
        TextCell(p.sku ?? ''),
        TextCell(p.category ?? ''),
        QtyCell(p.quantity),
        QtyCell(p.refundedQuantity),
        MoneyCell(p.net),
        MoneyCell(p.cost),
        MoneyCell(p.margin),
      ],
  ],
  totals: [
    TextCell(l10n.totalRow),
    const TextCell(''),
    const TextCell(''),
    QtyCell(Qty(r.variants.fold(0, (a, p) => a + p.quantity.milli))),
    QtyCell(Qty(r.variants.fold(0, (a, p) => a + p.refundedQuantity.milli))),
    MoneyCell(r.net),
    MoneyCell(r.cost),
    MoneyCell(r.margin),
  ],
);

ReportTable categoriesTable(
  AppLocalizations l10n,
  ProductsReport r,
  String subtitle,
) => ReportTable(
  title: '${l10n.reportTabProducts} · ${l10n.colCategory}',
  subtitle: subtitle,
  columns: [
    l10n.colCategory,
    l10n.colQty,
    l10n.colNet,
    l10n.colCost,
    l10n.colMargin,
  ],
  rows: [
    for (final c in r.categories)
      [
        TextCell(c.name),
        QtyCell(c.quantity),
        MoneyCell(c.net),
        MoneyCell(c.cost),
        MoneyCell(c.margin),
      ],
  ],
  totals: [
    TextCell(l10n.totalRow),
    QtyCell(Qty(r.categories.fold(0, (a, c) => a + c.quantity.milli))),
    MoneyCell(r.net),
    MoneyCell(r.cost),
    MoneyCell(r.margin),
  ],
);

ReportTable staffTable(
  AppLocalizations l10n,
  List<StaffRow> rows,
  String subtitle,
) => ReportTable(
  title: l10n.reportTabStaff,
  subtitle: subtitle,
  columns: [
    l10n.colStaff,
    l10n.colOrders,
    l10n.colSales,
    l10n.colAverage,
    l10n.colDiscounts,
    l10n.colVoids,
    l10n.colRefunds,
  ],
  rows: [
    for (final s in rows)
      [
        TextCell(s.name),
        CountCell(s.orders),
        MoneyCell(s.grand),
        MoneyCell(s.average),
        MoneyCell(s.discounts),
        MoneyCell(s.voids),
        MoneyCell(s.refunds),
      ],
  ],
  totals: [
    TextCell(l10n.totalRow),
    CountCell(rows.fold(0, (a, s) => a + s.orders)),
    MoneyCell(_sum(rows.map((s) => s.grand))),
    const TextCell(''),
    MoneyCell(_sum(rows.map((s) => s.discounts))),
    MoneyCell(_sum(rows.map((s) => s.voids))),
    MoneyCell(_sum(rows.map((s) => s.refunds))),
  ],
);

ReportTable taxTable(AppLocalizations l10n, TaxReport r, String subtitle) =>
    ReportTable(
      title: l10n.reportTabTax,
      subtitle: subtitle,
      columns: [
        l10n.colDate,
        l10n.colBase,
        l10n.colDpp,
        l10n.colTax,
        l10n.colExempt,
      ],
      rows: [
        for (final d in r.byDay)
          [
            TextCell(_day.format(d.date)),
            MoneyCell(d.base),
            MoneyCell(d.dpp),
            MoneyCell(d.tax),
            MoneyCell(d.exempt),
          ],
      ],
      totals: [
        TextCell(l10n.totalRow),
        MoneyCell(r.totals.base),
        MoneyCell(r.totals.dpp),
        MoneyCell(r.totals.tax),
        MoneyCell(r.totals.exempt),
      ],
    );

ReportTable stockValueTable(
  AppLocalizations l10n,
  StockValueReport r,
  String subtitle,
) => ReportTable(
  title: l10n.reportTabStock,
  subtitle: subtitle,
  columns: [
    l10n.colStore,
    l10n.colProduct,
    l10n.colSku,
    l10n.colStock,
    l10n.colCost,
    l10n.colValue,
  ],
  rows: [
    for (final i in r.items)
      [
        TextCell(i.storeCode),
        TextCell(i.name),
        TextCell(i.sku ?? ''),
        QtyCell(i.quantity),
        MoneyCell(i.cost),
        MoneyCell(i.value),
      ],
  ],
  totals: [
    TextCell(l10n.totalRow),
    const TextCell(''),
    const TextCell(''),
    const TextCell(''),
    const TextCell(''),
    MoneyCell(r.value),
  ],
);
