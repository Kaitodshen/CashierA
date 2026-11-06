import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/empty_state.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/features/back_office/data/payments_admin_repository.dart';
import 'package:cashiera/features/back_office/presentation/admin_shifts_screen.dart';
import 'package:cashiera/features/back_office/presentation/back_office_providers.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final _at = DateFormat('dd/MM/yyyy HH:mm');

Color chargeStatusColor(GatewayChargeRow c) => c.unmatched
    ? AppColors.error
    : switch (c.status) {
        'paid' => AppColors.success,
        'pending' => AppColors.warning,
        _ => AppColors.secondary,
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

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
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
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.sm,
          children: [
            Text(
              l10n.gatewayPaidTotal(paidTotal.format(), paid.length),
              key: const Key('gateway-paid-total'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (unmatched.isNotEmpty)
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
          ],
        ),
        if (unmatched.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(l10n.gatewayUnmatchedHint),
          ),
        const SizedBox(height: AppSpacing.md),
        if (charges.isLoading && all.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (charges.hasError)
          Text(l10n.commonError('${charges.error}'))
        else if (list.isEmpty)
          EmptyState(icon: Icons.qr_code_2, message: l10n.gatewayEmpty)
        else
          Card(
            child: Column(
              children: [
                for (final c in list)
                  ListTile(
                    key: Key('charge-${c.id}'),
                    leading: Icon(Icons.qr_code_2, color: chargeStatusColor(c)),
                    title: Text(
                      [
                        c.amount.format(),
                        if (c.unmatched)
                          l10n.gatewayUnmatched
                        else
                          l10n.gatewayStatus(c.status),
                      ].join(' · '),
                    ),
                    subtitle: Text(
                      [
                        c.storeCode,
                        _at.format(c.createdAt.toLocal()),
                        ?c.orderNumber,
                        ?c.providerRef,
                      ].join(' · '),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
