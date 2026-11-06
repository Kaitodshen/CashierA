import 'dart:async';

import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/catalog/qty_input.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/empty_state.dart';
import 'package:cashiera/core/design_system/widgets/toasts.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/features/back_office/data/back_office_backend.dart';
import 'package:cashiera/features/back_office/data/catalog_admin_models.dart';
import 'package:cashiera/features/back_office/presentation/back_office_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _moneyPattern = RegExp(r'^\d{1,12}$');
final _skuPattern = RegExp(r'^[A-Za-z0-9._-]{1,40}$');

/// Create or edit a product with its variants and per-store settings.
/// Owners edit; everyone else sees it read-only.
class ProductEditorScreen extends ConsumerStatefulWidget {
  const new({required this.productId, super.key});

  /// A product id, or `new`.
  final String productId;

  @override
  ConsumerState<ProductEditorScreen> createState() =>
      _ProductEditorScreenState();
}

class _ProductEditorScreenState extends ConsumerState<ProductEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  ProductDraft? _draft;
  Object? _loadError;
  bool _saving = false;

  bool get _isNew => widget.productId == 'new';

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final repo = ref.read(catalogAdminProvider);
    try {
      final draft = _isNew
          ? repo.newProduct(
              (await ref.read(adminUnitsProvider.future))
                  .firstWhere((u) => u.code == 'pcs')
                  .id,
            )
          : await repo.product(widget.productId);
      if (mounted) setState(() => _draft = draft);
    } on Object catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null || !_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    setState(() => _saving = true);
    try {
      await ref.read(catalogAdminProvider).saveProduct(draft);
      ref.invalidate(adminProductsProvider);
      if (!mounted) return;
      AppToast.success(context, l10n.commonSaved);
      context.go(AppRoutes.adminProducts);
    } on BackendException catch (e) {
      if (mounted) {
        AppToast.error(context, l10n.productSaveFailed(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canEdit =
        ref.watch(principalProvider).value?.can('catalog.manage') ?? false;
    final draft = _draft;

    if (_loadError != null) {
      return EmptyState(
        icon: Icons.cloud_off_outlined,
        message: l10n.commonError('$_loadError'),
      );
    }
    if (draft == null) return const Center(child: CircularProgressIndicator());

    final categories = ref.watch(adminCategoriesProvider).value ?? const [];
    final units = ref.watch(adminUnitsProvider).value ?? const [];
    final stores = ref.watch(backOfficeStoresProvider).value ?? const [];

    return Scaffold(
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              key: const Key('product-save'),
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(l10n.commonSave),
            )
          : null,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            96,
          ),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => context.go(AppRoutes.adminProducts),
                  icon: const Icon(Icons.arrow_back),
                ),
                Text(
                  _isNew ? l10n.productNewTitle : l10n.productEditTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            if (!canEdit) Text(l10n.productsReadOnly),
            const SizedBox(height: AppSpacing.lg),
            _Section(
              children: [
                TextFormField(
                  key: const Key('product-name'),
                  initialValue: draft.name,
                  enabled: canEdit,
                  decoration: InputDecoration(labelText: l10n.productName),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? l10n.commonRequired : null,
                  onChanged: (v) => draft.name = v,
                ),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    SizedBox(
                      width: 280,
                      child: DropdownButtonFormField<String?>(
                        initialValue: draft.categoryId,
                        decoration: InputDecoration(
                          labelText: l10n.productCategory,
                        ),
                        items: [
                          DropdownMenuItem(child: Text(l10n.commonNone)),
                          for (final c in categories)
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                        ],
                        onChanged: canEdit
                            ? (v) => setState(() => draft.categoryId = v)
                            : null,
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: DropdownButtonFormField<String>(
                        initialValue: draft.unitId,
                        decoration: InputDecoration(
                          labelText: l10n.productUnit,
                        ),
                        items: [
                          for (final u in units)
                            DropdownMenuItem(
                              value: u.id,
                              child: Text('${u.name} (${u.code})'),
                            ),
                        ],
                        onChanged: canEdit
                            ? (v) => setState(
                                () => draft.unitId = v ?? draft.unitId,
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.productTaxable),
                  subtitle: Text(l10n.productTaxableHint),
                  value: draft.isTaxable,
                  onChanged: canEdit
                      ? (v) => setState(() => draft.isTaxable = v)
                      : null,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.productTrackStock),
                  value: draft.trackStock,
                  onChanged: canEdit
                      ? (v) => setState(() => draft.trackStock = v)
                      : null,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.commonActive),
                  value: draft.isActive,
                  onChanged: canEdit
                      ? (v) => setState(() => draft.isActive = v)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.productVariants,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (canEdit)
                  TextButton.icon(
                    onPressed: () => setState(
                      () => draft.variants.add(
                        ref.read(catalogAdminProvider).newVariant(),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.productAddVariant),
                  ),
              ],
            ),
            for (final variant in draft.variants.where((v) => v.isActive))
              Padding(
                key: ValueKey(variant.id),
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: _VariantCard(
                  variant: variant,
                  draft: draft,
                  stores: stores,
                  canEdit: canEdit,
                  canRemove: draft.variants.where((v) => v.isActive).length > 1,
                  onRemove: () => setState(() => variant.isActive = false),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const new({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, child) in children.indexed) ...[
              if (i > 0) const SizedBox(height: AppSpacing.md),
              child,
            ],
          ],
        ),
      ),
    );
  }
}

class _VariantCard extends StatelessWidget {
  const new({
    required this.variant,
    required this.draft,
    required this.stores,
    required this.canEdit,
    required this.canRemove,
    required this.onRemove,
  });

  final VariantDraft variant;
  final ProductDraft draft;
  final List<StoreSummary> stores;
  final bool canEdit;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String? money(String? v, {bool required = true}) {
      final value = v?.trim() ?? '';
      if (value.isEmpty) return required ? l10n.commonRequired : null;
      return _moneyPattern.hasMatch(value) ? null : l10n.validationMoney;
    }

    Widget field(
      String label,
      String initial,
      ValueChanged<String> onChanged, {
      FormFieldValidator<String>? validator,
      double width = 180,
      bool numeric = false,
    }) => SizedBox(
      width: width,
      child: TextFormField(
        initialValue: initial,
        enabled: canEdit,
        keyboardType: numeric ? TextInputType.number : null,
        decoration: InputDecoration(labelText: label),
        validator: validator,
        onChanged: onChanged,
      ),
    );

    return _Section(
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            field(l10n.variantName, variant.name, (v) => variant.name = v),
            field(
              l10n.variantSku,
              variant.sku,
              (v) => variant.sku = v,
              validator: (v) => _skuPattern.hasMatch(v?.trim() ?? '')
                  ? null
                  : l10n.validationSku,
            ),
            field(
              l10n.variantBarcode,
              variant.barcode ?? '',
              (v) => variant.barcode = v,
            ),
            field(
              l10n.variantPrice,
              variant.price == 0 ? '' : '${variant.price}',
              (v) => variant.price = int.tryParse(v.trim()) ?? 0,
              validator: money,
              numeric: true,
              width: 140,
            ),
            field(
              l10n.variantCost,
              variant.cost == 0 ? '' : '${variant.cost}',
              (v) => variant.cost = int.tryParse(v.trim()) ?? 0,
              validator: money,
              numeric: true,
              width: 140,
            ),
            if (canEdit && canRemove)
              IconButton(
                tooltip: l10n.variantRemove,
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
        if (stores.isNotEmpty)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(l10n.productStoreSettings),
            children: [
              for (final (store, setting) in [
                for (final s in stores) (s, draft.settingFor(s.id, variant.id)),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(width: 160, child: Text(store.name)),
                      field(
                        l10n.storePriceOverride,
                        '${setting.priceOverride ?? ''}',
                        (v) => setting.priceOverride = int.tryParse(v.trim()),
                        validator: (v) => money(v, required: false),
                        numeric: true,
                        width: 160,
                      ),
                      field(
                        l10n.storeReorderPoint,
                        setting.reorderPoint?.toPlain() ?? '',
                        (v) => setting.reorderPoint = parseQtyInput(
                          v,
                          allowDecimal: true,
                          allowZero: true,
                        ).qty,
                        validator: (v) =>
                            (v?.trim().isEmpty ?? true) ||
                                parseQtyInput(
                                      v!,
                                      allowDecimal: true,
                                      allowZero: true,
                                    ).qty !=
                                    null
                            ? null
                            : l10n.stockInvalidQty,
                        numeric: true,
                        width: 160,
                      ),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
