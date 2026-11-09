import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/database/tables.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/empty_state.dart';
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
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.pos)),
        title: Text(l10n.syncTitle),
        actions: [
          IconButton(
            key: const Key('sync-now'),
            tooltip: l10n.syncNow,
            onPressed: () => _syncNow(context, ref),
            icon: const Icon(Icons.sync),
          ),
        ],
      ),
      body: items.isLoading
          ? const Skeletonizer(child: _PlaceholderList())
          : list.isEmpty
          ? EmptyState(icon: Icons.cloud_done_outlined, message: l10n.syncEmpty)
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) => _SyncItemTile(item: list[i]),
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
    final (label, color) = switch (item.status) {
      SyncStatus.pending => (l10n.syncStatusPending, AppColors.warning),
      SyncStatus.syncing => (l10n.syncStatusSyncing, AppColors.primary),
      SyncStatus.failed => (l10n.syncStatusFailed, AppColors.error),
      SyncStatus.done => (l10n.syncStatusDone, AppColors.success),
    };
    final subtitle = [
      DateFormat.yMMMd(locale).add_Hms().format(item.createdAt.toLocal()),
      if (item.retryCount > 0) l10n.syncAttempts(item.retryCount),
      if (item.lastError != null) item.lastError!,
    ].join('\n');

    return Card(
      child: ListTile(
        isThreeLine: item.lastError != null,
        title: Text(
          item.label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        leading: Icon(Icons.circle, size: 12, color: color),
        trailing: item.status == SyncStatus.failed
            ? TextButton(
                onPressed: () async {
                  await ref
                      .read(appDatabaseProvider)
                      .syncQueueDao
                      .retryFailed(item.id);
                  if (context.mounted) {
                    AppToast.info(context, l10n.syncRetried);
                  }
                },
                child: Text(l10n.commonRetry),
              )
            : Text(label, style: TextStyle(color: color)),
      ),
    );
  }
}

class _PlaceholderList extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
