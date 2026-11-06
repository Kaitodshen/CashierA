import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/features/back_office/presentation/import_issue_text.dart';
import 'package:cashiera/features/back_office/presentation/import_screen.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

CatalogImport _parse(List<String> lines) => parseCatalogTable(
  decodeCsv(lines.join('\n')),
  unitCodes: const {'pcs', 'kg'},
  storeCodes: const {'PST'},
);

const _header =
    'product_name;variant_name;sku;barcode;category;unit;price;cost;'
    'taxable;track_stock;reorder_point;stock_PST';

void main() {
  group('importIssueText', () {
    final id = lookupAppLocalizations(const Locale('id'));
    final en = lookupAppLocalizations(const Locale('en'));

    test('row issues name the row and the value', () {
      const issue = ImportIssue(
        3,
        ImportIssueCode.unknownUnit,
        column: 'unit',
        value: 'karung',
      );
      expect(
        importIssueText(id, issue),
        'Baris 3: Satuan "karung" tidak dikenal.',
      );
      expect(importIssueText(en, issue), 'Row 3: Unknown unit "karung".');
    });

    test('file-level issues say "File"', () {
      const issue = ImportIssue(1, ImportIssueCode.emptyFile);
      expect(importIssueText(en, issue), startsWith('File: '));
    });

    test('every issue code has a message in both languages', () {
      for (final code in ImportIssueCode.values) {
        final issue = ImportIssue(2, code, column: 'price', value: 'x');
        expect(importIssueText(id, issue), isNot(endsWith(': ')));
        expect(importIssueText(en, issue), isNot(endsWith(': ')));
      }
    });
  });

  group('ImportPreview', () {
    Future<bool> pump(WidgetTester tester, CatalogImport result) async {
      var tapped = false;
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpLocalized(
        SingleChildScrollView(
          child: ImportPreview(
            fileName: 'katalog.csv',
            result: result,
            onImport: result.isValid ? () => tapped = true : null,
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('import-run')));
      await tester.pump();
      return tapped;
    }

    testWidgets('a valid file shows its rows and can be imported', (
      tester,
    ) async {
      final result = _parse([
        _header,
        [
          'Air Mineral;600 ml;MNM-AIR-600;2000000000015;Minuman;pcs',
          '4000;2600;ya;ya;10;24',
        ].join(';'),
        [
          'Bawang Merah;Per kg;SYR-BWM-KG;;Sayur;kg',
          '42000;34000;tidak;ya;2;12,5',
        ].join(';'),
      ]);
      expect(result.issues, isEmpty);
      expect(await pump(tester, result), isTrue);
      expect(find.text('2 baris · 2 produk'), findsOneWidget);
      expect(find.text('Rp 42.000'), findsOneWidget);
      expect(find.text('PST 12.5'), findsOneWidget);
      expect(find.text('Impor 2 baris'), findsOneWidget);
    });

    testWidgets('problems are listed and block the import', (tester) async {
      final result = _parse([
        _header,
        'Air Mineral;600 ml;MNM-AIR-600;;Minuman;karung;4000;2600;ya;ya;;',
      ]);
      expect(result.isValid, isFalse);
      expect(await pump(tester, result), isFalse);
      expect(find.text('1 masalah harus diperbaiki dulu'), findsOneWidget);
      expect(
        find.text('• Baris 2: Satuan "karung" tidak dikenal.'),
        findsOneWidget,
      );
    });
  });
}
