import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/admin.dart';
import 'package:cashiera/core/design_system/widgets/buttons.dart';
import 'package:cashiera/core/design_system/widgets/data_display.dart';
import 'package:cashiera/core/design_system/widgets/glass.dart';
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

    final toolbar = AdminToolbar(
      filters: [
        if (canEdit)
          Text(
            l10n.categoryOrderHint,
            style: const TextStyle(color: AppColors.textMuted),
          ),
      ],
      actions: [
        if (canEdit)
          PrimaryButton(
            key: const Key('category-new'),
            onPressed: () => _edit(
              context,
              ref,
              null,
              ((list.isEmpty ? 0 : list.last.sortOrder) ~/ 10 + 1) * 10,
            ),
            icon: Icons.add,
            label: l10n.commonAdd,
          ),
      ],
    );

    return Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                toolbar,
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: categories.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : list.isEmpty
                      ? Align(
                          alignment: Alignment.topCenter,
                          child: adminMessage(
                            icon: Icons.category_outlined,
                            message: l10n.categoriesEmpty,
                          ),
                        )
                      : ReorderableListView.builder(
                          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
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
                            return Padding(
                              key: ValueKey(c.id),
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: GlassCard(
                                level: GlassLevel.solid,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                ),
                                onTap: canEdit
                                    ? () => _edit(context, ref, c)
                                    : null,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _color(c.color),
                                    radius: 10,
                                  ),
                                  title: Text(
                                    c.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      decoration: c.isActive
                                          ? null
                                          : TextDecoration.lineThrough,
                                    ),
                                  ),
                                  trailing: Padding(
                                    padding: const EdgeInsets.only(
                                      right: AppSpacing.xl,
                                    ),
                                    child: StatusChip(
                                      label: c.isActive
                                          ? l10n.commonActive
                                          : l10n.commonInactive,
                                      tone: c.isActive
                                          ? StatusTone.success
                                          : StatusTone.neutral,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
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
    return GlassDialog(
      title: Text(widget.category == null ? l10n.commonAdd : l10n.commonEdit),
      content: SingleChildScrollView(
        child: Form(
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
