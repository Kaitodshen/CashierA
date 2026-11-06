import 'dart:async';

import 'package:cashiera/core/catalog/catalog_pull_service.dart';
import 'package:cashiera/core/providers.dart';
import 'package:cashiera/core/session/session_controller.dart';
import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'catalog_sync.g.dart';

@immutable
class CatalogSyncState {
  const new({this.lastPulledAt, this.error, this.running = false});

  final DateTime? lastPulledAt;
  final String? error;
  final bool running;
}

/// Keeps the terminal's catalog mirror fresh: at start, every 5 minutes,
/// when the network comes back, and shortly after stock changes on the
/// server (Realtime on stock_levels for this store).
@Riverpod(keepAlive: true)
class CatalogSync extends _$CatalogSync {
  static const interval = Duration(minutes: 5);
  static const realtimeDebounce = Duration(seconds: 2);

  CatalogPullService? _service;
  Timer? _debounce;

  @override
  CatalogSyncState build() {
    final storeId = ref.watch(
      sessionControllerProvider.select((s) => s.value?.device?.storeId),
    );
    if (storeId == null || !ref.watch(appEnvProvider).isConfigured) {
      return const CatalogSyncState();
    }
    _service = CatalogPullService(
      db: ref.watch(appDatabaseProvider),
      source: ref.watch(catalogSourceProvider),
      storeId: storeId,
    );

    final timer = Timer.periodic(interval, (_) => unawaited(refresh()));
    ref
      ..onDispose(timer.cancel)
      ..onDispose(() => _debounce?.cancel())
      ..listen(onlineProvider, (previous, next) {
        if (next.value == true && previous?.value != true) {
          unawaited(refresh());
        }
      });
    _listenToStock(storeId);
    unawaited(Future.microtask(refresh));
    return const CatalogSyncState();
  }

  void _listenToStock(String storeId) {
    final client = ref.read(supabaseClientProvider);
    final channel = client
        .channel('stock-$storeId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'stock_levels',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'store_id',
            value: storeId,
          ),
          callback: (_) {
            _debounce?.cancel();
            _debounce = Timer(realtimeDebounce, () => unawaited(refresh()));
          },
        )
        .subscribe();
    ref.onDispose(() => unawaited(client.removeChannel(channel)));
  }

  /// Pulls now. Returns null when a pull is already running or the terminal
  /// isn't paired.
  Future<PullSummary?> refresh() async {
    final service = _service;
    if (service == null || state.running) return null;
    state = CatalogSyncState(lastPulledAt: state.lastPulledAt, running: true);
    try {
      final summary = await service.pull();
      if (ref.mounted) {
        state = CatalogSyncState(lastPulledAt: clock.now());
      }
      return summary;
    } on Object catch (e) {
      if (ref.mounted) {
        state = CatalogSyncState(lastPulledAt: state.lastPulledAt, error: '$e');
      }
      return null;
    }
  }
}
