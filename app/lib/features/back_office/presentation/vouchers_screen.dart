import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/empty_state.dart';
import 'package:cashiera/core/design_system/widgets/toasts.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/pos/money_input.dart';
import 'package:cashiera/features/back_office/data/pos_admin_repository.dart';
import 'package:cashiera/features/back_office/presentation/back_office_providers.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final _codePattern = RegExp(r'^[A-Z0-9_-]{3,32}$');

String voucherValueText(AdminVoucher v) => v.discountType == 'percent'
    ? '${bpsToPercentText(v.discountValue)}%'
    : Money(v.discountValue).format();

class VouchersScreen extends ConsumerWidget {
  const new({super.key});

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, [
    AdminVoucher? voucher,
  ]) async {
    final l10n = context.l10n;
    final result = await showDialog<AdminVoucher>(
      context: context,
      builder: (_) => _VoucherDialog(voucher: voucher),
    );
    if (result == null || !context.mounted) return;
    try {
      await ref.read(posAdminProvider).saveVoucher(result);
      ref.invalidate(adminVouchersProvider);
      if (context.mounted) AppToast.success(context, l10n.commonSaved);
    } on BackendException catch (e) {
      if (context.mounted) AppToast.error(context, l10n.commonError(e.message));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final canEdit =
        ref.watch(principalProvider).value?.can('promo.manage') ?? false;
    final vouchers = ref.watch(adminVouchersProvider);
    final list = vouchers.value ?? const <AdminVoucher>[];
    final date = DateFormat.yMMMd();

    return Scaffold(
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              key: const Key('voucher-add'),
              onPressed: () => _edit(context, ref),
              icon: const Icon(Icons.add),
              label: Text(l10n.commonAdd),
            )
          : null,
      body: vouchers.isLoading
          ? const Center(child: CircularProgressIndicator())
          : list.isEmpty
          ? EmptyState(
              icon: Icons.confirmation_number_outlined,
              message: l10n.vouchersEmpty,
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                96,
              ),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) {
                final v = list[i];
                return Card(
                  child: ListTile(
                    key: Key('voucher-${v.code}'),
                    title: Text('${v.code} · ${voucherValueText(v)}'),
                    subtitle: Text(
                      [
                        ?v.description,
                        if (v.minSubtotal > 0)
                          l10n.voucherMinSubtotal(
                            Money(v.minSubtotal).format(),
                          ),
                        if (v.maxDiscount != null)
                          l10n.voucherMaxDiscount(
                            Money(v.maxDiscount!).format(),
                          ),
                        l10n.voucherUsed(v.usedCount, '${v.maxUses ?? '∞'}'),
                        if (v.endsAt != null)
                          l10n.voucherUntil(date.format(v.endsAt!.toLocal())),
                        if (!v.isActive) l10n.commonInactive,
                      ].join(' · '),
                    ),
                    onTap: canEdit ? () => _edit(context, ref, v) : null,
                  ),
                );
              },
            ),
    );
  }
}

class _VoucherDialog extends StatefulWidget {
  const new({this.voucher});

  final AdminVoucher? voucher;

  @override
  State<_VoucherDialog> createState() => _VoucherDialogState();
}

class _VoucherDialogState extends State<_VoucherDialog> {
  final _form = GlobalKey<FormState>();
  late final AdminVoucher _v =
      widget.voucher ??
      AdminVoucher(code: '', discountType: 'percent', discountValue: 1000);

  Future<void> _pickDate({required bool start}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (start ? _v.startsAt : _v.endsAt) ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _v.startsAt = picked;
      } else {
        // Valid through the whole chosen day.
        _v.endsAt = picked.add(const Duration(days: 1));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final date = DateFormat.yMMMd();
    final percent = _v.discountType == 'percent';
    String? optionalMoney(String? v) =>
        (v ?? '').trim().isEmpty || (parseRupiah(v!) ?? 0) > 0
        ? null
        : l10n.validationMoney;
    String? optionalCount(String? v) =>
        (v ?? '').trim().isEmpty || (int.tryParse(v!.trim()) ?? 0) > 0
        ? null
        : l10n.voucherCountInvalid;

    return AlertDialog(
      title: Text(widget.voucher == null ? l10n.voucherNew : _v.code),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const Key('voucher-code'),
                  initialValue: _v.code,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: l10n.voucherCode,
                    helperText: l10n.voucherCodeHint,
                  ),
                  validator: (v) =>
                      _codePattern.hasMatch((v ?? '').trim().toUpperCase())
                      ? null
                      : l10n.voucherCodeHint,
                  onSaved: (v) => _v.code = v!.trim().toUpperCase(),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  initialValue: _v.description,
                  decoration: InputDecoration(labelText: l10n.promoDescription),
                  onSaved: (v) => _v.description = v,
                ),
                const SizedBox(height: AppSpacing.md),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'percent',
                      label: Text(l10n.discountPercent),
                    ),
                    ButtonSegment(
                      value: 'fixed',
                      label: Text(l10n.discountAmount),
                    ),
                  ],
                  selected: {_v.discountType},
                  onSelectionChanged: (s) =>
                      setState(() => _v.discountType = s.first),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: ValueKey('voucher-value-$percent'),
                  initialValue: percent
                      ? bpsToPercentText(_v.discountValue)
                      : '${_v.discountValue}',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.discountValue,
                    suffixText: percent ? '%' : null,
                    prefixText: percent ? null : 'Rp ',
                  ),
                  validator: (v) =>
                      (percent
                                  ? parsePercentBps(v ?? '')
                                  : parseRupiah(v ?? '')) ==
                              null ||
                          (!percent && parseRupiah(v!) == 0)
                      ? l10n.discountInvalid
                      : null,
                  onSaved: (v) => _v.discountValue = percent
                      ? parsePercentBps(v!)!
                      : parseRupiah(v!)!,
                ),
                if (percent) ...[
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    initialValue: _v.maxDiscount?.toString() ?? '',
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.voucherMaxDiscountLabel,
                      prefixText: 'Rp ',
                    ),
                    validator: optionalMoney,
                    onSaved: (v) => _v.maxDiscount = parseRupiah(v ?? ''),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  initialValue: _v.minSubtotal == 0 ? '' : '${_v.minSubtotal}',
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.voucherMinSubtotalLabel,
                    prefixText: 'Rp ',
                  ),
                  validator: optionalMoney,
                  onSaved: (v) => _v.minSubtotal = parseRupiah(v ?? '') ?? 0,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _v.maxUses?.toString() ?? '',
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.voucherMaxUses,
                        ),
                        validator: optionalCount,
                        onSaved: (v) => _v.maxUses = int.tryParse(v!.trim()),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        initialValue: _v.perCustomerLimit?.toString() ?? '',
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.voucherPerCustomer,
                        ),
                        validator: optionalCount,
                        onSaved: (v) =>
                            _v.perCustomerLimit = int.tryParse(v!.trim()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.event, size: 18),
                      label: Text(
                        _v.startsAt == null
                            ? l10n.promoStartsAnytime
                            : l10n.promoStarts(
                                date.format(_v.startsAt!.toLocal()),
                              ),
                      ),
                      onPressed: () => _pickDate(start: true),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.event_busy, size: 18),
                      label: Text(
                        _v.endsAt == null
                            ? l10n.promoEndsNever
                            : l10n.promoEnds(
                                date.format(
                                  _v.endsAt!.toLocal().subtract(
                                    const Duration(days: 1),
                                  ),
                                ),
                              ),
                      ),
                      onPressed: () => _pickDate(start: false),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.commonActive),
                  value: _v.isActive,
                  onChanged: (v) => setState(() => _v.isActive = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          key: const Key('voucher-save'),
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            if (_v.startsAt != null &&
                _v.endsAt != null &&
                !_v.endsAt!.isAfter(_v.startsAt!)) {
              AppToast.error(context, l10n.promoPeriodInvalid);
              return;
            }
            _form.currentState!.save();
            Navigator.of(context).pop(_v);
          },
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}
