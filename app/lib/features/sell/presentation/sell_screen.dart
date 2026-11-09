import 'dart:async';

import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/app/shell/terminal_search.dart';
import 'package:cashiera/core/catalog/catalog_item.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/buttons.dart';
import 'package:cashiera/core/design_system/widgets/data_display.dart';
import 'package:cashiera/core/design_system/widgets/empty_state.dart';
import 'package:cashiera/core/design_system/widgets/glass.dart';
import 'package:cashiera/core/design_system/widgets/inputs.dart';
import 'package:cashiera/core/design_system/widgets/toasts.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/pos/cart.dart';
import 'package:cashiera/core/pos/money_input.dart';
import 'package:cashiera/core/pos/pos_services.dart';
import 'package:cashiera/core/providers.dart';
import 'package:cashiera/core/session/session_controller.dart';
import 'package:cashiera/features/sell/presentation/cart_panel.dart';
import 'package:cashiera/features/sell/presentation/sell_dialogs.dart';
import 'package:cashiera/features/sell/presentation/sell_providers.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Below this content width the bill moves into a sheet behind a bottom bar.
/// Measured inside the terminal shell, so a 1280 px tablet (1040 px next to
/// the sidebar) keeps both panes.
const _twoPaneWidth = 760.0;

/// Category filter value for the store's favorites.
const favoritesFilter = '__favorites__';

final sellQueryProvider =
    NotifierProvider<SellQuery, ({String search, String? categoryId})>(
      SellQuery.new,
    );

class SellQuery extends Notifier<({String search, String? categoryId})> {
  @override
  ({String search, String? categoryId}) build() =>
      (search: '', categoryId: null);

  void setSearch(String value) =>
      state = (search: value, categoryId: state.categoryId);

  void setCategory(String? id) =>
      state = (search: state.search, categoryId: id);
}

final StreamProvider<List<CatalogItem>>
sellItemsProvider = StreamProvider.autoDispose<List<CatalogItem>>((ref) {
  final q = ref.watch(sellQueryProvider);
  final favorites = q.categoryId == favoritesFilter;
  return ref
      .watch(terminalCatalogProvider)
      .watchItems(search: q.search, categoryId: favorites ? null : q.categoryId)
      .map(
        (items) => favorites
            ? (items.where((i) => i.favoriteOrder != null).toList()
                ..sort((a, b) => a.favoriteOrder!.compareTo(b.favoriteOrder!)))
            : items,
      );
});

/// Adds [item] to the bill: asks for modifiers or a weight first when the
/// product needs them.
Future<void> addToCart(
  BuildContext context,
  WidgetRef ref,
  CatalogItem item,
) async {
  final cart = ref.read(cartControllerProvider.notifier);
  var modifiers = const <CartModifier>[];
  if (item.hasModifiers) {
    final groups = await ref
        .read(terminalCatalogProvider)
        .modifierGroups(item.productId);
    if (!context.mounted) return;
    if (groups.isNotEmpty) {
      final chosen = await showModifierSheet(
        context,
        item: item,
        groups: groups,
      );
      if (chosen == null) return;
      modifiers = chosen;
    }
  }
  Qty? quantity;
  if (item.allowDecimal) {
    if (!context.mounted) return;
    quantity = await showQuantityDialog(
      context,
      itemName: item.displayName,
      unitCode: item.unitCode,
      allowDecimal: true,
    );
    if (quantity == null) return;
  }
  cart.add(item, quantity: quantity, modifiers: modifiers);
}

class SellScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final shift = ref.watch(openShiftProvider);

    final body = switch (shift) {
      AsyncData(value: null) => const _OpenShiftPanel(),
      AsyncData() => LayoutBuilder(
        builder: (context, c) => c.maxWidth >= _twoPaneWidth
            ? const Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _ProductPane()),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 16, 16, 16),
                    child: SizedBox(width: 420, child: CartPanel()),
                  ),
                ],
              )
            : const Column(
                children: [
                  Expanded(child: _ProductPane()),
                  _CartBar(),
                ],
              ),
      ),
      AsyncError(:final error) => Center(
        child: Text(l10n.commonError('$error')),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };

    // The shell's top bar holds the title, search and held orders.
    return Scaffold(body: body);
  }
}

class _ProductPane extends ConsumerStatefulWidget {
  const new();

  @override
  ConsumerState<_ProductPane> createState() => _ProductPaneState();
}

class _ProductPaneState extends ConsumerState<_ProductPane> {
  @override
  void initState() {
    super.initState();
    // The grid follows the top-bar field, which starts empty here.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(sellQueryProvider.notifier).setSearch('');
    });
  }

  /// A scanner types the code and Enter: add that item straight away.
  Future<void> _submit(String text) async {
    final code = text.trim();
    if (code.isEmpty) return;
    final item = await ref.read(terminalCatalogProvider).findByCode(code);
    if (!mounted) return;
    if (item == null) {
      AppToast.error(context, context.l10n.sellNotFound(code));
    } else {
      await addToCart(context, ref, item);
      if (!mounted) return;
      ref.read(terminalSearchProvider.notifier).clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // The top-bar field: typing filters, Enter (a scanner) adds the item.
    ref.listen(terminalSearchProvider, (previous, next) {
      if (next.query != previous?.query) {
        ref.read(sellQueryProvider.notifier).setSearch(next.query);
      }
      if (next.submissions != previous?.submissions) {
        unawaited(_submit(next.lastSubmitted));
      }
    });
    final query = ref.watch(sellQueryProvider);
    final categories = ref.watch(_categoriesProvider).value ?? const [];
    final items = ref.watch(sellItemsProvider);
    final categoryNames = {for (final c in categories) c.id: c.name};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: ChipTabs<String?>(
            items: [
              (null, l10n.catalogAll),
              (favoritesFilter, l10n.sellFavorites),
              for (final c in categories) (c.id, c.name),
            ],
            selected: query.categoryId,
            onSelected: ref.read(sellQueryProvider.notifier).setCategory,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            0,
          ),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  l10n.sellItemsTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              StatusChip(label: l10n.sellItemsCount(items.value?.length ?? 0)),
            ],
          ),
        ),
        Expanded(
          child: switch (items) {
            AsyncData(value: final list) when list.isEmpty => EmptyState(
              icon: Icons.inventory_2_outlined,
              message: l10n.catalogNoMatch,
            ),
            AsyncData(value: final list) => GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisExtent: 268,
                crossAxisSpacing: AppSpacing.lg,
                mainAxisSpacing: AppSpacing.lg,
              ),
              itemCount: list.length,
              itemBuilder: (context, i) => _ProductTile(
                item: list[i],
                category: categoryNames[list[i].categoryId],
              ),
            ),
            AsyncError(:final error) => Center(
              child: Text(l10n.commonError('$error')),
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ],
    );
  }
}

final StreamProvider<List<CatalogCategory>> _categoriesProvider =
    StreamProvider.autoDispose(
      (ref) => ref.watch(terminalCatalogProvider).watchCategories(),
    );

class _ProductTile extends ConsumerWidget {
  const new({required this.item, this.category});

  final CatalogItem item;
  final String? category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final add = item.isAvailable ? () => addToCart(context, ref, item) : null;
    final badge = !item.isAvailable
        ? StatusChip(label: l10n.sellUnavailable)
        : item.trackStock
        ? StatusChip(
            label: l10n.sellStockBadge(item.stock.toPlain()),
            tone: item.isLow ? StatusTone.warning : StatusTone.neutral,
          )
        : null;
    return GlassCard(
      key: Key('sell-item-${item.sku}'),
      radius: AppRadius.tile,
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: add,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 104,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ProductThumb(name: item.productName, fill: true),
                if (badge != null) Positioned(left: 6, top: 6, child: badge),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 14,
            child: Text(
              (category ?? '').toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: Text(
              item.displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.sellPriceLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        item.allowDecimal
                            ? '${item.price.format()}/${item.unitCode}'
                            : item.price.format(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontFeatures: AppTypography.tabular,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _AddButton(
                key: Key('sell-add-${item.sku}'),
                tooltip: l10n.sellAddTooltip,
                onTap: add,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The rose square + on a product tile (40 dp inside a 48 dp hit area).
class _AddButton extends StatelessWidget {
  const new({required this.tooltip, required this.onTap, super.key});

  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.control - 2);
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: SizedBox.square(
          dimension: AppSizes.minTouch,
          child: Center(
            child: Opacity(
              opacity: onTap == null ? 0.4 : 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryPressed],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const SizedBox.square(
                  dimension: 40,
                  child: Icon(Icons.add, color: AppColors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Phone layout: totals and the pay button, the bill opens in a sheet.
class _CartBar extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final cart = ref.watch(cartControllerProvider);
    final bill = ref.watch(currentBillProvider(discountLabels(l10n)));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.7),
        border: Border(
          top: BorderSide(color: AppColors.white.withValues(alpha: 0.9)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  key: const Key('sell-open-cart'),
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    // Over the shell's bottom bar, not inside it.
                    useRootNavigator: true,
                    isScrollControlled: true,
                    builder: (_) => SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.9,
                      child: const CartPanel(inSheet: true),
                    ),
                  ),
                  icon: const Icon(Icons.shopping_basket_outlined),
                  label: Text(
                    l10n.sellCartSummary(
                      cart.itemCount,
                      (bill?.grandTotal ?? Money.zero).format(),
                    ),
                  ),
                ),
              ),
              PrimaryButton(
                key: const Key('sell-pay-bar'),
                label: l10n.sellPay,
                onPressed: cart.isEmpty
                    ? null
                    : () => context.go(AppRoutes.pay),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// No shift yet: open one with the opening cash in the drawer.
class _OpenShiftPanel extends ConsumerStatefulWidget {
  const new();

  @override
  ConsumerState<_OpenShiftPanel> createState() => _OpenShiftPanelState();
}

class _OpenShiftPanelState extends ConsumerState<_OpenShiftPanel> {
  final _cash = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _busy = false;

  @override
  void dispose() {
    _cash.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    if (!_form.currentState!.validate()) return;
    final session = ref.read(sessionControllerProvider).value;
    final staff = session?.staff;
    final device = session?.device;
    if (staff == null || device == null) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(shiftServiceProvider)
          .open(
            storeId: device.storeId,
            staff: staff,
            openingCash: Money(parseRupiah(_cash.text) ?? 0),
          );
      ref.read(syncSchedulerProvider.notifier).syncNow().ignore();
    } on PosPermissionException {
      if (mounted) AppToast.error(context, context.l10n.shiftNoPermission);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final staff = ref.watch(sessionControllerProvider).value?.staff;
    final canOpen = staff?.can('shift.manage') ?? false;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: GlassCard(
            level: GlassLevel.solid,
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.point_of_sale,
                    size: 48,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.shiftOpenTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    canOpen ? l10n.shiftOpenHint : l10n.shiftNoPermission,
                    textAlign: TextAlign.center,
                  ),
                  if (canOpen) ...[
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      key: const Key('shift-opening-cash'),
                      controller: _cash,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: rupiahInputFormatters,
                      decoration: InputDecoration(
                        labelText: l10n.shiftOpeningCash,
                        prefixText: 'Rp ',
                      ),
                      validator: (v) => parseRupiah(v ?? '') == null
                          ? l10n.commonRequired
                          : null,
                      onFieldSubmitted: (_) => _open(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      key: const Key('shift-open'),
                      label: l10n.shiftOpen,
                      expand: true,
                      onPressed: _busy ? null : _open,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
