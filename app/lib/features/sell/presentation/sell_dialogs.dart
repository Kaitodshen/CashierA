import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/auth/pin_verifier.dart';
import 'package:cashiera/core/catalog/catalog_item.dart';
import 'package:cashiera/core/catalog/qty_input.dart';
import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/pin_pad.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/pos/cart.dart';
import 'package:cashiera/core/pos/money_input.dart';
import 'package:cashiera/core/pos/pos_services.dart';
import 'package:cashiera/core/providers.dart';
import 'package:cashiera/core/session/session_controller.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

/// Asks for a discount in percent or rupiah. Returns the discount, or
/// `const FixedDiscount(0)` when the person removed it, or null on cancel.
Future<DiscountSpec?> showDiscountDialog(
  BuildContext context, {
  required String title,
  DiscountSpec? current,
}) => showDialog<DiscountSpec>(
  context: context,
  builder: (_) => _DiscountDialog(title: title, current: current),
);

class _DiscountDialog extends StatefulWidget {
  const new({required this.title, this.current});

  final String title;
  final DiscountSpec? current;

  @override
  State<_DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<_DiscountDialog> {
  final _form = GlobalKey<FormState>();
  late bool _percent = widget.current is! FixedDiscount;
  late final _value = TextEditingController(
    text: switch (widget.current) {
      PercentDiscount(:final bps) =>
        bps % 100 == 0 ? '${bps ~/ 100}' : (bps / 100).toString(),
      FixedDiscount(:final amount) => '$amount',
      null => '',
    },
  );

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    Navigator.of(context).pop(
      _percent
          ? PercentDiscount(parsePercentBps(_value.text)!)
          : FixedDiscount(parseRupiah(_value.text)!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: true, label: Text(l10n.discountPercent)),
                ButtonSegment(value: false, label: Text(l10n.discountAmount)),
              ],
              selected: {_percent},
              onSelectionChanged: (s) => setState(() => _percent = s.first),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              key: const Key('discount-value'),
              controller: _value,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.discountValue,
                prefixText: _percent ? null : 'Rp ',
                suffixText: _percent ? '%' : null,
              ),
              validator: (v) =>
                  (_percent
                      ? parsePercentBps(v ?? '') == null
                      : (parseRupiah(v ?? '') ?? 0) <= 0)
                  ? l10n.discountInvalid
                  : null,
              onFieldSubmitted: (_) => _save(),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.current != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(const FixedDiscount(0)),
            child: Text(l10n.discountRemove),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          key: const Key('discount-save'),
          onPressed: _save,
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}

/// Asks for one line of text (a voucher code, a note, a reason).
Future<String?> showTextDialog(
  BuildContext context, {
  required String title,
  required String label,
  String initial = '',
  int minLength = 0,
  String? tooShort,
  bool upperCase = false,
}) => showDialog<String>(
  context: context,
  builder: (context) {
    final controller = TextEditingController(text: initial);
    final form = GlobalKey<FormState>();
    void save() {
      if (form.currentState!.validate()) {
        Navigator.of(context).pop(controller.text.trim());
      }
    }

    return AlertDialog(
      title: Text(title),
      content: Form(
        key: form,
        child: TextFormField(
          key: const Key('text-dialog-field'),
          controller: controller,
          autofocus: true,
          textCapitalization: upperCase
              ? TextCapitalization.characters
              : TextCapitalization.sentences,
          decoration: InputDecoration(labelText: label),
          validator: (v) =>
              (v ?? '').trim().length < minLength ? tooShort : null,
          onFieldSubmitted: (_) => save(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.commonCancel),
        ),
        FilledButton(
          key: const Key('text-dialog-save'),
          onPressed: save,
          child: Text(context.l10n.commonSave),
        ),
      ],
    );
  },
);

/// Asks how much of a weighed item (kg, litre).
Future<Qty?> showQuantityDialog(
  BuildContext context, {
  required String itemName,
  required String unitCode,
  required bool allowDecimal,
  Qty? current,
}) => showDialog<Qty>(
  context: context,
  builder: (context) {
    final l10n = context.l10n;
    final controller = TextEditingController(
      text: current == null ? '' : current.toPlain().replaceAll('.', ','),
    );
    final form = GlobalKey<FormState>();
    void save() {
      if (!form.currentState!.validate()) return;
      Navigator.of(context)
          .pop(parseQtyInput(controller.text, allowDecimal: allowDecimal).qty);
    }

    return AlertDialog(
      title: Text(itemName),
      content: Form(
        key: form,
        child: TextFormField(
          key: const Key('quantity-field'),
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
          decoration: InputDecoration(
            labelText: l10n.stockQuantity,
            suffixText: unitCode,
          ),
          validator: (v) => switch (parseQtyInput(
            v ?? '',
            allowDecimal: allowDecimal,
          ).error) {
            null => null,
            QtyInputError.notWhole => l10n.stockWholeOnly,
            QtyInputError.invalid => l10n.stockInvalidQty,
          },
          onFieldSubmitted: (_) => save(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          key: const Key('quantity-save'),
          onPressed: save,
          child: Text(l10n.commonSave),
        ),
      ],
    );
  },
);

/// A colleague with [permission] approves with their PIN, offline. Returns
/// who approved, or null.
Future<StaffMember?> showApprovalDialog(
  BuildContext context, {
  required String permission,
  required String reason,
}) => showDialog<StaffMember>(
  context: context,
  builder: (_) => _ApprovalDialog(permission: permission, reason: reason),
);

class _ApprovalDialog extends ConsumerStatefulWidget {
  const new({required this.permission, required this.reason});

  final String permission;
  final String reason;

  @override
  ConsumerState<_ApprovalDialog> createState() => _ApprovalDialogState();
}

class _ApprovalDialogState extends ConsumerState<_ApprovalDialog> {
  StaffMember? _approver;
  String? _error;
  bool _busy = false;

  Future<void> _check(String pin) async {
    final approver = _approver!;
    setState(() => _busy = true);
    final result = await ref
        .read(pinVerifierProvider)
        .verify(approver.employeeId, pin);
    if (!mounted) return;
    final l10n = context.l10n;
    setState(() {
      _busy = false;
      _error = switch (result) {
        PinOk() => null,
        PinMismatch(:final attemptsLeft) => l10n.pinWrong(attemptsLeft),
        PinLocked() => l10n.approvalLocked,
        PinNoPin() => l10n.approvalNoPin,
      };
    });
    if (result is PinOk) Navigator.of(context).pop(result.staff);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final approvers = (ref.watch(rosterProvider).value ?? const [])
        .where((s) => s.can(widget.permission))
        .toList();
    return AlertDialog(
      title: Text(l10n.approvalTitle),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.reason),
            const SizedBox(height: AppSpacing.md),
            if (approvers.isEmpty)
              Text(l10n.approvalNobody)
            else if (_approver == null)
              for (final s in approvers)
                ListTile(
                  key: Key('approver-${s.employeeId}'),
                  leading: const Icon(Icons.verified_user_outlined),
                  title: Text(s.fullName),
                  subtitle: Text(s.roleCode),
                  onTap: () => setState(() => _approver = s),
                )
            else ...[
              Text(
                l10n.approvalEnterPin(_approver!.fullName),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              PinPad(onSubmitted: _check, enabled: !_busy),
            ],
          ],
        ),
      ),
      actions: [
        if (_approver != null)
          TextButton(
            onPressed: () => setState(() {
              _approver = null;
              _error = null;
            }),
            child: Text(l10n.approvalOther),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
      ],
    );
  }
}

/// Picks modifiers for a product, honouring each group's min and max.
Future<List<CartModifier>?> showModifierSheet(
  BuildContext context, {
  required CatalogItem item,
  required List<ModifierGroupOption> groups,
}) => showModalBottomSheet<List<CartModifier>>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _ModifierSheet(item: item, groups: groups),
);

class _ModifierSheet extends StatefulWidget {
  const new({required this.item, required this.groups});

  final CatalogItem item;
  final List<ModifierGroupOption> groups;

  @override
  State<_ModifierSheet> createState() => _ModifierSheetState();
}

class _ModifierSheetState extends State<_ModifierSheet> {
  final _chosen = <String, Set<String>>{};

  bool get _valid => widget.groups.every((g) {
    final n = _chosen[g.id]?.length ?? 0;
    return n >= g.minSelect && n <= g.maxSelect;
  });

  void _toggle(ModifierGroupOption g, ModifierOption o) => setState(() {
    final set = _chosen.putIfAbsent(g.id, () => {});
    if (g.maxSelect == 1) {
      set
        ..clear()
        ..add(o.id);
    } else if (!set.remove(o.id) && set.length < g.maxSelect) {
      set.add(o.id);
    }
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final extra = widget.groups
        .expand(
          (g) => g.options.where((o) => _chosen[g.id]?.contains(o.id) ?? false),
        )
        .fold(Money.zero, (a, o) => a + o.priceDelta);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.item.displayName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final g in widget.groups) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.lg),
                      child: Text(
                        '${g.name} · ${g.minSelect > 0 //
                                ? l10n.modifierRequired(g.minSelect) //
                              : l10n.modifierOptional(g.maxSelect)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: [
                        for (final o in g.options)
                          FilterChip(
                            label: Text(
                              o.priceDelta.rupiah == 0
                                  ? o.name
                                  : '${o.name} +${o.priceDelta.format()}',
                            ),
                            selected: _chosen[g.id]?.contains(o.id) ?? false,
                            onSelected: (_) => _toggle(g, o),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              key: const Key('modifier-add'),
              onPressed: _valid
                  ? () => Navigator.of(context).pop([
                      for (final g in widget.groups)
                        for (final o in g.options)
                          if (_chosen[g.id]?.contains(o.id) ?? false)
                            CartModifier(
                              modifierId: o.id,
                              groupName: g.name,
                              name: o.name,
                              priceDelta: o.priceDelta,
                            ),
                    ])
                  : null,
              child: Text(
                l10n.modifierAdd((widget.item.price + extra).format()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Finds a customer by name or phone, or adds one. Returns the choice, or
/// null on cancel.
Future<CartCustomer?> showCustomerPicker(BuildContext context) =>
    showModalBottomSheet<CartCustomer>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CustomerPicker(),
    );

class _CustomerPicker extends ConsumerStatefulWidget {
  const new();

  @override
  ConsumerState<_CustomerPicker> createState() => _CustomerPickerState();
}

class _CustomerPickerState extends ConsumerState<_CustomerPicker> {
  String _query = '';
  bool _adding = false;
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _form = GlobalKey<FormState>();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (!_form.currentState!.validate()) return;
    final session = ref.read(sessionControllerProvider).value;
    final staff = session?.staff;
    final device = session?.device;
    if (staff == null || device == null) return;
    try {
      final customer = await ref
          .read(customerServiceProvider)
          .quickAdd(
            staff: staff,
            storeId: device.storeId,
            name: _name.text,
            phone: _phone.text,
          );
      if (mounted) Navigator.of(context).pop(customer);
    } on PosPermissionException {
      setState(() => _error = context.l10n.customerNoPermission);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final results =
        ref.watch(_customerSearchProvider(_query)).value ?? const [];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: _adding
                ? Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.customerAdd,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextFormField(
                          key: const Key('customer-name'),
                          controller: _name,
                          autofocus: true,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: l10n.customerName,
                          ),
                          validator: (v) => (v ?? '').trim().isEmpty
                              ? l10n.commonRequired
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          key: const Key('customer-phone'),
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: l10n.customerPhone,
                          ),
                          validator: (v) {
                            final clean = (v ?? '').replaceAll(
                              RegExp(r'[\s-]'),
                              '',
                            );
                            return clean.isEmpty ||
                                    CustomerService.phonePattern.hasMatch(clean)
                                ? null
                                : l10n.customerPhoneInvalid;
                          },
                        ),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.md),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: AppColors.error),
                            ),
                          ),
                        const Spacer(),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => setState(() => _adding = false),
                              child: Text(l10n.commonCancel),
                            ),
                            const Spacer(),
                            FilledButton(
                              key: const Key('customer-save'),
                              onPressed: _add,
                              child: Text(l10n.commonSave),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        key: const Key('customer-search'),
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: l10n.customerSearchHint,
                          prefixIcon: const Icon(Icons.search),
                        ),
                        onChanged: (v) => setState(() => _query = v),
                      ),
                      Expanded(
                        child: ListView(
                          children: [
                            for (final c in results)
                              ListTile(
                                leading: const Icon(Icons.person_outline),
                                title: Text(c.name),
                                subtitle: Text([?c.phone, ?c.code].join(' · ')),
                                onTap: () => Navigator.of(context).pop(
                                  CartCustomer(
                                    id: c.id,
                                    name: c.name,
                                    phone: c.phone,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        key: const Key('customer-new'),
                        onPressed: () => setState(() {
                          _adding = true;
                          _name.text = _query;
                        }),
                        icon: const Icon(Icons.person_add_alt),
                        label: Text(l10n.customerAdd),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

final StreamProviderFamily<List<CustomerRow>, String> _customerSearchProvider =
    StreamProvider.autoDispose.family<List<CustomerRow>, String>(
      (ref, query) =>
          ref.watch(posConfigRepositoryProvider).searchCustomers(query),
    );

/// Digits only, for money fields.
final List<TextInputFormatter> rupiahInputFormatters = [
  FilteringTextInputFormatter.digitsOnly,
];
