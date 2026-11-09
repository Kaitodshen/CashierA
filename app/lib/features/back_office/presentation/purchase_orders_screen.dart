import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/empty_state.dart';
import 'package:cashiera/core/design_system/widgets/toasts.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/pos/money_input.dart';
import 'package:cashiera/features/back_office/data/catalog_files.dart';
import 'package:cashiera/features/back_office/data/purchasing_repository.dart';
import 'package:cashiera/features/back_office/presentation/admin_shifts_screen.dart';
import 'package:cashiera/features/back_office/presentation/back_office_providers.dart';
import 'package:cashiera/features/back_office/presentation/purchasing_widgets.dart';
import 'package:cashiera/features/reports/data/report_export.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

final _day = DateFormat('dd/MM/yyyy');

Color poStatusColor(String status) => switch (status) {
  'received' => AppColors.success,
  'partially_received' || 'ordered' => AppColors.success,
  'cancelled' => AppColors.error,
  _ => AppColors.warning,
};

/// Purchase orders of the stores the person may see.
class PurchaseOrdersScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<PurchaseOrdersScreen> createState() =>
      _PurchaseOrdersScreenState();
}

class _PurchaseOrdersScreenState extends ConsumerState<PurchaseOrdersScreen> {
  String? _storeId;
  String? _status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final orders = ref.watch(
      purchaseOrdersProvider(storeId: _storeId, status: _status),
    );
    final list = orders.value ?? const <PoListRow>[];
    final canEdit =
        ref.watch(principalProvider).value?.can('purchase.manage') ?? false;
    return Scaffold(
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              key: const Key('po-new'),
              onPressed: () => context.go(AppRoutes.adminPurchaseOrder('new')),
              icon: const Icon(Icons.add),
              label: Text(l10n.purchaseNew),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StoreFilter(
                  value: _storeId,
                  onChanged: (v) => setState(() => _storeId = v),
                ),
                for (final s in const [
                  null,
                  'draft',
                  'ordered',
                  'partially_received',
                  'received',
                  'cancelled',
                ])
                  ChoiceChip(
                    label: Text(s == null ? l10n.auditAll : l10n.poStatus(s)),
                    selected: _status == s,
                    onSelected: (_) => setState(() => _status = s),
                  ),
              ],
            ),
          ),
          Expanded(
            child: orders.isLoading && list.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : orders.hasError
                ? Center(child: Text(l10n.commonError('${orders.error}')))
                : list.isEmpty
                ? EmptyState(
                    icon: Icons.local_shipping_outlined,
                    message: l10n.purchaseEmpty,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      96,
                    ),
                    itemCount: list.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) {
                      final po = list[i];
                      return Card(
                        child: ListTile(
                          key: Key('po-${po.number}'),
                          title: Text('${po.number} · ${po.supplierName}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                [
                                  po.storeCode,
                                  l10n.poStatus(po.status),
                                  l10n.purchaseLines(po.lines),
                                  if (po.expectedDate != null)
                                    l10n.purchaseExpectedShort(
                                      _day.format(
                                        DateTime.parse(po.expectedDate!),
                                      ),
                                    ),
                                ].join(' · '),
                              ),
                              if (po.status == 'partially_received' ||
                                  po.status == 'received')
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: LinearProgressIndicator(
                                    value: po.receivedRatio,
                                    color: poStatusColor(po.status),
                                  ),
                                ),
                            ],
                          ),
                          trailing: Text(
                            po.total.format(),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          onTap: () =>
                              context.go(AppRoutes.adminPurchaseOrder(po.id)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// A purchase order: the editor for a new or still-editable one, or the
/// detail with receiving.
class PurchaseOrderScreen extends ConsumerStatefulWidget {
  const new({required this.purchaseOrderId, super.key});

  /// `new` creates one.
  final String purchaseOrderId;

  @override
  ConsumerState<PurchaseOrderScreen> createState() =>
      _PurchaseOrderScreenState();
}

class _PurchaseOrderScreenState extends ConsumerState<PurchaseOrderScreen> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (widget.purchaseOrderId == 'new') return const _PoEditor();
    final detail = ref.watch(purchaseOrderProvider(widget.purchaseOrderId));
    return switch (detail) {
      AsyncData(value: final po) =>
        _editing
            ? _PoEditor(
                existing: po,
                onDone: () => setState(() => _editing = false),
              )
            : _PoDetailView(
                po: po,
                onEdit: () => setState(() => _editing = true),
              ),
      AsyncError(:final error) => Center(
        child: Text(l10n.commonError('$error')),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _PoDetailView extends ConsumerStatefulWidget {
  const new({required this.po, required this.onEdit});
  final PoDetail po;
  final VoidCallback onEdit;

  @override
  ConsumerState<_PoDetailView> createState() => _PoDetailViewState();
}

class _PoDetailViewState extends ConsumerState<_PoDetailView> {
  bool _busy = false;

  /// Runs [action]; its result is the success message.
  Future<void> _run(Future<String> Function() action) async {
    setState(() => _busy = true);
    try {
      final done = await action();
      ref
        ..invalidate(purchaseOrderProvider(widget.po.id))
        ..invalidate(purchaseOrdersProvider)
        ..invalidate(stockVariantsProvider);
      if (mounted) AppToast.success(context, done);
    } on Exception catch (e) {
      if (mounted) AppToast.error(context, context.l10n.commonError('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _receive() async {
    final l10n = context.l10n;
    final po = widget.po;
    final open = [
      for (final l in po.lines)
        if (l.open.milli > 0) l,
    ];
    final quantities = await showReceiveDialog(
      context,
      title: l10n.purchaseReceiveTitle(po.number),
      confirm: l10n.purchaseReceive,
      lines: [for (final l in open) (l.id, l.name, l.open, l.open)],
      costs: {for (final l in open) l.id: l.unitCost},
    );
    if (quantities == null) return;
    await _run(() async {
      final number = await ref
          .read(purchasingProvider)
          .receive(po.id, quantities);
      return l10n.purchaseReceived(number);
    });
  }

  Future<void> _pdf() async {
    final l10n = context.l10n;
    final po = widget.po;
    final table = ReportTable(
      title: l10n.purchasePdfTitle(po.number),
      subtitle: [
        po.supplierName,
        ?po.supplierPhone,
        po.storeName,
        _day.format(DateTime.parse(po.orderDate)),
        if (po.expectedDate != null)
          l10n.purchaseExpectedShort(_day.format(po.expectedDate!)),
      ].join(' · '),
      columns: [
        l10n.colProduct,
        l10n.colSku,
        l10n.colQty,
        l10n.purchaseUnit,
        l10n.purchaseCost,
        l10n.totalRow,
      ],
      rows: [
        for (final l in po.lines)
          [
            TextCell(l.name),
            TextCell(l.sku ?? ''),
            QtyCell(l.ordered),
            TextCell(l.unit),
            MoneyCell(l.unitCost),
            MoneyCell(l.lineTotal),
          ],
      ],
      totals: [
        TextCell(l10n.totalRow),
        const TextCell(''),
        const TextCell(''),
        const TextCell(''),
        const TextCell(''),
        MoneyCell(po.total),
      ],
    );
    final bytes = await buildReportPdf(
      table,
      printedAt: [?po.note, po.createdBy ?? ''].join(' · '),
    );
    await saveBytes('${po.number}.pdf', bytes, 'application/pdf');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final po = widget.po;
    final principal = ref.watch(principalProvider).value;
    final canEdit = principal?.can('purchase.manage') ?? false;
    final canReceive = principal?.can('inventory.receive') ?? false;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: [
            IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () => context.go(AppRoutes.adminPurchaseOrders),
              icon: const Icon(Icons.arrow_back),
            ),
            Expanded(
              child: Text(
                '${po.number} · ${po.supplierName}',
                style: theme.textTheme.titleLarge,
              ),
            ),
            Chip(
              key: const Key('po-status'),
              label: Text(l10n.poStatus(po.status)),
              side: BorderSide(color: poStatusColor(po.status)),
            ),
          ],
        ),
        Text(
          [
            po.storeName,
            _day.format(DateTime.parse(po.orderDate)),
            if (po.expectedDate != null)
              l10n.purchaseExpectedShort(_day.format(po.expectedDate!)),
            ?po.note,
          ].join(' · '),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            if (canEdit && po.editable)
              OutlinedButton.icon(
                key: const Key('po-edit'),
                onPressed: _busy ? null : widget.onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: Text(l10n.commonEdit),
              ),
            if (canEdit && po.status == 'draft')
              FilledButton.icon(
                key: const Key('po-order'),
                onPressed: _busy
                    ? null
                    : () => _run(() async {
                        await ref
                            .read(purchasingProvider)
                            .setPurchaseOrderStatus(po.id, 'ordered');
                        return l10n.purchaseOrdered;
                      }),
                icon: const Icon(Icons.send_outlined),
                label: Text(l10n.purchaseOrder),
              ),
            if (canReceive && po.receivable)
              FilledButton.icon(
                key: const Key('po-receive'),
                onPressed: _busy ? null : _receive,
                icon: const Icon(Icons.inventory_outlined),
                label: Text(l10n.purchaseReceive),
              ),
            OutlinedButton.icon(
              key: const Key('po-pdf'),
              onPressed: _busy ? null : _pdf,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: Text(l10n.exportPdf),
            ),
            if (canEdit && po.editable)
              TextButton.icon(
                key: const Key('po-cancel'),
                onPressed: _busy
                    ? null
                    : () => _run(() async {
                        await ref
                            .read(purchasingProvider)
                            .setPurchaseOrderStatus(po.id, 'cancelled');
                        return l10n.purchaseCancelled;
                      }),
                icon: const Icon(Icons.cancel_outlined),
                label: Text(l10n.purchaseCancel),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(label: Text(l10n.colProduct)),
                DataColumn(label: Text(l10n.purchaseOrderedCol), numeric: true),
                DataColumn(
                  label: Text(l10n.purchaseReceivedCol),
                  numeric: true,
                ),
                DataColumn(label: Text(l10n.purchaseCost), numeric: true),
                DataColumn(label: Text(l10n.totalRow), numeric: true),
              ],
              rows: [
                for (final l in po.lines)
                  DataRow(
                    cells: [
                      DataCell(Text([l.name, ?l.sku].join(' · '))),
                      DataCell(Text('${l.ordered.toPlain()} ${l.unit}')),
                      DataCell(
                        Text(
                          l.received.toPlain(),
                          style: TextStyle(
                            color: l.open.milli == 0 ? AppColors.success : null,
                          ),
                        ),
                      ),
                      DataCell(Text(l.unitCost.format())),
                      DataCell(Text(l.lineTotal.format())),
                    ],
                  ),
                DataRow(
                  cells: [
                    DataCell(Text(l10n.totalRow)),
                    const DataCell(Text('')),
                    const DataCell(Text('')),
                    const DataCell(Text('')),
                    DataCell(
                      Text(
                        po.total.format(),
                        key: const Key('po-total'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (po.receipts.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.purchaseReceipts, style: theme.textTheme.titleMedium),
          Card(
            child: Column(
              children: [
                for (final r in po.receipts)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.inventory_outlined),
                    title: Text(r.number),
                    subtitle: Text(
                      [
                        DateFormat('dd/MM/yyyy HH:mm').format(r.at.toLocal()),
                        ?r.by,
                        l10n.purchaseLines(r.lines),
                      ].join(' · '),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PoEditor extends ConsumerStatefulWidget {
  const new({this.existing, this.onDone});
  final PoDetail? existing;
  final VoidCallback? onDone;

  @override
  ConsumerState<_PoEditor> createState() => _PoEditorState();
}

class _PoEditorState extends ConsumerState<_PoEditor> {
  late String? _storeId = widget.existing?.storeId;
  late String? _supplierId = widget.existing?.supplierId;
  late DateTime? _expected = widget.existing?.expectedDate;
  late final _note = TextEditingController(text: widget.existing?.note);
  final _lines = <PoLineDraft>[];
  bool _seeded = false;
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _seed(List<StockVariant> variants) {
    if (_seeded || widget.existing == null || variants.isEmpty) return;
    _seeded = true;
    final byId = {for (final v in variants) v.id: v};
    for (final l in widget.existing!.lines) {
      _lines.add(
        PoLineDraft(
          variant:
              byId[l.variantId] ??
              StockVariant(
                id: l.variantId,
                name: l.name,
                sku: l.sku,
                cost: l.unitCost,
                unit: l.unit,
              ),
          quantity: l.ordered,
          unitCost: l.unitCost,
        ),
      );
    }
  }

  Future<void> _add() async {
    final v = await pickStockVariant(
      context,
      exclude: {for (final l in _lines) l.variant.id},
    );
    if (v == null) return;
    setState(
      () => _lines.add(
        PoLineDraft(variant: v, quantity: Qty.one, unitCost: v.cost),
      ),
    );
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    if (_storeId == null || _supplierId == null || _lines.isEmpty) {
      AppToast.error(context, l10n.purchaseIncomplete);
      return;
    }
    if (_lines.any((l) => l.quantity.milli <= 0)) {
      AppToast.error(context, l10n.purchaseQtyNone);
      return;
    }
    setState(() => _busy = true);
    try {
      final id = await ref
          .read(purchasingProvider)
          .savePurchaseOrder(
            id: widget.existing?.id,
            storeId: _storeId!,
            supplierId: _supplierId!,
            expectedDate: _expected,
            note: _note.text,
            lines: _lines,
          );
      ref
        ..invalidate(purchaseOrdersProvider)
        ..invalidate(purchaseOrderProvider(id));
      if (!mounted) return;
      AppToast.success(context, l10n.commonSaved);
      widget.onDone?.call();
      context.go(AppRoutes.adminPurchaseOrder(id));
    } on Exception catch (e) {
      if (mounted) AppToast.error(context, l10n.commonError('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stores = ref.watch(backOfficeStoresProvider).value ?? const [];
    final suppliers = (ref.watch(adminSuppliersProvider).value ?? const [])
        .where((s) => s.isActive || s.id == _supplierId)
        .toList();
    _seed(ref.watch(stockVariantsProvider).value ?? const []);
    final total = _lines.fold(Money.zero, (a, l) => a + l.total);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: [
            IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () => widget.existing == null
                  ? context.go(AppRoutes.adminPurchaseOrders)
                  : widget.onDone?.call(),
              icon: const Icon(Icons.arrow_back),
            ),
            Text(
              widget.existing?.number ?? l10n.purchaseNew,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DropdownButton<String>(
              key: const Key('po-store'),
              hint: Text(l10n.colStore),
              value: _storeId,
              items: [
                for (final s in stores)
                  DropdownMenuItem(
                    value: s.id,
                    child: Text('${s.code} · ${s.name}'),
                  ),
              ],
              onChanged: widget.existing == null
                  ? (v) => setState(() => _storeId = v)
                  : null,
            ),
            DropdownButton<String>(
              key: const Key('po-supplier'),
              hint: Text(l10n.purchaseSupplier),
              value: _supplierId,
              items: [
                for (final s in suppliers)
                  DropdownMenuItem(value: s.id, child: Text(s.name)),
              ],
              onChanged: (v) => setState(() => _supplierId = v),
            ),
            OutlinedButton.icon(
              key: const Key('po-expected'),
              onPressed: () async {
                final now = clock.now();
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime(now.year - 1),
                  lastDate: DateTime(now.year + 1, 12, 31),
                  initialDate: _expected ?? now,
                );
                if (picked != null) setState(() => _expected = picked);
              },
              icon: const Icon(Icons.event_outlined),
              label: Text(
                _expected == null
                    ? l10n.purchaseExpected
                    : l10n.purchaseExpectedShort(_day.format(_expected!)),
              ),
            ),
          ],
        ),
        TextField(
          controller: _note,
          decoration: InputDecoration(labelText: l10n.closeNote),
        ),
        const SizedBox(height: AppSpacing.lg),
        Card(
          child: Column(
            children: [
              for (final (i, l) in _lines.indexed)
                _LineRow(
                  key: ValueKey(l.variant.id),
                  line: l,
                  onChanged: () => setState(() {}),
                  onRemove: () => setState(() => _lines.removeAt(i)),
                ),
              ListTile(
                leading: const Icon(Icons.add),
                title: Text(l10n.purchaseAddItem),
                onTap: _add,
                key: const Key('po-add-item'),
              ),
            ],
          ),
        ),
        ListTile(
          title: Text(l10n.totalRow),
          trailing: Text(
            total.format(),
            key: const Key('po-editor-total'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            key: const Key('po-save'),
            onPressed: _busy ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(l10n.commonSave),
          ),
        ),
      ],
    );
  }
}

class _LineRow extends StatefulWidget {
  const new({
    required this.line,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  final PoLineDraft line;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  State<_LineRow> createState() => _LineRowState();
}

class _LineRowState extends State<_LineRow> {
  late final _qty = TextEditingController(text: widget.line.quantity.toPlain());
  late final _cost = TextEditingController(
    text: '${widget.line.unitCost.rupiah}',
  );

  @override
  void dispose() {
    _qty.dispose();
    _cost.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.line;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(child: Text([l.variant.name, ?l.variant.sku].join(' · '))),
          SizedBox(
            width: 90,
            child: TextField(
              key: Key('po-qty-${l.variant.id}'),
              controller: _qty,
              textAlign: TextAlign.end,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: qtyInputFormatters,
              decoration: InputDecoration(suffixText: l.variant.unit),
              onChanged: (v) {
                l.quantity = parseQtyText(v) ?? Qty.zero;
                widget.onChanged();
              },
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 110,
            child: TextField(
              key: Key('po-cost-${l.variant.id}'),
              controller: _cost,
              textAlign: TextAlign.end,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(prefixText: 'Rp '),
              onChanged: (v) {
                l.unitCost = Money(parseRupiah(v) ?? 0);
                widget.onChanged();
              },
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(l.total.format(), textAlign: TextAlign.end),
          ),
          IconButton(
            onPressed: widget.onRemove,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}
