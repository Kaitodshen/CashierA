import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/empty_state.dart';
import 'package:cashiera/core/design_system/widgets/toasts.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/pos/pos_config.dart';
import 'package:cashiera/core/pos/report_pdf.dart';
import 'package:cashiera/core/pos/shift_report_text.dart';
import 'package:cashiera/features/back_office/data/shift_audit_repository.dart';
import 'package:cashiera/features/back_office/presentation/back_office_providers.dart';
import 'package:cashiera/features/shift/presentation/shift_widgets.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

final _day = DateFormat('dd/MM/yyyy');
final _dayTime = DateFormat('dd/MM HH:mm');

/// The last [days] days up to today, as dates.
DateTimeRange lastDays(int days) {
  final now = clock.now();
  final today = DateTime(now.year, now.month, now.day);
  return DateTimeRange(
    start: today.subtract(Duration(days: days - 1)),
    end: today,
  );
}

/// Store picker shared by the shift and audit pages (null = all stores).
class StoreFilter extends ConsumerWidget {
  const new({required this.value, required this.onChanged, super.key});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final stores = ref.watch(backOfficeStoresProvider).value ?? const [];
    return DropdownButton<String?>(
      key: const Key('filter-store'),
      value: stores.any((s) => s.id == value) ? value : null,
      items: [
        DropdownMenuItem(child: Text(l10n.adminAllStores)),
        for (final s in stores)
          DropdownMenuItem(value: s.id, child: Text('${s.code} · ${s.name}')),
      ],
      onChanged: onChanged,
    );
  }
}

/// Date range button shared by the shift and audit pages.
class PeriodFilter extends StatelessWidget {
  const new({required this.value, required this.onChanged, super.key});

  final DateTimeRange value;
  final ValueChanged<DateTimeRange> onChanged;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    key: const Key('filter-period'),
    onPressed: () async {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2024),
        lastDate: clock.now().add(const Duration(days: 1)),
        initialDateRange: value,
      );
      if (picked != null) onChanged(picked);
    },
    icon: const Icon(Icons.date_range),
    label: Text(
      context.l10n.adminPeriod(
        _day.format(value.start),
        _day.format(value.end),
      ),
    ),
  );
}

class AdminShiftsScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<AdminShiftsScreen> createState() => _AdminShiftsScreenState();
}

class _AdminShiftsScreenState extends ConsumerState<AdminShiftsScreen> {
  String? _storeId;
  DateTimeRange _period = lastDays(7);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final shifts = ref.watch(
      adminShiftsProvider(
        from: _period.start,
        to: _period.end,
        storeId: _storeId,
      ),
    );
    final list = shifts.value ?? const <ShiftOverviewRow>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Wrap(
            spacing: AppSpacing.md,
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
            ],
          ),
        ),
        Expanded(
          child: shifts.isLoading
              ? const Center(child: CircularProgressIndicator())
              : shifts.hasError
              ? Center(child: Text(l10n.commonError('${shifts.error}')))
              : list.isEmpty
              ? EmptyState(
                  icon: Icons.lock_clock_outlined,
                  message: l10n.shiftsEmpty,
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
                    final s = list[i];
                    final diff = s.cashDifference;
                    return Card(
                      child: ListTile(
                        key: Key('admin-shift-${s.shiftId}'),
                        title: Text(
                          '${s.storeName} · ${s.deviceCode} · '
                          '${_dayTime.format(s.openedAt.toLocal())}',
                        ),
                        subtitle: Text(
                          [
                            s.closedByName ?? s.openedByName,
                            l10n.shiftsSales(s.salesTotal.format()),
                            '${s.orderCount} ${l10n.reportTransactions}',
                          ].join(' · '),
                        ),
                        trailing: s.status == 'open'
                            ? Text(
                                l10n.shiftsOpen,
                                style: const TextStyle(
                                  color: AppColors.success,
                                ),
                              )
                            : Text(
                                diff == null ? '-' : differenceText(l10n, diff),
                                style: TextStyle(
                                  color: differenceColor(diff),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                        onTap: () =>
                            context.go(AppRoutes.adminShift(s.shiftId)),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// The server's X/Z report of one shift, with a PDF.
class AdminShiftReportScreen extends ConsumerWidget {
  const new({required this.shiftId, super.key});

  final String shiftId;

  Future<void> _pdf(
    BuildContext context,
    ShiftReport report,
    int offset, {
    required bool share,
  }) async {
    final l10n = context.l10n;
    try {
      final bytes = await buildShiftReportPdf(
        title: reportTitle(l10n, report),
        headerLines: [?report.storeName],
        sections: shiftReportSections(
          report,
          shiftReportLabels(l10n),
          utcOffsetMinutes: offset,
        ),
        footer: l10n.reportPrintedAt(_dayTime.format(clock.now())),
      );
      final name =
          '${reportTitle(l10n, report)} '
          '${report.storeName ?? ''} ${report.businessDate ?? ''}';
      if (share) {
        await Printing.sharePdf(bytes: bytes, filename: '${name.trim()}.pdf');
      } else {
        await Printing.layoutPdf(
          name: name.trim(),
          onLayout: (_) async => bytes,
        );
      }
    } on Exception catch (e) {
      if (context.mounted) AppToast.error(context, l10n.commonError('$e'));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final report = ref.watch(adminShiftReportProvider(shiftId));
    final stores = ref.watch(backOfficeStoresProvider).value ?? const [];

    return switch (report) {
      AsyncData(value: final r) => () {
        final store = stores.where((s) => s.id == r.storeId).firstOrNull;
        final offset = utcOffsetMinutesFor(store?.timezone ?? 'Asia/Jakarta');
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: () => context.go(AppRoutes.adminShifts),
                  icon: const Icon(Icons.arrow_back),
                ),
                Expanded(
                  child: Text(
                    [reportTitle(l10n, r), ?r.storeName].join(' · '),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  key: const Key('admin-report-share'),
                  tooltip: l10n.reportShare,
                  onPressed: () => _pdf(context, r, offset, share: true),
                  icon: const Icon(Icons.share_outlined),
                ),
                IconButton(
                  key: const Key('admin-report-print'),
                  tooltip: l10n.reportPrint,
                  onPressed: () => _pdf(context, r, offset, share: false),
                  icon: const Icon(Icons.print_outlined),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ShiftReportView(report: r, utcOffsetMinutes: offset),
              ),
            ),
          ],
        );
      }(),
      AsyncError(:final error) => Center(
        child: Text(l10n.commonError('$error')),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}
