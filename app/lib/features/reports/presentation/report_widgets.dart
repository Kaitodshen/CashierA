import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/toasts.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/features/back_office/data/catalog_files.dart';
import 'package:cashiera/features/reports/data/report_export.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:clock/clock.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A report table as on paper: header, rows, totals in bold.
class ReportTableView extends StatelessWidget {
  const new({required this.table, super.key});

  final ReportTable table;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    if (table.rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(l10n.reportEmpty),
      );
    }
    bool numeric(int i) => cellIsNumber(table.rows.first[i]);
    DataCell cell(ReportCell c, {bool strong = false}) => DataCell(
      Text(
        cellText(c),
        style: strong ? const TextStyle(fontWeight: FontWeight.w700) : null,
      ),
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        columnSpacing: AppSpacing.xl,
        columns: [
          for (final (i, c) in table.columns.indexed)
            DataColumn(label: Text(c), numeric: numeric(i)),
        ],
        rows: [
          for (final row in table.rows)
            DataRow(cells: [for (final c in row) cell(c)]),
          if (table.totals != null)
            DataRow(
              color: WidgetStatePropertyAll(
                theme.colorScheme.surfaceContainerHighest,
              ),
              cells: [for (final c in table.totals!) cell(c, strong: true)],
            ),
        ],
      ),
    );
  }
}

/// A titled card with the table and **PDF** / **Excel** buttons.
class ReportSection extends StatefulWidget {
  const new({required this.table, this.chart, this.footnote, super.key});

  final ReportTable table;
  final Widget? chart;
  final String? footnote;

  @override
  State<ReportSection> createState() => _ReportSectionState();
}

class _ReportSectionState extends State<ReportSection> {
  bool _busy = false;

  Future<void> _export({required bool pdf}) async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      final t = widget.table;
      final saved = pdf
          ? await saveBytes(
              '${t.fileName}.pdf',
              await buildReportPdf(
                t,
                printedAt: l10n.reportPrintedAt(
                  DateFormat('dd/MM/yyyy HH:mm').format(clock.now()),
                ),
              ),
              'application/pdf',
            )
          : await saveBytes('${t.fileName}.xlsx', buildReportXlsx(t), xlsxMime);
      if (saved && mounted) AppToast.success(context, l10n.exportSaved);
    } on Exception catch (e) {
      if (mounted) AppToast.error(context, l10n.commonError('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final key = widget.table.title;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.table.title,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton.icon(
                  key: Key('export-pdf-$key'),
                  onPressed: _busy ? null : () => _export(pdf: true),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(l10n.exportPdf),
                ),
                TextButton.icon(
                  key: Key('export-xlsx-$key'),
                  onPressed: _busy ? null : () => _export(pdf: false),
                  icon: const Icon(Icons.table_view_outlined),
                  label: Text(l10n.exportExcel),
                ),
              ],
            ),
            if (widget.chart != null) ...[
              const SizedBox(height: AppSpacing.md),
              widget.chart!,
            ],
            const SizedBox(height: AppSpacing.sm),
            ReportTableView(table: widget.table),
            if (widget.footnote != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  widget.footnote!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Bars of rupiah amounts with short labels underneath.
class MoneyBarChart extends StatelessWidget {
  const new({required this.bars, this.height = 200, super.key});

  /// (label, amount).
  final List<(String, Money)> bars;
  final double height;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final most = bars.fold(0, (a, b) => b.$2.rupiah > a ? b.$2.rupiah : a);
    final every = bars.length > 16 ? (bars.length / 8).ceil() : 1;
    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          maxY: most == 0 ? 1 : most * 1.15,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                '${bars[group.x].$1}\n${Money(rod.toY.round()).format()}',
                const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= bars.length || i % every != 0) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      bars[i].$1,
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (final (i, b) in bars.indexed)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: b.$2.rupiah.toDouble(),
                    color: color,
                    width: bars.length > 20 ? 6 : 14,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// A figure with a caption, and optionally a comparison line.
class SummaryTile extends StatelessWidget {
  const new({
    required this.label,
    required this.value,
    this.detail,
    this.detailColor,
    this.icon,
    super.key,
  });

  final String label;
  final String value;
  final String? detail;
  final Color? detailColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: AppColors.secondary),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Expanded(
                    child: Text(label, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (detail != null)
                Text(
                  detail!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: detailColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
