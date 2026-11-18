import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/database/tables.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/buttons.dart';
import 'package:cashiera/core/design_system/widgets/data_display.dart';
import 'package:cashiera/core/design_system/widgets/empty_state.dart';
import 'package:cashiera/core/design_system/widgets/flow.dart';
import 'package:cashiera/core/design_system/widgets/glass.dart';
import 'package:cashiera/core/design_system/widgets/toasts.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/providers.dart';
import 'package:cashiera/core/sync/sync_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// The outbox: what is waiting, what failed and why, with manual retry.
class SyncScreen extends ConsumerWidget {
  const new({super.key});

  Future<void> _syncNow(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final summary = await ref.read(syncSchedulerProvider.notifier).syncNow();
    if (!context.mounted || summary.skippedBecauseBusy) return;
    if (summary.stoppedByTransientError) {
      AppToast.info(context, l10n.syncOfflineNow);
    } else {
      AppToast.success(
        context,
        l10n.syncRunResult(summary.sent, summary.failed),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final items = ref.watch(syncItemsProvider);
    final list = items.value ?? const <SyncItem>[];

    return Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              FlowHeader(
                title: l10n.syncTitle,
                onBack: () => context.go(AppRoutes.pos),
                backKey: const Key('sync-back'),
                status: Text(
                  l10n.statusPending(
                    list.where((i) => i.status != SyncStatus.done).length,
                  ),
                ),
                actions: [
                  PrimaryButton(
                    key: const Key('sync-now'),
                    onPressed: () => _syncNow(context, ref),
                    icon: Icons.sync,
                    label: l10n.syncNow,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (items.isLoading)
                const Skeletonizer(child: _PlaceholderList())
              else if (list.isEmpty)
                GlassCard(
                  child: EmptyState(
                    icon: Icons.cloud_done_outlined,
                    message: l10n.syncEmpty,
                  ),
                )
              else
                for (final item in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _SyncItemTile(item: item),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncItemTile extends ConsumerWidget {
  const new({required this.item});

  final SyncItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final (label, tone) = switch (item.status) {
      SyncStatus.pending => (l10n.syncStatusPending, StatusTone.warning),
      SyncStatus.syncing => (l10n.syncStatusSyncing, StatusTone.primary),
      SyncStatus.failed => (l10n.syncStatusFailed, StatusTone.error),
      SyncStatus.done => (l10n.syncStatusDone, StatusTone.success),
    };
    final muted = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: AppColors.textMuted);

    return GlassCard(
      level: GlassLevel.solid,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  [
                    DateFormat.yMMMd(locale)
                        .add_Hms()
                        .format(item.createdAt.toLocal()),
                    if (item.retryCount > 0) l10n.syncAttempts(item.retryCount),
                  ].join(' · '),
                  style: muted,
                ),
                if (item.lastError != null)
                  Text(
                    item.lastError!,
                    style: muted?.copyWith(color: AppColors.error),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          if (item.status == SyncStatus.failed)
            SecondaryButton(
              onPressed: () async {
                await ref
                    .read(appDatabaseProvider)
                    .syncQueueDao
                    .retryFailed(item.id);
                if (context.mounted) AppToast.info(context, l10n.syncRetried);
              },
              icon: Icons.refresh,
              label: l10n.commonRetry,
            )
          else
            StatusChip(label: label, tone: tone),
        ],
      ),
    );
  }
}

class _PlaceholderList extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        5,
        (_) => const Card(
          child: ListTile(
            title: Text('order.upsert · PST-T1-000000-0000'),
            subtitle: Text('5 Nov 2026 10.00.00'),
          ),
        ),
      ),
    );
  }
}
