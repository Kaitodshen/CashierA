import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/data_display.dart';
import 'package:cashiera/core/design_system/widgets/glass.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/features/sell/presentation/sell_providers.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The Overview's headline numbers, all from the live X report.
({
  Money gross,
  int orders,
  Money averageBasket,
  Money expectedCash,
  Money openingCash,
  Money nonCash,
})
overviewNumbers(ShiftReport r) => (
  gross: r.sales.grand,
  orders: r.sales.orders,
  averageBasket: r.sales.averageBasket,
  expectedCash: r.cash.expected,
  openingCash: r.cash.openingCash,
  nonCash: Money(
    r.payments
        .where((p) => p.methodType != 'cash')
        .fold(0, (a, p) => a + p.amount.rupiah),
  ),
);

/// Four stat cards: sales, transactions, cash in drawer, non-cash.
class OverviewStats extends StatelessWidget {
  const new({required this.report, super.key});

  final ShiftReport? report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final n = report == null ? null : overviewNumbers(report!);
    String money(Money? m) => (m ?? Money.zero).format();
    final cards = [
      StatCard(
        icon: Icons.payments_outlined,
        label: l10n.overviewGross,
        value: money(n?.gross),
        footnote: l10n.overviewOrders(n?.orders ?? 0),
      ),
      StatCard(
        icon: Icons.receipt_long_outlined,
        label: l10n.overviewTransactions,
        value: '${n?.orders ?? 0}',
        tint: const Color(0xFF6366F1),
        footnote: l10n.overviewAverage(money(n?.averageBasket)),
      ),
      StatCard(
        icon: Icons.point_of_sale,
        label: l10n.overviewCashInDrawer,
        value: money(n?.expectedCash),
        valueKey: const Key('shift-expected'),
        tint: AppColors.warningText,
        footnote: l10n.overviewFloat(money(n?.openingCash)),
      ),
      StatCard(
        icon: Icons.qr_code_2,
        label: l10n.overviewNonCash,
        value: money(n?.nonCash),
        tint: AppColors.info,
      ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final perRow = c.maxWidth >= 900
            ? 4
            : c.maxWidth >= 520
            ? 2
            : 1;
        const gap = AppSpacing.lg;
        final width = (c.maxWidth - gap * (perRow - 1)) / perRow;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards) SizedBox(width: width, child: card),
          ],
        );
      },
    );
  }
}

/// This shift's latest orders, newest first; tap opens the receipt.
class RecentOrdersCard extends ConsumerWidget {
  const new({required this.shiftId, super.key});

  final String shiftId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final orders = (ref.watch(todaysOrdersProvider).value ?? const [])
        .where((o) => o.shiftId == shiftId && o.status != 'held')
        .take(6)
        .toList();
    return GlassCard(
      key: const Key('overview-recent'),
      level: GlassLevel.solid,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.overviewRecent, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          if (orders.isEmpty)
            Text(
              l10n.overviewNoOrders,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          for (final o in orders)
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.control),
              onTap: () => context.go(AppRoutes.receipt(o.id)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            o.orderNumber,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontFeatures: AppTypography.tabular,
                            ),
                          ),
                          Text(
                            [
                              l10n.receiptItems(o.itemCount),
                              o.cashierName,
                            ].join(' • '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (o.status != 'completed') ...[
                      StatusChip(label: o.status, tone: StatusTone.warning),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    MoneyText(
                      Money(o.grandTotal),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Totals per payment method in this shift.
class PaymentBreakdownCard extends StatelessWidget {
  const new({required this.report, super.key});

  final ShiftReport? report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final payments = report?.payments ?? const <PaymentTotal>[];
    final total = payments.fold(0, (a, p) => a + p.amount.rupiah);
    return GlassCard(
      level: GlassLevel.solid,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.overviewPayments, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          if (payments.isEmpty)
            Text(
              l10n.overviewNoOrders,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          for (final p in payments) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${p.name} (${p.count})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                MoneyText(p.amount),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            StockBar(
              fraction: total == 0 ? 0 : p.amount.rupiah / total,
              tone: p.methodType == 'cash'
                  ? StatusTone.warning
                  : StatusTone.primary,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}
