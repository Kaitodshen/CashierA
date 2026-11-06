import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/toasts.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/features/back_office/data/customers_admin_repository.dart';
import 'package:cashiera/features/back_office/presentation/back_office_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Company-wide loyalty and kasbon settings. Only the owner may change them
/// (the business_profile policy); others see them read-only.
class LoyaltySettingsScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(adminLoyaltySettingsProvider);
    final owner = ref.watch(principalProvider).value?.roleCode == 'owner';
    return switch (settings) {
      AsyncData(:final value) => _Form(
        key: ValueKey(value),
        settings: value,
        canEdit: owner,
      ),
      AsyncError(:final error) => Center(
        child: Text(l10n.commonError('$error')),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _Form extends ConsumerStatefulWidget {
  const new({required this.settings, required this.canEdit, super.key});

  final LoyaltySettings settings;
  final bool canEdit;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  final _form = GlobalKey<FormState>();
  late bool _enabled = widget.settings.enabled;
  late final _earn = TextEditingController(
    text: '${widget.settings.earnAmount}',
  );
  late final _value = TextEditingController(
    text: '${widget.settings.pointValue}',
  );
  late final _min = TextEditingController(
    text: '${widget.settings.minRedeemPoints}',
  );
  late final _days = TextEditingController(
    text: '${widget.settings.kasbonDueDays}',
  );
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_earn, _value, _min, _days]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final l10n = context.l10n;
    final s = widget.settings
      ..enabled = _enabled
      ..earnAmount = int.parse(_earn.text)
      ..pointValue = int.parse(_value.text)
      ..minRedeemPoints = int.parse(_min.text)
      ..kasbonDueDays = int.parse(_days.text);
    setState(() => _busy = true);
    try {
      await ref.read(customersAdminProvider).saveLoyaltySettings(s);
      ref.invalidate(adminLoyaltySettingsProvider);
      if (mounted) AppToast.success(context, l10n.commonSaved);
    } on Exception catch (e) {
      if (mounted) AppToast.error(context, l10n.commonError('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _number(
    String key,
    TextEditingController c,
    String label, {
    required int min,
    int? max,
    String? prefix,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: TextFormField(
      key: Key(key),
      controller: c,
      enabled: widget.canEdit,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label, prefixText: prefix),
      validator: (v) {
        final n = int.tryParse(v ?? '');
        if (n == null || n < min || (max != null && n > max)) {
          return context.l10n.loyaltyRange(min, max ?? 999999999);
        }
        return null;
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (!widget.canEdit)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(l10n.loyaltyOwnerOnly),
                ),
              SwitchListTile(
                key: const Key('loyalty-enabled'),
                contentPadding: EdgeInsets.zero,
                value: _enabled,
                onChanged: widget.canEdit
                    ? (v) => setState(() => _enabled = v)
                    : null,
                title: Text(l10n.loyaltyEnabled),
              ),
              _number(
                'loyalty-earn',
                _earn,
                l10n.loyaltyEarn,
                min: 1,
                prefix: 'Rp ',
              ),
              _number(
                'loyalty-value',
                _value,
                l10n.loyaltyValue,
                min: 1,
                prefix: 'Rp ',
              ),
              _number('loyalty-min', _min, l10n.loyaltyMin, min: 0),
              _number(
                'loyalty-days',
                _days,
                l10n.loyaltyDueDays,
                min: 1,
                max: 365,
              ),
              Text(
                l10n.loyaltyHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (widget.canEdit)
                FilledButton(
                  key: const Key('loyalty-save'),
                  onPressed: _busy ? null : _save,
                  child: Text(l10n.commonSave),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
