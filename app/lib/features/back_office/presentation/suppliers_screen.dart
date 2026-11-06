import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/empty_state.dart';
import 'package:cashiera/core/design_system/widgets/toasts.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/features/back_office/data/catalog_admin_models.dart';
import 'package:cashiera/features/back_office/presentation/back_office_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SuppliersScreen extends ConsumerWidget {
  const new({super.key});

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, [
    AdminSupplier? supplier,
  ]) async {
    final l10n = context.l10n;
    final result = await showDialog<AdminSupplier>(
      context: context,
      builder: (_) => _SupplierDialog(supplier: supplier),
    );
    if (result == null || !context.mounted) return;
    try {
      await ref.read(catalogAdminProvider).saveSupplier(result);
      ref.invalidate(adminSuppliersProvider);
      if (context.mounted) AppToast.success(context, l10n.commonSaved);
    } on BackendException catch (e) {
      if (context.mounted) AppToast.error(context, l10n.commonError(e.message));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final principal = ref.watch(principalProvider).value;
    final canEdit =
        (principal?.can('purchase.manage') ?? false) ||
        (principal?.can('catalog.manage') ?? false);
    final suppliers = ref.watch(adminSuppliersProvider);
    final list = suppliers.value ?? const <AdminSupplier>[];

    return Scaffold(
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => _edit(context, ref),
              icon: const Icon(Icons.add),
              label: Text(l10n.commonAdd),
            )
          : null,
      body: suppliers.isLoading
          ? const Center(child: CircularProgressIndicator())
          : list.isEmpty
          ? EmptyState(
              icon: Icons.local_shipping_outlined,
              message: l10n.suppliersEmpty,
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
                final s = list[i];
                return Card(
                  child: ListTile(
                    title: Text(s.name),
                    subtitle: Text(
                      [
                        s.contactName,
                        s.phone,
                        s.email,
                        if (!s.isActive) l10n.commonInactive,
                      ].nonNulls.where((v) => v.isNotEmpty).join(' · '),
                    ),
                    onTap: canEdit ? () => _edit(context, ref, s) : null,
                  ),
                );
              },
            ),
    );
  }
}

class _SupplierDialog extends StatefulWidget {
  const new({this.supplier});

  final AdminSupplier? supplier;

  @override
  State<_SupplierDialog> createState() => _SupplierDialogState();
}

class _SupplierDialogState extends State<_SupplierDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.supplier?.name);
  late final _contact = TextEditingController(
    text: widget.supplier?.contactName,
  );
  late final _phone = TextEditingController(text: widget.supplier?.phone);
  late final _email = TextEditingController(text: widget.supplier?.email);
  late final _address = TextEditingController(text: widget.supplier?.address);
  late bool _active = widget.supplier?.isActive ?? true;

  @override
  void dispose() {
    for (final c in [_name, _contact, _phone, _email, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _opt(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget field(
      TextEditingController c,
      String label, {
      bool required = false,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: c,
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (v) => (v?.trim().isEmpty ?? true) ? l10n.commonRequired : null
            : null,
      ),
    );

    return AlertDialog(
      title: Text(widget.supplier == null ? l10n.commonAdd : l10n.commonEdit),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              field(_name, l10n.supplierName, required: true),
              field(_contact, l10n.supplierContact),
              field(_phone, l10n.supplierPhone),
              field(_email, l10n.supplierEmail),
              field(_address, l10n.supplierAddress),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.commonActive),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
            ],
          ),
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
            Navigator.of(context).pop(
              AdminSupplier(
                id: widget.supplier?.id,
                name: _name.text.trim(),
                contactName: _opt(_contact),
                phone: _opt(_phone),
                email: _opt(_email),
                address: _opt(_address),
                isActive: _active,
              ),
            );
          },
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}
