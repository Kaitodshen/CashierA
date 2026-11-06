import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/features/back_office/presentation/admin_shifts_screen.dart';
import 'package:cashiera/features/back_office/presentation/back_office_providers.dart';
import 'package:cashiera/features/reports/data/reports_repository.dart';
import 'package:cashiera/features/reports/presentation/report_providers.dart';
import 'package:cashiera/features/reports/presentation/report_tables.dart';
import 'package:cashiera/features/reports/presentation/report_widgets.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

String periodLabel(AppLocalizations l10n, PeriodPreset p) => switch (p) {
  PeriodPreset.today => l10n.periodToday,
  PeriodPreset.yesterday => l10n.periodYesterday,
  PeriodPreset.last7 => l10n.periodLast7,
  PeriodPreset.thisMonth => l10n.periodThisMonth,
  PeriodPreset.lastMonth => l10n.periodLastMonth,
  PeriodPreset.custom => l10n.periodCustom,
};

/// Every report for one store or all of them, over a period.
class ReportsScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String? _storeId;
  PeriodPreset _preset = PeriodPreset.last7;
  ReportPeriod _period = ReportPeriod.preset(PeriodPreset.last7);

  Future<void> _pick(PeriodPreset p) async {
    if (p != PeriodPreset.custom) {
      setState(() {
        _preset = p;
        _period = ReportPeriod.preset(p);
      });
      return;
    }
    final now = clock.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: DateTimeRange(
        start: DateTime(
          _period.from.year,
          _period.from.month,
          _period.from.day,
        ),
        end: DateTime(_period.to.year, _period.to.month, _period.to.day),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _preset = PeriodPreset.custom;
      _period = ReportPeriod(
        DateTime.utc(picked.start.year, picked.start.month, picked.start.day),
        DateTime.utc(picked.end.year, picked.end.month, picked.end.day),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stores = ref.watch(backOfficeStoresProvider).value ?? const [];
    final storeName = _storeId == null
        ? l10n.adminAllStores
        : stores.where((s) => s.id == _storeId).firstOrNull?.name ?? '';
    final subtitle = reportSubtitle(l10n, storeName, _period);
    final tabs = [
      (l10n.reportTabSales, _SalesTab(_storeId, _period, subtitle)),
      (l10n.reportTabPayments, _PaymentsTab(_storeId, _period, subtitle)),
      (l10n.reportTabProducts, _ProductsTab(_storeId, _period, subtitle)),
      (l10n.reportTabStaff, _StaffTab(_storeId, _period, subtitle)),
      (l10n.reportTabTax, _TaxTab(_storeId, _period, subtitle)),
      (
        l10n.reportTabStock,
        _StockTab(
          _storeId,
          l10n.reportStockSubtitle(
            storeName,
            DateFormat('dd/MM/yyyy HH:mm').format(clock.now()),
          ),
        ),
      ),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              0,
            ),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StoreFilter(
                  value: _storeId,
                  onChanged: (v) => setState(() => _storeId = v),
                ),
                for (final p in PeriodPreset.values)
                  ChoiceChip(
                    key: Key('period-${p.name}'),
                    label: Text(
                      p == PeriodPreset.custom && _preset == PeriodPreset.custom
                          ? reportSubtitle(l10n, '', _period).substring(3)
                          : periodLabel(l10n, p),
                    ),
                    selected: p == _preset,
                    onSelected: (_) => _pick(p),
                  ),
              ],
            ),
          ),
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [for (final (label, _) in tabs) Tab(text: label)],
          ),
          Expanded(
            child: TabBarView(children: [for (final (_, tab) in tabs) tab]),
          ),
        ],
      ),
    );
  }
}

Widget _async<T>(
  BuildContext context,
  AsyncValue<T> value,
  Widget Function(T data) build,
) => switch (value) {
  AsyncData(:final value) => build(value),
  AsyncError(:final error) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Text(context.l10n.commonError('$error')),
    ),
  ),
  _ => const Center(child: CircularProgressIndicator()),
};

Widget _page(List<Widget> children) =>
    ListView(padding: const EdgeInsets.all(AppSpacing.lg), children: children);

class _SalesTab extends ConsumerWidget {
  const new(this.storeId, this.period, this.subtitle);
  final String? storeId;
  final ReportPeriod period;
  final String subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return _async(
      context,
      ref.watch(salesReportProvider(period: period, storeId: storeId)),
      (r) {
        final t = r.totals;
        return _page([
          Wrap(
            children: [
              SummaryTile(
                label: l10n.colNetSales,
                value: t.netSales.format(),
                icon: Icons.payments_outlined,
              ),
              SummaryTile(label: l10n.colOrders, value: '${t.orders}'),
              SummaryTile(label: l10n.colAverage, value: t.average.format()),
              SummaryTile(label: l10n.sumItems, value: t.items.toPlain()),
              SummaryTile(
                label: l10n.colRefunds,
                value: t.refunds.format(),
                detail: '${t.refundCount}×',
              ),
              SummaryTile(
                label: l10n.colVoids,
                value: t.voids.format(),
                detail: '${t.voidCount}×',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ReportSection(
            table: salesByDayTable(l10n, r, subtitle),
            chart: MoneyBarChart(
              key: const Key('sales-by-day-chart'),
              bars: [for (final d in r.byDay) (shortDay(d.date), d.grand)],
            ),
          ),
          ReportSection(
            table: salesSummaryTable(l10n, r, subtitle),
            footnote: l10n.reportSalesNote,
          ),
          if (r.byStore.length > 1)
            ReportSection(table: salesByStoreTable(l10n, r, subtitle)),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.reportByHour,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  MoneyBarChart(
                    height: 160,
                    bars: [
                      for (final h in r.byHour)
                        (h.hour.toString().padLeft(2, '0'), h.grand),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ]);
      },
    );
  }
}

class _PaymentsTab extends ConsumerWidget {
  const new(this.storeId, this.period, this.subtitle);
  final String? storeId;
  final ReportPeriod period;
  final String subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return _async(
      context,
      ref.watch(paymentsReportProvider(period: period, storeId: storeId)),
      (r) => _page([
        Wrap(
          children: [
            SummaryTile(label: l10n.totalRow, value: r.total.format()),
            SummaryTile(
              label: l10n.sumKasbonIssued,
              value: r.kasbonIssued.format(),
            ),
            SummaryTile(
              label: l10n.sumKasbonRepaid,
              value: r.kasbonRepaid.format(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ReportSection(
          table: paymentsTable(l10n, r, subtitle),
          chart: MoneyBarChart(
            height: 160,
            bars: [for (final m in r.methods) (m.name, m.amount)],
          ),
        ),
        ReportSection(table: refundsByMethodTable(l10n, r, subtitle)),
      ]),
    );
  }
}

class _ProductsTab extends ConsumerWidget {
  const new(this.storeId, this.period, this.subtitle);
  final String? storeId;
  final ReportPeriod period;
  final String subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return _async(
      context,
      ref.watch(productsReportProvider(period: period, storeId: storeId)),
      (r) => _page([
        Wrap(
          children: [
            SummaryTile(label: l10n.colNet, value: r.net.format()),
            SummaryTile(label: l10n.colCost, value: r.cost.format()),
            SummaryTile(
              label: l10n.sumMargin,
              value: r.margin.format(),
              detail: r.net.rupiah == 0
                  ? null
                  : percentText(r.margin.rupiah, r.net.rupiah),
            ),
            SummaryTile(label: l10n.colRefunds, value: r.refunded.format()),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ReportSection(
          table: categoriesTable(l10n, r, subtitle),
          chart: MoneyBarChart(
            height: 160,
            bars: [for (final c in r.categories) (c.name, c.net)],
          ),
        ),
        ReportSection(
          table: productsTable(l10n, r, subtitle),
          footnote: r.variantCount > r.variants.length
              ? l10n.reportProductsMore(r.variants.length, r.variantCount)
              : l10n.reportProductsNote,
        ),
      ]),
    );
  }
}

class _StaffTab extends ConsumerWidget {
  const new(this.storeId, this.period, this.subtitle);
  final String? storeId;
  final ReportPeriod period;
  final String subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return _async(
      context,
      ref.watch(staffReportProvider(period: period, storeId: storeId)),
      (rows) => _page([
        ReportSection(
          table: staffTable(l10n, rows, subtitle),
          chart: rows.isEmpty
              ? null
              : MoneyBarChart(
                  height: 160,
                  bars: [
                    for (final s in rows) (s.name.split(' ').first, s.grand),
                  ],
                ),
        ),
      ]),
    );
  }
}

class _TaxTab extends ConsumerWidget {
  const new(this.storeId, this.period, this.subtitle);
  final String? storeId;
  final ReportPeriod period;
  final String subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return _async(
      context,
      ref.watch(taxReportProvider(period: period, storeId: storeId)),
      (r) => _page([
        Wrap(
          children: [
            SummaryTile(label: l10n.colTax, value: r.totals.tax.format()),
            SummaryTile(label: l10n.colDpp, value: r.totals.dpp.format()),
            SummaryTile(label: l10n.colExempt, value: r.totals.exempt.format()),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ReportSection(
          table: taxTable(l10n, r, subtitle),
          footnote: l10n.reportTaxNote,
        ),
      ]),
    );
  }
}

class _StockTab extends ConsumerWidget {
  const new(this.storeId, this.subtitle);
  final String? storeId;
  final String subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return _async(
      context,
      ref.watch(stockValueReportProvider(storeId: storeId)),
      (r) => _page([
        Wrap(
          children: [
            SummaryTile(label: l10n.sumStockValue, value: r.value.format()),
            SummaryTile(
              label: l10n.sumLow,
              value: '${r.lowCount}',
              detailColor: AppColors.warning,
            ),
            SummaryTile(
              label: l10n.sumNegative,
              value: '${r.negativeCount}',
              detail: r.negativeCount > 0 ? l10n.reportNegativeNote : null,
              detailColor: AppColors.error,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ReportSection(
          table: stockValueTable(l10n, r, subtitle),
          footnote: l10n.reportStockNote,
        ),
      ]),
    );
  }
}

/// Days as chart bars (kept public for the dashboard).
List<(String, Money)> dayBars(List<DayRow> days) => [
  for (final d in days) (shortDay(d.date), d.grand),
];
