import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/catalog/catalog_item.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/empty_state.dart';
import 'package:cashiera/core/design_system/widgets/toasts.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/pos/cart.dart';
import 'package:cashiera/core/pos/money_input.dart';
import 'package:cashiera/core/pos/pos_services.dart';
import 'package:cashiera/core/providers.dart';
import 'package:cashiera/core/session/session_controller.dart';
import 'package:cashiera/features/pos_home/presentation/widgets/terminal_status_chip.dart';
import 'package:cashiera/features/sell/presentation/cart_panel.dart';
import 'package:cashiera/features/sell/presentation/sell_dialogs.dart';
import 'package:cashiera/features/sell/presentation/sell_providers.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Below this width the bill moves into a sheet behind a bottom bar.
const _twoPaneWidth = 900.0;

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
    final held = ref.watch(heldOrdersProvider).value?.length ?? 0;
    final wide = MediaQuery.sizeOf(context).width >= _twoPaneWidth;

    final body = switch (shift) {
      AsyncData(value: null) => const _OpenShiftPanel(),
      AsyncData() =>
        wide
            ? const Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _ProductPane()),
                  VerticalDivider(width: 1),
                  SizedBox(width: 400, child: CartPanel()),
                ],
              )
            : const Column(
                children: [
                  Expanded(child: _ProductPane()),
                  _CartBar(),
                ],
              ),
      AsyncError(:final error) => Center(
        child: Text(l10n.commonError('$error')),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.pos)),
        title: Text(l10n.sellTitle),
        actions: [
          IconButton(
            key: const Key('sell-orders'),
            tooltip: l10n.ordersTitle,
            onPressed: () => context.go(AppRoutes.orders),
            icon: Badge(
              isLabelVisible: held > 0,
              label: Text('$held'),
              child: const Icon(Icons.receipt_long_outlined),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: TerminalStatusChip(),
          ),
        ],
      ),
      body: body,
    );
  }
}

class _ProductPane extends ConsumerStatefulWidget {
  const new();

  @override
  ConsumerState<_ProductPane> createState() => _ProductPaneState();
}

class _ProductPaneState extends ConsumerState<_ProductPane> {
  final _search = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _search.dispose();
    _focus.dispose();
    super.dispose();
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
      _search.clear();
      ref.read(sellQueryProvider.notifier).setSearch('');
    }
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final query = ref.watch(sellQueryProvider);
    final categories = ref.watch(_categoriesProvider).value ?? const [];
    final items = ref.watch(sellItemsProvider);

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
          child: TextField(
            key: const Key('sell-search'),
            controller: _search,
            focusNode: _focus,
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n.catalogSearchHint,
              prefixIcon: const Icon(Icons.qr_code_scanner),
              suffixIcon: query.search.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _search.clear();
                        ref.read(sellQueryProvider.notifier).setSearch('');
                      },
                      icon: const Icon(Icons.clear),
                    ),
            ),
            onChanged: ref.read(sellQueryProvider.notifier).setSearch,
            onSubmitted: _submit,
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            children: [
              for (final (id, name) in [
                (null, l10n.catalogAll),
                (favoritesFilter, l10n.sellFavorites),
                for (final c in categories) (c.id, c.name),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(name),
                    selected: query.categoryId == id,
                    onSelected: (_) =>
                        ref.read(sellQueryProvider.notifier).setCategory(id),
                  ),
                ),
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
                maxCrossAxisExtent: 180,
                mainAxisExtent: 112,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
              ),
              itemCount: list.length,
              itemBuilder: (context, i) => _ProductTile(item: list[i]),
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
  const new({required this.item});

  final CatalogItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('sell-item-${item.sku}'),
        onTap: item.isAvailable ? () => addToCart(context, ref, item) : null,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.displayName,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.allowDecimal
                          ? '${item.price.format()}/${item.unitCode}'
                          : item.price.format(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (!item.isAvailable)
                    Text(
                      l10n.sellUnavailable,
                      style: theme.textTheme.labelSmall,
                    )
                  else if (item.trackStock)
                    Text(
                      item.stock.toPlain(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: item.isLow ? AppColors.warning : null,
                      ),
                    ),
                ],
              ),
            ],
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
    return Material(
      elevation: 8,
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
              FilledButton(
                key: const Key('sell-pay-bar'),
                onPressed: cart.isEmpty
                    ? null
                    : () => context.go(AppRoutes.pay),
                child: Text(l10n.sellPay),
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
        child: Card(
          margin: const EdgeInsets.all(AppSpacing.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.point_of_sale, size: 48),
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
                    FilledButton(
                      key: const Key('shift-open'),
                      onPressed: _busy ? null : _open,
                      child: Text(l10n.shiftOpen),
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
