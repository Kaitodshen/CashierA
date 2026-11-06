import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/pos/money_input.dart';
import 'package:cashiera/features/back_office/data/purchasing_repository.dart';
import 'package:cashiera/features/back_office/presentation/back_office_providers.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `12`, `1,5` → thousandths; null when not a positive number.
Qty? parseQtyText(String text) {
  final t = text.trim().replaceAll(',', '.');
  if (t.isEmpty) return null;
  try {
    final q = Qty.parse(t);
    return q.milli < 0 ? null : q;
  } on FormatException {
    return null;
  }
}

final qtyInputFormatters = [
  FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
];

/// Lets the person pick a stock item (search by name or SKU).
Future<StockVariant?> pickStockVariant(
  BuildContext context, {
  Set<String> exclude = const {},
}) => showDialog<StockVariant>(
  context: context,
  builder: (_) => _VariantPicker(exclude: exclude),
);

class _VariantPicker extends ConsumerStatefulWidget {
  const new({required this.exclude});
  final Set<String> exclude;

  @override
  ConsumerState<_VariantPicker> createState() => _VariantPickerState();
}

class _VariantPickerState extends ConsumerState<_VariantPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final all = ref.watch(stockVariantsProvider).value ?? const [];
    final q = _query.trim().toLowerCase();
    final list = [
      for (final v in all)
        if (!widget.exclude.contains(v.id) &&
            (q.isEmpty ||
                v.name.toLowerCase().contains(q) ||
                (v.sku?.toLowerCase().contains(q) ?? false)))
          v,
    ].take(50).toList();
    return AlertDialog(
      title: Text(l10n.purchaseAddItem),
      content: SizedBox(
        width: 460,
        height: 420,
        child: Column(
          children: [
            TextField(
              key: const Key('variant-search'),
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.purchaseSearchItem,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: ListView(
                children: [
                  for (final v in list)
                    ListTile(
                      key: Key('variant-${v.id}'),
                      dense: true,
                      title: Text(v.name),
                      subtitle: Text(
                        [?v.sku, v.unit, v.cost.format()].join(' · '),
                      ),
                      onTap: () => Navigator.pop(context, v),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
      ],
    );
  }
}

/// One quantity per line (ship or receive a transfer).
/// Returns line id → quantity, or null when cancelled.
Future<Map<String, Qty>?> showQuantitiesDialog(
  BuildContext context, {
  required String title,
  required List<(String id, String name, Qty suggested, Qty? max)> lines,
  required String confirm,
}) async {
  final out = await showDialog<Map<String, (Qty, Money?)>>(
    context: context,
    builder: (_) =>
        _QuantitiesDialog(title: title, lines: lines, confirm: confirm),
  );
  return out?.map((id, v) => MapEntry(id, v.$1));
}

/// Quantity and unit cost per line (receive goods against a PO). A cost is
/// returned only when it was changed.
Future<Map<String, (Qty, Money?)>?> showReceiveDialog(
  BuildContext context, {
  required String title,
  required List<(String id, String name, Qty suggested, Qty? max)> lines,
  required Map<String, Money> costs,
  required String confirm,
}) => showDialog<Map<String, (Qty, Money?)>>(
  context: context,
  builder: (_) => _QuantitiesDialog(
    title: title,
    lines: lines,
    confirm: confirm,
    costs: costs,
  ),
);

class _QuantitiesDialog extends StatefulWidget {
  const new({
    required this.title,
    required this.lines,
    required this.confirm,
    this.costs,
  });

  final String title;
  final List<(String, String, Qty, Qty?)> lines;
  final String confirm;
  final Map<String, Money>? costs;

  @override
  State<_QuantitiesDialog> createState() => _QuantitiesDialogState();
}

class _QuantitiesDialogState extends State<_QuantitiesDialog> {
  late final Map<String, TextEditingController> _fields = {
    for (final (id, _, qty, _) in widget.lines)
      id: TextEditingController(text: qty.toPlain()),
  };
  late final Map<String, TextEditingController> _costs = {
    for (final MapEntry(:key, :value) in (widget.costs ?? const {}).entries)
      key: TextEditingController(text: '${value.rupiah}'),
  };
  String? _error;

  @override
  void dispose() {
    for (final c in [..._fields.values, ..._costs.values]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final l10n = context.l10n;
    final out = <String, (Qty, Money?)>{};
    for (final (id, name, _, max) in widget.lines) {
      final q = parseQtyText(_fields[id]!.text);
      if (q == null) {
        setState(() => _error = l10n.purchaseQtyInvalid(name));
        return;
      }
      if (max != null && q.milli > max.milli) {
        setState(() => _error = l10n.purchaseQtyTooMuch(name, max.toPlain()));
        return;
      }
      Money? cost;
      if (_costs[id] case final c?) {
        final rupiah = parseRupiah(c.text);
        if (rupiah == null) {
          setState(() => _error = l10n.purchaseQtyInvalid(name));
          return;
        }
        if (rupiah != widget.costs![id]!.rupiah) cost = Money(rupiah);
      }
      out[id] = (q, cost);
    }
    if (out.values.every((v) => v.$1.milli == 0)) {
      setState(() => _error = l10n.purchaseQtyNone);
      return;
    }
    Navigator.pop(context, out);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (id, name, _, max) in widget.lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          max == null
                              ? name
                              : '$name (${l10n.purchaseMax(max.toPlain())})',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          key: Key('qty-$id'),
                          controller: _fields[id],
                          textAlign: TextAlign.end,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: qtyInputFormatters,
                        ),
                      ),
                      if (_costs[id] case final c?) ...[
                        const SizedBox(width: AppSpacing.sm),
                        SizedBox(
                          width: 110,
                          child: TextField(
                            key: Key('cost-$id'),
                            controller: c,
                            textAlign: TextAlign.end,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              prefixText: 'Rp ',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: AppColors.error)),
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
          key: const Key('qty-confirm'),
          onPressed: _submit,
          child: Text(widget.confirm),
        ),
      ],
    );
  }
}
