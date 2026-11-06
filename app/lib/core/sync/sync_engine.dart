import 'dart:math';

import 'package:cashiera/core/sync/sync_queue_dao.dart';
import 'package:cashiera/core/sync/sync_transport.dart';
import 'package:clock/clock.dart';

/// Retry delay after [retryCount] earlier failures: 2 s, 4 s, 8 s ... capped
/// at 300 s, plus up to 20% jitter so terminals don't retry in lockstep.
Duration retryDelay(int retryCount, {Random? random}) {
  final exponent = retryCount.clamp(0, 30);
  final seconds = min(300, 2 << exponent);
  final jitter = random == null ? 0.0 : random.nextDouble() * 0.2;
  return Duration(milliseconds: (seconds * 1000 * (1 + jitter)).round());
}

class SyncRunSummary {
  const new({
    required this.sent,
    required this.failed,
    required this.stoppedByTransientError,
    this.skippedBecauseBusy = false,
  });

  const new busy()
    : sent = 0,
      failed = 0,
      stoppedByTransientError = false,
      skippedBecauseBusy = true;

  final int sent;
  final int failed;
  final bool stoppedByTransientError;
  final bool skippedBecauseBusy;
}

/// Drains the outbox oldest-first. One run at a time.
class SyncEngine {
  /// [jitter] spreads retries of many terminals apart; tests turn it off to
  /// assert exact retry times.
  new({
    required this.dao,
    required this.transport,
    bool jitter = true,
    Random? random,
  }) : _random = jitter ? (random ?? Random()) : null;

  final SyncQueueDao dao;
  final SyncTransport transport;
  final Random? _random;
  bool _running = false;

  /// Call once at startup, before the first [runOnce].
  Future<void> recoverInterrupted() => dao.resetInterrupted();

  Future<SyncRunSummary> runOnce() async {
    if (_running) return const SyncRunSummary.busy();
    _running = true;
    var sent = 0;
    var failed = 0;
    try {
      while (true) {
        final now = clock.now();
        final item = await dao.nextDue(now);
        if (item == null) break;
        await dao.markSyncing(item.id);
        try {
          final response = await transport.push(item);
          switch (response) {
            case SyncApplied() || SyncDuplicate():
              await dao.markDone(item.id);
              sent++;
            case SyncRejected(:final code, :final message):
              await dao.markFailed(item.id, '$code: $message');
              failed++;
          }
        } on Object catch (error) {
          // Transient (network, server) or unexpected: never drop the item.
          final message = error is SyncTransientException
              ? error.message
              : error.toString();
          await dao.scheduleRetry(
            item.id,
            now.add(retryDelay(item.retryCount, random: _random)),
            message,
          );
          return SyncRunSummary(
            sent: sent,
            failed: failed,
            stoppedByTransientError: true,
          );
        }
      }
      return SyncRunSummary(
        sent: sent,
        failed: failed,
        stoppedByTransientError: false,
      );
    } finally {
      _running = false;
    }
  }
}
