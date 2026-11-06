import 'dart:async';

import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/toasts.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/pos/receipt.dart';
import 'package:cashiera/core/printing/receipt_printing.dart';
import 'package:cashiera/core/providers.dart';
import 'package:cashiera/features/printing/print_actions.dart';
import 'package:cashiera/features/sell/presentation/refund_screen.dart';
import 'package:cashiera/features/sell/presentation/sell_dialogs.dart';
import 'package:cashiera/features/sell/presentation/sell_providers.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

ReceiptLabels receiptLabels(AppLocalizations l10n) => ReceiptLabels(
  cashier: l10n.receiptCashier,
  customer: l10n.receiptCustomer,
  subtotal: l10n.receiptSubtotal,
  service: l10n.receiptService,
  taxIncluded: l10n.receiptTaxIncluded,
  taxAdded: l10n.receiptTaxAdded,
  taxBase: l10n.receiptTaxBase,
  rounding: l10n.receiptRounding,
  total: l10n.receiptTotal,
  change: l10n.receiptChange,
  tendered: l10n.receiptTendered,
  kasbonDue: l10n.receiptKasbonDue,
  cancelled: l10n.receiptCancelled,
  held: l10n.receiptHeld,
  voided: l10n.receiptVoided,
  copy: l10n.receiptCopy,
  items: l10n.receiptItems,
  pointsEarned: l10n.receiptPointsEarned,
);

/// One terminal order, kept fresh while it is voided, printed or refunded.
final StreamProviderFamily<LocalOrderRow?, String> orderProvider =
    StreamProvider.autoDispose.family<LocalOrderRow?, String>(
      (ref, id) => ref.watch(orderServiceProvider).watchOne(id),
    );

/// Refunds of one order.
final StreamProviderFamily<List<RefundRow>, String> orderRefundsProvider =
    StreamProvider.autoDispose.family<List<RefundRow>, String>(
      (ref, id) => ref.watch(refundServiceProvider).watchForOrder(id),
    );

/// The receipt the way it prints, on a paper-coloured card.
class ReceiptView extends StatelessWidget {
  const new({required this.receipt, super.key});

  final ReceiptData receipt;

  @override
  Widget build(BuildContext context) {
    final l = receiptLabels(context.l10n);
    const ink = Color(0xFF111827);
    const mono = TextStyle(
      fontFamily: 'monospace',
      fontSize: 13,
      color: ink,
      height: 1.35,
    );
    final strong = mono.copyWith(fontWeight: FontWeight.w700);
    Widget row(String a, String b, {bool isStrong = false}) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(a, style: isStrong ? strong : mono)),
        const SizedBox(width: AppSpacing.sm),
        Text(b, style: isStrong ? strong : mono),
      ],
    );
    const rule = Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Divider(color: Color(0xFF9CA3AF), height: 1),
    );

    return Container(
      width: receipt.paperMm >= 80 ? 420 : 320,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF7),
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, line) in receipt.headerLines.indexed)
            Text(
              line,
              textAlign: TextAlign.center,
              style: i == 0 ? strong : mono,
            ),
          if (receipt.status != 'completed')
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                receiptStatusLabel(receipt.status, l),
                key: const Key('receipt-status'),
                textAlign: TextAlign.center,
                style: strong.copyWith(color: AppColors.error),
              ),
            ),
          rule,
          row(receipt.orderNumber, receipt.dateText),
          row(l.cashier, receipt.cashierName),
          if (receipt.customerName != null)
            row(l.customer, receipt.customerName!),
          rule,
          for (final line in receipt.lines) ...[
            Text(line.name, style: mono),
            for (final d in line.details) Text('  $d', style: mono),
            row('  ${line.quantityText}', line.amount.format()),
            for (final (name, amount) in line.discounts)
              row('  $name', '-${amount.format()}'),
          ],
          rule,
          Text(l.items(receipt.itemCount), style: mono),
          for (final (label, value, strong: s) in receiptTotals(receipt, l))
            row(label, value, isStrong: s),
          if (receipt.pointsEarned > 0)
            Text(l.pointsEarned(receipt.pointsEarned), style: mono),
          if (receipt.kasbonDueDate != null)
            Text(l.kasbonDue(receipt.kasbonDueDate!), style: mono),
          rule,
          Text(receipt.footer, textAlign: TextAlign.center, style: mono),
        ],
      ),
    );
  }
}

class ReceiptScreen extends ConsumerStatefulWidget {
  const new({required this.orderId, this.justSold = false, super.key});

  final String orderId;

  /// Opened straight after payment: auto-print and open the drawer.
  final bool justSold;

  @override
  ConsumerState<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends ConsumerState<ReceiptScreen> {
  bool _busy = false;
  bool _afterSaleDone = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share(
    LocalOrderRow order,
    ReceiptData receipt,
  ) => _run(() async {
    try {
      final bytes = await buildReceiptPdf(receipt, receiptLabels(context.l10n));
      final shared = await Printing.sharePdf(
        bytes: bytes,
        filename: '${receipt.orderNumber}.pdf',
      );
      final ctx = ref.read(saleContextProvider);
      if (shared && ctx != null) {
        await ReceiptPrinting(
          printers: ref.read(printerServiceProvider),
          orders: ref.read(orderServiceProvider),
          audit: ref.read(auditServiceProvider),
        ).shared(order: order, staff: ctx.staff, storeId: ctx.config.storeId);
        ref.read(syncSchedulerProvider.notifier).syncNow().ignore();
      }
    } on Exception catch (e) {
      if (mounted) AppToast.error(context, context.l10n.commonError('$e'));
    }
  });

  Future<void> _print(LocalOrderRow order) => _run(
    () =>
        printReceipt(context, ref, order, labels: receiptLabels(context.l10n)),
  );

  Future<void> _void(LocalOrderRow order) async {
    final l10n = context.l10n;
    final ctx = ref.read(saleContextProvider);
    if (ctx == null) return;
    final reason = await showTextDialog(
      context,
      title: l10n.voidTitle(order.orderNumber),
      label: l10n.voidReason,
      minLength: 3,
      tooShort: l10n.reasonShort,
    );
    if (reason == null || !mounted) return;
    final printed = order.printedAt != null;
    StaffMember? approver;
    if (printed || !ctx.staff.can('pos.void')) {
      approver = await showApprovalDialog(
        context,
        permission: printed ? 'pos.void_after_print' : 'pos.void',
        reason: printed
            ? l10n.voidApprovalPrinted(order.orderNumber)
            : l10n.voidApproval(order.orderNumber),
      );
      if (approver == null || !mounted) return;
    }
    await _run(() async {
      try {
        await ref
            .read(orderServiceProvider)
            .voidOrder(
              order: order,
              ctx: ctx,
              reason: reason,
              approver: approver,
            );
        ref.read(syncSchedulerProvider.notifier).syncNow().ignore();
        if (mounted) {
          AppToast.success(context, l10n.voidDone(order.orderNumber));
        }
        if (mounted && ReceiptPrinting.tookCash(order)) {
          await openDrawerIfAny(context, ref);
        }
      } on Exception catch (e) {
        if (mounted) AppToast.error(context, posErrorText(l10n, e));
      }
    });
  }

  void _afterSale(LocalOrderRow order) {
    if (!widget.justSold || _afterSaleDone || order.status != 'completed') {
      return;
    }
    _afterSaleDone = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        _run(
          () => afterSale(
            context,
            ref,
            order,
            labels: receiptLabels(context.l10n),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final order = ref.watch(orderProvider(widget.orderId));
    final refunds =
        ref.watch(orderRefundsProvider(widget.orderId)).value ?? const [];
    final config = ref.watch(posConfigProvider).value;
    // Keeps the shift loaded for void and print.
    ref.watch(saleContextProvider);
    final time = DateFormat('dd/MM HH:mm');

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.orders)),
        title: Text(l10n.receiptTitle),
      ),
      body: switch (order) {
        AsyncData(value: final row?) when config != null => () {
          _afterSale(row);
          final receipt = ReceiptData.fromOrder(row, config);
          final completed = row.status == 'completed';
          final refunded = refunds.fold(0, (a, r) => a + r.amount);
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (completed &&
                  widget.justSold &&
                  receipt.changeTotal.rupiah > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: Text(
                    l10n.payChange(receipt.changeTotal.format()),
                    key: const Key('receipt-change'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Center(child: ReceiptView(receipt: receipt)),
              if (row.status == 'voided' && row.voidedAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Text(
                    l10n.receiptVoidedLine(
                      time.format(config.localTime(row.voidedAt!)),
                      row.voidedByName ?? '',
                      row.voidReason ?? '',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              if (refunds.isNotEmpty)
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Card(
                      margin: const EdgeInsets.only(top: AppSpacing.md),
                      child: Column(
                        children: [
                          for (final r in refunds)
                            ListTile(
                              key: Key('refund-${r.refundNumber}'),
                              dense: true,
                              leading: const Icon(Icons.undo),
                              title: Text(
                                l10n.receiptRefundLine(
                                  r.refundNumber,
                                  refundMethodLabel(l10n, r.methodType),
                                ),
                              ),
                              subtitle: Text(
                                '${time.format(config.localTime(r.refundedAt))}'
                                ' · ${r.reason}',
                              ),
                              trailing: Text('-${Money(r.amount).format()}'),
                            ),
                          if (refunds.length > 1)
                            ListTile(
                              dense: true,
                              title: Text(l10n.refundTotal),
                              trailing: Text('-${Money(refunded).format()}'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  OutlinedButton.icon(
                    key: const Key('receipt-share'),
                    onPressed: _busy ? null : () => _share(row, receipt),
                    icon: const Icon(Icons.share_outlined),
                    label: Text(l10n.receiptShare),
                  ),
                  OutlinedButton.icon(
                    key: const Key('receipt-print'),
                    onPressed: _busy || !completed ? null : () => _print(row),
                    icon: const Icon(Icons.print_outlined),
                    label: Text(
                      row.printedAt == null
                          ? l10n.receiptPrint
                          : l10n.receiptReprint,
                    ),
                  ),
                  if (completed && refunds.isEmpty)
                    OutlinedButton.icon(
                      key: const Key('receipt-void'),
                      onPressed: _busy ? null : () => _void(row),
                      icon: const Icon(Icons.block),
                      label: Text(l10n.receiptVoid),
                    ),
                  if (completed)
                    OutlinedButton.icon(
                      key: const Key('receipt-refund'),
                      onPressed: _busy
                          ? null
                          : () => context.go(AppRoutes.refund(row.id)),
                      icon: const Icon(Icons.undo),
                      label: Text(l10n.receiptRefund),
                    ),
                  FilledButton.icon(
                    key: const Key('receipt-new-sale'),
                    onPressed: () => context.go(AppRoutes.sell),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: Text(l10n.receiptNewSale),
                  ),
                ],
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
