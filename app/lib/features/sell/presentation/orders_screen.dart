import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/empty_state.dart';
import 'package:cashiera/core/design_system/widgets/toasts.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/pos/pos_services.dart';
import 'package:cashiera/core/providers.dart';
import 'package:cashiera/features/sell/presentation/sell_dialogs.dart';
import 'package:cashiera/features/sell/presentation/sell_providers.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Today's bills on this terminal and the held ones.
class OrdersScreen extends ConsumerWidget {
  const new({super.key});

  Future<void> _resume(
    BuildContext context,
    WidgetRef ref,
    LocalOrderRow order,
  ) async {
    final l10n = context.l10n;
    final current = ref.read(cartControllerProvider);
    if (!current.isEmpty && current.orderId != order.id) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.ordersResumeTitle),
          content: Text(l10n.ordersResumeReplace),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.commonContinue),
            ),
          ],
        ),
      );
      if (!(replace ?? false)) return;
    }
    ref.read(cartControllerProvider.notifier).resume(order);
    if (context.mounted) context.go(AppRoutes.sell);
  }

  Future<void> _cancel(
    BuildContext context,
    WidgetRef ref,
    LocalOrderRow order,
  ) async {
    final l10n = context.l10n;
    final ctx = ref.read(saleContextProvider);
    if (ctx == null) return;
    final reason = await showTextDialog(
      context,
      title: l10n.ordersCancelTitle(order.orderNumber),
      label: l10n.ordersCancelReason,
      minLength: 3,
      tooShort: l10n.ordersCancelReasonShort,
    );
    if (reason == null || !context.mounted) return;
    String? approvedBy;
    if (!ctx.staff.can('pos.void')) {
      final approver = await showApprovalDialog(
        context,
        permission: 'pos.void',
        reason: l10n.approvalCancelReason(order.orderNumber),
      );
      if (approver == null) return;
      approvedBy = approver.employeeId;
    }
    try {
      await ref
          .read(orderServiceProvider)
          .cancelHeld(
            order: order,
            ctx: ctx,
            reason: reason,
            approvedBy: approvedBy,
          );
      ref.read(syncSchedulerProvider.notifier).syncNow().ignore();
      final cart = ref.read(cartControllerProvider);
      if (cart.orderId == order.id) {
        ref.read(cartControllerProvider.notifier).clear();
      }
      if (context.mounted) {
        AppToast.success(context, l10n.ordersCancelled(order.orderNumber));
      }
    } on PosPermissionException catch (e) {
      if (context.mounted) AppToast.error(context, l10n.commonError('$e'));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final today = ref.watch(todaysOrdersProvider).value ?? const [];
    final held = ref.watch(heldOrdersProvider).value ?? const [];
    final config = ref.watch(posConfigProvider).value;
    final time = DateFormat.Hm();
    final completed = today.where((o) => o.status == 'completed').toList();
    final total = completed.fold(0, (a, o) => a + o.grandTotal);

    String when(LocalOrderRow o) =>
        time.format(config?.localTime(o.updatedAt) ?? o.updatedAt.toLocal());

    Widget tile(LocalOrderRow o, {required bool heldTab}) {
      final status = switch (o.status) {
        'held' => (l10n.ordersStatusHeld, AppColors.warning),
        'cancelled' => (l10n.ordersStatusCancelled, AppColors.error),
        'voided' => (l10n.receiptVoid, AppColors.error),
        _ => (l10n.ordersStatusPaid, AppColors.success),
      };
      return ListTile(
        key: Key('order-${o.orderNumber}'),
        title: Text(o.orderNumber),
        subtitle: Text(
          [
            when(o),
            l10n.receiptItems(o.itemCount),
            ?o.customerName,
            o.cashierName,
          ].join(' · '),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(Money(o.grandTotal).format()),
                Text(
                  status.$1,
                  style: TextStyle(color: status.$2, fontSize: 12),
                ),
              ],
            ),
            if (heldTab)
              IconButton(
                key: Key('order-cancel-${o.orderNumber}'),
                tooltip: l10n.ordersCancel,
                onPressed: () => _cancel(context, ref, o),
                icon: const Icon(Icons.cancel_outlined),
              ),
          ],
        ),
        onTap: () => o.status == 'held'
            ? _resume(context, ref, o)
            : context.go(AppRoutes.receipt(o.id)),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.go(AppRoutes.sell)),
          title: Text(l10n.ordersTitle),
          actions: const [],
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.ordersToday),
              Tab(text: l10n.ordersHeld(held.length)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Column(
              children: [
                ListTile(
                  title: Text(l10n.ordersTodayTotal),
                  trailing: Text(
                    Money(total).format(),
                    key: const Key('orders-total'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(l10n.ordersTodayCount(completed.length)),
                ),
                const Divider(height: 1),
                Expanded(
                  child: today.isEmpty
                      ? EmptyState(
                          icon: Icons.receipt_long_outlined,
                          message: l10n.ordersNone,
                        )
                      : ListView.separated(
                          itemCount: today.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (_, i) => tile(today[i], heldTab: false),
                        ),
                ),
              ],
            ),
            if (held.isEmpty)
              EmptyState(
                icon: Icons.pause_circle_outline,
                message: l10n.ordersNoHeld,
              )
            else
              ListView.separated(
                itemCount: held.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) => tile(held[i], heldTab: true),
              ),
          ],
        ),
      ),
    );
  }
}
