import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/catalog/qty_input.dart';
import 'package:cashiera/core/catalog/stock_service.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/empty_state.dart';
import 'package:cashiera/core/design_system/widgets/toasts.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/features/back_office/data/catalog_admin_models.dart';
import 'package:cashiera/features/back_office/presentation/back_office_providers.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Stock per store: low-stock filter, open alerts, movement history, and
/// stock in/out (validated server-side like terminal adjustments).
class StockScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends ConsumerState<StockScreen> {
  String? _storeId;
  bool _lowOnly = false;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stores = ref.watch(backOfficeStoresProvider).value ?? const [];
    final storeId = _storeId ?? stores.firstOrNull?.id;
    if (storeId == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final stock = ref.watch(stockOverviewProvider(storeId));
    final alerts = ref.watch(storeAlertsProvider(storeId)).value ?? const [];
    final term = _search.trim().toLowerCase();
    final rows = (stock.value ?? const <StockRow>[])
        .where((r) => !_lowOnly || r.isLow)
        .where(
          (r) =>
              term.isEmpty ||
              r.displayName.toLowerCase().contains(term) ||
              r.sku.toLowerCase().contains(term),
        )
        .toList();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref
            ..invalidate(stockOverviewProvider(storeId))
            ..invalidate(storeAlertsProvider(storeId));
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<String>(
                    initialValue: storeId,
                    decoration: InputDecoration(labelText: l10n.stockStore),
                    items: [
                      for (final s in stores)
                        DropdownMenuItem(value: s.id, child: Text(s.name)),
                    ],
                    onChanged: (v) => setState(() => _storeId = v),
                  ),
                ),
                SizedBox(
                  width: 280,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: l10n.catalogSearchHint,
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                FilterChip(
                  label: Text(l10n.stockLowOnly),
                  selected: _lowOnly,
                  onSelected: (v) => setState(() => _lowOnly = v),
                ),
              ],
            ),
            if (alerts.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _AlertsCard(alerts: alerts, storeId: storeId),
            ],
            const SizedBox(height: AppSpacing.lg),
            if (stock.hasError)
              EmptyState(
                icon: Icons.cloud_off_outlined,
                message: l10n.commonError('${stock.error}'),
              )
            else if (!stock.isLoading && rows.isEmpty)
              EmptyState(
                icon: Icons.warehouse_outlined,
                message: l10n.stockEmpty,
              )
            else
              Skeletonizer(
                enabled: stock.isLoading,
                child: Column(
                  children: [
                    for (final row in stock.isLoading ? _placeholders : rows)
                      _StockTile(row: row, storeId: storeId),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static final List<StockRow> _placeholders = List.generate(
    6,
    (i) => StockRow(
      variantId: '$i',
      productName: 'Nama produk contoh',
      variantName: 'Default',
      sku: 'SKU-0000',
      unitCode: 'pcs',
      quantity: const Qty(10000),
      reorderPoint: null,
      isLow: false,
    ),
  );
}

class _AlertsCard extends ConsumerWidget {
  const new({required this.alerts, required this.storeId});

  final List<AlertRow> alerts;
  final String storeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final principal = ref.watch(principalProvider).value;
    return Card(
      color: AppColors.warning.withValues(alpha: 0.08),
      child: ExpansionTile(
        leading: const Icon(Icons.warning_amber, color: AppColors.warning),
        title: Text(l10n.stockAlerts(alerts.length)),
        children: [
          for (final a in alerts)
            ListTile(
              dense: true,
              title: Text(a.message),
              subtitle: Text(
                '${a.type} · '
                '${DateFormat.yMMMd().add_Hm().format(a.createdAt)}',
              ),
              trailing: principal?.employeeId == null
                  ? null
                  : TextButton(
                      onPressed: () async {
                        try {
                          await ref
                              .read(catalogAdminProvider)
                              .resolveAlert(a.id, principal!.employeeId!);
                          ref.invalidate(storeAlertsProvider(storeId));
                        } on BackendException catch (e) {
                          if (context.mounted) {
                            AppToast.error(
                              context,
                              l10n.commonError(e.message),
                            );
                          }
                        }
                      },
                      child: Text(l10n.stockResolve),
                    ),
            ),
        ],
      ),
    );
  }
}

class _StockTile extends ConsumerWidget {
  const new({required this.row, required this.storeId});

  final StockRow row;
  final String storeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Card(
      child: ListTile(
        onTap: row.variantId.length < 4
            ? null
            : () => showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                isScrollControlled: true,
                builder: (_) => _MovementsSheet(row: row, storeId: storeId),
              ),
        title: Text(
          row.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          [
            row.sku,
            row.categoryName,
            if (row.reorderPoint != null)
              l10n.stockReorder(row.reorderPoint!.toPlain()),
          ].nonNulls.join(' · '),
        ),
        trailing: Text(
          '${row.quantity.toPlain()} ${row.unitCode}',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: row.isLow ? AppColors.warning : null,
          ),
        ),
      ),
    );
  }
}

class _MovementsSheet extends ConsumerWidget {
  const new({required this.row, required this.storeId});

  final StockRow row;
  final String storeId;

  String _typeLabel(AppLocalizations l10n, String type) => switch (type) {
    'initial' => l10n.movementType_initial,
    'sale' => l10n.movementType_sale,
    'sale_void' => l10n.movementType_sale_void,
    'refund' => l10n.movementType_refund,
    'purchase_receive' => l10n.movementType_purchase_receive,
    'adjustment' => l10n.movementType_adjustment,
    'waste' => l10n.movementType_waste,
    'opname' => l10n.movementType_opname,
    'transfer_out' => l10n.movementType_transfer_out,
    'transfer_in' => l10n.movementType_transfer_in,
    _ => type,
  };

  Future<void> _adjust(
    BuildContext context,
    WidgetRef ref,
    bool increase,
  ) async {
    final l10n = context.l10n;
    final principal = ref.read(principalProvider).value;
    if (principal?.employeeId == null) return;
    final result = await showDialog<(Qty, StockReason, String?)>(
      context: context,
      builder: (_) => _AdjustDialog(row: row, increase: increase),
    );
    if (result == null || !context.mounted) return;
    final (qty, reason, note) = result;
    try {
      await ref
          .read(catalogAdminProvider)
          .adjustStock(
            storeId: storeId,
            employeeId: principal!.employeeId!,
            variantId: row.variantId,
            delta: Qty(reason.increases ? qty.milli : -qty.milli),
            reason: reason.code,
            note: note,
          );
      ref
        ..invalidate(stockOverviewProvider(storeId))
        ..invalidate(stockMovementsProvider(storeId, row.variantId))
        ..invalidate(storeAlertsProvider(storeId));
      if (context.mounted) {
        AppToast.success(context, l10n.stockSaved(row.displayName));
      }
    } on BackendException catch (e) {
      if (context.mounted) AppToast.error(context, l10n.commonError(e.message));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final movements = ref.watch(stockMovementsProvider(storeId, row.variantId));
    final canAdjust =
        ref.watch(principalProvider).value?.can('inventory.adjust') ?? false;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          Text(row.displayName, style: Theme.of(context).textTheme.titleLarge),
          Text('${row.quantity.toPlain()} ${row.unitCode} · ${row.sku}'),
          if (canAdjust) ...[
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.md,
              children: [
                FilledButton.icon(
                  onPressed: () => _adjust(context, ref, true),
                  icon: const Icon(Icons.add_box_outlined),
                  label: Text(l10n.stockIn),
                ),
                OutlinedButton.icon(
                  onPressed: () => _adjust(context, ref, false),
                  icon: const Icon(Icons.indeterminate_check_box_outlined),
                  label: Text(l10n.stockOut),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Text(
            l10n.stockMovements,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          ...switch (movements) {
            AsyncData(:final value) when value.isEmpty => [
              Text(l10n.stockNoMovements),
            ],
            AsyncData(:final value) => [
              for (final m in value)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(_typeLabel(l10n, m.type)),
                  subtitle: Text(
                    [
                      DateFormat.yMMMd().add_Hm().format(m.createdAt),
                      if (m.note != null) m.note!,
                    ].join(' · '),
                  ),
                  trailing: Text(
                    '${m.delta.milli > 0 ? '+' : ''}${m.delta.toPlain()} → '
                    '${m.balance.toPlain()}',
                    style: TextStyle(
                      color: m.delta.milli < 0
                          ? AppColors.error
                          : AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
            AsyncError(:final error) => [Text(l10n.commonError('$error'))],
            _ => [const LinearProgressIndicator()],
          },
        ],
      ),
    );
  }
}

class _AdjustDialog extends StatefulWidget {
  const new({required this.row, required this.increase});

  final StockRow row;
  final bool increase;

  @override
  State<_AdjustDialog> createState() => _AdjustDialogState();
}

class _AdjustDialogState extends State<_AdjustDialog> {
  final _formKey = GlobalKey<FormState>();
  final _qty = TextEditingController();
  final _note = TextEditingController();
  late StockReason _reason = widget.increase
      ? StockReason.stockIn
      : StockReason.stockOut;

  @override
  void dispose() {
    _qty.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reasons = StockReason.values
        .where((r) => r.increases == widget.increase)
        .toList();
    String label(StockReason r) => switch (r) {
      StockReason.stockIn => l10n.reasonStockIn,
      StockReason.stockOut => l10n.reasonStockOut,
      StockReason.damaged => l10n.reasonDamaged,
      StockReason.expired => l10n.reasonExpired,
      StockReason.lost => l10n.reasonLost,
    };
    return AlertDialog(
      title: Text(widget.increase ? l10n.stockIn : l10n.stockOut),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.row.displayName),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _qty,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.stockQuantity,
                suffixText: widget.row.unitCode,
              ),
              validator: (v) =>
                  parseQtyInput(v ?? '', allowDecimal: true).qty == null
                  ? l10n.stockInvalidQty
                  : null,
            ),
            if (reasons.length > 1) ...[
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<StockReason>(
                initialValue: _reason,
                decoration: InputDecoration(labelText: l10n.stockReason),
                items: [
                  for (final r in reasons)
                    DropdownMenuItem(value: r, child: Text(label(r))),
                ],
                onChanged: (r) => setState(() => _reason = r ?? _reason),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _note,
              decoration: InputDecoration(labelText: l10n.stockNote),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final note = _note.text.trim();
            Navigator.of(context).pop((
              parseQtyInput(_qty.text, allowDecimal: true).qty!,
              _reason,
              note.isEmpty ? null : note,
            ));
          },
          child: Text(l10n.stockSave),
        ),
      ],
    );
  }
}
