import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/features/sell/presentation/sell_providers.dart';
import 'package:cashiera/features/shift/presentation/report_actions.dart';
import 'package:cashiera/features/shift/presentation/shift_providers.dart';
import 'package:cashiera/features/shift/presentation/shift_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// X or Z report of one of this terminal's shifts, with print and share.
class ShiftReportScreen extends ConsumerWidget {
  const new({required this.shiftId, super.key});

  final String shiftId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final config = ref.watch(posConfigProvider).value;
    final report = ref.watch(shiftReportProvider(shiftId));

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.shift)),
        title: Text(
          report.value == null
              ? l10n.shiftReport
              : reportTitle(l10n, report.value!),
        ),
      ),
      body: switch (report) {
        AsyncData(value: final r?) when config != null => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                ShiftReportView(
                  report: r,
                  utcOffsetMinutes: config.utcOffsetMinutes,
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    OutlinedButton.icon(
                      key: const Key('report-share'),
                      onPressed: () => shareShiftReport(context, r, config),
                      icon: const Icon(Icons.share_outlined),
                      label: Text(l10n.reportShare),
                    ),
                    FilledButton.icon(
                      key: const Key('report-print'),
                      onPressed: () =>
                          printShiftReport(context, ref, r, config),
                      icon: const Icon(Icons.print_outlined),
                      label: Text(l10n.reportPrint),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        AsyncData() => Center(child: Text(l10n.reportMissing)),
        AsyncError(:final error) => Center(
          child: Text(l10n.commonError('$error')),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
