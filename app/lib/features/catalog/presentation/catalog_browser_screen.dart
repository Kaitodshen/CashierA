import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/catalog/catalog_item.dart';
import 'package:cashiera/core/catalog/catalog_sync.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/empty_state.dart';
import 'package:cashiera/core/design_system/widgets/toasts.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/providers.dart';
import 'package:cashiera/core/session/session_controller.dart';
import 'package:cashiera/features/catalog/presentation/catalog_providers.dart';
import 'package:cashiera/features/catalog/presentation/stock_adjust_dialog.dart';
import 'package:cashiera/features/pos_home/presentation/widgets/terminal_status_chip.dart';
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
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
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
    _search.clear();
    ref.read(catalogQueryProvider.notifier).setSearch('');
    await _openItem(item);
  }

  Future<void> _openItem(CatalogItem item) => showModalBottomSheet<void>(
    context: context,
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final items = ref.watch(catalogItemsProvider);
    final categories = ref.watch(catalogCategoriesProvider).value ?? const [];
    final query = ref.watch(catalogQueryProvider);
    final sync = ref.watch(catalogSyncProvider);
    final staff = ref.watch(sessionControllerProvider).value?.staff;
    final list = items.value ?? const <CatalogItem>[];

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.pos)),
        title: Text(l10n.catalogTitle),
        actions: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: TerminalStatusChip(),
          ),
          if (staff?.can('inventory.opname') ?? false)
            TextButton.icon(
              onPressed: () => context.go(AppRoutes.opname),
              icon: const Icon(Icons.fact_check_outlined),
              label: Text(l10n.opnameTitle),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: TextField(
              key: const Key('catalog-search'),
              controller: _search,
              autofocus: true,
              decoration: InputDecoration(
                hintText: l10n.catalogSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: const Icon(Icons.qr_code_scanner),
              ),
              onChanged: ref.read(catalogQueryProvider.notifier).setSearch,
              onSubmitted: _onSubmitted,
            ),
          ),
          SizedBox(
            height: AppSizes.minTouch + AppSpacing.sm,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: [
                _CategoryChip(
                  label: l10n.catalogAll,
                  selected: query.categoryId == null,
                  onTap: () =>
                      ref.read(catalogQueryProvider.notifier).setCategory(null),
                ),
                for (final c in categories)
                  _CategoryChip(
                    label: c.name,
                    color: _parseColor(c.color),
                    selected: query.categoryId == c.id,
                    onTap: () => ref
                        .read(catalogQueryProvider.notifier)
                        .setCategory(c.id),
                  ),
              ],
            ),
          ),
          Expanded(
            child: items.isLoading
                ? Skeletonizer(
                    child: _ItemList(items: _placeholders, onTap: (_) {}),
                  )
                : list.isEmpty
                ? EmptyState(
                    icon: Icons.inventory_2_outlined,
                    message: query.search.isEmpty && query.categoryId == null
                        ? l10n.catalogEmpty
                        : l10n.catalogNoMatch,
                    action: query.search.isEmpty && query.categoryId == null
                        ? OutlinedButton.icon(
                            onPressed: _refresh,
                            icon: const Icon(Icons.cloud_download_outlined),
                            label: Text(l10n.catalogRefresh),
                          )
                        : null,
                  )
                : _ItemList(items: list, onTap: _openItem),
          ),
        ],
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

Color? _parseColor(String? hex) {
  if (hex == null || !RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(hex)) return null;
  return Color(int.parse('FF${hex.substring(1)}', radix: 16));
}

class _CategoryChip extends StatelessWidget {
  const new({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        avatar: color == null
            ? null
            : CircleAvatar(backgroundColor: color, radius: 6),
      ),
    );
  }
}

class _ItemList extends StatelessWidget {
  const new({required this.items, required this.onTap});

  final List<CatalogItem> items;
  final ValueChanged<CatalogItem> onTap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) => _ItemTile(item: items[i], onTap: onTap),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const new({required this.item, required this.onTap});

  final CatalogItem item;
  final ValueChanged<CatalogItem> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Card(
      key: Key('catalog-item-${item.sku}'),
      child: ListTile(
        onTap: () => onTap(item),
        title: Text(
          item.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          [
            item.sku,
            if (item.trackStock)
              l10n.catalogStock(item.stock.toPlain(), item.unitCode),
          ].join(' · '),
          style: TextStyle(color: item.isLow ? AppColors.warning : null),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              item.price.format(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (item.isLow)
              Text(
                l10n.catalogLow,
                style: const TextStyle(color: AppColors.warning, fontSize: 12),
              ),
          ],
        ),
      ),
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
