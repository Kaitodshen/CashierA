import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/providers.dart';
import 'package:cashiera/core/session/session_controller.dart';
import 'package:cashiera/features/pos_home/presentation/widgets/terminal_status_chip.dart';
import 'package:cashiera/features/printing/printer_screen.dart';
import 'package:cashiera/features/sell/presentation/sell_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Terminal home after PIN login: who is on duty, store settings in effect,
/// and the outbox. The cashier, shift, printer and catalog screens open here.
class PosHomeScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(sessionControllerProvider).value;
    final store = session?.store;
    final staff = session?.staff;
    final pending = ref.watch(syncOutstandingProvider).value ?? 0;
    final shift = ref.watch(openShiftProvider).value;
    final printer = ref.watch(receiptPrinterProvider).value;
    final config = ref.watch(posConfigProvider).value;

    final cards = [
      _InfoCard(
        icon: Icons.badge_outlined,
        title: staff == null ? '' : l10n.posOnDuty(staff.fullName),
        lines: [
          if (session?.device != null)
            l10n.posTerminal(session!.device!.deviceCode),
          if (store != null) store.store.name,
        ],
      ),
      if (store != null)
        _InfoCard(
          icon: Icons.receipt_long_outlined,
          title: l10n.posStoreSettings,
          lines: [
            l10n.posTaxLine(
              store.settings.taxName,
              (store.settings.taxRateBps / 100).toStringAsFixed(
                store.settings.taxRateBps % 100 == 0 ? 0 : 2,
              ),
              store.settings.taxInclusive
                  ? l10n.posTaxInclusive
                  : l10n.posTaxExclusive,
            ),
            l10n.posPaper(store.settings.receiptPaperMm),
          ],
        ),
      _InfoCard(
        key: const Key('pos-sell'),
        icon: Icons.point_of_sale,
        title: l10n.posSell,
        lines: [l10n.posSellHint],
        onTap: () => context.go(AppRoutes.sell),
      ),
      if (config?.fnbMode ?? false) ...[
        _InfoCard(
          key: const Key('pos-tables'),
          icon: Icons.table_restaurant_outlined,
          title: l10n.navTables,
          lines: [l10n.posTablesHint],
          onTap: () => context.go(AppRoutes.tables),
        ),
        if (staff?.can('kitchen.view') ?? false)
          _InfoCard(
            key: const Key('pos-kitchen'),
            icon: Icons.soup_kitchen_outlined,
            title: l10n.kitchenTitle,
            lines: [l10n.posKitchenHint],
            onTap: () => context.go(AppRoutes.kitchen),
          ),
      ],
      _InfoCard(
        key: const Key('pos-shift'),
        icon: Icons.lock_clock_outlined,
        title: l10n.posShift,
        lines: [
          if (shift == null)
            l10n.posShiftNone
          else
            l10n.posShiftOpenSince(
              DateFormat.Hm().format(
                config?.localTime(shift.openedAt) ?? shift.openedAt.toLocal(),
              ),
              shift.openedByName,
            ),
        ],
        onTap: () => context.go(AppRoutes.shift),
      ),
      _InfoCard(
        key: const Key('pos-customers'),
        icon: Icons.people_outline,
        title: l10n.posCustomers,
        lines: [l10n.posCustomersHint],
        onTap: () => context.go(AppRoutes.customers),
      ),
      _InfoCard(
        key: const Key('pos-printer'),
        icon: Icons.print_outlined,
        title: l10n.posPrinter,
        lines: [
          if (printer == null)
            l10n.posPrinterNone
          else ...[
            printer.name,
            [
              connectionLabel(l10n, printer.connection),
              l10n.printerPaperMm(printer.paperMm),
            ].join(' · '),
          ],
        ],
        onTap: () => context.go(AppRoutes.printer),
      ),
      _InfoCard(
        key: const Key('pos-catalog'),
        icon: Icons.inventory_2_outlined,
        title: l10n.posCatalog,
        lines: [l10n.posCatalogHint],
        onTap: () => context.go(AppRoutes.catalog),
      ),
      _InfoCard(
        icon: Icons.cloud_sync_outlined,
        title: l10n.posOpenSync,
        lines: [l10n.statusPending(pending)],
        onTap: () => context.go(AppRoutes.sync),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.posTitle),
        actions: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: TerminalStatusChip(),
          ),
          IconButton(
            key: const Key('pos-lock'),
            tooltip: l10n.posLock,
            onPressed: () =>
                ref.read(sessionControllerProvider.notifier).lock(),
            icon: const Icon(Icons.lock_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: GridView.extent(
          padding: const EdgeInsets.all(AppSpacing.lg),
          maxCrossAxisExtent: 360,
          mainAxisSpacing: AppSpacing.lg,
          crossAxisSpacing: AppSpacing.lg,
          childAspectRatio: 1.6,
          children: cards,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.lines,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final List<String> lines;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.success),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              for (final line in lines)
                Text(
                  line,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
