import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/empty_state.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/features/back_office/data/customers_admin_repository.dart';
import 'package:cashiera/features/back_office/presentation/admin_shifts_screen.dart';
import 'package:cashiera/features/back_office/presentation/back_office_providers.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

final _day = DateFormat('dd/MM/yyyy');

/// Outstanding kasbon by customer and store, most overdue first.
class AdminKasbonScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<AdminKasbonScreen> createState() => _AdminKasbonScreenState();
}

class _AdminKasbonScreenState extends ConsumerState<AdminKasbonScreen> {
  String? _storeId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = ref.watch(adminKasbonProvider(storeId: _storeId));
    final list = rows.value ?? const <KasbonOverviewRow>[];
    final total = list.fold(Money.zero, (a, r) => a + r.outstanding);
    final overdue = list.fold(Money.zero, (a, r) => a + r.overdue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StoreFilter(
                value: _storeId,
                onChanged: (v) => setState(() => _storeId = v),
              ),
              Text(
                l10n.adminKasbonTotal(total.format(), overdue.format()),
                key: const Key('admin-kasbon-total'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        Expanded(
          child: rows.isLoading && list.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : rows.hasError
              ? Center(child: Text(l10n.commonError('${rows.error}')))
              : list.isEmpty
              ? EmptyState(
                  icon: Icons.request_quote_outlined,
                  message: l10n.adminKasbonEmpty,
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  itemCount: list.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final r = list[i];
                    final late = r.overdue.rupiah > 0;
                    final overLimit =
                        r.kasbonLimit != null &&
                        r.outstanding.rupiah > r.kasbonLimit!.rupiah;
                    return Card(
                      child: ListTile(
                        key: Key('admin-kasbon-${r.customerId}'),
                        title: Text('${r.customerName} · ${r.storeName}'),
                        subtitle: Text(
                          [
                            ?r.customerPhone,
                            l10n.adminKasbonOldest(_day.format(r.oldestDue)),
                            if (late)
                              l10n.adminKasbonOverdue(r.overdue.format()),
                            if (overLimit)
                              l10n.adminCustomerLimitShort(
                                r.kasbonLimit!.format(),
                              ),
                          ].join(' · '),
                        ),
                        trailing: Text(
                          r.outstanding.format(),
                          style: TextStyle(
                            color: late || overLimit ? AppColors.error : null,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onTap: () =>
                            context.go(AppRoutes.adminCustomer(r.customerId)),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
