import 'dart:async';

import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/app/shell/terminal_search.dart';
import 'package:cashiera/core/catalog/catalog_item.dart';
import 'package:cashiera/core/catalog/catalog_sync.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/buttons.dart';
import 'package:cashiera/core/design_system/widgets/data_display.dart';
import 'package:cashiera/core/design_system/widgets/empty_state.dart';
import 'package:cashiera/core/design_system/widgets/glass.dart';
import 'package:cashiera/core/design_system/widgets/glass_table.dart';
import 'package:cashiera/core/design_system/widgets/inputs.dart';
import 'package:cashiera/core/design_system/widgets/toasts.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/providers.dart';
import 'package:cashiera/core/session/session_controller.dart';
import 'package:cashiera/features/catalog/presentation/catalog_providers.dart';
import 'package:cashiera/features/catalog/presentation/stock_adjust_dialog.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Terminal product browser: search (or scan), filter by category, see the
/// store price and stock, record stock in/out. Works offline.
class CatalogBrowserScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<CatalogBrowserScreen> createState() =>
      _CatalogBrowserScreenState();
}

class _CatalogBrowserScreenState extends ConsumerState<CatalogBrowserScreen> {
  @override
  void initState() {
    super.initState();
    // The list follows the top-bar field, which starts empty here.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(catalogQueryProvider.notifier).setSearch('');
    });
  }

  /// Barcode scanners type the code and press Enter: open the exact match.
  Future<void> _onSubmitted(String text) async {
    final l10n = context.l10n;
    final item = await ref.read(terminalCatalogProvider).findByCode(text);
    if (!mounted) return;
    if (item == null) {
      if (text.trim().isNotEmpty) {
        AppToast.info(context, l10n.catalogCodeNotFound(text.trim()));
      }
      return;
    }
    ref.read(terminalSearchProvider.notifier).clear();
    await _openItem(item);
  }

  Future<void> _openItem(CatalogItem item) => showGlassSheet<void>(
    context,
    showDragHandle: true,
    builder: (_) => _ItemSheet(item: item),
  );

  Future<void> _refresh() async {
    final l10n = context.l10n;
    final summary = await ref.read(catalogSyncProvider.notifier).refresh();
    if (!mounted) return;
    final error = ref.read(catalogSyncProvider).error;
    if (summary != null) {
      AppToast.success(context, l10n.catalogSynced(summary.rows));
    } else if (error != null) {
      AppToast.error(context, l10n.commonError(error));
    }
  }

  StockFilter _stockFilter = StockFilter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // The top-bar field: typing filters, Enter (a scanner) opens the item.
    ref.listen(terminalSearchProvider, (previous, next) {
      if (next.query != previous?.query) {
        ref.read(catalogQueryProvider.notifier).setSearch(next.query);
      }
      if (next.submissions != previous?.submissions) {
        unawaited(_onSubmitted(next.lastSubmitted));
      }
    });
    final locale = Localizations.localeOf(context).toLanguageTag();
    final items = ref.watch(catalogItemsProvider);
    final categories = ref.watch(catalogCategoriesProvider).value ?? const [];
    final query = ref.watch(catalogQueryProvider);
    final sync = ref.watch(catalogSyncProvider);
    final staff = ref.watch(sessionControllerProvider).value?.staff;
    final all = items.value ?? const <CatalogItem>[];
    final list = [
      for (final i in all)
        if (matchesStockFilter(i, _stockFilter)) i,
    ];
    final categoryNames = {for (final c in categories) c.id: c.name};
    final unfiltered =
        query.search.isEmpty &&
        query.categoryId == null &&
        _stockFilter == StockFilter.all;

    // The shell's top bar holds the search; this is the stock table.
    return Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              PageHeader(
                title: l10n.catalogTitle,
                status: Text(
                  l10n.catalogHeaderCount(
                    all.length,
                    all.where((i) => i.isLow).length,
                  ),
                ),
                actions: [
                  if (staff?.can('inventory.opname') ?? false)
                    SecondaryButton(
                      key: const Key('catalog-opname'),
                      label: l10n.opnameTitle,
                      icon: Icons.fact_check_outlined,
                      onPressed: () => context.go(AppRoutes.opname),
                    ),
                  IconButton(
                    tooltip: sync.lastPulledAt == null
                        ? l10n.catalogRefresh
                        : l10n.catalogLastSync(
                            DateFormat.Hm(locale).format(sync.lastPulledAt!),
                          ),
                    onPressed: sync.running ? null : _refresh,
                    icon: sync.running
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_download_outlined),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              GlassCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ChipTabs<String?>(
                      items: [
                        (null, l10n.catalogAll),
                        for (final c in categories) (c.id, c.name),
                      ],
                      selected: query.categoryId,
                      onSelected: (id) => ref
                          .read(catalogQueryProvider.notifier)
                          .setCategory(id),
                    ),
                    // Three segments are wider than a phone card: scroll.
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SegmentedTabs<StockFilter>(
                        items: [
                          (StockFilter.all, l10n.stockFilterAll),
                          (StockFilter.low, l10n.stockFilterLow),
                          (StockFilter.out, l10n.stockFilterOut),
                        ],
                        selected: _stockFilter,
                        onSelected: (f) => setState(() => _stockFilter = f),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (items.isLoading)
                Skeletonizer(
                  child: _ItemTable(
                    items: _placeholders,
                    categoryNames: const {},
                    onTap: (_) {},
                  ),
                )
              else if (list.isEmpty)
                GlassCard(
                  child: EmptyState(
                    icon: Icons.inventory_2_outlined,
                    message: unfiltered
                        ? l10n.catalogEmpty
                        : l10n.catalogNoMatch,
                    action: unfiltered
                        ? SecondaryButton(
                            onPressed: _refresh,
                            icon: Icons.cloud_download_outlined,
                            label: l10n.catalogRefresh,
                          )
                        : null,
                  ),
                )
              else
                _ItemTable(
                  items: list,
                  categoryNames: categoryNames,
                  onTap: _openItem,
                ),
            ],
          ),
        ),
      ),
    );
  }

  static final List<CatalogItem> _placeholders = List.generate(
    8,
    (i) => CatalogItem(
      variantId: '$i',
      productId: '$i',
      productName: 'Nama produk contoh',
      variantName: 'Default',
      sku: 'SKU-0000',
      barcode: null,
      categoryId: null,
      unitCode: 'pcs',
      allowDecimal: false,
      basePrice: const Money(10000),
      priceOverride: null,
      isTaxable: true,
      trackStock: true,
      stock: const Qty(10000),
      reorderPoint: null,
      isAvailable: true,
    ),
  );
}

/// The stock-status filter above the catalog table.
enum StockFilter { all, low, out }

bool matchesStockFilter(CatalogItem i, StockFilter f) => switch (f) {
  StockFilter.all => true,
  StockFilter.low => i.trackStock && i.isLow,
  StockFilter.out => i.trackStock && i.stock.milli <= 0,
};

StatusTone _stockTone(CatalogItem i) => i.stock.milli <= 0
    ? StatusTone.error
    : i.isLow
    ? StatusTone.warning
    : StatusTone.success;

/// Fill of the stock bar: stock against three times the reorder point (a
/// full bar is "comfortably stocked"); full when there is no reorder point.
double _stockFraction(CatalogItem i) {
  final reorder = i.reorderPoint?.milli ?? 0;
  if (reorder <= 0) return i.stock.milli > 0 ? 1 : 0;
  return i.stock.milli / (reorder * 3);
}

class _ItemTable extends StatelessWidget {
  const new({
    required this.items,
    required this.categoryNames,
    required this.onTap,
  });

  final List<CatalogItem> items;
  final Map<String, String> categoryNames;
  final ValueChanged<CatalogItem> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: AppColors.textMuted,
    );
    return GlassTable<CatalogItem>(
      rows: items,
      onRowTap: onTap,
      columns: [
        GlassColumn(
          label: l10n.catalogColProduct,
          flex: 4,
          cell: (i) => Row(
            key: Key('catalog-item-${i.sku}'),
            children: [
              ProductThumb(name: i.productName, size: 40),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      i.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (i.variantName != 'Default')
                      Text(
                        i.variantName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: muted,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        GlassColumn(
          label: l10n.catalogColSku,
          flex: 2,
          cell: (i) => Text(
            [i.sku, ?i.barcode].join('\n'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: muted?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        GlassColumn(
          label: l10n.catalogColCategory,
          flex: 2,
          cell: (i) {
            final name = categoryNames[i.categoryId];
            return name == null
                ? const Text('—')
                : StatusChip(label: name, tone: StatusTone.primary);
          },
        ),
        GlassColumn(
          label: l10n.catalogColStock,
          flex: 2,
          cell: (i) => !i.trackStock
              ? const Text('—')
              : SizedBox(
                  width: 120,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${i.stock.toPlain()} ${i.unitCode}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _stockTone(i).text,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      StockBar(
                        fraction: _stockFraction(i),
                        tone: _stockTone(i),
                      ),
                    ],
                  ),
                ),
        ),
        GlassColumn(
          label: l10n.catalogColPrice,
          flex: 2,
          numeric: true,
          cell: (i) => MoneyText(
            i.price,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _ItemSheet extends ConsumerWidget {
  const new({required this.item});

  final CatalogItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final staff = ref.watch(sessionControllerProvider).value?.staff;
    final canAdjust =
        item.trackStock && (staff?.can('inventory.adjust') ?? false);

    Future<void> adjust({required bool increase}) async {
      final saved = await showDialog<bool>(
        context: context,
        builder: (_) => StockAdjustDialog(item: item, increase: increase),
      );
      if ((saved ?? false) && context.mounted) Navigator.of(context).pop();
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.displayName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${item.sku}${item.barcode == null ? '' : ' · ${item.barcode}'}',
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              item.price.format(),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            if (item.trackStock) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.catalogStock(item.stock.toPlain(), item.unitCode),
                style: TextStyle(
                  color: item.isLow ? AppColors.warning : null,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (canAdjust) ...[
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      key: const Key('item-stock-in'),
                      onPressed: () => adjust(increase: true),
                      icon: const Icon(Icons.add_box_outlined),
                      label: Text(l10n.stockIn),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('item-stock-out'),
                      onPressed: () => adjust(increase: false),
                      icon: const Icon(Icons.indeterminate_check_box_outlined),
                      label: Text(l10n.stockOut),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
