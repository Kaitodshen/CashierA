import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/buttons.dart';
import 'package:cashiera/core/design_system/widgets/data_display.dart';
import 'package:cashiera/core/design_system/widgets/empty_state.dart';
import 'package:cashiera/core/design_system/widgets/glass.dart';
import 'package:cashiera/core/design_system/widgets/toasts.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/pos/money_input.dart';
import 'package:cashiera/core/providers.dart';
import 'package:cashiera/features/printing/print_actions.dart';
import 'package:cashiera/features/sell/presentation/sell_dialogs.dart';
import 'package:cashiera/features/sell/presentation/sell_providers.dart';
import 'package:cashiera/features/shift/presentation/overview_widgets.dart';
import 'package:cashiera/features/shift/presentation/report_actions.dart';
import 'package:cashiera/features/shift/presentation/shift_providers.dart';
import 'package:cashiera/features/shift/presentation/shift_widgets.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Amount and reason for kas masuk / keluar.
Future<(Money, String)?> showCashMovementDialog(
  BuildContext context, {
  required bool isIn,
}) => showDialog<(Money, String)>(
  context: context,
  builder: (context) => _CashMovementDialog(isIn: isIn),
);

class _CashMovementDialog extends StatefulWidget {
  const new({required this.isIn});
  final bool isIn;

  @override
  State<_CashMovementDialog> createState() => _CashMovementDialogState();
}

class _CashMovementDialogState extends State<_CashMovementDialog> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(context, (
      Money(parseRupiah(_amount.text)!),
      _reason.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(widget.isIn ? l10n.shiftCashIn : l10n.shiftCashOut),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('cash-amount'),
                controller: _amount,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: rupiahInputFormatters,
                decoration: InputDecoration(
                  labelText: l10n.shiftMovementAmount,
                  prefixText: 'Rp ',
                ),
                validator: (v) => (parseRupiah(v ?? '') ?? 0) > 0
                    ? null
                    : l10n.commonRequired,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('cash-reason'),
                controller: _reason,
                decoration: InputDecoration(
                  labelText: l10n.shiftMovementReason,
                ),
                validator: (v) =>
                    (v ?? '').trim().length >= 3 ? null : l10n.reasonShort,
                onFieldSubmitted: (_) => _submit(),
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
          key: const Key('cash-save'),
          onPressed: _submit,
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}

/// The terminal's shift: the live X report, cash in/out, the drawer, and
/// closing. Earlier shifts open their Z report.
class ShiftScreen extends ConsumerWidget {
  const new({super.key});

  Future<void> _movement(
    BuildContext context,
    WidgetRef ref,
    ShiftRow shift, {
    required bool isIn,
  }) async {
    final l10n = context.l10n;
    final ctx = ref.read(saleContextProvider);
    if (ctx == null) return;
    final input = await showCashMovementDialog(context, isIn: isIn);
    if (input == null || !context.mounted) return;
    final (amount, reason) = input;
    // The drawer opens for the cash: the same approval as a no-sale open.
    StaffMember? approver;
    if (!ctx.staff.can('pos.open_drawer')) {
      approver = await showApprovalDialog(
        context,
        permission: 'pos.open_drawer',
        reason: l10n.cashMovementApproval(
          isIn ? l10n.shiftCashIn : l10n.shiftCashOut,
          amount.format(),
          reason,
        ),
      );
      if (approver == null || !context.mounted) return;
    }
    try {
      await ref
          .read(shiftServiceProvider)
          .cashMovement(
            shift: shift,
            staff: ctx.staff,
            isIn: isIn,
            amount: amount,
            reason: reason,
            config: ctx.config,
            approver: approver,
          );
      ref.read(syncSchedulerProvider.notifier).syncNow().ignore();
      if (!context.mounted) return;
      AppToast.success(
        context,
        l10n.shiftMovementSaved(
          isIn ? l10n.shiftCashIn : l10n.shiftCashOut,
          amount.format(),
        ),
      );
      await openDrawerIfAny(context, ref);
    } on Exception catch (e) {
      if (context.mounted) AppToast.error(context, posErrorText(l10n, e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final config = ref.watch(posConfigProvider).value;
    final open = ref.watch(openShiftProvider).value;
    final recent = (ref.watch(recentShiftsProvider).value ?? const [])
        .where((s) => s.status == 'closed')
        .toList();
    final report = open == null
        ? null
        : ref.watch(shiftReportProvider(open.id)).value;
    final staff = ref.watch(saleContextProvider)?.staff;
    final date = DateFormat('dd/MM/yyyy HH:mm');
    String local(DateTime t) =>
        date.format(config?.localTime(t) ?? t.toLocal());

    final history = recent.isEmpty
        ? null
        : GlassCard(
            level: GlassLevel.solid,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.shiftHistory,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                for (final s in recent)
                  ListTile(
                    key: Key('shift-history-${s.id}'),
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.history),
                    title: Text(
                      l10n.shiftHistoryLine(
                        local(s.openedAt),
                        s.closedByName ?? s.openedByName,
                      ),
                    ),
                    trailing: s.countedCash == null || s.expectedCash == null
                        ? null
                        : Text(
                            differenceText(
                              l10n,
                              Money(s.countedCash! - s.expectedCash!),
                            ),
                            style: TextStyle(
                              color: differenceColor(
                                Money(s.countedCash! - s.expectedCash!),
                              ),
                            ),
                          ),
                    onTap: () => context.go(AppRoutes.shiftReport(s.id)),
                  ),
              ],
            ),
          );

    // The shell's top bar holds the title; this is the dashboard.
    return Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (open == null)
                GlassCard(
                  child: EmptyState(
                    icon: Icons.lock_clock_outlined,
                    message: l10n.shiftNoneOpen,
                    action: PrimaryButton(
                      key: const Key('shift-go-sell'),
                      label: l10n.shiftGoSell,
                      onPressed: () => context.go(AppRoutes.sell),
                    ),
                  ),
                )
              else ...[
                PageHeader(
                  title: l10n.shiftTitle,
                  subtitle: l10n.overviewSubtitle,
                  status: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n.shiftOpenedBy(
                            local(open.openedAt),
                            open.openedByName,
                          ),
                          style: const TextStyle(
                            color: AppColors.primaryPressed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    if (staff?.can('shift.cash_movement') ?? false) ...[
                      SecondaryButton(
                        key: const Key('shift-cash-in'),
                        icon: Icons.south_west,
                        label: l10n.shiftCashIn,
                        onPressed: () =>
                            _movement(context, ref, open, isIn: true),
                      ),
                      SecondaryButton(
                        key: const Key('shift-cash-out'),
                        icon: Icons.north_east,
                        label: l10n.shiftCashOut,
                        onPressed: () =>
                            _movement(context, ref, open, isIn: false),
                      ),
                    ],
                    SecondaryButton(
                      key: const Key('shift-drawer'),
                      icon: Icons.inbox_outlined,
                      label: l10n.shiftOpenDrawer,
                      onPressed: () => openDrawerNoSale(context, ref),
                    ),
                    SecondaryButton(
                      key: const Key('shift-print-x'),
                      icon: Icons.print_outlined,
                      label: l10n.shiftPrintX,
                      onPressed: report == null || config == null
                          ? null
                          : () =>
                                printShiftReport(context, ref, report, config),
                    ),
                    if (staff?.can('shift.manage') ?? false)
                      PrimaryButton(
                        key: const Key('shift-close'),
                        icon: Icons.lock_outline,
                        label: l10n.shiftClose,
                        onPressed: () => context.go(AppRoutes.shiftClose),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                OverviewStats(report: report),
                const SizedBox(height: AppSpacing.lg),
                LayoutBuilder(
                  builder: (context, c) {
                    final recentCard = RecentOrdersCard(shiftId: open.id);
                    final payments = PaymentBreakdownCard(report: report);
                    if (c.maxWidth < 900) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          recentCard,
                          const SizedBox(height: AppSpacing.lg),
                          payments,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: recentCard),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(flex: 2, child: payments),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                if (report != null && config != null)
                  GlassCard(
                    level: GlassLevel.solid,
                    child: ShiftReportView(
                      report: report,
                      utcOffsetMinutes: config.utcOffsetMinutes,
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                _Movements(shiftId: open.id),
              ],
              if (history != null) ...[
                const SizedBox(height: AppSpacing.lg),
                history,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Movements extends ConsumerWidget {
  const new({required this.shiftId});
  final String shiftId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final config = ref.watch(posConfigProvider).value;
    final moves = ref.watch(shiftMovementsProvider(shiftId)).value ?? const [];
    final time = DateFormat.Hm();
    DateTime when(DateTime t) => config?.localTime(t) ?? t.toLocal();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.shiftMovements,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (moves.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(l10n.shiftNoMovements),
              ),
            for (final m in moves)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(
                  m.movementType == 'in' ? Icons.south_west : Icons.north_east,
                  color: m.movementType == 'in'
                      ? AppColors.success
                      : AppColors.warning,
                ),
                title: Text(m.reason),
                subtitle: Text(
                  '${time.format(when(m.occurredAt))}'
                  ' · ${m.employeeName}',
                ),
                trailing: Text(
                  '${m.movementType == 'in' ? '+' : '-'}'
                  '${Money(m.amount).format()}',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
