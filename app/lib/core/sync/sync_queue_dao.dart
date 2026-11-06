import 'dart:convert';

import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/database/tables.dart';
import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

part 'sync_queue_dao.g.dart';

/// A retry scheduled further ahead than this is treated as due, so a device
/// clock that jumped backwards cannot freeze the queue.
const maxScheduledDelay = Duration(minutes: 6);

@DriftAccessor(tables: [SyncQueue])
class SyncQueueDao extends DatabaseAccessor<AppDatabase>
    with _$SyncQueueDaoMixin {
  new(super.attachedDatabase);

  /// Adds an item to the outbox and returns its client UUID. Call it inside
  /// the same `transaction` as the local write it describes. Enqueuing an
  /// existing [clientUuid] again is a no-op.
  Future<String> enqueue({
    required String entity,
    required String action,
    required Map<String, Object?> payload,
    String? clientUuid,
  }) async {
    final uuid = clientUuid ?? const Uuid().v7();
    await into(syncQueue).insert(
      SyncQueueCompanion.insert(
        clientUuid: uuid,
        entity: entity,
        action: action,
        payload: jsonEncode(payload),
        createdAt: clock.now(),
        status: SyncStatus.pending,
      ),
      mode: InsertMode.insertOrIgnore,
    );
    return uuid;
  }

  /// The oldest PENDING item, if it may be sent at [now]. Strict FIFO: when
  /// the head is waiting for a retry, nothing behind it overtakes it (a sale
  /// must never arrive before the shift it belongs to). FAILED items are
  /// skipped so they never block the queue.
  Future<SyncQueueEntry?> nextDue(DateTime now) async {
    final head =
        await (select(syncQueue)
              ..where((q) => q.status.equalsValue(SyncStatus.pending))
              ..orderBy([(q) => OrderingTerm.asc(q.id)])
              ..limit(1))
            .getSingleOrNull();
    if (head == null) return null;
    final at = head.nextAttemptAt;
    final due =
        at == null ||
        !at.isAfter(now) ||
        at.difference(now) > maxScheduledDelay;
    return due ? head : null;
  }

  Future<void> markSyncing(int id) =>
      _update(id, const SyncQueueCompanion(status: Value(SyncStatus.syncing)));

  Future<void> markDone(int id) => _update(
    id,
    const SyncQueueCompanion(
      status: Value(SyncStatus.done),
      lastError: Value(null),
      nextAttemptAt: Value(null),
    ),
  );

  Future<void> markFailed(int id, String error) => _update(
    id,
    SyncQueueCompanion(
      status: const Value(SyncStatus.failed),
      lastError: Value(error),
      nextAttemptAt: const Value(null),
    ),
  );

  /// Puts the item back to PENDING after a transient error.
  Future<void> scheduleRetry(int id, DateTime at, String error) async {
    await customUpdate(
      'UPDATE sync_queue SET status = ?, retry_count = retry_count + 1, '
      'last_error = ?, next_attempt_at = ? WHERE id = ?',
      variables: [
        Variable<String>(SyncStatus.pending.code),
        Variable<String>(error),
        Variable<DateTime>(at),
        Variable<int>(id),
      ],
      updates: {syncQueue},
    );
  }

  /// Manual retry of a FAILED item from the Sync screen.
  Future<void> retryFailed(int id) async {
    await (update(syncQueue)..where(
          (q) => q.id.equals(id) & q.status.equalsValue(SyncStatus.failed),
        ))
        .write(
          const SyncQueueCompanion(
            status: Value(SyncStatus.pending),
            nextAttemptAt: Value(null),
          ),
        );
  }

  /// Items left in SYNCING by a crash or kill go back to PENDING. Safe: the
  /// server deduplicates on client_uuid.
  Future<int> resetInterrupted() =>
      (update(syncQueue)
            ..where((q) => q.status.equalsValue(SyncStatus.syncing)))
          .write(const SyncQueueCompanion(status: Value(SyncStatus.pending)));

  /// Deletes DONE items created before [before].
  Future<int> pruneDone(DateTime before) =>
      (delete(syncQueue)..where(
            (q) =>
                q.status.equalsValue(SyncStatus.done) &
                q.createdAt.isSmallerThanValue(before),
          ))
          .go();

  /// Items the server has not confirmed yet: PENDING + SYNCING + FAILED.
  Stream<int> watchOutstanding() {
    final count = syncQueue.id.count();
    return (selectOnly(syncQueue)
          ..addColumns([count])
          ..where(syncQueue.status.equalsValue(SyncStatus.done).not()))
        .map((row) => row.read(count) ?? 0)
        .watchSingle();
  }

  /// Outstanding items plus the 50 most recently sent, newest first.
  Stream<List<SyncQueueEntry>> watchItems() {
    final outstanding = select(syncQueue)
      ..where((q) => q.status.equalsValue(SyncStatus.done).not())
      ..orderBy([(q) => OrderingTerm.desc(q.id)]);
    final recentDone = select(syncQueue)
      ..where((q) => q.status.equalsValue(SyncStatus.done))
      ..orderBy([(q) => OrderingTerm.desc(q.id)])
      ..limit(50);
    return outstanding.watch().asyncMap(
      (open) async => [...open, ...await recentDone.get()],
    );
  }

  Future<void> _update(int id, SyncQueueCompanion values) =>
      (update(syncQueue)..where((q) => q.id.equals(id))).write(values);
}
