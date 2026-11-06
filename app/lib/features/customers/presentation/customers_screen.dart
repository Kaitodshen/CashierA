import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/empty_state.dart';
import 'package:cashiera/core/design_system/widgets/toasts.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/pos/money_input.dart';
import 'package:cashiera/core/pos/pos_config.dart';
import 'package:cashiera/core/pos/pos_services.dart';
import 'package:cashiera/core/printing/slips.dart';
import 'package:cashiera/core/providers.dart';
import 'package:cashiera/features/customers/presentation/customer_providers.dart';
import 'package:cashiera/features/pos_home/presentation/widgets/terminal_status_chip.dart';
import 'package:cashiera/features/printing/print_actions.dart';
import 'package:cashiera/features/sell/presentation/refund_screen.dart';
import 'package:cashiera/features/sell/presentation/sell_dialogs.dart';
import 'package:cashiera/features/sell/presentation/sell_providers.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

final _day = DateFormat('dd/MM/yyyy');

String repaymentProblemText(AppLocalizations l10n, RepaymentProblem p) =>
    switch (p) {
      RepaymentProblem.invalidAmount => l10n.repayInvalid,
      RepaymentProblem.nothingOwed => l10n.repayNothing,
      RepaymentProblem.exceedsBalance => l10n.repayExceeds,
    };

/// Name and phone of a customer (new or edited).
Future<(String, String)?> showCustomerForm(
  BuildContext context, {
  String name = '',
  String phone = '',
}) => showDialog<(String, String)>(
  context: context,
  builder: (context) {
    final l10n = context.l10n;
    final form = GlobalKey<FormState>();
    final nameField = TextEditingController(text: name);
    final phoneField = TextEditingController(text: phone);
    void save() {
      if (form.currentState!.validate()) {
        Navigator.pop(context, (nameField.text.trim(), phoneField.text.trim()));
      }
    }

    return AlertDialog(
      title: Text(name.isEmpty ? l10n.sellAddCustomer : l10n.customerEdit),
      content: SizedBox(
        width: 360,
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('customer-name'),
                controller: nameField,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: l10n.customerName),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? l10n.commonRequired : null,
              ),
              TextFormField(
                key: const Key('customer-phone'),
                controller: phoneField,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: l10n.customerPhone),
                validator: (v) {
                  final digits = (v ?? '').replaceAll(RegExp(r'[\s-]'), '');
                  return digits.isEmpty ||
                          CustomerService.phonePattern.hasMatch(digits)
                      ? null
                      : l10n.customerPhoneInvalid;
                },
                onFieldSubmitted: (_) => save(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          key: const Key('customer-save'),
          onPressed: save,
          child: Text(l10n.commonSave),
        ),
      ],
    );
  },
);

/// The store's customers: search, points and kasbon at a glance.
class CustomersScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  String _query = '';

  Future<void> _add() async {
    final l10n = context.l10n;
    final ctx = ref.read(saleContextProvider);
    final input = await showCustomerForm(context);
    if (input == null || ctx == null || !mounted) return;
    try {
      final c = await ref
          .read(customerServiceProvider)
          .quickAdd(
            staff: ctx.staff,
            storeId: ctx.config.storeId,
            name: input.$1,
            phone: input.$2,
          );
      ref.read(syncSchedulerProvider.notifier).syncNow().ignore();
      if (mounted) context.go(AppRoutes.customer(c.id));
    } on Exception catch (e) {
      if (mounted) AppToast.error(context, posErrorText(l10n, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final customers =
        ref.watch(customerSearchProvider(_query)).value ?? const [];
    final owed = ref.watch(kasbonOutstandingProvider).value ?? const {};
    final canAdd = ref.watch(saleContextProvider)?.staff.can('customer.manage');

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.pos)),
        title: Text(l10n.customersTitle),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: TerminalStatusChip(),
          ),
        ],
      ),
      floatingActionButton: canAdd ?? false
          ? FloatingActionButton.extended(
              key: const Key('customer-add'),
              onPressed: _add,
              icon: const Icon(Icons.person_add_alt),
              label: Text(l10n.commonAdd),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: TextField(
              key: const Key('customer-search'),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.customersSearch,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: customers.isEmpty
                ? EmptyState(
                    icon: Icons.people_outline,
                    message: l10n.customersEmpty,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: customers.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final c = customers[i];
                      final debt = owed[c.id];
                      return ListTile(
                        key: Key('customer-${c.id}'),
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(c.name),
                        subtitle: Text(
                          [
                            ?c.phone,
                            l10n.customersPoints(c.pointsBalance),
                          ].join(' · '),
                        ),
                        trailing: debt == null
                            ? null
                            : Text(
                                l10n.customersOwes(debt.format()),
                                style: const TextStyle(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                        onTap: () => context.go(AppRoutes.customer(c.id)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// One customer: points, open kasbon, installments, and **Bayar kasbon**.
class CustomerDetailScreen extends ConsumerStatefulWidget {
  const new({required this.customerId, super.key});

  final String customerId;

  @override
  ConsumerState<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  bool _busy = false;

  Future<void> _edit(CustomerRow c) async {
    final l10n = context.l10n;
    final ctx = ref.read(saleContextProvider);
    final input = await showCustomerForm(
      context,
      name: c.name,
      phone: c.phone ?? '',
    );
    if (input == null || ctx == null || !mounted) return;
    try {
      await ref
          .read(customerServiceProvider)
          .update(
            staff: ctx.staff,
            storeId: ctx.config.storeId,
            id: c.id,
            name: input.$1,
            phone: input.$2,
          );
      ref.read(syncSchedulerProvider.notifier).syncNow().ignore();
      if (mounted) AppToast.success(context, l10n.customerSaved);
    } on Exception catch (e) {
      if (mounted) AppToast.error(context, posErrorText(l10n, e));
    }
  }

  Future<void> _repay(CustomerRow c, Money owed) async {
    final l10n = context.l10n;
    final ctx = ref.read(saleContextProvider);
    if (ctx == null) return;
    final input = await showDialog<(Money, String, String?)>(
      context: context,
      builder: (_) => _RepayDialog(
        name: c.name,
        owed: owed,
        methods: [
          for (final o in ctx.config.paymentOptions)
            if (o.kind != TenderKind.kasbon) o,
        ],
        hasShift: ctx.shiftId != null,
      ),
    );
    if (input == null || !mounted) return;
    final (amount, method, reference) = input;
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(kasbonServiceProvider)
          .repay(
            customerId: c.id,
            amount: amount,
            methodType: method,
            reference: reference,
            ctx: ctx,
          );
      ref.read(syncSchedulerProvider.notifier).syncNow().ignore();
      if (!mounted) return;
      AppToast.success(
        context,
        l10n.repayDone(amount.format(), result.balanceAfter.format()),
      );
      final printer = await ref.read(printerRepositoryProvider).current();
      if (!mounted) return;
      if (printer != null) {
        await printSlip(
          context,
          ref,
          kasbonSlipDocument(
            kasbonSlip(l10n, ctx.config, c.name, ctx.staff.fullName, result),
            openDrawer: method == 'cash',
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) AppToast.error(context, kasbonErrorText(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final customer = ref.watch(customerRowProvider(widget.customerId)).value;
    final kasbon =
        ref.watch(customerKasbonProvider(widget.customerId)).value ?? const [];
    final installments =
        ref.watch(customerInstallmentsProvider(widget.customerId)).value ??
        const [];
    final numbers = ref.watch(localOrderNumbersProvider).value ?? const {};
    final ctx = ref.watch(saleContextProvider);
    final config = ctx?.config;
    final today = config?.businessDate(clock.now()) ?? clock.now();
    final owed = totalOutstanding([
      for (final r in kasbon)
        KasbonDebt(
          orderId: r.orderId,
          amount: Money(r.amount),
          paid: Money(r.paidAmount),
          dueDate: r.dueDate,
        ),
    ]);
    final time = DateFormat('dd/MM HH:mm');

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.customers)),
        title: Text(customer?.name ?? l10n.customersTitle),
        actions: [
          if (customer != null && (ctx?.staff.can('customer.manage') ?? false))
            IconButton(
              key: const Key('customer-edit'),
              tooltip: l10n.customerEdit,
              onPressed: () => _edit(customer),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: customer == null
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.stars_outlined),
                        title: Text(
                          l10n.customersPoints(customer.pointsBalance),
                          key: const Key('customer-points'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        subtitle: Text(
                          [?customer.code, ?customer.phone].join(' · '),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.customerTotalOwed(owed.format()),
                            key: const Key('customer-owed'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (ctx?.staff.can('kasbon.manage') ?? false)
                          FilledButton.icon(
                            key: const Key('customer-pay'),
                            onPressed: _busy || owed.rupiah == 0
                                ? null
                                : () => _repay(customer, owed),
                            icon: const Icon(Icons.payments_outlined),
                            label: Text(l10n.customerPay),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Card(
                      child: Column(
                        children: [
                          if (kasbon.isEmpty)
                            ListTile(title: Text(l10n.customerNoKasbon)),
                          for (final r in kasbon)
                            () {
                              final debt = KasbonDebt(
                                orderId: r.orderId,
                                amount: Money(r.amount),
                                paid: Money(r.paidAmount),
                                dueDate: r.dueDate,
                              );
                              final late = debt.daysLate(today);
                              return ListTile(
                                key: Key('kasbon-${r.orderId}'),
                                title: Text(
                                  l10n.customerKasbonLine(
                                    debt.remaining.format(),
                                    debt.amount.format(),
                                  ),
                                ),
                                subtitle: Text(
                                  [
                                    ?numbers[r.orderId],
                                    l10n.customerDue(_day.format(r.dueDate)),
                                  ].join(' · '),
                                ),
                                trailing: late > 0
                                    ? Text(
                                        l10n.customerOverdue(late),
                                        style: const TextStyle(
                                          color: AppColors.error,
                                        ),
                                      )
                                    : null,
                              );
                            }(),
                        ],
                      ),
                    ),
                    if (installments.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        l10n.customerInstallments,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Card(
                        child: Column(
                          children: [
                            for (final p in installments)
                              ListTile(
                                dense: true,
                                title: Text(Money(p.amount).format()),
                                subtitle: Text(
                                  [
                                    time.format(
                                      config?.localTime(p.paidAt) ??
                                          p.paidAt.toLocal(),
                                    ),
                                    refundMethodLabel(l10n, p.methodType),
                                    ?p.reference,
                                    p.employeeName,
                                  ].join(' · '),
                                ),
                                trailing: Text(numbers[p.orderId] ?? ''),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

String kasbonErrorText(AppLocalizations l10n, Object e) => switch (e) {
  RepaymentRejected(:final problem) => repaymentProblemText(l10n, problem),
  _ => posErrorText(l10n, e),
};

/// The slip handed to the customer after an installment.
KasbonSlipData kasbonSlip(
  AppLocalizations l10n,
  PosConfig config,
  String customerName,
  String cashierName,
  RepaymentResult r,
) => KasbonSlipData(
  headerLines: [config.business.name, config.storeName],
  title: l10n.kasbonSlipTitle,
  dateText: DateFormat('dd/MM/yyyy HH:mm').format(config.localTime(r.paidAt)),
  customerLine: l10n.kasbonSlipCustomer(customerName),
  cashierLine: l10n.kasbonSlipCashier(cashierName),
  rows: [
    (l10n.kasbonSlipBefore, r.balanceBefore.format(), false),
    (l10n.kasbonSlipPaid, '-${r.amount.format()}', false),
    (l10n.kasbonSlipAfter, r.balanceAfter.format(), true),
  ],
  methodLine: l10n.kasbonSlipMethod(
    [refundMethodLabel(l10n, r.methodType), ?r.reference].join(' · '),
  ),
  settledText: r.balanceAfter.rupiah == 0 ? l10n.kasbonSlipSettled : null,
);

class _RepayDialog extends StatefulWidget {
  const new({
    required this.name,
    required this.owed,
    required this.methods,
    required this.hasShift,
  });

  final String name;
  final Money owed;
  final List<PaymentOption> methods;
  final bool hasShift;

  @override
  State<_RepayDialog> createState() => _RepayDialogState();
}

class _RepayDialogState extends State<_RepayDialog> {
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  late String _method = _types.contains('cash') ? 'cash' : _types.first;
  String? _error;

  List<String> get _types => [
    for (final m in kasbonRepaymentMethods)
      if ((m != 'cash' || widget.hasShift) &&
          (m == 'cash' || widget.methods.any((o) => o.kind.code == m)))
        m,
  ];

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = context.l10n;
    final amount = parseRupiah(_amount.text) ?? 0;
    final problem = amount <= 0
        ? RepaymentProblem.invalidAmount
        : amount > widget.owed.rupiah
        ? RepaymentProblem.exceedsBalance
        : null;
    if (problem != null) {
      setState(() => _error = repaymentProblemText(l10n, problem));
      return;
    }
    Navigator.pop(context, (
      Money(amount),
      _method,
      _reference.text.trim().isEmpty ? null : _reference.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.repayTitle(widget.name)),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.repayOwed(widget.owed.format())),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('repay-amount'),
                    controller: _amount,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: rupiahInputFormatters,
                    decoration: InputDecoration(
                      labelText: l10n.repayAmount,
                      prefixText: 'Rp ',
                      errorText: _error,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                TextButton(
                  key: const Key('repay-all'),
                  onPressed: () => _amount.text = '${widget.owed.rupiah}',
                  child: Text(l10n.repayAll),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.repayMethod),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final m in _types)
                  ChoiceChip(
                    key: Key('repay-method-$m'),
                    label: Text(refundMethodLabel(l10n, m)),
                    selected: m == _method,
                    onSelected: (_) => setState(() => _method = m),
                  ),
              ],
            ),
            if (_method != 'cash')
              TextField(
                key: const Key('repay-reference'),
                controller: _reference,
                decoration: InputDecoration(labelText: l10n.repayReference),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          key: const Key('repay-submit'),
          onPressed: _submit,
          child: Text(l10n.customerPay),
        ),
      ],
    );
  }
}
