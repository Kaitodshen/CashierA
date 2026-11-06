import 'dart:convert';
import 'dart:typed_data';

import 'package:cashiera_core/cashiera_core.dart';
import 'package:excel_plus/excel_plus.dart';
import 'package:file_picker/file_picker.dart';

/// Reads a CSV or XLSX catalog file into rows of trimmed strings.
/// Throws [FormatException] for anything else.
List<List<String>> readCatalogFile(String fileName, Uint8List bytes) {
  final name = fileName.toLowerCase();
  if (name.endsWith('.csv') || name.endsWith('.txt')) {
    return decodeCsv(utf8.decode(bytes, allowMalformed: true));
  }
  if (name.endsWith('.xlsx')) {
    final Excel excel;
    try {
      excel = Excel.decodeBytes(bytes);
    } on ExcelException catch (e) {
      throw FormatException(e.message);
    }
    if (excel.tables.isEmpty) return const [];
    final sheet = excel.tables[excel.tables.keys.first]!;
    return [
      for (final row in sheet.rows)
        if (row.any((c) => _cellText(c?.value).isNotEmpty))
          [for (final cell in row) _cellText(cell?.value)],
    ];
  }
  throw FormatException('Use a .csv or .xlsx file', fileName);
}

String _cellText(CellValue? value) => switch (value) {
  null => '',
  IntCellValue(:final value) => '$value',
  DoubleCellValue(:final value) =>
    value == value.roundToDouble() ? '${value.toInt()}' : '$value',
  BoolCellValue(:final value) => value ? 'yes' : 'no',
  TextCellValue(:final value) => _spanText(value).trim(),
  _ => value.toString().trim(),
};

/// Plain text of a (possibly rich-text) cell.
String _spanText(TextSpan span) =>
    '${span.text ?? ''}${span.children?.map(_spanText).join() ?? ''}';

/// The catalog as an .xlsx workbook in template layout. Prices stay numbers
/// so Excel can sum them; everything else is text.
Uint8List encodeCatalogXlsx(
  List<CatalogExportRow> rows,
  List<String> storeCodes,
) {
  final excel = Excel.createExcel();
  final sheetName = excel.tables.keys.first;
  final sheet = excel[sheetName]
    ..appendRow([for (final h in catalogHeader(storeCodes)) TextCellValue(h)]);
  for (final row in rows) {
    final cells = row.cells(storeCodes);
    sheet.appendRow([
      for (final (i, cell) in cells.indexed)
        if ((i == 6 || i == 7) && int.tryParse(cell) != null)
          IntCellValue(int.parse(cell))
        else
          TextCellValue(cell),
    ]);
  }
  return Uint8List.fromList(excel.save()!);
}

/// Saves bytes where the platform allows: a download on web, a save dialog
/// on desktop and mobile. Returns false when the person cancelled.
Future<bool> saveBytes(
  String fileName,
  Uint8List bytes,
  String mimeType,
) async {
  final uri = await FilePicker.saveFile(
    fileName: fileName,
    bytes: bytes,
    mimeType: mimeType,
  );
  return uri != null;
}

/// Lets the person pick a catalog file. Returns (name, bytes) or null.
Future<(String, Uint8List)?> pickCatalogFile() async {
  final files = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['csv', 'xlsx'],
  );
  final file = files.firstOrNull;
  if (file == null) return null;
  return (file.name, await file.readAsBytes());
}

const csvMime = 'text/csv';
const xlsxMime =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
