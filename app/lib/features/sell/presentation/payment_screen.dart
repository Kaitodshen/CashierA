import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/toasts.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/pos/money_input.dart';
import 'package:cashiera/core/pos/pos_config.dart';
import 'package:cashiera/core/pos/pos_services.dart';
import 'package:cashiera/core/providers.dart';
import 'package:cashiera/features/printing/print_actions.dart';
import 'package:cashiera/features/sell/presentation/cart_panel.dart';
import 'package:cashiera/features/sell/presentation/qris_dialog.dart';
import 'package:cashiera/features/sell/presentation/sell_dialogs.dart';
import 'package:cashiera/features/sell/presentation/sell_providers.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

/// Banknote-friendly amounts at or above [due]: exact, then the next
/// multiples of Rp 5.000, 10.000, 50.000 and 100.000.
List<int> quickCashAmounts(int due) {
  if (due <= 0) return const [];
  final amounts = <int>{due};
  for (final unit in const [5000, 10000, 20000, 50000, 100000]) {
    final next = (due + unit - 1) ~/ unit * unit;
    if (next > due) amounts.add(next);
  }
  return (amounts.toList()..sort()).take(4).toList();
}

String settlementProblemText(AppLocalizations l10n, SettlementProblem p) =>
    switch (p) {
      SettlementProblem.invalidAmount => l10n.payInvalidAmount,
      SettlementProblem.nonCashExceedsDue => l10n.payNonCashTooMuch,
      SettlementProblem.multipleKasbon => l10n.payOneKasbon,
      SettlementProblem.unneededTender => l10n.payUnneeded,
    };

class PaymentScreen extends ConsumerStatefulWidget {
  const new({this.initialMethodId, this.initialAmount, super.key});

  /// Payment method to select on arrival (the cart's tiles); ignored when the
  /// store does not offer it.
  final String? initialMethodId;

  /// Amount to type in after selecting [initialMethodId] (quick cash).
  final int? initialAmount;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  static const _uuid = Uuid();
  bool _initialApplied = false;
  final _tenders = <Tender>[];
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  PaymentOption? _method;
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  void _addTender(PaymentOption method, int amount) {
    final l10n = context.l10n;
    if (amount <= 0) {
      AppToast.error(context, l10n.payInvalidAmount);
      return;
    }
    final reference = _reference.text.trim();
    if (method.requiresReference && reference.isEmpty) {
      AppToast.error(context, l10n.payReferenceRequired(method.name));
      return;
    }
    setState(() {
      _tenders.add(
        Tender(
          id: _uuid.v7(),
          methodId: method.id,
          kind: method.kind,
          amount: Money(amount),
          reference: reference.isEmpty ? null : reference,
        ),
      );
      _amount.clear();
      _reference.clear();
      _method = null;
    });
  }

  /// Once: select the method (and amount) the cart asked for.
  void _applyInitial(List<PaymentOption> options, int remaining) {
    if (_initialApplied) return;
    _initialApplied = true;
    final initial = options
        .where((o) => o.id == widget.initialMethodId)
        .firstOrNull;
    if (initial == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _select(initial, remaining);
      final amount = widget.initialAmount;
      if (mounted && amount != null && amount > 0) {
        setState(() => _amount.text = '$amount');
      }
    });
  }

  Future<void> _select(PaymentOption method, int remaining) async {
    if (method.kind == TenderKind.kasbon &&
        ref.read(cartControllerProvider).customer == null) {
      final customer = await showCustomerPicker(context);
      if (customer == null || !mounted) return;
      ref.read(cartControllerProvider.notifier).setCustomer(customer);
    }
    setState(() {
      _method = method;
      _amount.text = remaining > 0 ? '$remaining' : '';
    });
  }

  /// Dynamic QRIS: show the QR, and keep the payment on the bill once the
  /// gateway confirms it.
  Future<void> _gateway(PaymentOption method, int amount) async {
    final l10n = context.l10n;
    final gateway = ref.read(paymentGatewayProvider);
    final ctx = ref.read(saleContextProvider);
    if (gateway == null || ctx == null) return;
    if (amount <= 0) {
      AppToast.error(context, l10n.payInvalidAmount);
      return;
    }
    final cart = ref.read(cartControllerProvider);
    final paid = await showQrisDialog(
      context,
      gateway: gateway,
      storeId: ctx.config.storeId,
      paymentMethodId: method.id,
      orderId: cart.orderId,
      orderNumber: cart.orderNumber,
      amount: Money(amount),
    );
    if (paid == null || !mounted) return;
    ref
        .read(cartControllerProvider.notifier)
        .addGatewayTender(
          Tender(
            id: paid.id,
            methodId: method.id,
            kind: method.kind,
            amount: paid.amount,
            reference: paid.providerRef,
            provider: method.gateway,
            providerRef: paid.providerRef,
          ),
        );
    setState(() {
      _amount.clear();
      _method = null;
    });
    AppToast.success(context, l10n.qrisPaid(paid.amount.format()));
  }

  Future<void> _finish(Bill bill, Settlement settlement) async {
    final l10n = context.l10n;
    final ctx = ref.read(saleContextProvider);
    if (ctx == null) return;
    if (!await ensureDiscountApproval(context, ref)) return;
    setState(() => _busy = true);
    try {
      final order = await ref
          .read(orderServiceProvider)
          .complete(
            cart: ref.read(cartControllerProvider),
            bill: bill,
            settlement: settlement,
            ctx: ctx,
          );
      ref.read(cartControllerProvider.notifier).clear();
      ref.read(syncSchedulerProvider.notifier).syncNow().ignore();
      if (mounted) context.go(AppRoutes.receipt(order.id, justSold: true));
    } on PosStateException catch (e) {
      if (mounted) AppToast.error(context, posErrorText(l10n, e));
    } on PosPermissionException catch (e) {
      if (mounted) AppToast.error(context, posErrorText(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final bill = ref.watch(currentBillProvider(discountLabels(l10n)));
    final ctx = ref.watch(saleContextProvider);
    final cart = ref.watch(cartControllerProvider);
    if (bill == null || ctx == null || cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.go(AppRoutes.sell)),
        ),
        body: Center(child: Text(l10n.sellEmpty)),
      );
    }

    final tenders = [...cart.gatewayTenders, ..._tenders];
    final settlement = settle(bill.grandTotal, tenders);
    final remaining = settlement.problem == null
        ? settlement.remaining.rupiah
        : bill.grandTotal.rupiah -
              tenders.fold<int>(0, (a, t) => a + t.amount.rupiah);
    final hasGateway = ref.watch(paymentGatewayProvider) != null;
    final options = ctx.config.paymentOptions
        .where(
          (o) =>
              o.kind != TenderKind.kasbon ||
              (ctx.config.kasbonEnabled && ctx.staff.can('kasbon.manage')),
        )
        .where((o) => o.gateway == null || hasGateway)
        .toList();
    final method = _method;
    _applyInitial(options, remaining);

    final summary = Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.payDue, style: theme.textTheme.titleMedium),
            Text(
              bill.grandTotal.format(),
              key: const Key('pay-due'),
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (cart.customer != null)
              Text(l10n.payCustomer(cart.customer!.name)),
            const Divider(height: AppSpacing.xl),
            for (final (i, t) in tenders.indexed)
              ListTile(
                key: Key('tender-$i'),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  options.where((o) => o.id == t.methodId).firstOrNull?.name ??
                      t.kind.code,
                ),
                subtitle: t.reference == null ? null : Text(t.reference!),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(t.amount.format()),
                    if (t.isGateway)
                      const Padding(
                        padding: EdgeInsets.all(AppSpacing.sm),
                        child: Icon(Icons.verified, color: AppColors.success),
                      )
                    else
                      IconButton(
                        tooltip: l10n.sellRemove,
                        onPressed: () => setState(() => _tenders.remove(t)),
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
              ),
            if (settlement.problem != null)
              Text(
                settlementProblemText(l10n, settlement.problem!),
                style: const TextStyle(color: AppColors.error),
              )
            else if (remaining > 0)
              Text(
                l10n.payRemaining(Money(remaining).format()),
                key: const Key('pay-remaining'),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.warning,
                ),
              )
            else if (settlement.changeTotal.rupiah > 0)
              Text(
                l10n.payChange(settlement.changeTotal.format()),
                key: const Key('pay-change'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (settlement.kasbonAmount.rupiah > 0)
              Text(
                l10n.payKasbonNote(
                  settlement.kasbonAmount.format(),
                  ctx.config.business.kasbonDueDays,
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              key: const Key('pay-finish'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              onPressed: settlement.isComplete && !_busy
                  ? () => _finish(bill, settlement)
                  : null,
              child: Text(l10n.payFinish),
            ),
          ],
        ),
      ),
    );

    final entry = Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.payMethod, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final o in options)
                  ChoiceChip(
                    key: Key('pay-method-${o.code}'),
                    label: Text(o.name),
                    selected: method?.id == o.id,
                    onSelected: remaining > 0
                        ? (_) => _select(o, remaining)
                        : null,
                  ),
              ],
            ),
            if (method != null) ...[
              const SizedBox(height: AppSpacing.lg),
              if (method.kind == TenderKind.cash) ...[
                Text(l10n.payQuickCash),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final (i, amount) in quickCashAmounts(
                      remaining,
                    ).indexed)
                      ActionChip(
                        key: Key('pay-quick-$i'),
                        label: Text(
                          i == 0 ? l10n.payExact : Money(amount).format(),
                        ),
                        onPressed: () => _addTender(method, amount),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              TextField(
                key: const Key('pay-amount'),
                controller: _amount,
                keyboardType: TextInputType.number,
                inputFormatters: rupiahInputFormatters,
                decoration: InputDecoration(
                  labelText: method.kind == TenderKind.cash
                      ? l10n.payTendered
                      : l10n.payAmount,
                  prefixText: 'Rp ',
                ),
                onSubmitted: (v) => _addTender(method, parseRupiah(v) ?? 0),
              ),
              if (method.gateway == null &&
                  method.kind != TenderKind.cash &&
                  method.kind != TenderKind.kasbon) ...[
                const SizedBox(height: AppSpacing.md),
                TextField(
                  key: const Key('pay-reference'),
                  controller: _reference,
                  decoration: InputDecoration(
                    labelText: method.requiresReference
                        ? l10n.payReference
                        : l10n.payReferenceOptional,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              if (method.gateway != null)
                FilledButton.icon(
                  key: const Key('pay-qris-create'),
                  onPressed: () =>
                      _gateway(method, parseRupiah(_amount.text) ?? 0),
                  icon: const Icon(Icons.qr_code_2),
                  label: Text(l10n.payQrisCreate),
                )
              else
                FilledButton.tonal(
                  key: const Key('pay-add'),
                  onPressed: () =>
                      _addTender(method, parseRupiah(_amount.text) ?? 0),
                  child: Text(l10n.payAdd(method.name)),
                ),
            ],
          ],
        ),
      ),
    );

    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.sell)),
        title: Text(l10n.payTitle(cart.orderNumber ?? l10n.sellNewBill)),
      ),
      body: SafeArea(
        child: wide
            ? Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: SingleChildScrollView(child: summary)),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(child: SingleChildScrollView(child: entry)),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  entry,
                  const SizedBox(height: AppSpacing.md),
                  summary,
                ],
              ),
      ),
    );
  }
}
