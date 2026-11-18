import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/admin.dart';
import 'package:cashiera/core/design_system/widgets/data_display.dart';
import 'package:cashiera/core/design_system/widgets/glass.dart';
import 'package:cashiera/core/design_system/widgets/glass_table.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/features/back_office/data/payments_admin_repository.dart';
import 'package:cashiera/features/back_office/presentation/admin_shifts_screen.dart';
import 'package:cashiera/features/back_office/presentation/back_office_providers.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final _at = DateFormat('dd/MM/yyyy HH:mm');

Color chargeStatusColor(GatewayChargeRow c) =>
    chargeColorFor(status: c.status, unmatched: c.unmatched);

Color chargeColorFor({required String status, required bool unmatched}) =>
    unmatched
    ? AppColors.error
    : switch (status) {
        'paid' => AppColors.success,
        'pending' => AppColors.warning,
        _ => AppColors.textMuted,
      };

/// Pembayaran QRIS: every dynamic QRIS charge, with the money that arrived
/// but no sale booked flagged for reconciliation.
class GatewayPaymentsScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<GatewayPaymentsScreen> createState() =>
      _GatewayPaymentsScreenState();
}

class _GatewayPaymentsScreenState extends ConsumerState<GatewayPaymentsScreen> {
  String? _storeId;
  DateTimeRange _period = lastDays(7);
  bool _onlyUnmatched = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final charges = ref.watch(
      gatewayChargesProvider(
        from: _period.start,
        to: _period.end,
        storeId: _storeId,
      ),
    );
    final all = charges.value ?? const <GatewayChargeRow>[];
    final list = _onlyUnmatched ? all.where((c) => c.unmatched).toList() : all;
    final paid = all.where((c) => c.status == 'paid');
    final unmatched = all.where((c) => c.unmatched).toList();
    final paidTotal = paid.fold(Money.zero, (a, c) => a + c.amount);
    final unmatchedTotal = unmatched.fold(Money.zero, (a, c) => a + c.amount);

    final muted = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: AppColors.textMuted);
    return AdminPage(
      toolbar: AdminToolbar(
        filters: [
          StoreFilter(
            value: _storeId,
            onChanged: (v) => setState(() => _storeId = v),
          ),
          PeriodFilter(
            value: _period,
            onChanged: (v) => setState(() => _period = v),
          ),
          FilterChip(
            key: const Key('gateway-unmatched'),
            label: Text(l10n.gatewayOnlyUnmatched),
            selected: _onlyUnmatched,
            onSelected: (v) => setState(() => _onlyUnmatched = v),
          ),
        ],
      ),
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.gatewayPaidTotal(paidTotal.format(), paid.length),
                key: const Key('gateway-paid-total'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (unmatched.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.gatewayUnmatchedTotal(
                    unmatchedTotal.format(),
                    unmatched.length,
                  ),
                  key: const Key('gateway-unmatched-total'),
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(l10n.gatewayUnmatchedHint, style: muted),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (charges.isLoading && all.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (charges.hasError)
          adminMessage(
            icon: Icons.cloud_off_outlined,
            message: l10n.commonError('${charges.error}'),
          )
        else if (list.isEmpty)
          adminMessage(icon: Icons.qr_code_2, message: l10n.gatewayEmpty)
        else
          GlassTable<GatewayChargeRow>(
            rows: list,
            columns: [
              GlassColumn(
                label: l10n.ordersColTime,
                flex: 3,
                cell: (c) => Column(
                  key: Key('charge-${c.id}'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      [
                        c.storeCode,
                        _at.format(c.createdAt.toLocal()),
                      ].join(' · '),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      [?c.orderNumber, ?c.providerRef].join(' · '),
                      style: muted,
                    ),
                  ],
                ),
              ),
              GlassColumn(
                label: l10n.adminColStatus,
                flex: 2,
                cell: (c) => StatusChip(
                  label: c.unmatched
                      ? l10n.gatewayUnmatched
                      : l10n.gatewayStatus(c.status),
                  tone: c.unmatched
                      ? StatusTone.error
                      : switch (c.status) {
                          'paid' => StatusTone.success,
                          'pending' => StatusTone.warning,
                          _ => StatusTone.error,
                        },
                ),
              ),
              GlassColumn(
                label: l10n.ordersColTotal,
                numeric: true,
                flex: 2,
                cell: (c) => Text(
                  c.amount.format(),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
