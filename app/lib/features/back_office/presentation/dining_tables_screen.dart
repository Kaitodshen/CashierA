import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/empty_state.dart';
import 'package:cashiera/core/design_system/widgets/toasts.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/features/back_office/presentation/back_office_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Meja: a store's F&B switch (owner) and its dining tables.
class DiningTablesScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<DiningTablesScreen> createState() => _DiningTablesScreenState();
}

class _DiningTablesScreenState extends ConsumerState<DiningTablesScreen> {
  String? _storeId;

  Future<void> _edit(String storeId, [Map<String, dynamic>? table]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _TableDialog(storeId: storeId, table: table),
    );
    if (saved ?? false) ref.invalidate(diningTablesProvider(storeId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stores = ref.watch(backOfficeStoresProvider).value ?? const [];
    final principal = ref.watch(principalProvider).value;
    final isOwner = principal?.roleCode == 'owner';
    final canEdit = principal?.can('settings.manage') ?? false;
    final storeId = stores.any((s) => s.id == _storeId)
        ? _storeId
        : stores.firstOrNull?.id;
    final fnb = storeId == null
        ? null
        : ref.watch(storeFnbModeProvider(storeId));
    final tables = storeId == null
        ? null
        : ref.watch(diningTablesProvider(storeId));
    final list = tables?.value ?? const <Map<String, dynamic>>[];

    return Scaffold(
      floatingActionButton: canEdit && storeId != null
          ? FloatingActionButton.extended(
              key: const Key('table-new'),
              onPressed: () => _edit(storeId),
              icon: const Icon(Icons.add),
              label: Text(l10n.tableNew),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          96,
        ),
        children: [
          DropdownButton<String>(
            key: const Key('tables-store'),
            value: storeId,
            items: [
              for (final s in stores)
                DropdownMenuItem(
                  value: s.id,
                  child: Text('${s.code} · ${s.name}'),
                ),
            ],
            onChanged: (v) => setState(() => _storeId = v),
          ),
          if (storeId != null)
            SwitchListTile(
              key: const Key('fnb-switch'),
              title: Text(l10n.fnbMode),
              subtitle: Text(
                isOwner ? l10n.fnbModeHint : l10n.fnbModeOwnerOnly,
              ),
              value: fnb?.value ?? false,
              onChanged: !isOwner || fnb?.value == null
                  ? null
                  : (on) async {
                      try {
                        await ref
                            .read(purchasingProvider)
                            .setFnbMode(storeId, on: on);
                        ref.invalidate(storeFnbModeProvider(storeId));
                      } on Exception catch (e) {
                        if (context.mounted) {
                          AppToast.error(context, l10n.commonError('$e'));
                        }
                      }
                    },
            ),
          const Divider(),
          if (tables?.isLoading ?? false)
            const Center(child: CircularProgressIndicator())
          else if (list.isEmpty)
            EmptyState(icon: Icons.table_restaurant, message: l10n.tablesEmpty)
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final t in list)
                  SizedBox(
                    width: 180,
                    child: Card(
                      child: ListTile(
                        key: Key('table-${t['name']}'),
                        leading: Icon(
                          Icons.table_restaurant,
                          color: t['is_active'] as bool
                              ? (t['status'] == 'available'
                                    ? AppColors.success
                                    : AppColors.warning)
                              : AppColors.error,
                        ),
                        title: Text(t['name'] as String),
                        subtitle: Text(
                          [
                            ?t['area'] as String?,
                            l10n.tableSeats(t['capacity'] as int),
                            if (!(t['is_active'] as bool)) l10n.commonInactive,
                          ].join(' · '),
                        ),
                        onTap: canEdit ? () => _edit(storeId!, t) : null,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TableDialog extends ConsumerStatefulWidget {
  const new({required this.storeId, this.table});
  final String storeId;
  final Map<String, dynamic>? table;

  @override
  ConsumerState<_TableDialog> createState() => _TableDialogState();
}

class _TableDialogState extends ConsumerState<_TableDialog> {
  late final _name = TextEditingController(
    text: widget.table?['name'] as String?,
  );
  late final _area = TextEditingController(
    text: widget.table?['area'] as String?,
  );
  late final _capacity = TextEditingController(
    text: '${widget.table?['capacity'] ?? 4}',
  );
  late bool _active = widget.table?['is_active'] as bool? ?? true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _area.dispose();
    _capacity.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final capacity = int.tryParse(_capacity.text) ?? 0;
    if (_name.text.trim().isEmpty || capacity < 1) {
      setState(() => _error = l10n.tableInvalid);
      return;
    }
    try {
      await ref
          .read(purchasingProvider)
          .saveDiningTable(
            id: widget.table?['id'] as String?,
            storeId: widget.storeId,
            name: _name.text,
            area: _area.text,
            capacity: capacity,
            isActive: _active,
          );
      if (mounted) Navigator.pop(context, true);
    } on Exception catch (e) {
      setState(() => _error = l10n.commonError('$e'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(widget.table == null ? l10n.tableNew : l10n.tableEdit),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('table-name'),
              controller: _name,
              autofocus: true,
              decoration: InputDecoration(labelText: l10n.tableName),
            ),
            TextField(
              controller: _area,
              decoration: InputDecoration(labelText: l10n.tableArea),
            ),
            TextField(
              key: const Key('table-capacity'),
              controller: _capacity,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: l10n.tableCapacity),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.commonActive),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: AppColors.error)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          key: const Key('table-save'),
          onPressed: _save,
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}
