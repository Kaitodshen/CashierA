import 'dart:typed_data';

import 'package:cashiera/core/pos/receipt.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:excel_plus/excel_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// One cell of a report table: text, money, a quantity or a count.
sealed class ReportCell {
  const new();
}

final class TextCell extends ReportCell {
  const new(this.text);
  final String text;
}

final class MoneyCell extends ReportCell {
  const new(this.value);
  final Money value;
}

final class QtyCell extends ReportCell {
  const new(this.value);
  final Qty value;
}

final class CountCell extends ReportCell {
  const new(this.value);
  final int value;
}

/// What a report table shows on screen and in its PDF/Excel export.
class ReportTable {
  const new({
    required this.title,
    required this.subtitle,
    required this.columns,
    required this.rows,
    this.totals,
  });

  final String title;

  /// Store and period.
  final String subtitle;
  final List<String> columns;
  final List<List<ReportCell>> rows;

  /// A last row in bold.
  final List<ReportCell>? totals;

  /// A file name without extension: `Penjualan 2026-10-01 - 2026-10-04`.
  String get fileName =>
      '$title $subtitle'.replaceAll(RegExp(r'[\\/:*?"<>|]'), '-').trim();
}

String cellText(ReportCell c) => switch (c) {
  TextCell(:final text) => text,
  MoneyCell(:final value) => value.format(),
  QtyCell(:final value) => value.toPlain(),
  CountCell(:final value) => '$value',
};

bool cellIsNumber(ReportCell c) => c is! TextCell;

/// An .xlsx with the title, the subtitle, a header row and the rows; money
/// and counts as whole numbers, quantities as decimals.
Uint8List buildReportXlsx(ReportTable t) {
  final excel = Excel.createExcel();
  final sheetName = excel.getDefaultSheet() ?? 'Sheet1';
  final sheet = excel[sheetName];
  CellValue value(ReportCell c) => switch (c) {
    TextCell(:final text) => TextCellValue(text),
    MoneyCell(:final value) => IntCellValue(value.rupiah),
    QtyCell(:final value) => DoubleCellValue(value.milli / 1000),
    CountCell(:final value) => IntCellValue(value),
  };
  sheet
    ..appendRow([TextCellValue(t.title)])
    ..appendRow([TextCellValue(t.subtitle)])
    ..appendRow([TextCellValue('')])
    ..appendRow([for (final c in t.columns) TextCellValue(c)]);
  for (final row in t.rows) {
    sheet.appendRow([for (final c in row) value(c)]);
  }
  if (t.totals != null) sheet.appendRow([for (final c in t.totals!) value(c)]);
  return Uint8List.fromList(excel.save()!);
}

/// The table on A4 (landscape when it is wide), with a page footer.
Future<Uint8List> buildReportPdf(ReportTable t, {required String printedAt}) {
  final base = pw.Font.helvetica();
  final bold = pw.Font.helveticaBold();
  final wide = t.columns.length > 6;
  final size = wide ? 7.5 : 8.5;
  pw.Widget text(String s, {bool right = false, bool strong = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2),
        child: pw.Text(
          pdfSafe(s),
          textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
          style: pw.TextStyle(font: strong ? bold : base, fontSize: size),
        ),
      );
  pw.Widget cell(ReportCell c, {bool strong = false}) =>
      text(cellText(c), right: cellIsNumber(c), strong: strong);
  bool numeric(int column) =>
      t.rows.isNotEmpty && cellIsNumber(t.rows.first[column]);
  final doc = pw.Document(title: t.title)
    ..addPage(
      pw.MultiPage(
        pageFormat: wide ? PdfPageFormat.a4.landscape : PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              pdfSafe(printedAt),
              style: pw.TextStyle(font: base, fontSize: 7),
            ),
            pw.Text(
              '${context.pageNumber} / ${context.pagesCount}',
              style: pw.TextStyle(font: base, fontSize: 7),
            ),
          ],
        ),
        build: (_) => [
          pw.Text(
            pdfSafe(t.title),
            style: pw.TextStyle(font: bold, fontSize: 14),
          ),
          pw.Text(
            pdfSafe(t.subtitle),
            style: pw.TextStyle(font: base, fontSize: 9),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: const pw.TableBorder(
              horizontalInside: pw.BorderSide(
                width: 0.3,
                color: PdfColors.grey400,
              ),
              bottom: pw.BorderSide(width: 0.5),
              top: pw.BorderSide(width: 0.5),
            ),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  for (final (i, c) in t.columns.indexed)
                    text(c, right: numeric(i), strong: true),
                ],
              ),
              for (final row in t.rows)
                pw.TableRow(children: [for (final c in row) cell(c)]),
              if (t.totals != null)
                pw.TableRow(
                  children: [for (final c in t.totals!) cell(c, strong: true)],
                ),
            ],
          ),
        ],
      ),
    );
  return doc.save();
}
