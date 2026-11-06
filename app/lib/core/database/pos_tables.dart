import 'package:drift/drift.dart';

// Phase 4 (schema v3): what the cashier screen needs offline.

/// Small server tables kept as JSON rows: payment methods and which ones the
/// store accepts, promotions and their stores, vouchers, the business
/// profile. Filled by CatalogPullService; [pk] joins the primary key values
/// with `|` in the table's key order.
@DataClassName('MirrorRecordRow')
class MirrorRecords extends Table {
  TextColumn get sourceTable => text()();
  TextColumn get pk => text()();

  /// The server row as JSON.
  TextColumn get data => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {sourceTable, pk};
}

/// Customers (company-wide), searchable by name and phone. Customers added
/// on this terminal appear here at once and reach the server via the outbox.
@DataClassName('CustomerRow')
class LocalCustomers extends Table {
  TextColumn get id => text()();
  TextColumn get code => text().nullable()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  IntColumn get pointsBalance => integer().withDefault(const Constant(0))();
  IntColumn get kasbonLimit => integer().nullable()();
  BoolColumn get isActive => boolean()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Shifts opened on this terminal (at most one open).
@DataClassName('ShiftRow')
class LocalShifts extends Table {
  TextColumn get id => text()();
  TextColumn get storeId => text()();
  TextColumn get openedBy => text()();
  TextColumn get openedByName => text()();
  DateTimeColumn get openedAt => dateTime()();
  IntColumn get openingCash => integer()();

  /// `open` or `closed`.
  TextColumn get status => text()();
  DateTimeColumn get closedAt => dateTime().nullable()();

  // v4 (Phase 5): closing.
  TextColumn get closedBy => text().nullable()();
  TextColumn get closedByName => text().nullable()();
  IntColumn get countedCash => integer().nullable()();

  /// What this terminal computed when closing (sent as client_expected_cash).
  IntColumn get expectedCash => integer().nullable()();
  TextColumn get closeNote => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Every bill made on this terminal: held, completed or cancelled.
@DataClassName('LocalOrderRow')
class LocalOrders extends Table {
  TextColumn get id => text()();
  TextColumn get orderNumber => text()();

  /// `held`, `completed`, `cancelled` or `voided`.
  TextColumn get status => text()();

  /// Version of the last snapshot queued for the server.
  IntColumn get version => integer()();

  /// The cart (to resume a held bill).
  TextColumn get cartJson => text()();

  /// The last `order.upsert` payload (receipts are built from it).
  TextColumn get payloadJson => text()();
  IntColumn get grandTotal => integer()();
  IntColumn get itemCount => integer()();
  TextColumn get customerName => text().nullable()();
  TextColumn get cashierName => text()();
  TextColumn get shiftId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get printedAt => dateTime().nullable()();

  // v4 (Phase 5): voids.
  DateTimeColumn get voidedAt => dateTime().nullable()();
  TextColumn get voidReason => text().nullable()();
  TextColumn get voidedByName => text().nullable()();

  /// The shift whose drawer gave the money back.
  TextColumn get voidedShiftId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Named counters, e.g. the order sequence per business date.
@DataClassName('CounterRow')
class LocalCounters extends Table {
  TextColumn get name => text()();
  IntColumn get value => integer()();

  @override
  Set<Column<Object>> get primaryKey => {name};
}

// Phase 5 (schema v4): petty cash, refunds and the printer.

/// Kas masuk / kas keluar during a shift.
@DataClassName('CashMovementRow')
class LocalCashMovements extends Table {
  TextColumn get id => text()();
  TextColumn get shiftId => text()();

  /// `in` or `out`.
  TextColumn get movementType => text()();
  IntColumn get amount => integer()();
  TextColumn get reason => text()();
  TextColumn get employeeName => text()();
  DateTimeColumn get occurredAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Refunds of this terminal's orders.
@DataClassName('RefundRow')
class LocalRefunds extends Table {
  TextColumn get id => text()();
  TextColumn get orderId => text()();

  /// The open shift when refunding (required for cash).
  TextColumn get shiftId => text().nullable()();
  TextColumn get refundNumber => text()();
  IntColumn get amount => integer()();

  /// `cash`, `qris`, `card`, `transfer` or `ewallet`.
  TextColumn get methodType => text()();
  BoolColumn get restock => boolean()();
  TextColumn get reason => text()();

  /// The refund items as sent: `[{id, order_item_id, quantity, amount}]`.
  TextColumn get itemsJson => text()();
  TextColumn get employeeName => text()();
  TextColumn get approvedByName => text()();
  DateTimeColumn get refundedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// The terminal's receipt printer (one row, id `receipt`). Kept when the
/// terminal is unpaired: it belongs to the hardware, not to the store.
@DataClassName('PrinterRow')
class LocalPrinters extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// `bluetooth`, `ble`, `usb` or `network` (as in public.printers).
  TextColumn get connection => text()();

  /// MAC or BLE id, USB id or Windows printer name, or host:port.
  TextColumn get address => text()();
  IntColumn get paperMm => integer()();
  BoolColumn get opensCashDrawer => boolean()();

  /// Print every finished sale without asking.
  BoolColumn get autoPrint => boolean()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
