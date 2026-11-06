import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/pos/shift_report_text.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/material.dart';

ShiftReportLabels shiftReportLabels(AppLocalizations l10n) => ShiftReportLabels(
  titleX: l10n.reportTitleX,
  titleZ: l10n.reportTitleZ,
  terminal: l10n.reportTerminal,
  opened: l10n.reportOpened,
  closed: l10n.reportClosed,
  sales: l10n.reportSales,
  transactions: l10n.reportTransactions,
  gross: l10n.reportGross,
  discounts: l10n.reportDiscounts,
  net: l10n.reportNet,
  service: l10n.reportService,
  tax: l10n.reportTax,
  rounding: l10n.reportRounding,
  total: l10n.reportTotal,
  average: l10n.reportAverage,
  payments: l10n.reportPayments,
  corrections: l10n.reportCorrections,
  voids: l10n.reportVoids,
  cancelled: l10n.reportCancelled,
  refunds: l10n.reportRefunds,
  kasbonIssued: l10n.reportKasbonIssued,
  kasbonRepaid: l10n.reportKasbonRepaid,
  cash: l10n.reportCash,
  openingCash: l10n.reportOpeningCash,
  cashSales: l10n.reportCashSales,
  voidedCash: l10n.reportVoidedCash,
  cashRefunds: l10n.reportCashRefunds,
  kasbonCash: l10n.reportKasbonCash,
  cashIn: l10n.reportCashIn,
  cashOut: l10n.reportCashOut,
  expected: l10n.reportExpected,
  counted: l10n.reportCounted,
  difference: l10n.reportDifference,
  topItems: l10n.reportTopItems,
);

String reportTitle(AppLocalizations l10n, ShiftReport r) =>
    r.kind == ShiftReportKind.x ? l10n.reportTitleX : l10n.reportTitleZ;

/// Green when even, amber when over, red when short.
Color differenceColor(Money? difference) {
  final d = difference?.rupiah ?? 0;
  if (d == 0) return AppColors.success;
  return d > 0 ? AppColors.warning : AppColors.error;
}

/// `Pas`, `Lebih Rp 500`, `Kurang Rp 2.000`.
String differenceText(AppLocalizations l10n, Money difference) {
  final d = difference.rupiah;
  if (d == 0) return l10n.closeEven;
  return d > 0
      ? l10n.closeOver(difference.format())
      : l10n.closeShort(Money(-d).format());
}

/// The report's sections as cards (terminal and back office).
class ShiftReportView extends StatelessWidget {
  const new({required this.report, required this.utcOffsetMinutes, super.key});

  final ShiftReport report;
  final int utcOffsetMinutes;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final sections = shiftReportSections(
      report,
      shiftReportLabels(l10n),
      utcOffsetMinutes: utcOffsetMinutes,
    );
    final difference = report.cash.difference;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final section in sections)
          Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (section.title != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        section.title!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  for (final row in section.rows)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              row.label,
                              style: row.strong
                                  ? const TextStyle(fontWeight: FontWeight.w700)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            row.value,
                            style: TextStyle(
                              fontWeight: row.strong ? FontWeight.w700 : null,
                              color:
                                  row.label == l10n.reportDifference &&
                                      difference != null
                                  ? differenceColor(difference)
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
