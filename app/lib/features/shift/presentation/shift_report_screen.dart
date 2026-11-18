import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/buttons.dart';
import 'package:cashiera/core/design_system/widgets/flow.dart';
import 'package:cashiera/core/design_system/widgets/glass.dart';
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

    final r = report.value;
    final body = switch (report) {
      AsyncData(value: final r?) when config != null => GlassCard(
        level: GlassLevel.solid,
        child: Center(
          child: ShiftReportView(
            report: r,
            utcOffsetMinutes: config.utcOffsetMinutes,
          ),
        ),
      ),
      AsyncData() => GlassCard(child: Center(child: Text(l10n.reportMissing))),
      AsyncError(:final error) => GlassCard(
        child: Center(child: Text(l10n.commonError('$error'))),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };

    return Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              FlowHeader(
                title: r == null ? l10n.shiftReport : reportTitle(l10n, r),
                onBack: () => context.go(AppRoutes.shift),
                backKey: const Key('report-back'),
                actions: [
                  if (r != null && config != null) ...[
                    SecondaryButton(
                      key: const Key('report-share'),
                      onPressed: () => shareShiftReport(context, r, config),
                      icon: Icons.share_outlined,
                      label: l10n.reportShare,
                    ),
                    PrimaryButton(
                      key: const Key('report-print'),
                      onPressed: () =>
                          printShiftReport(context, ref, r, config),
                      icon: Icons.print_outlined,
                      label: l10n.reportPrint,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              body,
            ],
          ),
        ),
      ),
    );
  }
}
