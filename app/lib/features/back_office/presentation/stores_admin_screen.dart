import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/admin.dart';
import 'package:cashiera/core/design_system/widgets/buttons.dart';
import 'package:cashiera/core/design_system/widgets/data_display.dart';
import 'package:cashiera/core/design_system/widgets/glass.dart';
import 'package:cashiera/core/design_system/widgets/glass_table.dart';
import 'package:cashiera/core/design_system/widgets/toasts.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/features/back_office/data/staff_admin_repository.dart';
import 'package:cashiera/features/back_office/presentation/back_office_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The timezones offered for a store, with their labels.
List<(String, String)> storeTimezones(AppLocalizations l10n) => [
  ('Asia/Jakarta', l10n.tzWib),
  ('Asia/Makassar', l10n.tzWita),
  ('Asia/Jayapura', l10n.tzWit),
];

/// The server's code as a sentence for the person.
String staffErrorText(AppLocalizations l10n, BackendException e) =>
    switch (e.code) {
      'duplicate_code' => l10n.staffErrorDuplicateCode,
      'permission_denied' || 'owner_only' => l10n.staffErrorPermission,
      _ => l10n.commonError(e.message),
    };

/// Settings → Stores: the owner adds and edits stores; others only see them.
class StoresAdminScreen extends ConsumerWidget {
  const new({super.key});

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, [
    AdminStore? store,
  ]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _StoreDialog(store: store),
    );
    if (!(saved ?? false)) return;
    ref
      ..invalidate(adminStoresListProvider)
      ..invalidate(backOfficeStoresProvider);
    if (context.mounted) AppToast.success(context, context.l10n.storeSaved);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isOwner = ref.watch(principalProvider).value?.roleCode == 'owner';
    final stores = ref.watch(adminStoresListProvider);
    final list = stores.value ?? const <AdminStore>[];
    final zones = {for (final (id, label) in storeTimezones(l10n)) id: label};
    final muted = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: AppColors.textMuted);

    return AdminPage(
      toolbar: AdminToolbar(
        actions: [
          if (isOwner)
            PrimaryButton(
              key: const Key('store-add'),
              onPressed: () => _edit(context, ref),
              icon: Icons.add_business_outlined,
              label: l10n.storesAdd,
            ),
        ],
      ),
      children: [
        if (stores.isLoading && list.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (stores.hasError)
          adminMessage(
            icon: Icons.cloud_off_outlined,
            message: l10n.commonError('${stores.error}'),
          )
        else if (list.isEmpty)
          adminMessage(icon: Icons.store_outlined, message: l10n.storesEmpty)
        else
          GlassTable<AdminStore>(
            rows: list,
            onRowTap: isOwner ? (s) => _edit(context, ref, s) : null,
            columns: [
              GlassColumn(
                label: l10n.adminColStore,
                flex: 3,
                cell: (s) => Row(
                  key: Key('store-${s.code}'),
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(AppRadius.control),
                      ),
                      child: Text(
                        s.code,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        s.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              GlassColumn(
                label: l10n.adminColContact,
                flex: 3,
                cell: (s) =>
                    Text([?s.address, ?s.phone].join(' · '), style: muted),
              ),
              GlassColumn(
                label: l10n.adminColTimezone,
                flex: 2,
                cell: (s) => Text(zones[s.timezone] ?? s.timezone),
              ),
              GlassColumn(
                label: l10n.adminColStatus,
                cell: (s) => StatusChip(
                  label: s.isActive ? l10n.commonActive : l10n.commonInactive,
                  tone: s.isActive ? StatusTone.success : StatusTone.neutral,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _StoreDialog extends ConsumerStatefulWidget {
  const new({this.store});

  final AdminStore? store;

  @override
  ConsumerState<_StoreDialog> createState() => _StoreDialogState();
}

class _StoreDialogState extends ConsumerState<_StoreDialog> {
  final _form = GlobalKey<FormState>();
  late final _code = TextEditingController(text: widget.store?.code);
  late final _name = TextEditingController(text: widget.store?.name);
  late final _address = TextEditingController(text: widget.store?.address);
  late final _phone = TextEditingController(text: widget.store?.phone);
  late String _timezone = widget.store?.timezone ?? 'Asia/Jakarta';
  late bool _active = widget.store?.isActive ?? true;
  bool _busy = false;
  String? _error;

  bool get _isNew => widget.store == null;

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final l10n = context.l10n;
    final input = StoreInput(
      code: _code.text.trim().toUpperCase(),
      name: _name.text,
      address: _address.text,
      phone: _phone.text,
      timezone: _timezone,
      isActive: _active,
    );
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final admin = ref.read(staffAdminProvider);
      if (_isNew) {
        await admin.addStore(input);
      } else {
        await admin.updateStore(widget.store!.id, input);
      }
      if (mounted) Navigator.pop(context, true);
    } on BackendException catch (e) {
      if (mounted) setState(() => _error = staffErrorText(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GlassDialog(
      title: Text(_isNew ? l10n.storesAdd : l10n.storeEditTitle),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const Key('store-code'),
                  controller: _code,
                  enabled: _isNew,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: l10n.storeCode,
                    helperText: _isNew ? l10n.storeCodeHint : null,
                  ),
                  validator: (v) =>
                      storeCodePattern.hasMatch((v ?? '').trim().toUpperCase())
                      ? null
                      : l10n.storeCodeInvalid,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const Key('store-name'),
                  controller: _name,
                  decoration: InputDecoration(labelText: l10n.storeNameLabel),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? l10n.commonRequired : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const Key('store-address'),
                  controller: _address,
                  decoration: InputDecoration(labelText: l10n.storeAddress),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const Key('store-phone'),
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(labelText: l10n.storePhone),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  key: const Key('store-timezone'),
                  initialValue: _timezone,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l10n.storeTimezone),
                  items: [
                    for (final (id, label) in storeTimezones(l10n))
                      DropdownMenuItem(value: id, child: Text(label)),
                  ],
                  onChanged: (v) => setState(() => _timezone = v ?? _timezone),
                ),
                SwitchListTile(
                  key: const Key('store-active'),
                  contentPadding: EdgeInsets.zero,
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                  title: Text(l10n.commonActive),
                ),
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: AppColors.error)),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.commonCancel),
        ),
        PrimaryButton(
          key: const Key('store-save'),
          onPressed: _busy ? null : _save,
          label: l10n.commonSave,
        ),
      ],
    );
  }
}
