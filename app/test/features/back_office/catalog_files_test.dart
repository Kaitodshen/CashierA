import 'dart:convert';
import 'dart:typed_data';

import 'package:cashiera/features/back_office/data/catalog_files.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter_test/flutter_test.dart';

final rows = [
  CatalogExportRow(
    productName: 'Air Mineral',
    variantName: '600 ml',
    sku: 'MNM-AIR-600',
    barcode: '2000000000015',
    category: 'Minuman',
    unit: 'pcs',
    price: 4000,
    cost: 2600,
    taxable: true,
    trackStock: true,
    reorderPoint: Qty.parse('10'),
    stock: {'PST': Qty.parse('48'), 'BKS': Qty.parse('40')},
  ),
  CatalogExportRow(
    productName: 'Bawang Merah Curah',
    variantName: 'Per kg',
    sku: 'SYR-BWM-KG',
    barcode: null,
    category: 'Sayur & Buah',
    unit: 'kg',
    price: 42000,
    cost: 34000,
    taxable: false,
    trackStock: true,
    reorderPoint: null,
    stock: {'PST': Qty.parse('12.5')},
  ),
];

CatalogImport parse(List<List<String>> table) => parseCatalogTable(
  table,
  unitCodes: const {'pcs', 'kg'},
  storeCodes: const {'PST', 'BKS'},
);

void main() {
  test('an exported XLSX imports back unchanged', () {
    final bytes = encodeCatalogXlsx(rows, ['PST', 'BKS']);
    final result = parse(readCatalogFile('katalog.xlsx', bytes));
    expect(result.issues, isEmpty);
    expect(result.rows.map((r) => r.sku), ['MNM-AIR-600', 'SYR-BWM-KG']);
    expect(result.rows.first.price, 4000);
    expect(result.rows.first.barcode, '2000000000015');
    expect(result.rows.last.taxable, isFalse);
    expect(result.rows.last.stock, {'PST': Qty.parse('12.5')});
  });

  test('a CSV file is read as UTF-8 (with BOM)', () {
    final csv =
        '${String.fromCharCode(0xFEFF)}'
        '${encodeCatalogCsv(rows, ['PST', 'BKS'])}';
    final result = parse(
      readCatalogFile('katalog.CSV', Uint8List.fromList(utf8.encode(csv))),
    );
    expect(result.issues, isEmpty);
    expect(result.rows, hasLength(2));
  });

  test('other file types are refused', () {
    expect(
      () => readCatalogFile('katalog.pdf', Uint8List(0)),
      throwsFormatException,
    );
    expect(
      () => readCatalogFile('rusak.xlsx', Uint8List.fromList([1, 2, 3])),
      throwsFormatException,
    );
  });
}
