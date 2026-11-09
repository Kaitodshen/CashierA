import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/empty_state.dart';
import 'package:cashiera/core/design_system/widgets/toasts.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/features/back_office/data/catalog_admin_models.dart';
import 'package:cashiera/features/back_office/presentation/back_office_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _colorPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');

/// Categories in cashier-screen order. Drag to reorder.
class CategoriesScreen extends ConsumerWidget {
  const new({super.key});

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, [
    AdminCategory? category,
    int? nextSort,
  ]) async {
    final l10n = context.l10n;
    final result = await showDialog<(String, String?, bool)>(
      context: context,
      builder: (_) => _CategoryDialog(category: category),
    );
    if (result == null || !context.mounted) return;
    try {
      await ref
          .read(catalogAdminProvider)
          .saveCategory(
            id: category?.id,
            name: result.$1,
            color: result.$2,
            isActive: result.$3,
            sortOrder: category?.sortOrder ?? nextSort,
          );
      ref.invalidate(adminCategoriesProvider);
      if (context.mounted) AppToast.success(context, l10n.commonSaved);
    } on BackendException catch (e) {
      if (context.mounted) AppToast.error(context, l10n.commonError(e.message));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final canEdit =
        ref.watch(principalProvider).value?.can('catalog.manage') ?? false;
    final categories = ref.watch(adminCategoriesProvider);
    final list = categories.value ?? const <AdminCategory>[];

    return Scaffold(
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => _edit(
                context,
                ref,
                null,
                ((list.isEmpty ? 0 : list.last.sortOrder) ~/ 10 + 1) * 10,
              ),
              icon: const Icon(Icons.add),
              label: Text(l10n.commonAdd),
            )
          : null,
      body: categories.isLoading
          ? const Center(child: CircularProgressIndicator())
          : list.isEmpty
          ? EmptyState(
              icon: Icons.category_outlined,
              message: l10n.categoriesEmpty,
            )
          : Column(
              children: [
                if (canEdit)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(l10n.categoryOrderHint),
                  ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      96,
                    ),
                    buildDefaultDragHandles: canEdit,
                    itemCount: list.length,
                    onReorderItem: (from, to) async {
                      final ordered = [...list];
                      final moved = ordered.removeAt(from);
                      ordered.insert(to, moved);
                      await ref
                          .read(catalogAdminProvider)
                          .reorderCategories(ordered);
                      ref.invalidate(adminCategoriesProvider);
                    },
                    itemBuilder: (context, i) {
                      final c = list[i];
                      return Card(
                        key: ValueKey(c.id),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _color(c.color),
                            radius: 10,
                          ),
                          title: Text(
                            c.name,
                            style: TextStyle(
                              decoration: c.isActive
                                  ? null
                                  : TextDecoration.lineThrough,
                            ),
                          ),
                          subtitle: c.isActive
                              ? null
                              : Text(l10n.commonInactive),
                          onTap: canEdit ? () => _edit(context, ref, c) : null,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

Color _color(String? hex) => hex != null && _colorPattern.hasMatch(hex)
    ? Color(int.parse('FF${hex.substring(1)}', radix: 16))
    : AppColors.textMuted;

class _CategoryDialog extends StatefulWidget {
  const new({this.category});

  final AdminCategory? category;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.category?.name);
  late final _color = TextEditingController(text: widget.category?.color);
  late bool _active = widget.category?.isActive ?? true;

  @override
  void dispose() {
    _name.dispose();
    _color.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(widget.category == null ? l10n.commonAdd : l10n.commonEdit),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              autofocus: true,
              decoration: InputDecoration(labelText: l10n.categoryName),
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? l10n.commonRequired : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _color,
              decoration: InputDecoration(labelText: l10n.categoryColor),
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ||
                      _colorPattern.hasMatch(v!.trim())
                  ? null
                  : l10n.categoryColor,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.commonActive),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
          ],
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
            final color = _color.text.trim();
            Navigator.of(
              context,
            ).pop((_name.text.trim(), color.isEmpty ? null : color, _active));
          },
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}
