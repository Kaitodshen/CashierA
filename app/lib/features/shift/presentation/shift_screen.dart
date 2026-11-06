import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/empty_state.dart';
import 'package:cashiera/core/design_system/widgets/toasts.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/pos/money_input.dart';
import 'package:cashiera/core/providers.dart';
import 'package:cashiera/features/pos_home/presentation/widgets/terminal_status_chip.dart';
import 'package:cashiera/features/printing/print_actions.dart';
import 'package:cashiera/features/sell/presentation/sell_dialogs.dart';
import 'package:cashiera/features/sell/presentation/sell_providers.dart';
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

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.pos)),
        title: Text(l10n.shiftTitle),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: TerminalStatusChip(),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (open == null)
                EmptyState(
                  icon: Icons.lock_clock_outlined,
                  message: l10n.shiftNoneOpen,
                  action: FilledButton(
                    key: const Key('shift-go-sell'),
                    onPressed: () => context.go(AppRoutes.sell),
                    child: Text(l10n.shiftGoSell),
                  ),
                )
              else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.shiftDrawerExpected),
                        Text(
                          report?.cash.expected.format() ?? '…',
                          key: const Key('shift-expected'),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.shiftOpenedBy(
                            local(open.openedAt),
                            open.openedByName,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    if (staff?.can('shift.cash_movement') ?? false) ...[
                      OutlinedButton.icon(
                        key: const Key('shift-cash-in'),
                        onPressed: () =>
                            _movement(context, ref, open, isIn: true),
                        icon: const Icon(Icons.south_west),
                        label: Text(l10n.shiftCashIn),
                      ),
                      OutlinedButton.icon(
                        key: const Key('shift-cash-out'),
                        onPressed: () =>
                            _movement(context, ref, open, isIn: false),
                        icon: const Icon(Icons.north_east),
                        label: Text(l10n.shiftCashOut),
                      ),
                    ],
                    OutlinedButton.icon(
                      key: const Key('shift-drawer'),
                      onPressed: () => openDrawerNoSale(context, ref),
                      icon: const Icon(Icons.inbox_outlined),
                      label: Text(l10n.shiftOpenDrawer),
                    ),
                    OutlinedButton.icon(
                      key: const Key('shift-print-x'),
                      onPressed: report == null || config == null
                          ? null
                          : () =>
                                printShiftReport(context, ref, report, config),
                      icon: const Icon(Icons.print_outlined),
                      label: Text(l10n.shiftPrintX),
                    ),
                    if (staff?.can('shift.manage') ?? false)
                      FilledButton.icon(
                        key: const Key('shift-close'),
                        onPressed: () => context.go(AppRoutes.shiftClose),
                        icon: const Icon(Icons.lock_outline),
                        label: Text(l10n.shiftClose),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                if (report != null && config != null)
                  ShiftReportView(
                    report: report,
                    utcOffsetMinutes: config.utcOffsetMinutes,
                  ),
                _Movements(shiftId: open.id),
              ],
              if (recent.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.shiftHistory,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Card(
                  child: Column(
                    children: [
                      for (final s in recent)
                        ListTile(
                          key: Key('shift-history-${s.id}'),
                          leading: const Icon(Icons.history),
                          title: Text(
                            l10n.shiftHistoryLine(
                              local(s.openedAt),
                              s.closedByName ?? s.openedByName,
                            ),
                          ),
                          trailing:
                              s.countedCash == null || s.expectedCash == null
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
                ),
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
