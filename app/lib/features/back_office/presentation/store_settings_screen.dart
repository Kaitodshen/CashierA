import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/toasts.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/pos/money_input.dart';
import 'package:cashiera/features/back_office/data/pos_admin_repository.dart';
import 'package:cashiera/features/back_office/presentation/back_office_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Per store: tax, service charge, rounding, discount limit, kasbon, receipt
/// and accepted payment methods.
class StoreSettingsScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<StoreSettingsScreen> createState() =>
      _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends ConsumerState<StoreSettingsScreen> {
  String? _storeId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stores = ref.watch(backOfficeStoresProvider).value ?? const [];
    final storeId = _storeId ?? stores.firstOrNull?.id;
    final canEdit =
        ref.watch(principalProvider).value?.can('settings.manage') ?? false;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        DropdownButtonFormField<String>(
          key: const Key('settings-store'),
          initialValue: storeId,
          decoration: InputDecoration(labelText: l10n.stockStore),
          items: [
            for (final s in stores)
              DropdownMenuItem(
                value: s.id,
                child: Text('${s.code} · ${s.name}'),
              ),
          ],
          onChanged: (id) => setState(() => _storeId = id),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (storeId != null) ...[
          _SettingsForm(
            key: ValueKey('settings-$storeId'),
            storeId: storeId,
            canEdit: canEdit,
          ),
          const SizedBox(height: AppSpacing.lg),
          _PaymentMethods(storeId: storeId, canEdit: canEdit),
        ],
      ],
    );
  }
}

class _SettingsForm extends ConsumerStatefulWidget {
  const new({required this.storeId, required this.canEdit, super.key});

  final String storeId;
  final bool canEdit;

  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<_SettingsForm> {
  final _form = GlobalKey<FormState>();
  StoreSettingsDraft? _draft;
  bool _saving = false;

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null || !_form.currentState!.validate()) return;
    _form.currentState!.save();
    final l10n = context.l10n;
    setState(() => _saving = true);
    try {
      await ref.read(posAdminProvider).saveStoreSettings(draft);
      ref.invalidate(adminStoreSettingsProvider(widget.storeId));
      if (mounted) AppToast.success(context, l10n.commonSaved);
    } on BackendException catch (e) {
      if (mounted) AppToast.error(context, l10n.commonError(e.message));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final loaded = ref.watch(adminStoreSettingsProvider(widget.storeId));
    final d = _draft ??= loaded.value;
    if (d == null) {
      return loaded.hasError
          ? Text(l10n.commonError('${loaded.error}'))
          : const Center(child: CircularProgressIndicator());
    }
    final enabled = widget.canEdit;
    String? percent(String? v) => parsePercentOrZero(v ?? '') == null
        ? l10n.settingsPercentInvalid
        : null;

    Widget section(String title, List<Widget> children) => Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            for (final (i, c) in children.indexed) ...[
              if (i > 0) const SizedBox(height: AppSpacing.md),
              c,
            ],
          ],
        ),
      ),
    );

    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          section(l10n.settingsTax, [
            SwitchListTile(
              key: const Key('settings-tax-enabled'),
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.settingsTaxEnabled),
              value: d.taxEnabled,
              onChanged: enabled
                  ? (v) => setState(() => d.taxEnabled = v)
                  : null,
            ),
            if (d.taxEnabled) ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: d.taxName,
                      enabled: enabled,
                      decoration: InputDecoration(
                        labelText: l10n.settingsTaxName,
                      ),
                      validator: (v) =>
                          (v ?? '').trim().isEmpty ? l10n.commonRequired : null,
                      onSaved: (v) => d.taxName = v!.trim(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  SizedBox(
                    width: 140,
                    child: TextFormField(
                      key: const Key('settings-tax-rate'),
                      initialValue: bpsToPercentText(d.taxRateBps),
                      enabled: enabled,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.settingsRate,
                        suffixText: '%',
                      ),
                      validator: percent,
                      onSaved: (v) => d.taxRateBps = parsePercentOrZero(v!)!,
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                key: const Key('settings-tax-inclusive'),
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.settingsTaxInclusive),
                subtitle: Text(
                  d.taxInclusive
                      ? l10n.settingsTaxInclusiveHint
                      : l10n.settingsTaxExclusiveHint,
                ),
                value: d.taxInclusive,
                onChanged: enabled
                    ? (v) => setState(() => d.taxInclusive = v)
                    : null,
              ),
            ],
          ]),
          const SizedBox(height: AppSpacing.md),
          section(l10n.settingsServiceCharge, [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.settingsServiceChargeEnabled),
              value: d.serviceChargeEnabled,
              onChanged: enabled
                  ? (v) => setState(() => d.serviceChargeEnabled = v)
                  : null,
            ),
            if (d.serviceChargeEnabled) ...[
              TextFormField(
                initialValue: bpsToPercentText(d.serviceChargeBps),
                enabled: enabled,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.settingsRate,
                  suffixText: '%',
                ),
                validator: percent,
                onSaved: (v) => d.serviceChargeBps = parsePercentOrZero(v!)!,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.settingsServiceChargeTaxable),
                value: d.serviceChargeTaxable,
                onChanged: enabled
                    ? (v) => setState(() => d.serviceChargeTaxable = v)
                    : null,
              ),
            ],
          ]),
          const SizedBox(height: AppSpacing.md),
          section(l10n.settingsCashier, [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: const Key('settings-rounding'),
                    initialValue: d.roundingMode,
                    decoration: InputDecoration(
                      labelText: l10n.settingsRounding,
                    ),
                    items: [
                      for (final (code, label) in [
                        ('none', l10n.settingsRoundingNone),
                        ('nearest', l10n.settingsRoundingNearest),
                        ('up', l10n.settingsRoundingUp),
                        ('down', l10n.settingsRoundingDown),
                      ])
                        DropdownMenuItem(value: code, child: Text(label)),
                    ],
                    onChanged: enabled
                        ? (v) => setState(() => d.roundingMode = v!)
                        : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<int>(
                    initialValue: d.roundingUnit,
                    decoration: InputDecoration(
                      labelText: l10n.settingsRoundingUnit,
                    ),
                    items: [
                      for (final unit in const [50, 100, 500, 1000])
                        DropdownMenuItem(value: unit, child: Text('Rp $unit')),
                    ],
                    onChanged: enabled && d.roundingMode != 'none'
                        ? (v) => setState(() => d.roundingUnit = v!)
                        : null,
                  ),
                ),
              ],
            ),
            TextFormField(
              key: const Key('settings-discount-limit'),
              initialValue: bpsToPercentText(d.discountApprovalBps),
              enabled: enabled,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.settingsDiscountLimit,
                helperText: l10n.settingsDiscountLimitHint,
                suffixText: '%',
              ),
              validator: percent,
              onSaved: (v) => d.discountApprovalBps = parsePercentOrZero(v!)!,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.settingsKasbon),
              value: d.kasbonEnabled,
              onChanged: enabled
                  ? (v) => setState(() => d.kasbonEnabled = v)
                  : null,
            ),
          ]),
          const SizedBox(height: AppSpacing.md),
          section(l10n.settingsReceipt, [
            TextFormField(
              initialValue: d.receiptHeader ?? '',
              enabled: enabled,
              decoration: InputDecoration(
                labelText: l10n.settingsReceiptHeader,
              ),
              onSaved: (v) => d.receiptHeader = v,
            ),
            TextFormField(
              initialValue: d.receiptFooter,
              enabled: enabled,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l10n.settingsReceiptFooter,
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l10n.commonRequired : null,
              onSaved: (v) => d.receiptFooter = v!,
            ),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 58, label: Text('58 mm')),
                ButtonSegment(value: 80, label: Text('80 mm')),
              ],
              selected: {d.receiptPaperMm},
              onSelectionChanged: enabled
                  ? (s) => setState(() => d.receiptPaperMm = s.first)
                  : null,
            ),
          ]),
          if (enabled) ...[
            const SizedBox(height: AppSpacing.lg),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                key: const Key('settings-save'),
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(l10n.commonSave),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentMethods extends ConsumerWidget {
  const new({required this.storeId, required this.canEdit});

  final String storeId;
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final methods = ref.watch(adminPaymentMethodsProvider(storeId));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.settingsPaymentMethods,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(l10n.settingsPaymentMethodsHint),
            for (final m in methods.value ?? const <StorePaymentMethod>[])
              SwitchListTile(
                key: Key('settings-pay-${m.code}'),
                contentPadding: EdgeInsets.zero,
                title: Text(m.name),
                subtitle: Text(
                  m.requiresReference
                      ? '${m.methodType} · ${l10n.settingsNeedsReference}'
                      : m.methodType,
                ),
                value: m.enabled,
                onChanged: canEdit
                    ? (v) async {
                        try {
                          await ref
                              .read(posAdminProvider)
                              .setPaymentMethod(storeId, m, enabled: v);
                          ref.invalidate(adminPaymentMethodsProvider(storeId));
                        } on BackendException catch (e) {
                          if (context.mounted) {
                            AppToast.error(
                              context,
                              l10n.commonError(e.message),
                            );
                          }
                        }
                      }
                    : null,
              ),
            if (methods.isLoading)
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
