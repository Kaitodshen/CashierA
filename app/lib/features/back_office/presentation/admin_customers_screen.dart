import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/empty_state.dart';
import 'package:cashiera/core/design_system/widgets/toasts.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/pos/money_input.dart';
import 'package:cashiera/features/back_office/data/customers_admin_repository.dart';
import 'package:cashiera/features/back_office/presentation/back_office_providers.dart';
import 'package:cashiera/features/sell/presentation/refund_screen.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

final _day = DateFormat('dd/MM/yyyy');
final _time = DateFormat('dd/MM/yyyy HH:mm');

String ledgerTypeText(AppLocalizations l10n, String type) =>
    l10n.ledgerEntryType(type);

String kasbonStatusText(AppLocalizations l10n, String status) =>
    l10n.kasbonStatus(status);

/// Edits [customer] (or a new one). Returns true when saved.
Future<bool> showAdminCustomerDialog(
  BuildContext context,
  WidgetRef ref, {
  AdminCustomer? customer,
}) async {
  final saved = await showDialog<bool>(
    context: context,
    builder: (_) => _CustomerDialog(customer: customer),
  );
  return saved ?? false;
}

class _CustomerDialog extends ConsumerStatefulWidget {
  const new({this.customer});
  final AdminCustomer? customer;

  @override
  ConsumerState<_CustomerDialog> createState() => _CustomerDialogState();
}

class _CustomerDialogState extends ConsumerState<_CustomerDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.customer?.name);
  late final _phone = TextEditingController(text: widget.customer?.phone);
  late final _email = TextEditingController(text: widget.customer?.email);
  late final _limit = TextEditingController(
    text: widget.customer?.kasbonLimit == null
        ? ''
        : '${widget.customer!.kasbonLimit!.rupiah}',
  );
  late bool _active = widget.customer?.isActive ?? true;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _limit.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final repo = ref.read(customersAdminProvider);
    final isNew = widget.customer == null;
    final c = (widget.customer ?? AdminCustomer(id: repo.newId(), name: ''))
      ..name = _name.text
      ..phone = _phone.text
      ..email = _email.text
      ..kasbonLimit = _limit.text.trim().isEmpty
          ? null
          : Money(parseRupiah(_limit.text)!)
      ..isActive = _active;
    setState(() => _busy = true);
    try {
      await repo.save(c, isNew: isNew);
      if (mounted) Navigator.pop(context, true);
    } on Exception catch (e) {
      if (mounted) AppToast.error(context, context.l10n.commonError('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(
        widget.customer == null ? l10n.sellAddCustomer : l10n.customerEdit,
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('admin-customer-name'),
                controller: _name,
                decoration: InputDecoration(labelText: l10n.customerName),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? l10n.commonRequired : null,
              ),
              TextFormField(
                key: const Key('admin-customer-phone'),
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: l10n.customerPhone),
                validator: (v) {
                  final d = (v ?? '').replaceAll(RegExp(r'[\s-]'), '');
                  return d.isEmpty || RegExp(r'^\+?[0-9]{8,15}$').hasMatch(d)
                      ? null
                      : l10n.customerPhoneInvalid;
                },
              ),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: l10n.adminCustomerEmail),
                validator: (v) {
                  final t = (v ?? '').trim();
                  return t.isEmpty ||
                          RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)
                      ? null
                      : l10n.adminEmailInvalid;
                },
              ),
              TextFormField(
                key: const Key('admin-customer-limit'),
                controller: _limit,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: l10n.adminCustomerLimit,
                  helperText: l10n.adminCustomerLimitHint,
                  prefixText: 'Rp ',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _active,
                onChanged: (v) => setState(() => _active = v),
                title: Text(l10n.commonActive),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          key: const Key('admin-customer-save'),
          onPressed: _busy ? null : _save,
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}

class AdminCustomersScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<AdminCustomersScreen> createState() =>
      _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends ConsumerState<AdminCustomersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final customers = ref.watch(adminCustomersProvider(_query));
    final canEdit =
        ref.watch(principalProvider).value?.can('customer.manage') ?? false;
    final list = customers.value ?? const <AdminCustomer>[];

    return Scaffold(
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              key: const Key('admin-customer-add'),
              onPressed: () async {
                if (await showAdminCustomerDialog(context, ref)) {
                  ref.invalidate(adminCustomersProvider);
                }
              },
              icon: const Icon(Icons.person_add_alt),
              label: Text(l10n.commonAdd),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: TextField(
              key: const Key('admin-customer-search'),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.customersSearch,
              ),
              onSubmitted: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: customers.isLoading && list.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : customers.hasError
                ? Center(child: Text(l10n.commonError('${customers.error}')))
                : list.isEmpty
                ? EmptyState(
                    icon: Icons.people_outline,
                    message: l10n.customersEmpty,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      96,
                    ),
                    itemCount: list.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) {
                      final c = list[i];
                      return Card(
                        child: ListTile(
                          key: Key('admin-customer-${c.id}'),
                          title: Text(c.name),
                          subtitle: Text(
                            [
                              ?c.code,
                              ?c.phone,
                              if (c.kasbonLimit != null)
                                l10n.adminCustomerLimitShort(
                                  c.kasbonLimit!.format(),
                                ),
                              if (!c.isActive) l10n.commonInactive,
                            ].join(' · '),
                          ),
                          trailing: Text(l10n.customersPoints(c.pointsBalance)),
                          onTap: () =>
                              context.go(AppRoutes.adminCustomer(c.id)),
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

/// A customer's points history and kasbon across the caller's stores.
class AdminCustomerScreen extends ConsumerWidget {
  const new({required this.customerId, super.key});

  final String customerId;

  Future<void> _adjust(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final points = TextEditingController();
    final note = TextEditingController();
    final form = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminAdjustPoints),
        content: SizedBox(
          width: 360,
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  key: const Key('adjust-points'),
                  controller: points,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.adminAdjustPointsField,
                  ),
                  validator: (v) => (int.tryParse((v ?? '').trim()) ?? 0) == 0
                      ? l10n.commonRequired
                      : null,
                ),
                TextFormField(
                  key: const Key('adjust-note'),
                  controller: note,
                  decoration: InputDecoration(labelText: l10n.adminAdjustNote),
                  validator: (v) =>
                      (v ?? '').trim().length < 3 ? l10n.reasonShort : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            key: const Key('adjust-save'),
            onPressed: () {
              if (form.currentState!.validate()) Navigator.pop(context, true);
            },
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
    if (!(ok ?? false) || !context.mounted) return;
    try {
      final balance = await ref
          .read(customersAdminProvider)
          .adjustPoints(customerId, int.parse(points.text.trim()), note.text);
      ref.invalidate(adminCustomerStatementProvider(customerId));
      if (context.mounted) {
        AppToast.success(context, l10n.adminAdjustDone(balance));
      }
    } on Exception catch (e) {
      if (context.mounted) AppToast.error(context, l10n.commonError('$e'));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final statement = ref.watch(adminCustomerStatementProvider(customerId));
    final principal = ref.watch(principalProvider).value;

    return switch (statement) {
      AsyncData(value: final s) => ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Row(
            children: [
              IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => context.go(AppRoutes.adminCustomers),
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Text(s.customer.name, style: theme.textTheme.titleLarge),
              ),
              if (principal?.can('customer.manage') ?? false)
                IconButton(
                  key: const Key('admin-customer-edit'),
                  tooltip: l10n.customerEdit,
                  onPressed: () async {
                    if (await showAdminCustomerDialog(
                      context,
                      ref,
                      customer: s.customer,
                    )) {
                      ref
                        ..invalidate(adminCustomerStatementProvider(customerId))
                        ..invalidate(adminCustomersProvider);
                    }
                  },
                  icon: const Icon(Icons.edit_outlined),
                ),
            ],
          ),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                l10n.customersPoints(s.customer.pointsBalance),
                key: const Key('admin-customer-points'),
                style: theme.textTheme.titleMedium,
              ),
              Text(
                l10n.customerTotalOwed(s.outstanding.format()),
                style: theme.textTheme.titleMedium,
              ),
              if (principal?.can('loyalty.adjust') ?? false)
                OutlinedButton.icon(
                  key: const Key('admin-adjust-points'),
                  onPressed: () => _adjust(context, ref),
                  icon: const Icon(Icons.tune),
                  label: Text(l10n.adminAdjustPoints),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.customerKasbon, style: theme.textTheme.titleMedium),
          if (s.kasbon.isEmpty) Text(l10n.customerNoKasbon),
          for (final k in s.kasbon)
            Card(
              child: ExpansionTile(
                title: Text(
                  '${k.orderNumber} · ${kasbonStatusText(l10n, k.status)}',
                ),
                subtitle: Text(
                  [
                    k.storeName,
                    l10n.adminKasbonPaidLine(
                      k.paid.format(),
                      k.amount.format(),
                    ),
                    l10n.customerDue(_day.format(k.dueDate)),
                  ].join(' · '),
                ),
                children: [
                  for (final p in k.payments)
                    ListTile(
                      dense: true,
                      title: Text(p.amount.format()),
                      subtitle: Text(
                        [
                          _time.format(p.paidAt.toLocal()),
                          refundMethodLabel(l10n, p.methodType),
                          ?p.employeeName,
                        ].join(' · '),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.adminPointsHistory, style: theme.textTheme.titleMedium),
          Card(
            child: Column(
              children: [
                for (final e in s.ledger)
                  ListTile(
                    dense: true,
                    title: Text(ledgerTypeText(l10n, e.entryType)),
                    subtitle: Text(
                      [
                        _time.format(e.createdAt.toLocal()),
                        ?e.orderNumber,
                        ?e.storeName,
                        ?e.note,
                        ?e.employeeName,
                      ].join(' · '),
                    ),
                    trailing: Text(
                      e.points > 0 ? '+${e.points}' : '${e.points}',
                      style: TextStyle(
                        color: e.points > 0
                            ? AppColors.success
                            : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      AsyncError(:final error) => Center(
        child: Text(l10n.commonError('$error')),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}
