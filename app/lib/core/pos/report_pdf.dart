import 'dart:typed_data';

import 'package:cashiera/core/pos/receipt.dart';
import 'package:cashiera/core/pos/shift_report_text.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// The X/Z report as a PDF: A4 for the back office, roll paper for the
/// terminal's share button.
Future<Uint8List> buildShiftReportPdf({
  required String title,
  required List<String> headerLines,
  required List<ReportSection> sections,
  required String footer,
  bool roll = false,
}) {
  final base = pw.Font.helvetica();
  final bold = pw.Font.helveticaBold();
  final size = roll ? 8.0 : 10.0;
  final normal = pw.TextStyle(font: base, fontSize: size);
  final strong = pw.TextStyle(font: bold, fontSize: size);

  pw.Widget row(ReportRow r) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Text(pdfSafe(r.label), style: r.strong ? strong : normal),
        ),
        pw.SizedBox(width: 8),
        pw.Text(pdfSafe(r.value), style: r.strong ? strong : normal),
      ],
    ),
  );

  final content = <pw.Widget>[
    for (final line in headerLines)
      pw.Text(pdfSafe(line), style: strong, textAlign: pw.TextAlign.center),
    pw.SizedBox(height: 4),
    pw.Text(
      pdfSafe(title),
      style: pw.TextStyle(font: bold, fontSize: size + 4),
      textAlign: pw.TextAlign.center,
    ),
    pw.SizedBox(height: 6),
    for (final section in sections) ...[
      if (section.title != null) ...[
        pw.SizedBox(height: 6),
        pw.Text(pdfSafe(section.title!.toUpperCase()), style: strong),
        pw.Divider(height: 4, thickness: 0.5),
      ],
      for (final r in section.rows) row(r),
    ],
    pw.SizedBox(height: 10),
    pw.Text(pdfSafe(footer), style: normal, textAlign: pw.TextAlign.center),
  ];

  final doc = pw.Document(title: title);
  if (roll) {
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80.copyWith(
          marginLeft: 4 * PdfPageFormat.mm,
          marginRight: 4 * PdfPageFormat.mm,
          marginTop: 4 * PdfPageFormat.mm,
          marginBottom: 6 * PdfPageFormat.mm,
        ),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: content,
        ),
      ),
    );
  } else {
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 120, vertical: 48),
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        build: (_) => content,
      ),
    );
  }
  return doc.save();
}
