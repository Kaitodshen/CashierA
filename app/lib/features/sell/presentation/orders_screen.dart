import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/data_display.dart';
import 'package:cashiera/core/design_system/widgets/empty_state.dart';
import 'package:cashiera/core/design_system/widgets/flow.dart';
import 'package:cashiera/core/design_system/widgets/glass.dart';
import 'package:cashiera/core/design_system/widgets/glass_table.dart';
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
        builder: (context) => GlassDialog(
          title: Text(l10n.ordersResumeTitle),
          content: SingleChildScrollView(child: Text(l10n.ordersResumeReplace)),
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

    StatusChip statusChip(LocalOrderRow o) => switch (o.status) {
      'held' => StatusChip(
        label: l10n.ordersStatusHeld,
        tone: StatusTone.warning,
      ),
      'cancelled' => StatusChip(
        label: l10n.ordersStatusCancelled,
        tone: StatusTone.error,
      ),
      'voided' => StatusChip(label: l10n.receiptVoid, tone: StatusTone.error),
      _ => StatusChip(label: l10n.ordersStatusPaid, tone: StatusTone.success),
    };
    final muted = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: AppColors.textMuted);

    Widget table(List<LocalOrderRow> rows, {required bool heldTab}) =>
        GlassTable<LocalOrderRow>(
          rows: rows,
          onRowTap: (o) => o.status == 'held'
              ? _resume(context, ref, o)
              : context.go(AppRoutes.receipt(o.id)),
          columns: [
            GlassColumn(
              label: l10n.ordersColNumber,
              flex: 3,
              cell: (o) => Column(
                key: Key('order-${o.orderNumber}'),
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    o.orderNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    [?o.customerName, o.cashierName].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: muted,
                  ),
                ],
              ),
            ),
            GlassColumn(label: l10n.ordersColTime, cell: (o) => Text(when(o))),
            GlassColumn(
              label: l10n.ordersColItems,
              cell: (o) => Text(l10n.receiptItems(o.itemCount)),
            ),
            GlassColumn(label: l10n.ordersColStatus, cell: statusChip),
            GlassColumn(
              label: l10n.ordersColTotal,
              numeric: true,
              flex: 2,
              cell: (o) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MoneyText(
                    Money(o.grandTotal),
                    style: const TextStyle(fontWeight: FontWeight.w700),
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
            ),
          ],
        );

    Widget tab(List<Widget> children) => ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      children: children,
    );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
                  FlowHeader(
                    title: l10n.ordersTitle,
                    onBack: () => context.go(AppRoutes.sell),
                    backKey: const Key('orders-back'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  GlassCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: TabBar(
                      dividerHeight: 0,
                      tabs: [
                        Tab(text: l10n.ordersToday),
                        Tab(text: l10n.ordersHeld(held.length)),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: TabBarView(
                      children: [
                        tab([
                          StatCard(
                            icon: Icons.payments_outlined,
                            label: l10n.ordersTodayTotal,
                            value: Money(total).format(),
                            valueKey: const Key('orders-total'),
                            footnote: l10n.ordersTodayCount(completed.length),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          if (today.isEmpty)
                            GlassCard(
                              child: EmptyState(
                                icon: Icons.receipt_long_outlined,
                                message: l10n.ordersNone,
                              ),
                            )
                          else
                            table(today, heldTab: false),
                        ]),
                        tab([
                          if (held.isEmpty)
                            GlassCard(
                              child: EmptyState(
                                icon: Icons.pause_circle_outline,
                                message: l10n.ordersNoHeld,
                              ),
                            )
                          else
                            table(held, heldTab: true),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
