import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/toasts.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/pos/pos_config.dart';
import 'package:cashiera/core/pos/pos_services.dart';
import 'package:cashiera/core/printing/slips.dart';
import 'package:cashiera/core/providers.dart';
import 'package:cashiera/features/printing/print_actions.dart';
import 'package:cashiera/features/sell/presentation/receipt_screen.dart';
import 'package:cashiera/features/sell/presentation/sell_dialogs.dart';
import 'package:cashiera/features/sell/presentation/sell_providers.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

String refundMethodLabel(AppLocalizations l10n, String methodType) =>
    switch (methodType) {
      'cash' => l10n.refundViaCash,
      'qris' => l10n.refundViaQris,
      'card' => l10n.refundViaCard,
      'transfer' => l10n.refundViaTransfer,
      'ewallet' => l10n.refundViaEwallet,
      _ => methodType,
    };

final FutureProviderFamily<OrderRefundInfo?, String> _refundInfoProvider =
    FutureProvider.autoDispose.family<OrderRefundInfo?, String>((
      ref,
      id,
    ) async {
      final order = await ref.watch(orderProvider(id).future);
      if (order == null) return null;
      return await ref.watch(refundServiceProvider).info(order);
    });

/// The slip handed to the customer with their money.
RefundSlipData refundSlip({
  required AppLocalizations l10n,
  required PosConfig config,
  required LocalOrderRow order,
  required RefundRow refund,
  required OrderRefundInfo before,
  required Map<String, Qty> quantities,
}) {
  final byId = {for (final l in before.lines) l.line.id: l};
  final plan = planRefund(
    lines: [for (final l in before.lines) l.line],
    quantities: quantities,
    refundable: before.refundable,
  );
  return RefundSlipData(
    headerLines: [config.business.name, config.storeName],
    title: l10n.refundSlipTitle,
    refundNumber: refund.refundNumber,
    orderLine: l10n.refundSlipOrder(order.orderNumber),
    dateText: DateFormat('dd/MM/yyyy HH:mm')
        .format(config.localTime(refund.refundedAt)),
    staffLine: l10n.refundSlipStaff(refund.employeeName),
    approverLine: l10n.refundSlipApprover(refund.approvedByName),
    lines: [
      for (final i in plan.items)
        (byId[i.lineId]!.name, '${i.quantity.toPlain()} x', i.amount),
    ],
    totalLabel: l10n.refundTotal,
    total: Money(refund.amount),
    methodLine: l10n.refundSlipMethod(
      refundMethodLabel(l10n, refund.methodType),
    ),
    reasonLine: l10n.refundSlipReason(refund.reason),
  );
}

class RefundScreen extends ConsumerStatefulWidget {
  const new({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<RefundScreen> createState() => _RefundScreenState();
}

class _RefundScreenState extends ConsumerState<RefundScreen> {
  final _quantities = <String, Qty>{};
  final _reason = TextEditingController();
  bool _restock = true;
  String? _method;
  bool _busy = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _set(RefundLineInfo line, int milli) => setState(() {
    final max = line.line.remainingQuantity.milli;
    final clamped = milli.clamp(0, max);
    if (clamped == 0) {
      _quantities.remove(line.line.id);
    } else {
      _quantities[line.line.id] = Qty(clamped);
    }
  });

  Future<void> _submit(
    LocalOrderRow order,
    OrderRefundInfo info,
    RefundPlan plan,
    String method,
  ) async {
    final l10n = context.l10n;
    final ctx = ref.read(saleContextProvider);
    if (ctx == null) return;
    if (_reason.text.trim().length < 3) {
      AppToast.error(context, l10n.reasonShort);
      return;
    }
    final approver = await showApprovalDialog(
      context,
      permission: 'pos.refund',
      reason: l10n.refundApproval(plan.total.format(), order.orderNumber),
    );
    if (approver == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final quantities = Map<String, Qty>.of(_quantities);
      final refund = await ref
          .read(refundServiceProvider)
          .refund(
            order: order,
            quantities: quantities,
            methodType: method,
            restock: _restock,
            reason: _reason.text,
            approver: approver,
            ctx: ctx,
          );
      ref.read(syncSchedulerProvider.notifier).syncNow().ignore();
      if (!mounted) return;
      AppToast.success(context, l10n.refundDone(refund.refundNumber));
      final printer = await ref.read(printerRepositoryProvider).current();
      if (printer != null && mounted) {
        await printSlip(
          context,
          ref,
          refundSlipDocument(
            refundSlip(
              l10n: l10n,
              config: ctx.config,
              order: order,
              refund: refund,
              before: info,
              quantities: quantities,
            ),
            openDrawer: method == 'cash',
          ),
        );
      }
      if (mounted) context.go(AppRoutes.receipt(order.id));
    } on Exception catch (e) {
      if (mounted) AppToast.error(context, posErrorText(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final order = ref.watch(orderProvider(widget.orderId)).value;
    final info = ref.watch(_refundInfoProvider(widget.orderId));
    final hasShift = ref.watch(saleContextProvider)?.shiftId != null;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => context.go(AppRoutes.receipt(widget.orderId)),
        ),
        title: Text(l10n.refundTitle(order?.orderNumber ?? '')),
      ),
      body: switch (info) {
        AsyncData(value: final data?) when order != null => () {
          if (data.fullyRefunded) {
            return Center(child: Text(l10n.refundFull));
          }
          final methods = [
            if (hasShift) 'cash',
            for (final m in refundMethodTypes)
              if (m != 'cash' && data.paidMethodTypes.contains(m)) m,
          ];
          final method = methods.contains(_method)
              ? _method
              : (methods.isEmpty ? null : methods.first);
          final plan = planRefund(
            lines: [for (final l in data.lines) l.line],
            quantities: _quantities,
            refundable: data.refundable,
          );
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                l10n.refundPickItems,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Card(
                child: Column(
                  children: [
                    for (final line in data.lines)
                      if (line.line.remainingQuantity.milli > 0)
                        _RefundLineTile(
                          key: Key('refund-line-${line.line.id}'),
                          line: line,
                          quantity: _quantities[line.line.id] ?? Qty.zero,
                          onChanged: (milli) => _set(line, milli),
                        ),
                  ],
                ),
              ),
              SwitchListTile(
                key: const Key('refund-restock'),
                value: _restock,
                onChanged: (v) => setState(() => _restock = v),
                title: Text(l10n.refundRestock),
                subtitle: Text(l10n.refundRestockHint),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.refundMethod),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final m in methods)
                    ChoiceChip(
                      key: Key('refund-method-$m'),
                      label: Text(refundMethodLabel(l10n, m)),
                      selected: m == method,
                      onSelected: (_) => setState(() => _method = m),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const Key('refund-reason'),
                controller: _reason,
                decoration: InputDecoration(labelText: l10n.refundReason),
              ),
              const SizedBox(height: AppSpacing.lg),
              ListTile(
                title: Text(l10n.refundTotal),
                subtitle: Text(l10n.refundRefundable(data.refundable.format())),
                trailing: Text(
                  plan.total.format(),
                  key: const Key('refund-total'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (plan.problem != null && plan.problem != RefundProblem.empty)
                Text(
                  refundProblemText(l10n, plan.problem!),
                  style: const TextStyle(color: AppColors.error),
                ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                key: const Key('refund-submit'),
                onPressed: _busy || plan.problem != null || method == null
                    ? null
                    : () => _submit(order, data, plan, method),
                icon: const Icon(Icons.undo),
                label: Text(l10n.refundSubmit(plan.total.format())),
              ),
            ],
          );
        }(),
        AsyncData() => Center(child: Text(l10n.receiptMissing)),
        AsyncError(:final error) => Center(
          child: Text(l10n.commonError('$error')),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _RefundLineTile extends StatelessWidget {
  const new({
    required this.line,
    required this.quantity,
    required this.onChanged,
    super.key,
  });

  final RefundLineInfo line;
  final Qty quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final left = line.line.remainingQuantity;
    final step = line.allowDecimal ? 100 : 1000;
    return ListTile(
      title: Text(line.name),
      subtitle: Text(
        l10n.refundLeft(left.toPlain(), line.line.quantity.toPlain()),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: const Key('refund-minus'),
            onPressed: quantity.milli > 0
                ? () => onChanged(quantity.milli - step)
                : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          SizedBox(
            width: 48,
            child: Text(
              quantity.toPlain(),
              textAlign: TextAlign.center,
              key: const Key('refund-qty'),
            ),
          ),
          IconButton(
            key: const Key('refund-plus'),
            onPressed: quantity.milli < left.milli
                ? () => onChanged(quantity.milli + step)
                : null,
            icon: const Icon(Icons.add_circle_outline),
          ),
          TextButton(
            key: const Key('refund-all'),
            onPressed: () => onChanged(left.milli),
            child: Text(l10n.refundAll),
          ),
        ],
      ),
    );
  }
}
