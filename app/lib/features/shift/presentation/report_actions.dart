import 'package:cashiera/core/design_system/widgets/toasts.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/pos/pos_config.dart';
import 'package:cashiera/core/pos/report_pdf.dart';
import 'package:cashiera/core/pos/shift_report_text.dart';
import 'package:cashiera/core/printing/slips.dart';
import 'package:cashiera/features/printing/print_actions.dart';
import 'package:cashiera/features/shift/presentation/shift_widgets.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

List<String> _header(PosConfig config) => [
  config.business.name,
  if (config.storeName != config.business.name) config.storeName,
];

String _printedAt(AppLocalizations l10n, PosConfig config) =>
    l10n.reportPrintedAt(
      DateFormat('dd/MM/yyyy HH:mm').format(config.localTime(clock.now())),
    );

/// Prints the X/Z report on the receipt printer.
Future<bool> printShiftReport(
  BuildContext context,
  WidgetRef ref,
  ShiftReport report,
  PosConfig config,
) {
  final l10n = context.l10n;
  return printSlip(
    context,
    ref,
    shiftReportDocument(
      title: reportTitle(l10n, report),
      headerLines: _header(config),
      sections: shiftReportSections(
        report,
        shiftReportLabels(l10n),
        utcOffsetMinutes: config.utcOffsetMinutes,
      ),
      printedAt: _printedAt(l10n, config),
    ),
  );
}

/// Shares the X/Z report as a roll-paper PDF.
Future<void> shareShiftReport(
  BuildContext context,
  ShiftReport report,
  PosConfig config,
) async {
  final l10n = context.l10n;
  try {
    final bytes = await buildShiftReportPdf(
      title: reportTitle(l10n, report),
      headerLines: _header(config),
      sections: shiftReportSections(
        report,
        shiftReportLabels(l10n),
        utcOffsetMinutes: config.utcOffsetMinutes,
      ),
      footer: _printedAt(l10n, config),
      roll: true,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${reportTitle(l10n, report)} ${report.businessDate ?? ''}.pdf'
          .trim(),
    );
  } on Exception catch (e) {
    if (context.mounted) AppToast.error(context, l10n.commonError('$e'));
  }
}
