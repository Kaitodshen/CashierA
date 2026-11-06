import 'package:drift/drift.dart';

/// Status values stored exactly as the spec names them.
enum SyncStatus {
  pending('PENDING'),
  syncing('SYNCING'),
  failed('FAILED'),
  done('DONE');

  new(this.code);
  final String code;

  static SyncStatus fromCode(String code) =>
      values.firstWhere((s) => s.code == code);
}

class SyncStatusConverter extends TypeConverter<SyncStatus, String> {
  const new();

  @override
  SyncStatus fromSql(String fromDb) => SyncStatus.fromCode(fromDb);

  @override
  String toSql(SyncStatus value) => value.code;
}

/// Durable outbox. Every local write adds a row here in the same transaction;
/// the sync engine sends rows oldest-first to `sync_push`.
@DataClassName('SyncQueueEntry')
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get clientUuid => text().unique()();
  TextColumn get entity => text()();
  TextColumn get action => text()();

  /// JSON object.
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get status => text().map(const SyncStatusConverter())();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
}

/// The paired terminal (at most one row).
@DataClassName('LocalDeviceRow')
class LocalDevice extends Table {
  TextColumn get deviceId => text()();
  TextColumn get deviceCode => text()();
  TextColumn get storeId => text()();
  TextColumn get name => text()();
  DateTimeColumn get pairedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {deviceId};
}

/// Mirror of public.stores (only the terminal's own store).
@DataClassName('LocalStoreRow')
class LocalStores extends Table {
  TextColumn get id => text()();
  TextColumn get code => text()();
  TextColumn get name => text()();
  TextColumn get address => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get timezone => text()();
  BoolColumn get fnbMode => boolean()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Mirror of public.store_settings.
@DataClassName('LocalStoreSettingsRow')
class LocalStoreSettings extends Table {
  TextColumn get storeId => text()();
  BoolColumn get taxEnabled => boolean()();
  TextColumn get taxName => text()();
  IntColumn get taxRateBps => integer()();
  BoolColumn get taxInclusive => boolean()();
  BoolColumn get serviceChargeEnabled => boolean()();
  IntColumn get serviceChargeBps => integer()();
  BoolColumn get serviceChargeTaxable => boolean()();
  TextColumn get roundingMode => text()();
  IntColumn get roundingUnit => integer()();
  IntColumn get discountApprovalBps => integer()();
  BoolColumn get kasbonEnabled => boolean()();
  TextColumn get receiptHeader => text().nullable()();
  TextColumn get receiptFooter => text()();
  IntColumn get receiptPaperMm => integer()();

  @override
  Set<Column<Object>> get primaryKey => {storeId};
}

/// Staff roster from `device_staff()`, including bcrypt PIN hashes for
/// offline PIN login.
@DataClassName('LocalStaffRow')
class LocalStaff extends Table {
  TextColumn get employeeId => text()();
  TextColumn get fullName => text()();
  TextColumn get roleCode => text()();

  /// JSON array of permission codes.
  TextColumn get permissions => text()();
  TextColumn get pinHash => text().nullable()();
  BoolColumn get isActive => boolean()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {employeeId};
}

/// Wrong-PIN counters, kept apart from the roster so a refresh never clears
/// a lockout.
@DataClassName('PinAttemptRow')
class PinAttempts extends Table {
  TextColumn get employeeId => text()();
  IntColumn get failedAttempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get lockedUntil => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {employeeId};
}

/// Incremental pull cursors (`updated_at` per table), used from Phase 3.
@DataClassName('SyncCursorRow')
class SyncCursors extends Table {
  TextColumn get name => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {name};
}
