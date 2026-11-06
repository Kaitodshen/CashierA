import 'dart:convert';
import 'dart:typed_data';

import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/toasts.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/features/back_office/data/catalog_files.dart';
import 'package:cashiera/features/back_office/presentation/back_office_providers.dart';
import 'package:cashiera/features/back_office/presentation/import_issue_text.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Catalog import (CSV/XLSX → preview → all-or-nothing import) and export.
class ImportScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  String? _fileName;
  CatalogImport? _result;
  bool _busy = false;

  Future<List<String>> _storeCodes() async =>
      (await ref.read(backOfficeStoresProvider.future))
          .map((s) => s.code)
          .toList();

  String _stamp() => DateFormat('yyyyMMdd-HHmm').format(DateTime.now());

  Future<void> _run(Future<void> Function() body) async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      await body();
    } on BackendException catch (e) {
      if (mounted) AppToast.error(context, l10n.commonError(e.toString()));
    } on FormatException catch (e) {
      if (mounted) AppToast.error(context, l10n.importFileError(e.message));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _downloadTemplate() => _run(() async {
    final codes = await _storeCodes();
    final csv = encodeCatalogCsv(_templateRows(codes), codes);
    await _save('template-katalog.csv', utf8.encode(csv), csvMime);
  });

  Future<void> _export({required bool xlsx}) => _run(() async {
    final codes = await _storeCodes();
    final rows = await ref.read(catalogAdminProvider).exportCatalog();
    final bytes = xlsx
        ? encodeCatalogXlsx(rows, codes)
        : Uint8List.fromList(utf8.encode(encodeCatalogCsv(rows, codes)));
    await _save(
      'katalog-${_stamp()}.${xlsx ? 'xlsx' : 'csv'}',
      bytes,
      xlsx ? xlsxMime : csvMime,
    );
  });

  Future<void> _save(String name, List<int> bytes, String mime) async {
    final saved = await saveBytes(name, Uint8List.fromList(bytes), mime);
    if (saved && mounted) AppToast.success(context, context.l10n.importSaved);
  }

  Future<void> _pick() => _run(() async {
    final file = await pickCatalogFile();
    if (file == null) return;
    final (name, bytes) = file;
    final units = await ref.read(adminUnitsProvider.future);
    final codes = await _storeCodes();
    final result = parseCatalogTable(
      readCatalogFile(name, bytes),
      unitCodes: units.map((u) => u.code).toSet(),
      storeCodes: codes.toSet(),
    );
    setState(() {
      _fileName = name;
      _result = result;
    });
  });

  Future<void> _import() => _run(() async {
    final result = _result;
    if (result == null || !result.isValid) return;
    final summary = await ref
        .read(catalogAdminProvider)
        .importCatalog(result.rows);
    ref
      ..invalidate(adminProductsProvider)
      ..invalidate(adminCategoriesProvider)
      ..invalidate(stockOverviewProvider);
    if (!mounted) return;
    AppToast.success(
      context,
      context.l10n.importDone(
        summary.count('variants_created'),
        summary.count('variants_updated'),
        summary.count('stock_lines'),
      ),
    );
    setState(() {
      _result = null;
      _fileName = null;
    });
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canImport =
        ref.watch(principalProvider).value?.can('catalog.manage') ?? false;
    final result = _result;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(l10n.importTitle, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.importHelp),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            OutlinedButton.icon(
              onPressed: _busy ? null : _downloadTemplate,
              icon: const Icon(Icons.description_outlined),
              label: Text(l10n.importDownloadTemplate),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _export(xlsx: false),
              icon: const Icon(Icons.download_outlined),
              label: Text(l10n.importExportCsv),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _export(xlsx: true),
              icon: const Icon(Icons.grid_on_outlined),
              label: Text(l10n.importExportXlsx),
            ),
            if (canImport)
              FilledButton.icon(
                key: const Key('import-pick'),
                onPressed: _busy ? null : _pick,
                icon: const Icon(Icons.upload_file),
                label: Text(l10n.importPick),
              ),
          ],
        ),
        if (_busy) ...[
          const SizedBox(height: AppSpacing.lg),
          const LinearProgressIndicator(),
        ],
        if (result != null) ...[
          const SizedBox(height: AppSpacing.xl),
          ImportPreview(
            fileName: _fileName ?? '',
            result: result,
            onImport: _busy || !result.isValid ? null : _import,
          ),
        ],
      ],
    );
  }
}

/// Summary, problems and the first rows of a parsed file.
class ImportPreview extends StatelessWidget {
  const new({
    required this.fileName,
    required this.result,
    required this.onImport,
    super.key,
  });

  final String fileName;
  final CatalogImport result;
  final VoidCallback? onImport;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(fileName, style: theme.textTheme.titleMedium),
            Text(l10n.importPreview(result.rows.length, result.productCount)),
            if (result.issues.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.importIssues(result.issues.length),
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              for (final issue in result.issues.take(100))
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text('• ${importIssueText(l10n, issue)}'),
                ),
            ],
            if (result.rows.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text(l10n.productName)),
                    DataColumn(label: Text(l10n.variantName)),
                    DataColumn(label: Text(l10n.variantSku)),
                    DataColumn(label: Text(l10n.productCategory)),
                    DataColumn(label: Text(l10n.variantPrice), numeric: true),
                    DataColumn(label: Text(l10n.navStock)),
                  ],
                  rows: [
                    for (final r in result.rows.take(20))
                      DataRow(
                        cells: [
                          DataCell(Text(r.productName)),
                          DataCell(Text(r.variantName)),
                          DataCell(Text(r.sku)),
                          DataCell(Text(r.category)),
                          DataCell(Text(Money(r.price).format())),
                          DataCell(
                            Text(
                              r.stock.entries
                                  .map((e) => '${e.key} ${e.value.toPlain()}')
                                  .join(', '),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              key: const Key('import-run'),
              onPressed: onImport,
              icon: const Icon(Icons.cloud_upload_outlined),
              label: Text(l10n.importRun(result.rows.length)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Example rows for the downloadable template (same as docs/templates).
List<CatalogExportRow> _templateRows(List<String> storeCodes) {
  Map<String, Qty> stock(List<String> values) => {
    for (final (i, code) in storeCodes.indexed)
      if (i < values.length) code: Qty.parse(values[i]),
  };
  return [
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
      stock: stock(['48', '40', '35']),
    ),
    CatalogExportRow(
      productName: 'Beras Premium 5 kg',
      variantName: 'Default',
      sku: 'SMB-BRS-5KG',
      barcode: '2000000000213',
      category: 'Sembako',
      unit: 'pcs',
      price: 78000,
      cost: 70000,
      taxable: false,
      trackStock: true,
      reorderPoint: Qty.parse('5'),
      stock: stock(['20', '15', '12']),
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
      reorderPoint: Qty.parse('5'),
      stock: stock(['12.5', '10', '8.75']),
    ),
  ];
}
