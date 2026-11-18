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
import 'package:cashiera/features/back_office/presentation/stores_admin_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String roleLabel(AppLocalizations l10n, String code) => switch (code) {
  'owner' => l10n.roleOwner,
  'manager' => l10n.roleManager,
  'cashier' => l10n.roleCashier,
  'kitchen' => l10n.roleKitchen,
  'inventory' => l10n.roleInventory,
  _ => code,
};

/// What the viewer may do: which stores they manage and which rows.
class StaffPermissions {
  const new({required this.principal, required this.stores});

  final Principal? principal;
  final List<AdminStore> stores;

  bool get isOwner => principal?.roleCode == 'owner';
  bool get canManage => isOwner || (principal?.can('employee.manage') ?? false);

  /// Stores the viewer may put staff in.
  List<AdminStore> get manageableStores => isOwner
      ? stores
      : [
          for (final s in stores)
            if (principal?.storeIds.contains(s.id) ?? false) s,
        ];

  /// Full management (edit, invite, deactivate) of [s].
  bool canManageRow(AdminStaff s) {
    if (!canManage || s.isOwner) return false;
    if (isOwner) return true;
    final mine = principal?.storeIds ?? const <String>[];
    return s.storeIds.isEmpty || s.storeIds.any(mine.contains);
  }

  /// Anyone may set their own PIN; managers set the PINs they manage.
  bool canSetPin(AdminStaff s) =>
      canManageRow(s) || s.id == principal?.employeeId;
}

/// Settings → Staff: who works where, their PINs and back-office logins.
class StaffAdminScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<StaffAdminScreen> createState() => _StaffAdminScreenState();
}

class _StaffAdminScreenState extends ConsumerState<StaffAdminScreen> {
  String _search = '';
  String? _storeId;

  void _refresh() => ref.invalidate(adminStaffListProvider);

  Future<void> _edit(StaffPermissions can, [AdminStaff? staff]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _StaffDialog(staff: staff, stores: can.manageableStores),
    );
    if (!(saved ?? false)) return;
    _refresh();
    if (mounted) AppToast.success(context, context.l10n.staffSaved);
  }

  Future<void> _pin(AdminStaff s) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _PinDialog(staff: s),
    );
    if (!(saved ?? false)) return;
    _refresh();
    if (mounted) AppToast.success(context, context.l10n.staffPinSaved);
  }

  Future<void> _invite(AdminStaff s) async {
    final email = await showDialog<String>(
      context: context,
      builder: (_) => _InviteDialog(staff: s),
    );
    if (email == null) return;
    _refresh();
    if (mounted) {
      AppToast.success(context, context.l10n.staffInviteSent(email));
    }
  }

  Future<void> _toggle(AdminStaff s) async {
    final l10n = context.l10n;
    if (s.isActive) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => GlassDialog(
          title: Text(l10n.staffDeactivateTitle(s.fullName)),
          content: SingleChildScrollView(child: Text(l10n.staffDeactivateBody)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonCancel),
            ),
            PrimaryButton(
              key: const Key('staff-toggle-confirm'),
              onPressed: () => Navigator.pop(context, true),
              label: l10n.staffDeactivate,
            ),
          ],
        ),
      );
      if (!(ok ?? false)) return;
    }
    try {
      await ref.read(staffAdminProvider).setActive(s.id, isActive: !s.isActive);
      _refresh();
    } on BackendException catch (e) {
      if (mounted) AppToast.error(context, staffErrorText(l10n, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final principal = ref.watch(principalProvider).value;
    final stores = ref.watch(adminStoresListProvider).value ?? const [];
    final staff = ref.watch(adminStaffListProvider);
    final can = StaffPermissions(principal: principal, stores: stores);
    final codes = {for (final s in stores) s.id: s.code};
    final term = _search.trim().toLowerCase();
    final list = [
      for (final s in staff.value ?? const <AdminStaff>[])
        if ((term.isEmpty || s.fullName.toLowerCase().contains(term)) &&
            (_storeId == null || s.isOwner || s.storeIds.contains(_storeId)))
          s,
    ];
    final muted = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: AppColors.textMuted);

    return AdminPage(
      toolbar: AdminToolbar(
        filters: [
          SizedBox(
            width: 260,
            child: TextField(
              key: const Key('staff-search'),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.staffSearch,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<String?>(
              key: const Key('staff-store'),
              initialValue: _storeId,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.staffStores),
              items: [
                DropdownMenuItem(child: Text(l10n.staffAllStoresFilter)),
                for (final s in can.manageableStores)
                  DropdownMenuItem(value: s.id, child: Text(s.name)),
              ],
              onChanged: (v) => setState(() => _storeId = v),
            ),
          ),
        ],
        actions: [
          if (can.canManage)
            PrimaryButton(
              key: const Key('staff-add'),
              onPressed: () => _edit(can),
              icon: Icons.person_add_alt,
              label: l10n.staffAdd,
            ),
        ],
      ),
      children: [
        if (staff.isLoading && list.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (staff.hasError)
          adminMessage(
            icon: Icons.cloud_off_outlined,
            message: l10n.commonError('${staff.error}'),
          )
        else if (list.isEmpty)
          adminMessage(icon: Icons.badge_outlined, message: l10n.staffEmpty)
        else
          GlassTable<AdminStaff>(
            rows: list,
            onRowTap: (s) => can.canManageRow(s) ? _edit(can, s) : null,
            columns: [
              GlassColumn(
                label: l10n.staffColPerson,
                flex: 4,
                cell: (s) => Row(
                  key: Key('staff-${s.id}'),
                  children: [
                    InitialsAvatar(name: s.fullName, size: 40),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            s.fullName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              decoration: s.isActive
                                  ? null
                                  : TextDecoration.lineThrough,
                            ),
                          ),
                          if (s.phone != null) Text(s.phone!, style: muted),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              GlassColumn(
                label: l10n.staffColRole,
                flex: 2,
                cell: (s) => StatusChip(
                  label: roleLabel(l10n, s.roleCode),
                  tone: s.isOwner ? StatusTone.primary : StatusTone.neutral,
                ),
              ),
              GlassColumn(
                label: l10n.staffColStores,
                flex: 2,
                cell: (s) => Text(
                  s.isOwner
                      ? l10n.staffAllStores
                      : [for (final id in s.storeIds) codes[id] ?? '?']
                            .join(', '),
                ),
              ),
              GlassColumn(
                label: l10n.staffColLogin,
                flex: 3,
                cell: (s) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatusChip(
                      label: !s.hasLogin
                          ? l10n.staffLoginNone
                          : s.loginConfirmed
                          ? l10n.staffLoginActive
                          : l10n.staffLoginInvited,
                      tone: !s.hasLogin
                          ? StatusTone.neutral
                          : s.loginConfirmed
                          ? StatusTone.success
                          : StatusTone.warning,
                    ),
                    if (s.email != null)
                      Text(
                        s.email!,
                        style: muted,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              GlassColumn(
                label: l10n.staffColPin,
                cell: (s) => StatusChip(
                  label: s.hasPin ? l10n.staffPinSet : l10n.staffPinMissing,
                  tone: s.hasPin ? StatusTone.success : StatusTone.warning,
                ),
              ),
              GlassColumn(
                label: l10n.staffActions,
                numeric: true,
                cell: (s) => !can.canSetPin(s)
                    ? const SizedBox(height: 48)
                    : PopupMenuButton<String>(
                        key: Key('staff-actions-${s.id}'),
                        tooltip: l10n.staffActions,
                        icon: const Icon(Icons.more_horiz),
                        onSelected: (action) => switch (action) {
                          'pin' => _pin(s),
                          'invite' => _invite(s),
                          _ => _toggle(s),
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            key: const Key('staff-pin'),
                            value: 'pin',
                            child: Text(l10n.staffSetPin),
                          ),
                          if (can.canManageRow(s) && !s.loginConfirmed)
                            PopupMenuItem(
                              key: const Key('staff-invite'),
                              value: 'invite',
                              child: Text(
                                s.hasLogin
                                    ? l10n.staffInviteAgain
                                    : l10n.staffInvite,
                              ),
                            ),
                          if (can.canManageRow(s))
                            PopupMenuItem(
                              key: const Key('staff-toggle'),
                              value: 'toggle',
                              child: Text(
                                s.isActive
                                    ? l10n.staffDeactivate
                                    : l10n.staffReactivate,
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
      ],
    );
  }
}

class _StaffDialog extends ConsumerStatefulWidget {
  const new({required this.stores, this.staff});

  final AdminStaff? staff;
  final List<AdminStore> stores;

  @override
  ConsumerState<_StaffDialog> createState() => _StaffDialogState();
}

class _StaffDialogState extends ConsumerState<_StaffDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.staff?.fullName);
  late final _phone = TextEditingController(text: widget.staff?.phone);
  late String _role = widget.staff?.roleCode ?? 'cashier';
  late final Set<String> _stores = {...?widget.staff?.storeIds};
  late bool _active = widget.staff?.isActive ?? true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    if (!_form.currentState!.validate()) return;
    if (_stores.isEmpty) {
      setState(() => _error = l10n.staffStoresRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(staffAdminProvider)
          .saveStaff(
            StaffInput(
              fullName: _name.text,
              phone: _phone.text,
              roleCode: _role,
              storeIds: [
                for (final s in widget.stores)
                  if (_stores.contains(s.id)) s.id,
              ],
              isActive: _active,
            ),
            id: widget.staff?.id,
          );
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
      title: Text(widget.staff == null ? l10n.staffAdd : l10n.staffEditTitle),
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
                  key: const Key('staff-name'),
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: l10n.staffName),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? l10n.commonRequired : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const Key('staff-phone'),
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(labelText: l10n.staffPhone),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  key: const Key('staff-role'),
                  initialValue: _role,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l10n.staffRole),
                  items: [
                    for (final r in staffRoles)
                      DropdownMenuItem(
                        key: ValueKey('role-$r'),
                        value: r,
                        child: Text(roleLabel(l10n, r)),
                      ),
                  ],
                  onChanged: (v) => setState(() => _role = v ?? _role),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(l10n.staffStores),
                for (final s in widget.stores)
                  CheckboxListTile(
                    key: Key('staff-store-${s.code}'),
                    contentPadding: EdgeInsets.zero,
                    value: _stores.contains(s.id),
                    title: Text('${s.code} · ${s.name}'),
                    onChanged: (v) => setState(
                      () => (v ?? false)
                          ? _stores.add(s.id)
                          : _stores.remove(s.id),
                    ),
                  ),
                SwitchListTile(
                  key: const Key('staff-active'),
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
          key: const Key('staff-save'),
          onPressed: _busy ? null : _save,
          label: l10n.commonSave,
        ),
      ],
    );
  }
}

class _PinDialog extends ConsumerStatefulWidget {
  const new({required this.staff});

  final AdminStaff staff;

  @override
  ConsumerState<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends ConsumerState<_PinDialog> {
  final _first = TextEditingController();
  final _second = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    if (_first.text != _second.text) {
      setState(() => _error = l10n.staffPinMismatch);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(staffAdminProvider).setPin(widget.staff.id, _first.text);
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
    Widget field(String key, TextEditingController c, String label) =>
        TextField(
          key: Key(key),
          controller: c,
          obscureText: true,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          decoration: InputDecoration(labelText: label),
        );
    return GlassDialog(
      title: Text(l10n.staffPinTitle(widget.staff.fullName)),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              field('pin-1', _first, l10n.staffPinNew),
              const SizedBox(height: AppSpacing.md),
              field('pin-2', _second, l10n.staffPinAgain),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(_error!, style: const TextStyle(color: AppColors.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.commonCancel),
        ),
        PrimaryButton(
          key: const Key('pin-save'),
          onPressed: _busy ? null : _save,
          label: l10n.commonSave,
        ),
      ],
    );
  }
}

class _InviteDialog extends ConsumerStatefulWidget {
  const new({required this.staff});

  final AdminStaff staff;

  @override
  ConsumerState<_InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends ConsumerState<_InviteDialog> {
  late final _email = TextEditingController(text: widget.staff.email);
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = context.l10n;
    final email = _email.text.trim().toLowerCase();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(staffAdminProvider).invite(widget.staff.id, email);
      if (mounted) Navigator.pop(context, email);
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
      title: Text(l10n.staffInviteTitle(widget.staff.fullName)),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.staffInviteBody,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const Key('invite-email'),
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: l10n.staffInviteEmail),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(_error!, style: const TextStyle(color: AppColors.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        PrimaryButton(
          key: const Key('invite-send'),
          onPressed: _busy ? null : _send,
          icon: Icons.mail_outline,
          label: l10n.staffInviteSend,
        ),
      ],
    );
  }
}
