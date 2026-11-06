import 'package:cashiera/core/catalog/catalog_item.dart';
import 'package:cashiera/core/catalog/qty_input.dart';
import 'package:cashiera/core/catalog/stock_service.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/toasts.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/providers.dart';
import 'package:cashiera/core/session/session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Records stock in or out for one item, offline. Returns true when saved.
class StockAdjustDialog extends ConsumerStatefulWidget {
  const new({required this.item, required this.increase, super.key});

  final CatalogItem item;
  final bool increase;

  @override
  ConsumerState<StockAdjustDialog> createState() => _StockAdjustDialogState();
}

class _StockAdjustDialogState extends ConsumerState<StockAdjustDialog> {
  final _formKey = GlobalKey<FormState>();
  final _qty = TextEditingController();
  final _note = TextEditingController();
  late StockReason _reason = widget.increase
      ? StockReason.stockIn
      : StockReason.stockOut;
  bool _busy = false;

  @override
  void dispose() {
    _qty.dispose();
    _note.dispose();
    super.dispose();
  }

  String _reasonLabel(AppLocalizations l10n, StockReason r) => switch (r) {
    StockReason.stockIn => l10n.reasonStockIn,
    StockReason.stockOut => l10n.reasonStockOut,
    StockReason.damaged => l10n.reasonDamaged,
    StockReason.expired => l10n.reasonExpired,
    StockReason.lost => l10n.reasonLost,
  };

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    final session = ref.read(sessionControllerProvider).value;
    final device = session?.device;
    final staff = session?.staff;
    if (device == null || staff == null) return;
    final qty = parseQtyInput(
      _qty.text,
      allowDecimal: widget.item.allowDecimal,
    ).qty!;
    setState(() => _busy = true);
    try {
      await ref
          .read(stockServiceProvider)
          .adjust(
            storeId: device.storeId,
            deviceCode: device.deviceCode,
            staff: staff,
            variantId: widget.item.variantId,
            quantity: qty,
            reason: _reason,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
      unawaitedSync();
      if (!mounted) return;
      AppToast.success(context, l10n.stockSaved(widget.item.displayName));
      Navigator.of(context).pop(true);
    } on Exception catch (e) {
      if (mounted) AppToast.error(context, l10n.commonError('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Sends the queued adjustment right away when online.
  void unawaitedSync() {
    ref.read(syncSchedulerProvider.notifier).syncNow().ignore();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reasons = StockReason.values
        .where((r) => r.increases == widget.increase)
        .toList();
    return AlertDialog(
      title: Text(widget.increase ? l10n.stockIn : l10n.stockOut),
      content: Form(
        key: _formKey,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.item.displayName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                l10n.catalogStock(
                  widget.item.stock.toPlain(),
                  widget.item.unitCode,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                key: const Key('stock-qty'),
                controller: _qty,
                autofocus: true,
                keyboardType: TextInputType.numberWithOptions(
                  decimal: widget.item.allowDecimal,
                ),
                decoration: InputDecoration(
                  labelText: l10n.stockQuantity,
                  suffixText: widget.item.unitCode,
                ),
                validator: (v) => switch (parseQtyInput(
                  v ?? '',
                  allowDecimal: widget.item.allowDecimal,
                ).error) {
                  null => null,
                  QtyInputError.notWhole => l10n.stockWholeOnly,
                  QtyInputError.invalid => l10n.stockInvalidQty,
                },
              ),
              if (reasons.length > 1) ...[
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<StockReason>(
                  initialValue: _reason,
                  decoration: InputDecoration(labelText: l10n.stockReason),
                  items: [
                    for (final r in reasons)
                      DropdownMenuItem(
                        value: r,
                        child: Text(_reasonLabel(l10n, r)),
                      ),
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
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          key: const Key('stock-save'),
          onPressed: _busy ? null : _save,
          child: Text(l10n.stockSave),
        ),
      ],
    );
  }
}
