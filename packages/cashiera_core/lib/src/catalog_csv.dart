import 'package:cashiera_core/src/qty.dart';

/// Columns of docs/templates/products-template.csv, in order. Stock columns
/// (`stock_<STORE CODE>`) follow them.
const catalogColumns = [
  'product_name',
  'variant_name',
  'sku',
  'barcode',
  'category',
  'unit',
  'price',
  'cost',
  'taxable',
  'track_stock',
  'reorder_point',
];

/// Columns that must be present; the others have defaults.
const requiredCatalogColumns = [
  'product_name',
  'sku',
  'category',
  'unit',
  'price',
  'cost',
];

/// Same limit as the `import_catalog` RPC.
const maxImportRows = 5000;

const _stockPrefix = 'stock_';

enum ImportIssueCode {
  emptyFile,
  missingColumn,
  unknownStore,
  tooManyRows,
  requiredValue,
  skuFormat,
  barcodeFormat,
  priceFormat,
  quantityFormat,
  booleanFormat,
  unknownUnit,
  duplicateSku,
  duplicateBarcode,
  productMismatch,
}

/// One problem in an import file. [row] is the spreadsheet row number
/// (the header is row 1); 0 means the whole file.
class ImportIssue {
  const new(this.row, this.code, {this.column, this.value});

  final int row;
  final ImportIssueCode code;
  final String? column;
  final String? value;

  @override
  String toString() => 'row $row ${column ?? ''}: ${code.name} ${value ?? ''}';
}

class CatalogImportRow {
  const new({
    required this.row,
    required this.productName,
    required this.variantName,
    required this.sku,
    required this.barcode,
    required this.category,
    required this.unit,
    required this.price,
    required this.cost,
    required this.taxable,
    required this.trackStock,
    required this.reorderPoint,
    required this.stock,
  });

  final int row;
  final String productName;
  final String variantName;
  final String sku;
  final String? barcode;
  final String category;
  final String unit;
  final int price;
  final int cost;
  final bool taxable;
  final bool trackStock;
  final Qty? reorderPoint;

  /// Counted on-hand stock per store code.
  final Map<String, Qty> stock;

  /// The row as the `import_catalog` RPC expects it.
  Map<String, Object?> toJson() => {
    'row': row,
    'product_name': productName,
    'variant_name': variantName,
    'sku': sku,
    'barcode': barcode,
    'category': category,
    'unit': unit,
    'price': price,
    'cost': cost,
    'taxable': taxable,
    'track_stock': trackStock,
    'reorder_point': reorderPoint?.toPayload(),
    'stock': {for (final e in stock.entries) e.key: e.value.toPayload()},
  };
}

class CatalogImport {
  const new({required this.rows, required this.issues});

  final List<CatalogImportRow> rows;
  final List<ImportIssue> issues;

  bool get isValid => issues.isEmpty && rows.isNotEmpty;

  int get productCount =>
      rows.map((r) => r.productName.toLowerCase()).toSet().length;
}

/// A catalog row for export, with the same meaning as an import row.
class CatalogExportRow {
  const new({
    required this.productName,
    required this.variantName,
    required this.sku,
    required this.barcode,
    required this.category,
    required this.unit,
    required this.price,
    required this.cost,
    required this.taxable,
    required this.trackStock,
    required this.reorderPoint,
    required this.stock,
  });

  final String productName;
  final String variantName;
  final String sku;
  final String? barcode;
  final String category;
  final String unit;
  final int price;
  final int cost;
  final bool taxable;
  final bool trackStock;
  final Qty? reorderPoint;
  final Map<String, Qty> stock;

  /// Cells in template order, followed by one cell per store code.
  List<String> cells(List<String> storeCodes) => [
    productName,
    variantName,
    sku,
    barcode ?? '',
    category,
    unit,
    '$price',
    '$cost',
    if (taxable) 'yes' else 'no',
    if (trackStock) 'yes' else 'no',
    reorderPoint?.toPlain() ?? '',
    for (final code in storeCodes) stock[code]?.toPlain() ?? '',
  ];
}

/// Header row for an export with these store codes.
List<String> catalogHeader(List<String> storeCodes) => [
  ...catalogColumns,
  for (final code in storeCodes) '$_stockPrefix$code',
];

// ---------------------------------------------------------------------------
// CSV
// ---------------------------------------------------------------------------

/// Decodes CSV text. Handles a UTF-8 BOM, quoted fields (with `""` escapes
/// and embedded newlines), CRLF, and both `,` and `;` separators (Excel in
/// Indonesian locale writes `;`). The separator is detected from the header.
/// Blank lines are skipped.
List<List<String>> decodeCsv(String text) {
  var source = text;
  if (source.startsWith('\uFEFF')) source = source.substring(1);
  final delimiter = _detectDelimiter(source);

  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;

  void endField() {
    row.add(field.toString());
    field.clear();
  }

  void endRow() {
    endField();
    if (!(row.length == 1 && row.first.trim().isEmpty)) rows.add(row);
    row = <String>[];
  }

  for (var i = 0; i < source.length; i++) {
    final c = source[i];
    if (inQuotes) {
      if (c == '"') {
        if (i + 1 < source.length && source[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field.write(c);
      }
    } else if (c == '"') {
      inQuotes = true;
    } else if (c == delimiter) {
      endField();
    } else if (c == '\n' || c == '\r') {
      if (c == '\r' && i + 1 < source.length && source[i + 1] == '\n') i++;
      endRow();
    } else {
      field.write(c);
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) endRow();
  return rows;
}

String _detectDelimiter(String text) {
  var commas = 0;
  var semicolons = 0;
  var inQuotes = false;
  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (c == '"') inQuotes = !inQuotes;
    if (inQuotes) continue;
    if (c == '\n' || c == '\r') break;
    if (c == ',') commas++;
    if (c == ';') semicolons++;
  }
  return semicolons > commas ? ';' : ',';
}

/// Encodes rows as CSV (comma separated, quotes only where needed, LF).
String encodeCsv(List<List<String>> rows) {
  String quote(String v) =>
      v.contains(RegExp('[",;\r\n]')) ? '"${v.replaceAll('"', '""')}"' : v;
  return '${rows.map((r) => r.map(quote).join(',')).join('\n')}\n';
}

/// The catalog as CSV in template format.
String encodeCatalogCsv(List<CatalogExportRow> rows, List<String> storeCodes) =>
    encodeCsv([
      catalogHeader(storeCodes),
      for (final r in rows) r.cells(storeCodes),
    ]);

// ---------------------------------------------------------------------------
// Validation
// ---------------------------------------------------------------------------

final _skuPattern = RegExp(r'^[A-Za-z0-9._-]{1,40}$');
final _barcodePattern = RegExp(r'^[0-9A-Za-z-]{4,32}$');
const _yes = {'yes', 'ya', 'y', 'true', '1'};
const _no = {'no', 'tidak', 'n', 'false', '0'};

/// Validates a decoded table against the template rules
/// (docs/templates/README.md). Every problem is reported, not just the first,
/// so the owner can fix the whole file at once.
CatalogImport parseCatalogTable(
  List<List<String>> table, {
  required Set<String> unitCodes,
  required Set<String> storeCodes,
}) {
  if (table.isEmpty) {
    return const CatalogImport(
      rows: [],
      issues: [ImportIssue(0, ImportIssueCode.emptyFile)],
    );
  }

  final header = table.first.map((h) => h.trim().toLowerCase()).toList();
  final issues = <ImportIssue>[];
  for (final column in requiredCatalogColumns) {
    if (!header.contains(column)) {
      issues.add(ImportIssue(1, ImportIssueCode.missingColumn, column: column));
    }
  }
  final stockColumns = <int, String>{};
  for (var i = 0; i < header.length; i++) {
    if (!header[i].startsWith(_stockPrefix)) continue;
    final code = header[i].substring(_stockPrefix.length).toUpperCase();
    if (storeCodes.contains(code)) {
      stockColumns[i] = code;
    } else {
      issues.add(
        ImportIssue(1, ImportIssueCode.unknownStore, column: table.first[i]),
      );
    }
  }
  if (issues.isNotEmpty) return CatalogImport(rows: const [], issues: issues);

  final data = table.skip(1).toList();
  if (data.length > maxImportRows) {
    return const CatalogImport(
      rows: [],
      issues: [ImportIssue(0, ImportIssueCode.tooManyRows)],
    );
  }

  final rows = <CatalogImportRow>[];
  final skus = <String>{};
  final barcodes = <String>{};
  final products = <String, CatalogImportRow>{};

  for (var index = 0; index < data.length; index++) {
    final cells = data[index];
    final rowNumber = index + 2;
    final before = issues.length;

    String cell(String column) {
      final i = header.indexOf(column);
      return i < 0 || i >= cells.length ? '' : cells[i].trim();
    }

    void issue(ImportIssueCode code, String column, [String? value]) =>
        issues.add(ImportIssue(rowNumber, code, column: column, value: value));

    String required(String column) {
      final value = cell(column);
      if (value.isEmpty) issue(ImportIssueCode.requiredValue, column);
      return value;
    }

    int? money(String column) {
      final value = required(column);
      if (value.isEmpty) return null;
      if (!RegExp(r'^\d{1,12}$').hasMatch(value)) {
        issue(ImportIssueCode.priceFormat, column, value);
        return null;
      }
      return int.parse(value);
    }

    bool flag(String column) {
      final value = cell(column).toLowerCase();
      if (value.isEmpty || _yes.contains(value)) return true;
      if (_no.contains(value)) return false;
      issue(ImportIssueCode.booleanFormat, column, cell(column));
      return true;
    }

    Qty? quantity(String column, String raw) {
      if (raw.isEmpty) return null;
      final normalized = raw.contains('.') ? raw : raw.replaceAll(',', '.');
      try {
        final q = Qty.parse(normalized);
        if (q.milli < 0) throw const FormatException('negative');
        return q;
      } on FormatException {
        issue(ImportIssueCode.quantityFormat, column, raw);
        return null;
      }
    }

    final productName = required('product_name');
    final variantName = cell('variant_name').isEmpty
        ? 'Default'
        : cell('variant_name');

    final sku = required('sku');
    if (sku.isNotEmpty) {
      if (!_skuPattern.hasMatch(sku)) {
        issue(ImportIssueCode.skuFormat, 'sku', sku);
      } else if (!skus.add(sku.toUpperCase())) {
        issue(ImportIssueCode.duplicateSku, 'sku', sku);
      }
    }

    final barcode = cell('barcode').isEmpty ? null : cell('barcode');
    if (barcode != null) {
      if (!_barcodePattern.hasMatch(barcode)) {
        issue(ImportIssueCode.barcodeFormat, 'barcode', barcode);
      } else if (!barcodes.add(barcode)) {
        issue(ImportIssueCode.duplicateBarcode, 'barcode', barcode);
      }
    }

    final category = required('category');
    final unit = required('unit').toLowerCase();
    if (unit.isNotEmpty && !unitCodes.contains(unit)) {
      issue(ImportIssueCode.unknownUnit, 'unit', cell('unit'));
    }
    final price = money('price');
    final cost = money('cost');
    final taxable = flag('taxable');
    final trackStock = flag('track_stock');
    final reorderPoint = quantity('reorder_point', cell('reorder_point'));

    final stock = <String, Qty>{};
    for (final entry in stockColumns.entries) {
      final raw = entry.key < cells.length ? cells[entry.key].trim() : '';
      final q = quantity(header[entry.key], raw);
      if (q != null) stock[entry.value] = q;
    }

    if (issues.length > before) continue;

    final row = CatalogImportRow(
      row: rowNumber,
      productName: productName,
      variantName: variantName,
      sku: sku,
      barcode: barcode,
      category: category,
      unit: unit,
      price: price!,
      cost: cost!,
      taxable: taxable,
      trackStock: trackStock,
      reorderPoint: reorderPoint,
      stock: stock,
    );

    final first = products.putIfAbsent(productName.toLowerCase(), () => row);
    if (!identical(first, row) &&
        (first.category.toLowerCase() != category.toLowerCase() ||
            first.unit != unit ||
            first.taxable != taxable ||
            first.trackStock != trackStock)) {
      issue(ImportIssueCode.productMismatch, 'product_name', productName);
      continue;
    }
    rows.add(row);
  }

  return CatalogImport(rows: rows, issues: issues);
}
