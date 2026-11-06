import 'package:cashiera/core/pos/receipt.dart';
import 'package:cashiera/core/pos/shift_report_text.dart';
import 'package:cashiera_core/cashiera_core.dart';

/// A sale receipt for a thermal printer. [openDrawer] pulses the drawer
/// first (cash sales); [copy] marks a reprint.
ReceiptDocument receiptDocument(
  ReceiptData r,
  ReceiptLabels l, {
  bool openDrawer = false,
  bool copy = false,
}) => ReceiptDocument([
  if (openDrawer) const PrintDrawer(),
  for (final (i, line) in r.headerLines.indexed)
    PrintText(line, align: PrintAlign.center, bold: i == 0, large: i == 0),
  if (r.status != 'completed')
    PrintText(
      receiptStatusLabel(r.status, l),
      align: PrintAlign.center,
      bold: true,
    ),
  if (copy) PrintText(l.copy, align: PrintAlign.center, bold: true),
  const PrintRule(),
  PrintRow(r.orderNumber, r.dateText),
  PrintRow(l.cashier, r.cashierName),
  if (r.customerName != null) PrintRow(l.customer, r.customerName!),
  const PrintRule(),
  for (final line in r.lines) ...[
    PrintText(line.name),
    for (final d in line.details) PrintText('  $d'),
    PrintRow('  ${line.quantityText}', line.amount.format()),
    for (final (name, amount) in line.discounts)
      PrintRow('  $name', '-${amount.format()}'),
  ],
  const PrintRule(),
  PrintText(l.items(r.itemCount)),
  for (final (label, value, :strong) in receiptTotals(r, l))
    PrintRow(label, value, bold: strong),
  if (r.kasbonDueDate != null) PrintText(l.kasbonDue(r.kasbonDueDate!)),
  const PrintRule(),
  PrintText(r.footer, align: PrintAlign.center),
  PrintQr(r.orderNumber, size: 4),
  const PrintFeed(2),
  const PrintCut(),
]);

/// The X or Z report as a slip.
ReceiptDocument shiftReportDocument({
  required String title,
  required List<String> headerLines,
  required List<ReportSection> sections,
  required String printedAt,
}) => ReceiptDocument([
  for (final line in headerLines)
    PrintText(line, align: PrintAlign.center, bold: true),
  PrintText(title, align: PrintAlign.center, bold: true, large: true),
  const PrintRule(),
  for (final section in sections) ...[
    if (section.title != null) ...[
      PrintText(section.title!.toUpperCase(), bold: true),
    ],
    for (final row in section.rows)
      PrintRow(row.label, row.value, bold: row.strong),
    const PrintRule(),
  ],
  PrintText(printedAt, align: PrintAlign.center),
  const PrintFeed(2),
  const PrintCut(),
]);

/// What a refund slip shows.
class RefundSlipData {
  const new({
    required this.headerLines,
    required this.title,
    required this.refundNumber,
    required this.orderLine,
    required this.dateText,
    required this.staffLine,
    required this.approverLine,
    required this.lines,
    required this.totalLabel,
    required this.total,
    required this.methodLine,
    required this.reasonLine,
  });

  final List<String> headerLines;
  final String title;
  final String refundNumber;
  final String orderLine;
  final String dateText;
  final String staffLine;
  final String approverLine;

  /// (name, `2 x`, amount).
  final List<(String, String, Money)> lines;
  final String totalLabel;
  final Money total;
  final String methodLine;
  final String reasonLine;
}

ReceiptDocument refundSlipDocument(
  RefundSlipData r, {
  bool openDrawer = false,
}) => ReceiptDocument([
  if (openDrawer) const PrintDrawer(),
  for (final (i, line) in r.headerLines.indexed)
    PrintText(line, align: PrintAlign.center, bold: i == 0),
  PrintText(r.title, align: PrintAlign.center, bold: true, large: true),
  const PrintRule(),
  PrintRow(r.refundNumber, r.dateText),
  PrintText(r.orderLine),
  PrintText(r.staffLine),
  PrintText(r.approverLine),
  const PrintRule(),
  for (final (name, qty, amount) in r.lines) ...[
    PrintText(name),
    PrintRow('  $qty', '-${amount.format()}'),
  ],
  const PrintRule(),
  PrintRow(r.totalLabel, '-${r.total.format()}', bold: true),
  PrintText(r.methodLine),
  PrintText(r.reasonLine),
  const PrintFeed(2),
  const PrintCut(),
]);

/// A test page: shows the column width so the paper setting can be checked.
ReceiptDocument testPageDocument({
  required String title,
  required List<String> lines,
  required int columns,
}) => ReceiptDocument([
  PrintText(title, align: PrintAlign.center, bold: true, large: true),
  const PrintRule(),
  for (final line in lines) PrintText(line),
  PrintText(List.generate(columns, (i) => '${(i + 1) % 10}').join()),
  const PrintRule(char: '='),
  const PrintRow('Rp', '1.234.567'),
  const PrintQr('CashierA'),
  const PrintFeed(2),
  const PrintCut(),
]);
