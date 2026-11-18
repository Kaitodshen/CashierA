import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/admin.dart';
import 'package:cashiera/core/design_system/widgets/buttons.dart';
import 'package:cashiera/core/design_system/widgets/data_display.dart';
import 'package:cashiera/core/design_system/widgets/glass.dart';
import 'package:cashiera/core/design_system/widgets/glass_table.dart';
import 'package:cashiera/core/design_system/widgets/toasts.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/features/back_office/data/purchasing_repository.dart';
import 'package:cashiera/features/back_office/presentation/admin_shifts_screen.dart';
import 'package:cashiera/features/back_office/presentation/back_office_providers.dart';
import 'package:cashiera/features/back_office/presentation/purchasing_widgets.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

final _at = DateFormat('dd/MM/yyyy HH:mm');

Color transferStatusColor(String status) => switch (status) {
  'received' => AppColors.success,
  'approved' || 'in_transit' => AppColors.info,
  'rejected' || 'cancelled' => AppColors.error,
  _ => AppColors.warning,
};

StatusTone transferStatusTone(String status) => switch (status) {
  'received' => StatusTone.success,
  'approved' || 'in_transit' => StatusTone.primary,
  'rejected' || 'cancelled' => StatusTone.error,
  _ => StatusTone.warning,
};

/// Stock transfers between stores: incoming and outgoing.
class TransfersScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<TransfersScreen> createState() => _TransfersScreenState();
}

class _TransfersScreenState extends ConsumerState<TransfersScreen> {
  String? _storeId;
  String? _direction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final transfers = ref.watch(
      transfersProvider(storeId: _storeId, direction: _direction),
    );
    final list = transfers.value ?? const <TransferListRow>[];
    final canRequest =
        ref.watch(principalProvider).value?.can('transfer.request') ?? false;
    final muted = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: AppColors.textMuted);
    return AdminPage(
      toolbar: AdminToolbar(
        filters: [
          StoreFilter(
            value: _storeId,
            onChanged: (v) => setState(() {
              _storeId = v;
              if (v == null) _direction = null;
            }),
          ),
          for (final d in const [null, 'in', 'out'])
            ChoiceChip(
              key: Key('transfer-dir-${d ?? 'all'}'),
              label: Text(switch (d) {
                'in' => l10n.transferIncoming,
                'out' => l10n.transferOutgoing,
                _ => l10n.auditAll,
              }),
              selected: _direction == d,
              showCheckmark: false,
              onSelected: _storeId == null && d != null
                  ? null
                  : (_) => setState(() => _direction = d),
            ),
        ],
        actions: [
          if (canRequest)
            PrimaryButton(
              key: const Key('transfer-new'),
              onPressed: () async {
                final id = await showDialog<String>(
                  context: context,
                  builder: (_) => const _RequestTransferDialog(),
                );
                if (id != null && context.mounted) {
                  ref.invalidate(transfersProvider);
                  context.go(AppRoutes.adminTransfer(id));
                }
              },
              icon: Icons.add,
              label: l10n.transferNew,
            ),
        ],
      ),
      children: [
        if (transfers.isLoading && list.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (transfers.hasError)
          adminMessage(
            icon: Icons.cloud_off_outlined,
            message: l10n.commonError('${transfers.error}'),
          )
        else if (list.isEmpty)
          adminMessage(icon: Icons.swap_horiz, message: l10n.transferEmpty)
        else
          GlassTable<TransferListRow>(
            rows: list,
            onRowTap: (t) => context.go(AppRoutes.adminTransfer(t.id)),
            columns: [
              GlassColumn(
                label: l10n.navTransfers,
                flex: 4,
                cell: (t) => Column(
                  key: Key('transfer-${t.number}'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${t.number} · ${t.fromStore} → ${t.toStore}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      [
                        _at.format(t.requestedAt.toLocal()),
                        ?t.requestedBy,
                        l10n.purchaseLines(t.lines),
                      ].join(' · '),
                      style: muted,
                    ),
                  ],
                ),
              ),
              GlassColumn(
                label: l10n.adminColStatus,
                flex: 2,
                cell: (t) => StatusChip(
                  label: l10n.transferStatus(t.status),
                  tone: transferStatusTone(t.status),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// The receiving store asks another store for stock.
class _RequestTransferDialog extends ConsumerStatefulWidget {
  const new();

  @override
  ConsumerState<_RequestTransferDialog> createState() =>
      _RequestTransferDialogState();
}

class _RequestTransferDialogState
    extends ConsumerState<_RequestTransferDialog> {
  String? _from;
  String? _to;
  final _lines = <(StockVariant, TextEditingController)>[];
  final _note = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    for (final (_, c) in _lines) {
      c.dispose();
    }
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (_from == null || _to == null || _from == _to || _lines.isEmpty) {
      setState(() => _error = l10n.transferIncomplete);
      return;
    }
    final quantities = <String, Qty>{};
    for (final (v, c) in _lines) {
      final q = parseQtyText(c.text);
      if (q == null || q.milli <= 0) {
        setState(() => _error = l10n.purchaseQtyInvalid(v.name));
        return;
      }
      quantities[v.id] = q;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final id = await ref
          .read(purchasingProvider)
          .requestTransfer(
            fromStoreId: _from!,
            toStoreId: _to!,
            quantities: quantities,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
      if (mounted) Navigator.pop(context, id);
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = l10n.commonError('$e');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stores = ref.watch(backOfficeStoresProvider).value ?? const [];
    DropdownButton<String> store(
      Key key,
      String hint,
      String? value,
      ValueChanged<String?> onChanged,
    ) => DropdownButton<String>(
      key: key,
      isExpanded: true,
      hint: Text(hint),
      value: value,
      items: [
        for (final s in stores)
          DropdownMenuItem(value: s.id, child: Text('${s.code} · ${s.name}')),
      ],
      onChanged: onChanged,
    );
    return AlertDialog(
      title: Text(l10n.transferNew),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              store(
                const Key('transfer-from'),
                l10n.transferFrom,
                _from,
                (v) => setState(() => _from = v),
              ),
              store(
                const Key('transfer-to'),
                l10n.transferTo,
                _to,
                (v) => setState(() => _to = v),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final (i, (v, c)) in _lines.indexed)
                Row(
                  children: [
                    Expanded(child: Text([v.name, ?v.sku].join(' · '))),
                    SizedBox(
                      width: 90,
                      child: TextField(
                        key: Key('transfer-qty-${v.id}'),
                        controller: c,
                        textAlign: TextAlign.end,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: qtyInputFormatters,
                        decoration: InputDecoration(suffixText: v.unit),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() {
                        _lines.removeAt(i).$2.dispose();
                      }),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              TextButton.icon(
                key: const Key('transfer-add-item'),
                onPressed: () async {
                  final v = await pickStockVariant(
                    context,
                    exclude: {for (final (v, _) in _lines) v.id},
                  );
                  if (v != null) {
                    setState(
                      () => _lines.add((v, TextEditingController(text: '1'))),
                    );
                  }
                },
                icon: const Icon(Icons.add),
                label: Text(l10n.purchaseAddItem),
              ),
              TextField(
                controller: _note,
                decoration: InputDecoration(labelText: l10n.closeNote),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          key: const Key('transfer-submit'),
          onPressed: _busy ? null : _submit,
          child: Text(l10n.transferSubmit),
        ),
      ],
    );
  }
}

/// One transfer with the actions its status and the person allow.
class TransferScreen extends ConsumerStatefulWidget {
  const new({required this.transferId, super.key});
  final String transferId;

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  bool _busy = false;

  Future<void> _transition(
    TransferDetail t,
    String status, {
    Map<String, Qty>? quantities,
    String? note,
  }) async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      await ref
          .read(purchasingProvider)
          .transition(t.id, status, quantities: quantities, note: note);
      ref
        ..invalidate(transferProvider(t.id))
        ..invalidate(transfersProvider)
        ..invalidate(stockVariantsProvider);
      if (mounted) AppToast.success(context, l10n.transferStatus(status));
    } on Exception catch (e) {
      if (mounted) AppToast.error(context, l10n.commonError('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _ship(TransferDetail t) async {
    final l10n = context.l10n;
    final q = await showQuantitiesDialog(
      context,
      title: l10n.transferShipTitle(t.number),
      confirm: l10n.transferShip,
      lines: [
        for (final l in t.lines) (l.variantId, l.name, l.requested, null),
      ],
    );
    if (q != null) await _transition(t, 'in_transit', quantities: q);
  }

  Future<void> _receive(TransferDetail t) async {
    final l10n = context.l10n;
    final q = await showQuantitiesDialog(
      context,
      title: l10n.transferReceiveTitle(t.number),
      confirm: l10n.purchaseReceive,
      lines: [
        for (final l in t.lines)
          (l.variantId, l.name, l.shipped ?? l.requested, l.shipped),
      ],
    );
    if (q != null) await _transition(t, 'received', quantities: q);
  }

  Future<void> _reject(TransferDetail t) async {
    final l10n = context.l10n;
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.transferReject),
        content: TextField(
          key: const Key('transfer-reject-reason'),
          controller: reason,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.transferRejectReason),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, reason.text.trim().length >= 3),
            child: Text(l10n.transferReject),
          ),
        ],
      ),
    );
    final text = reason.text.trim();
    reason.dispose();
    if (ok ?? false) await _transition(t, 'rejected', note: text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final detail = ref.watch(transferProvider(widget.transferId));
    final principal = ref.watch(principalProvider).value;
    final canApprove = principal?.can('transfer.approve') ?? false;
    final canReceive = principal?.can('inventory.receive') ?? false;
    final canRequest = principal?.can('transfer.request') ?? false;
    return switch (detail) {
      AsyncError(:final error) => AdminPage(
        children: [
          adminMessage(
            icon: Icons.cloud_off_outlined,
            message: l10n.commonError('$error'),
          ),
        ],
      ),
      AsyncData(value: final t) => AdminPage(
        toolbar: AdminToolbar(
          filters: [
            SecondaryButton(
              key: const Key('transfer-back'),
              onPressed: () => context.go(AppRoutes.adminTransfers),
              icon: Icons.arrow_back,
              label: l10n.commonBack,
            ),
            Text(t.number, style: theme.textTheme.titleLarge),
            StatusChip(
              key: const Key('transfer-status'),
              label: l10n.transferStatus(t.status),
              tone: transferStatusTone(t.status),
            ),
          ],
          actions: [
            if (canApprove && t.status == 'requested') ...[
              PrimaryButton(
                key: const Key('transfer-approve'),
                onPressed: _busy ? null : () => _transition(t, 'approved'),
                icon: Icons.check,
                label: l10n.transferApprove,
              ),
              SecondaryButton(
                key: const Key('transfer-reject'),
                onPressed: _busy ? null : () => _reject(t),
                icon: Icons.block,
                label: l10n.transferReject,
              ),
            ],
            if (canApprove && t.status == 'approved')
              PrimaryButton(
                key: const Key('transfer-ship'),
                onPressed: _busy ? null : () => _ship(t),
                icon: Icons.local_shipping_outlined,
                label: l10n.transferShip,
              ),
            if (canReceive && t.status == 'in_transit')
              PrimaryButton(
                key: const Key('transfer-receive'),
                onPressed: _busy ? null : () => _receive(t),
                icon: Icons.inventory_outlined,
                label: l10n.purchaseReceive,
              ),
            if ((canRequest || canApprove) &&
                (t.status == 'requested' || t.status == 'approved'))
              TextButton.icon(
                key: const Key('transfer-cancel'),
                onPressed: _busy ? null : () => _transition(t, 'cancelled'),
                icon: const Icon(Icons.cancel_outlined),
                label: Text(l10n.transferCancel),
              ),
          ],
        ),
        children: [
          Text(
            '${t.fromStore} → ${t.toStore}',
            style: theme.textTheme.titleMedium,
          ),
          if (t.note != null) Text(t.note!),
          if (t.rejectReason != null)
            Text(
              l10n.transferRejectedBecause(t.rejectReason!),
              style: const TextStyle(color: AppColors.error),
            ),
          const SizedBox(height: AppSpacing.md),
          GlassTable<TransferLine>(
            rows: t.lines,
            columns: [
              GlassColumn(
                label: l10n.colProduct,
                flex: 3,
                cell: (l) => Text([l.name, ?l.sku].join(' · ')),
              ),
              GlassColumn(
                label: l10n.transferRequested,
                numeric: true,
                cell: (l) => Text(l.requested.toPlain()),
              ),
              GlassColumn(
                label: l10n.transferShipped,
                numeric: true,
                cell: (l) => Text(l.shipped?.toPlain() ?? '–'),
              ),
              GlassColumn(
                label: l10n.purchaseReceivedCol,
                numeric: true,
                cell: (l) => Text(
                  l.received?.toPlain() ?? '–',
                  key: Key('transfer-received-${l.variantId}'),
                  style: TextStyle(
                    color:
                        l.received != null &&
                            l.shipped != null &&
                            l.received!.milli != l.shipped!.milli
                        ? AppColors.error
                        : null,
                  ),
                ),
              ),
              GlassColumn(
                label: l10n.transferSenderStock,
                numeric: true,
                cell: (l) => Text(l.stockAtSender?.toPlain() ?? '–'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.transferHistory, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          GlassCard(
            level: GlassLevel.solid,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              children: [
                for (final e in const [
                  'requested',
                  'approved',
                  'shipped',
                  'received',
                  'rejected',
                  'cancelled',
                ])
                  if (t.events[e] case final ev?)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.history),
                      title: Text(l10n.transferEvent(e)),
                      subtitle: Text(
                        [_at.format(ev.at.toLocal()), ?ev.by].join(' · '),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}
