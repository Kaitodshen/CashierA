import 'dart:convert';

import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/database/app_database.dart';
import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

/// What a paired terminal keeps locally: its pairing, its store, its staff.
class TerminalContext {
  const new({required this.device, required this.store});

  final LocalDeviceRow device;
  final StoreSnapshot? store;
}

class TerminalRepository {
  new(this._db);

  final AppDatabase _db;

  /// Saves the pairing, store and roster together: a half-paired terminal
  /// (device row but no staff) can't happen.
  Future<void> savePairing(
    PairedDevice device,
    StoreSnapshot store,
    List<StaffMember> roster,
  ) => _db.transaction(() async {
    await _db.clearTerminalData();
    await _db
        .into(_db.localDevice)
        .insert(
          LocalDeviceCompanion.insert(
            deviceId: device.deviceId,
            deviceCode: device.deviceCode,
            storeId: device.storeId,
            name: device.name,
            pairedAt: clock.now(),
          ),
        );
    await saveStore(store);
    await replaceRoster(roster);
  });

  Future<TerminalContext?> load() async {
    final device = await _db.select(_db.localDevice).getSingleOrNull();
    if (device == null) return null;
    final store = await (_db.select(
      _db.localStores,
    )..where((s) => s.id.equals(device.storeId))).getSingleOrNull();
    final settings = await (_db.select(
      _db.localStoreSettings,
    )..where((s) => s.storeId.equals(device.storeId))).getSingleOrNull();
    return TerminalContext(
      device: device,
      store: store == null || settings == null
          ? null
          : StoreSnapshot(store: store, settings: settings),
    );
  }

  Future<void> saveStore(StoreSnapshot snapshot) => _db.batch((b) {
    b
      ..insert(
        _db.localStores,
        snapshot.store,
        mode: InsertMode.insertOrReplace,
      )
      ..insert(
        _db.localStoreSettings,
        snapshot.settings,
        mode: InsertMode.insertOrReplace,
      );
  });

  /// Replaces the roster. Wrong-PIN counters live in another table, so a
  /// refresh never lifts a lockout.
  Future<void> replaceRoster(List<StaffMember> roster) =>
      _db.transaction(() async {
        final now = clock.now();
        await _db.delete(_db.localStaff).go();
        await _db.batch((b) {
          b.insertAll(_db.localStaff, [
            for (final s in roster)
              LocalStaffCompanion.insert(
                employeeId: s.employeeId,
                fullName: s.fullName,
                roleCode: s.roleCode,
                permissions: jsonEncode(s.permissions.toList()..sort()),
                pinHash: Value(s.pinHash),
                isActive: s.isActive,
                syncedAt: now,
              ),
          ]);
        });
      });

  Stream<List<StaffMember>> watchStaff() =>
      (_db.select(_db.localStaff)
            ..where((s) => s.isActive.equals(true))
            ..orderBy([(s) => OrderingTerm.asc(s.fullName)]))
          .watch()
          .map((rows) => rows.map(StaffMember.fromRow).toList());

  Future<void> unpair() => _db.clearTerminalData();
}
