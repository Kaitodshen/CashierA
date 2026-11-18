import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/admin.dart';
import 'package:cashiera/core/design_system/widgets/data_display.dart';
import 'package:cashiera/core/design_system/widgets/glass_table.dart';
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

    final muted = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: AppColors.textMuted);
    return AdminPage(
      toolbar: AdminToolbar(
        filters: [
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
      children: [
        if (rows.isLoading && list.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (rows.hasError)
          adminMessage(
            icon: Icons.cloud_off_outlined,
            message: l10n.commonError('${rows.error}'),
          )
        else if (list.isEmpty)
          adminMessage(
            icon: Icons.request_quote_outlined,
            message: l10n.adminKasbonEmpty,
          )
        else
          GlassTable<KasbonOverviewRow>(
            rows: list,
            onRowTap: (r) => context.go(AppRoutes.adminCustomer(r.customerId)),
            columns: [
              GlassColumn(
                label: l10n.navCustomers,
                flex: 4,
                cell: (r) {
                  final late = r.overdue.rupiah > 0;
                  final overLimit =
                      r.kasbonLimit != null &&
                      r.outstanding.rupiah > r.kasbonLimit!.rupiah;
                  return Column(
                    key: Key('admin-kasbon-${r.customerId}'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          InitialsAvatar(name: r.customerName, size: 32),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              '${r.customerName} · ${r.storeName}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        [
                          ?r.customerPhone,
                          l10n.adminKasbonOldest(_day.format(r.oldestDue)),
                          if (late) l10n.adminKasbonOverdue(r.overdue.format()),
                          if (overLimit)
                            l10n.adminCustomerLimitShort(
                              r.kasbonLimit!.format(),
                            ),
                        ].join(' · '),
                        style: muted,
                      ),
                    ],
                  );
                },
              ),
              GlassColumn(
                label: l10n.customerKasbon,
                numeric: true,
                flex: 2,
                cell: (r) {
                  final bad =
                      r.overdue.rupiah > 0 ||
                      (r.kasbonLimit != null &&
                          r.outstanding.rupiah > r.kasbonLimit!.rupiah);
                  return StatusChip(
                    label: r.outstanding.format(),
                    tone: bad ? StatusTone.error : StatusTone.warning,
                  );
                },
              ),
            ],
          ),
      ],
    );
  }
}
