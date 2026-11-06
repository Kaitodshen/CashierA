import 'dart:math';

import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/database/tables.dart';
import 'package:cashiera/core/sync/sync_engine.dart';
import 'package:cashiera/core/sync/sync_transport.dart';
import 'package:clock/clock.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers queued per entity, in order; records what was sent.
class FakeTransport implements SyncTransport {
  final answers = <Object>[];
  final sent = <String>[];

  @override
  Future<SyncResponse> push(SyncQueueEntry item) async {
    sent.add(item.clientUuid);
    final next = answers.isEmpty ? const SyncApplied({}) : answers.removeAt(0);
    if (next is Exception) throw next;
    return next as SyncResponse;
  }
}

void main() {
  late AppDatabase db;
  late FakeTransport transport;
  late SyncEngine engine;
  final t0 = DateTime.utc(2026, 11, 5, 3);

  Future<SyncQueueEntry> row(String uuid) => (db.select(
    db.syncQueue,
  )..where((q) => q.clientUuid.equals(uuid))).getSingle();

  Future<void> enqueue(String uuid) => db.syncQueueDao.enqueue(
    entity: 'order',
    action: 'upsert',
    payload: {'id': uuid},
    clientUuid: uuid,
  );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    transport = FakeTransport();
    engine = SyncEngine(
      dao: db.syncQueueDao,
      transport: transport,
      jitter: false,
    );
  });

  tearDown(() => db.close());

  Future<T> at<T>(DateTime time, Future<T> Function() body) =>
      withClock(Clock.fixed(time), body);

  test('applied_marks_done', () async {
    await at(t0, () => enqueue('a'));
    final summary = await at(t0, engine.runOnce);
    expect(summary.sent, 1);
    expect((await row('a')).status, SyncStatus.done);
  });

  test('duplicate_marks_done', () async {
    await at(t0, () => enqueue('a'));
    transport.answers.add(const SyncDuplicate({'order_id': 'a'}));
    await at(t0, engine.runOnce);
    expect((await row('a')).status, SyncStatus.done);
  });

  test('rejected_marks_failed_and_continues_with_next', () async {
    await at(t0, () async {
      await enqueue('a');
      await enqueue('b');
    });
    transport.answers.add(
      const SyncRejected(code: 'tax_mismatch', message: 'tax 800 <> 793'),
    );
    final summary = await at(t0, engine.runOnce);
    final a = await row('a');
    expect(a.status, SyncStatus.failed);
    expect(a.lastError, 'tax_mismatch: tax 800 <> 793');
    expect((await row('b')).status, SyncStatus.done);
    expect(summary.failed, 1);
    expect(summary.sent, 1);
  });

  test('transient_schedules_retry_and_stops_run', () async {
    await at(t0, () async {
      await enqueue('a');
      await enqueue('b');
    });
    transport.answers.add(const SyncTransientException('offline'));
    final summary = await at(t0, engine.runOnce);
    final a = await row('a');
    expect(summary.stoppedByTransientError, isTrue);
    expect(a.status, SyncStatus.pending);
    expect(a.retryCount, 1);
    expect(a.lastError, 'offline');
    expect(a.nextAttemptAt, t0.add(const Duration(seconds: 2)));
    expect(transport.sent, ['a'], reason: 'b must not overtake a');
  });

  test('not_retried_before_due', () async {
    await at(t0, () => enqueue('a'));
    transport.answers.add(const SyncTransientException('offline'));
    await at(t0, engine.runOnce);
    await at(t0.add(const Duration(seconds: 1)), engine.runOnce);
    expect(transport.sent, ['a']);
    await at(t0.add(const Duration(seconds: 2)), engine.runOnce);
    expect(transport.sent, ['a', 'a']);
    expect((await row('a')).status, SyncStatus.done);
  });

  test('clock_jumping_backwards_does_not_freeze_the_queue', () async {
    await at(t0, () => enqueue('a'));
    transport.answers.add(const SyncTransientException('offline'));
    await at(t0, engine.runOnce);
    // The device clock is set back one hour: the retry looks 1h+ away.
    await at(t0.subtract(const Duration(hours: 1)), engine.runOnce);
    expect((await row('a')).status, SyncStatus.done);
  });

  test('manual_retry_requeues_failed', () async {
    await at(t0, () => enqueue('a'));
    transport.answers.add(
      const SyncRejected(code: 'shift_required', message: ''),
    );
    await at(t0, engine.runOnce);
    await db.syncQueueDao.retryFailed((await row('a')).id);
    expect((await row('a')).status, SyncStatus.pending);
    await at(t0, engine.runOnce);
    expect((await row('a')).status, SyncStatus.done);
  });

  test('fifo_order', () async {
    await at(t0, () async {
      for (final id in ['shift', 'order-1', 'order-2', 'close']) {
        await enqueue(id);
      }
    });
    await at(t0, engine.runOnce);
    expect(transport.sent, ['shift', 'order-1', 'order-2', 'close']);
  });

  test('enqueue_same_uuid_once', () async {
    await at(t0, () async {
      await enqueue('a');
      await enqueue('a');
    });
    final rows = await db.select(db.syncQueue).get();
    expect(rows, hasLength(1));
  });

  test('interrupted_syncing_reset_on_start', () async {
    await at(t0, () => enqueue('a'));
    await db.syncQueueDao.markSyncing((await row('a')).id);
    await engine.recoverInterrupted();
    expect((await row('a')).status, SyncStatus.pending);
  });

  test('transaction_rollback_drops_queue_row', () async {
    await expectLater(
      db.transaction(() async {
        await enqueue('a');
        throw StateError('local write failed');
      }),
      throwsStateError,
    );
    expect(await db.select(db.syncQueue).get(), isEmpty);
  });

  test('outstanding_counts_pending_syncing_failed', () async {
    await at(t0, () async {
      for (final id in ['a', 'b', 'c', 'd']) {
        await enqueue(id);
      }
    });
    await db.syncQueueDao.markDone((await row('a')).id);
    await db.syncQueueDao.markSyncing((await row('b')).id);
    await db.syncQueueDao.markFailed((await row('c')).id, 'x');
    expect(await db.syncQueueDao.watchOutstanding().first, 3);
  });

  test('payload_is_stored_as_json', () async {
    await at(
      t0,
      () => db.syncQueueDao.enqueue(
        entity: 'cash_movement',
        action: 'create',
        payload: {'amount': 25000, 'reason': 'Beli es batu'},
        clientUuid: 'p',
      ),
    );
    expect(
      (await row('p')).payload,
      '{"amount":25000,"reason":"Beli es batu"}',
    );
  });

  group('retryDelay', () {
    test('doubles from 2 s and caps at 300 s', () {
      expect(retryDelay(0), const Duration(seconds: 2));
      expect(retryDelay(1), const Duration(seconds: 4));
      expect(retryDelay(2), const Duration(seconds: 8));
      expect(retryDelay(8), const Duration(seconds: 300));
      expect(retryDelay(50), const Duration(seconds: 300));
    });

    test('jitter stays within 20%', () {
      final random = Random(7);
      for (var i = 0; i < 100; i++) {
        final d = retryDelay(1, random: random);
        expect(d.inMilliseconds, inInclusiveRange(4000, 4800));
      }
    });
  });

  test('unknown status from the server is a format error', () {
    expect(
      () => SyncResponse.fromJson({'status': 'weird'}),
      throwsFormatException,
    );
    expect(
      SyncResponse.fromJson({
        'status': 'rejected',
        'code': 'payment_mismatch',
        'message': 'm',
      }),
      isA<SyncRejected>().having((r) => r.code, 'code', 'payment_mismatch'),
    );
  });

  // Keep the drift import used even if helpers change.
  test('drift value helper', () => expect(const Value(1).present, isTrue));
}
