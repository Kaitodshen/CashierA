import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/design_system/widgets/toasts.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/pos/pos_services.dart';
import 'package:cashiera/core/pos/receipt.dart';
import 'package:cashiera/core/printing/printer_transport.dart';
import 'package:cashiera/core/printing/receipt_printing.dart';
import 'package:cashiera/core/providers.dart';
import 'package:cashiera/features/sell/presentation/sell_dialogs.dart';
import 'package:cashiera/features/sell/presentation/sell_providers.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

String printerErrorText(AppLocalizations l10n, PrinterException e) =>
    switch (e.code) {
      'not_configured' => l10n.printNotConfigured,
      'unsupported' => l10n.printUnsupported,
      'connect_failed' => l10n.printConnectFailed,
      'send_failed' => l10n.printSendFailed,
      'invalid_address' => l10n.printInvalidAddress,
      'no_drawer' => l10n.drawerNotSet,
      _ => l10n.printFailed('$e'),
    };

String refundProblemText(AppLocalizations l10n, RefundProblem p) => switch (p) {
  RefundProblem.empty => l10n.refundNothing,
  RefundProblem.quantity => l10n.refundQuantity,
  RefundProblem.exceedsPaid => l10n.refundExceedsPaid,
  RefundProblem.zero => l10n.refundZero,
};

/// Cashier-facing text for anything the till services throw.
String posErrorText(AppLocalizations l10n, Object e) => switch (e) {
  PosStateException(:final code) => switch (code) {
    'shift_required' => l10n.payShiftRequired,
    'not_paid' => l10n.payNotPaid,
    'kasbon_requires_customer' => l10n.payKasbonCustomer,
    'approval_required' => l10n.sellNeedsApproval,
    'shift_closed' => l10n.posErrShiftClosed,
    'reason_required' => l10n.reasonShort,
    'not_completed' => l10n.posErrNotCompleted,
    'void_after_refund' => l10n.posErrVoidAfterRefund,
    'refund_method' => l10n.posErrRefundMethod,
    _ => l10n.sellEmpty,
  },
  PosPermissionException(:final permission) => l10n.posErrPermission(
    permission,
  ),
  DrawerShortException(:final available) => l10n.shiftDrawerShort(
    available.format(),
  ),
  RefundRejected(:final problem) => refundProblemText(l10n, problem),
  PrinterException() => printerErrorText(l10n, e),
  _ => l10n.commonError('$e'),
};

/// Sends [doc] to the receipt printer. Shows what went wrong and returns
/// false when it did not print; never throws.
Future<bool> printSlip(
  BuildContext context,
  WidgetRef ref,
  ReceiptDocument doc,
) async {
  try {
    await ref.read(printerServiceProvider).print(doc);
    return true;
  } on PrinterException catch (e) {
    if (context.mounted) {
      AppToast.error(context, printerErrorText(context.l10n, e));
    }
    return false;
  }
}

/// Opens the drawer when the printer drives one. Silent when there is no
/// printer or it has no drawer; shows other errors.
Future<void> openDrawerIfAny(BuildContext context, WidgetRef ref) async {
  final printer = await ref.read(printerRepositoryProvider).current();
  if (printer == null || !printer.opensCashDrawer) return;
  try {
    await ref.read(printerServiceProvider).kickDrawer(using: printer);
  } on PrinterException catch (e) {
    if (context.mounted) {
      AppToast.error(context, printerErrorText(context.l10n, e));
    }
  }
}

/// Prints [order]'s receipt: on the thermal printer when one is set up
/// (copies are marked and audited), else through the system print dialog.
Future<void> printReceipt(
  BuildContext context,
  WidgetRef ref,
  LocalOrderRow order, {
  required ReceiptLabels labels,
  bool openDrawer = false,
}) async {
  final l10n = context.l10n;
  final config = ref.read(posConfigProvider).value;
  final ctx = ref.read(saleContextProvider);
  if (config == null || ctx == null) return;
  final receipt = ReceiptData.fromOrder(order, config);
  final printer = await ref.read(printerRepositoryProvider).current();
  try {
    if (printer == null) {
      final bytes = await buildReceiptPdf(receipt, labels);
      final printed = await Printing.layoutPdf(
        name: receipt.orderNumber,
        onLayout: (_) async => bytes,
      );
      if (printed && order.printedAt == null) {
        await ref.read(orderServiceProvider).markPrinted(order.id);
      }
      return;
    }
    await ReceiptPrinting(
      printers: ref.read(printerServiceProvider),
      orders: ref.read(orderServiceProvider),
      audit: ref.read(auditServiceProvider),
    ).printOrder(
      order: order,
      receipt: receipt,
      labels: labels,
      staff: ctx.staff,
      storeId: config.storeId,
      openDrawer: openDrawer,
    );
    if (context.mounted) AppToast.success(context, l10n.receiptPrinted);
  } on PrinterException catch (e) {
    if (context.mounted) AppToast.error(context, printerErrorText(l10n, e));
  } on Exception catch (e) {
    if (context.mounted) AppToast.error(context, l10n.commonError('$e'));
  } finally {
    ref.read(syncSchedulerProvider.notifier).syncNow().ignore();
  }
}

/// Right after a sale: print when auto-print is on (opening the drawer for
/// cash), else just open the drawer for cash.
Future<void> afterSale(
  BuildContext context,
  WidgetRef ref,
  LocalOrderRow order, {
  required ReceiptLabels labels,
}) async {
  final printer = await ref.read(printerRepositoryProvider).current();
  if (printer == null || !context.mounted) return;
  final cash = ReceiptPrinting.tookCash(order);
  if (printer.autoPrint) {
    await printReceipt(context, ref, order, labels: labels, openDrawer: cash);
  } else if (cash) {
    await openDrawerIfAny(context, ref);
  }
}

/// Opens the drawer without a sale: a colleague with `pos.open_drawer`
/// approves with their PIN, then it is audited.
Future<void> openDrawerNoSale(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final ctx = ref.read(saleContextProvider);
  if (ctx == null) return;
  final printer = await ref.read(printerRepositoryProvider).current();
  if (!context.mounted) return;
  if (printer == null) {
    AppToast.error(context, l10n.printNotConfigured);
    return;
  }
  if (!printer.opensCashDrawer) {
    AppToast.error(context, l10n.drawerNotSet);
    return;
  }
  final reason = await showTextDialog(
    context,
    title: l10n.drawerReasonTitle,
    label: l10n.shiftMovementReason,
    minLength: 3,
    tooShort: l10n.reasonShort,
  );
  if (reason == null || !context.mounted) return;
  final approver = await showApprovalDialog(
    context,
    permission: 'pos.open_drawer',
    reason: l10n.drawerApprovalReason(reason),
  );
  if (approver == null || !context.mounted) return;
  try {
    await ref.read(printerServiceProvider).kickDrawer(using: printer);
    await ref
        .read(auditServiceProvider)
        .log(
          storeId: ctx.config.storeId,
          action: AuditService.drawerNoSale,
          actor: ctx.staff,
          approver: approver,
          entityType: 'shift',
          entityId: ctx.shiftId,
          details: {'reason': reason},
        );
    ref.read(syncSchedulerProvider.notifier).syncNow().ignore();
    if (context.mounted) AppToast.success(context, l10n.drawerOpened);
  } on Exception catch (e) {
    if (context.mounted) AppToast.error(context, posErrorText(l10n, e));
  }
}
