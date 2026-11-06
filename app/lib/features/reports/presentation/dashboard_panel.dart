import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/features/back_office/presentation/admin_shifts_screen.dart';
import 'package:cashiera/features/reports/data/reports_repository.dart';
import 'package:cashiera/features/reports/presentation/report_providers.dart';
import 'package:cashiera/features/reports/presentation/report_widgets.dart';
import 'package:cashiera/features/reports/presentation/reports_screen.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// `+12%` / `-5%` against yesterday, or null when yesterday had nothing.
String? changeText(Money today, Money yesterday) {
  if (yesterday.rupiah == 0) return null;
  final pct = (today.rupiah - yesterday.rupiah) * 100 / yesterday.rupiah;
  final rounded = pct.round();
  return '${rounded > 0 ? '+' : ''}$rounded%';
}

/// Today at a glance for the back-office home.
class DashboardPanel extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<DashboardPanel> createState() => _DashboardPanelState();
}

class _DashboardPanelState extends ConsumerState<DashboardPanel> {
  String? _storeId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final data = ref.watch(dashboardProvider(storeId: _storeId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(l10n.dashTitle, style: theme.textTheme.titleMedium),
            ),
            StoreFilter(
              value: _storeId,
              onChanged: (v) => setState(() => _storeId = v),
            ),
            const SizedBox(width: AppSpacing.sm),
            TextButton.icon(
              key: const Key('dash-reports'),
              onPressed: () => context.go(AppRoutes.adminReports),
              icon: const Icon(Icons.bar_chart),
              label: Text(l10n.dashAllReports),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        switch (data) {
          AsyncData(value: final d) => _Body(data: d),
          AsyncError(:final error) => Text(l10n.commonError('$error')),
          _ => const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          ),
        },
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const new({required this.data});
  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final t = data.today;
    final y = data.yesterday;
    final change = changeText(t.netSales, y.netSales);
    final payments = data.payments.fold(Money.zero, (a, m) => a + m.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          children: [
            SummaryTile(
              key: const Key('dash-sales'),
              icon: Icons.payments_outlined,
              label: l10n.colNetSales,
              value: t.netSales.format(),
              detail: [
                l10n.dashVsYesterday(y.netSales.format()),
                ?change,
              ].join(' · '),
              detailColor: change == null
                  ? null
                  : change.startsWith('-')
                  ? AppColors.error
                  : AppColors.success,
            ),
            SummaryTile(
              label: l10n.colOrders,
              value: '${t.orders}',
              detail: l10n.dashVsYesterday('${y.orders}'),
            ),
            SummaryTile(
              label: l10n.colAverage,
              value: t.average.format(),
              detail: l10n.dashVsYesterday(y.average.format()),
            ),
          ],
        ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _Flag(
              icon: Icons.lock_clock_outlined,
              text: l10n.dashOpenShifts(data.openShifts),
              onTap: () => context.go(AppRoutes.adminShifts),
            ),
            if (data.lowStock > 0)
              _Flag(
                icon: Icons.inventory_2_outlined,
                text: l10n.dashLowStock(data.lowStock),
                color: AppColors.warning,
                onTap: () => context.go(AppRoutes.adminStock),
              ),
            if (data.overdueKasbon.rupiah > 0)
              _Flag(
                icon: Icons.request_quote_outlined,
                text: l10n.dashOverdue(data.overdueKasbon.format()),
                color: AppColors.error,
                onTap: () => context.go(AppRoutes.adminKasbon),
              ),
            if (data.openAlerts > 0)
              _Flag(
                icon: Icons.warning_amber_outlined,
                text: l10n.dashAlerts(data.openAlerts),
                color: AppColors.warning,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.dashLast7, style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.md),
                MoneyBarChart(height: 160, bars: dayBars(data.last7)),
              ],
            ),
          ),
        ),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            SizedBox(
              width: 420,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l10n.dashTop, style: theme.textTheme.titleSmall),
                      if (data.topProducts.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                          child: Text(l10n.dashNothing),
                        ),
                      for (final p in data.topProducts)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(p.name),
                          subtitle: Text('${p.quantity.toPlain()} ×'),
                          trailing: Text(p.net.format()),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 420,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.dashPayments,
                        style: theme.textTheme.titleSmall,
                      ),
                      if (data.payments.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                          child: Text(l10n.dashNothing),
                        ),
                      for (final m in data.payments)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(m.name)),
                                  Text(m.amount.format()),
                                ],
                              ),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: payments.rupiah == 0
                                    ? 0
                                    : m.amount.rupiah / payments.rupiah,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Flag extends StatelessWidget {
  const new({required this.icon, required this.text, this.color, this.onTap});

  final IconData icon;
  final String text;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ActionChip(
    avatar: Icon(icon, size: 18, color: color),
    label: Text(text),
    onPressed: onTap,
  );
}
