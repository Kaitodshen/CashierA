import 'dart:io';

import 'package:cashiera_core/cashiera_core.dart';
import 'package:test/test.dart';

const units = {
  'pcs',
  'kg',
  'g',
  'l',
  'ml',
  'pack',
  'box',
  'dus',
  'renceng',
  'lusin',
};
const stores = {'PST', 'BKS', 'TGR'};

CatalogImport parse(String csv) =>
    parseCatalogTable(decodeCsv(csv), unitCodes: units, storeCodes: stores);

const header =
    'product_name,variant_name,sku,barcode,category,unit,price,cost,taxable,'
    'track_stock,reorder_point,stock_PST,stock_BKS,stock_TGR';

Iterable<ImportIssueCode> codes(CatalogImport i) => i.issues.map((e) => e.code);

void main() {
  group('decodeCsv', () {
    test('handles quotes, escaped quotes and CRLF', () {
      expect(decodeCsv('a,b\r\n"x, y","say ""hi"""\r\n'), [
        ['a', 'b'],
        ['x, y', 'say "hi"'],
      ]);
    });

    test(
      'detects semicolons and strips the BOM (Excel, Indonesian locale)',
      () {
        expect(decodeCsv('\uFEFFa;b;c\n1;"2;3";4\n'), [
          ['a', 'b', 'c'],
          ['1', '2;3', '4'],
        ]);
      },
    );

    test('quoted fields may contain newlines; blank lines are skipped', () {
      expect(decodeCsv('a,b\n"line1\nline2",x\n\n'), [
        ['a', 'b'],
        ['line1\nline2', 'x'],
      ]);
    });
  });

  group('parseCatalogTable', () {
    test('the shipped template parses into 4 rows with no issues', () {
      final file = File('../../docs/templates/products-template.csv');
      final result = parse(file.readAsStringSync());
      expect(result.issues, isEmpty);
      expect(result.rows, hasLength(4));
      expect(result.productCount, 3);
      final air = result.rows.first;
      expect(air.sku, 'MNM-AIR-600');
      expect(air.price, 4000);
      expect(air.taxable, isTrue);
      expect(air.stock['PST'], Qty.parse('48'));
      final bawang = result.rows.last;
      expect(bawang.barcode, isNull);
      expect(bawang.unit, 'kg');
      expect(bawang.stock['TGR'], Qty.parse('8.75'));
      expect(bawang.toJson()['stock'], {
        'PST': '12.500',
        'BKS': '10.000',
        'TGR': '8.750',
      });
      expect(bawang.toJson()['row'], 5);
    });

    test('Indonesian Excel CSV: semicolons, decimal commas, ya/tidak', () {
      final header = [
        'product_name', 'variant_name', 'sku', 'barcode', 'category', 'unit', //
        'price', 'cost', 'taxable', 'track_stock', 'reorder_point', 'stock_PST',
      ].join(';');
      final line = [
        'Bawang Putih', 'Per kg', 'SYR-BWP-KG', '', 'Sayur & Buah', 'KG', //
        '38000', '30000', 'tidak', 'ya', '2,5', '7,25',
      ].join(';');
      final result = parse('\uFEFF$header\n$line\n');
      expect(result.issues, isEmpty);
      final row = result.rows.single;
      expect(row.unit, 'kg');
      expect(row.taxable, isFalse);
      expect(row.reorderPoint, Qty.parse('2.5'));
      expect(row.stock['PST'], Qty.parse('7.25'));
    });

    test('Rp-formatted prices are refused with a clear code', () {
      final result = parse(
        '$header\n'
        'Kopi,Default,KOPI-1,,Minuman,pcs,Rp 25.000,20000,yes,yes,,,,\n',
      );
      expect(result.issues.single.code, ImportIssueCode.priceFormat);
      expect(result.issues.single.row, 2);
      expect(result.issues.single.column, 'price');
      expect(result.issues.single.value, 'Rp 25.000');
    });

    test(
      'duplicate SKU (any case) and barcode are flagged on the later row',
      () {
        final result = parse(
          '$header\n'
          'Kopi,A,KOPI-1,2000000000015,Minuman,pcs,1000,500,yes,yes,,,,\n'
          'Kopi,B,kopi-1,2000000000015,Minuman,pcs,1000,500,yes,yes,,,,\n',
        );
        expect(codes(result), [
          ImportIssueCode.duplicateSku,
          ImportIssueCode.duplicateBarcode,
        ]);
        expect(result.issues.every((i) => i.row == 3), isTrue);
      },
    );

    test('unknown unit, bad quantity, bad yes/no, missing values', () {
      final result = parse(
        '$header\n'
        'Kopi,A,KOPI-1,,Minuman,karung,1000,500,mungkin,yes,abc,-1,,\n'
        ',B,KOPI-2,,Minuman,pcs,,500,yes,yes,,,,\n',
      );
      expect(codes(result), [
        ImportIssueCode.unknownUnit,
        ImportIssueCode.booleanFormat,
        ImportIssueCode.quantityFormat,
        ImportIssueCode.quantityFormat,
        ImportIssueCode.requiredValue,
        ImportIssueCode.requiredValue,
      ]);
    });

    test('rows of one product must agree on category, unit and flags', () {
      final result = parse(
        '$header\n'
        'Kopi,A,KOPI-1,,Minuman,pcs,1000,500,yes,yes,,,,\n'
        'Kopi,B,KOPI-2,,Snack,pcs,1000,500,yes,yes,,,,\n',
      );
      expect(result.issues.single.code, ImportIssueCode.productMismatch);
      expect(result.issues.single.row, 3);
    });

    test('unknown stock column and missing required column', () {
      expect(
        codes(parse('$header,stock_JKT\n')),
        contains(ImportIssueCode.unknownStore),
      );
      final missing = parse(
        'product_name,sku,category,unit,price\nA,B,C,pcs,1\n',
      );
      expect(missing.issues.single.code, ImportIssueCode.missingColumn);
      expect(missing.issues.single.column, 'cost');
      expect(missing.rows, isEmpty);
    });

    test('defaults: variant Default, taxable and stock tracking on', () {
      final result = parse(
        'product_name,sku,category,unit,price,cost\n'
        'Gula,GLA-1,Sembako,pcs,18500,16200\n',
      );
      expect(result.issues, isEmpty);
      final row = result.rows.single;
      expect(row.variantName, 'Default');
      expect(row.taxable, isTrue);
      expect(row.trackStock, isTrue);
      expect(row.stock, isEmpty);
    });

    test('empty file and more than 5000 rows', () {
      expect(codes(parse('')), [ImportIssueCode.emptyFile]);
      final big = StringBuffer('product_name,sku,category,unit,price,cost\n');
      for (var i = 0; i <= maxImportRows; i++) {
        big.writeln('P$i,SKU-$i,Kat,pcs,1000,500');
      }
      expect(codes(parse(big.toString())), [ImportIssueCode.tooManyRows]);
    });
  });

  group('encodeCatalogCsv', () {
    test('round-trips through decode and parse', () {
      final csv = encodeCatalogCsv(
        [
          CatalogExportRow(
            productName: 'Kopi, "Spesial"',
            variantName: 'Default',
            sku: 'KOPI-1',
            barcode: null,
            category: 'Minuman',
            unit: 'pcs',
            price: 25000,
            cost: 18000,
            taxable: true,
            trackStock: true,
            reorderPoint: Qty.parse('5'),
            stock: {'PST': Qty.parse('12.5')},
          ),
        ],
        ['PST', 'BKS'],
      );
      expect(
        csv.split('\n').first,
        startsWith('product_name,variant_name,sku'),
      );
      final result = parse(csv);
      expect(result.issues, isEmpty);
      final row = result.rows.single;
      expect(row.productName, 'Kopi, "Spesial"');
      expect(row.stock, {'PST': Qty.parse('12.5')});
      expect(row.reorderPoint, Qty.parse('5'));
    });
  });

  test('Qty.toPlain drops trailing zeros', () {
    expect(Qty.parse('12.500').toPlain(), '12.5');
    expect(Qty.parse('10').toPlain(), '10');
    expect(Qty.parse('0.125').toPlain(), '0.125');
  });
}
