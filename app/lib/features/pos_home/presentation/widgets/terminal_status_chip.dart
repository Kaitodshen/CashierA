import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/catalog/catalog_sync.dart';
import 'package:cashiera/core/design_system/widgets/sync_status_chip.dart';
import 'package:cashiera/core/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Online/offline + outstanding queue items, shown in every terminal header.
/// Watching the scheduler here keeps the outbox draining on every terminal
/// screen, locked or not.
class TerminalStatusChip extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref
      ..watch(syncSchedulerProvider)
      ..watch(catalogSyncProvider);
    final online = ref.watch(onlineProvider).value ?? false;
    final pending = ref.watch(syncOutstandingProvider).value ?? 0;
    final unlocked =
        GoRouterState.of(context).matchedLocation != AppRoutes.lock;
    return SyncStatusChip(
      online: online,
      pending: pending,
      onTap: unlocked ? () => context.go(AppRoutes.sync) : null,
    );
  }
}
