import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/providers.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'visual_effects.g.dart';

/// The terminal's "Visual effects" switch: real blur on the top bar, dialogs
/// and sheets. Stored as a named counter (1 on, 0 off; missing means on), so
/// no schema change is needed.
class VisualEffectsRepository {
  const new(this._db);

  final AppDatabase _db;

  static const counterName = 'ui.visual_effects';

  Stream<bool> watch() =>
      (_db.select(_db.localCounters)..where((c) => c.name.equals(counterName)))
          .watchSingleOrNull()
          .map((row) => row == null || row.value != 0);

  Future<void> set({required bool enabled}) => _db
      .into(_db.localCounters)
      .insertOnConflictUpdate(
        LocalCountersCompanion.insert(
          name: counterName,
          value: enabled ? 1 : 0,
        ),
      );
}

@Riverpod(keepAlive: true)
VisualEffectsRepository visualEffectsRepository(Ref ref) =>
    VisualEffectsRepository(ref.watch(appDatabaseProvider));

/// Whether real blur is on. The back office (web) always has it on.
@Riverpod(keepAlive: true)
Stream<bool> visualEffects(Ref ref) {
  if (kIsWeb) return Stream.value(true);
  return ref.watch(visualEffectsRepositoryProvider).watch();
}
