import 'package:cashiera/core/database/app_database.dart';

/// How the terminal reaches its printer. Codes match `public.printers`.
enum PrinterConnection {
  ble('ble'),
  usb('usb'),
  network('network');

  new(this.code);
  final String code;

  static PrinterConnection fromCode(String code) => values.firstWhere(
    (c) => c.code == code,
    orElse: () => throw ArgumentError.value(code, 'code'),
  );
}

/// The terminal's receipt printer.
class PrinterSetting {
  const new({
    required this.name,
    required this.connection,
    required this.address,
    this.paperMm = 58,
    this.opensCashDrawer = false,
    this.autoPrint = false,
  });

  factory fromRow(PrinterRow row) => PrinterSetting(
    name: row.name,
    connection: PrinterConnection.fromCode(row.connection),
    address: row.address,
    paperMm: row.paperMm,
    opensCashDrawer: row.opensCashDrawer,
    autoPrint: row.autoPrint,
  );

  final String name;
  final PrinterConnection connection;

  /// BLE device id, USB id or Windows printer name, or `host[:port]`.
  final String address;
  final int paperMm;
  final bool opensCashDrawer;
  final bool autoPrint;

  /// `192.168.1.50` or `192.168.1.50:9100` → host and port (9100 when
  /// missing). Null when [address] is not a usable network address.
  static (String, int)? parseNetworkAddress(String address) {
    final text = address.trim();
    final match = RegExp(
      r'^([A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?)(?::(\d{1,5}))?$',
    ).firstMatch(text);
    if (match == null) return null;
    final port = match.group(3) == null ? 9100 : int.parse(match.group(3)!);
    if (port < 1 || port > 65535) return null;
    return (match.group(1)!, port);
  }

  PrinterSetting copyWith({
    String? name,
    PrinterConnection? connection,
    String? address,
    int? paperMm,
    bool? opensCashDrawer,
    bool? autoPrint,
  }) => PrinterSetting(
    name: name ?? this.name,
    connection: connection ?? this.connection,
    address: address ?? this.address,
    paperMm: paperMm ?? this.paperMm,
    opensCashDrawer: opensCashDrawer ?? this.opensCashDrawer,
    autoPrint: autoPrint ?? this.autoPrint,
  );
}

/// Stores the terminal's printers in `local_printers`, one row per slot:
/// `receipt`, and for F&B stores `kitchen` and `bar`.
class PrinterRepository {
  new(this._db);

  static const receiptId = 'receipt';
  static const kitchenId = 'kitchen';
  static const barId = 'bar';
  static const List<String> slots = [receiptId, kitchenId, barId];

  final AppDatabase _db;

  Stream<PrinterSetting?> watch({String slot = receiptId}) =>
      (_db.select(_db.localPrinters)..where((p) => p.id.equals(slot)))
          .watchSingleOrNull()
          .map((row) => row == null ? null : PrinterSetting.fromRow(row));

  Future<PrinterSetting?> current({String slot = receiptId}) async {
    final row = await (_db.select(
      _db.localPrinters,
    )..where((p) => p.id.equals(slot))).getSingleOrNull();
    return row == null ? null : PrinterSetting.fromRow(row);
  }

  Future<void> save(PrinterSetting setting, {String slot = receiptId}) => _db
      .into(_db.localPrinters)
      .insertOnConflictUpdate(
        PrinterRow(
          id: slot,
          name: setting.name.trim(),
          connection: setting.connection.code,
          address: setting.address.trim(),
          paperMm: setting.paperMm,
          opensCashDrawer: setting.opensCashDrawer,
          autoPrint: setting.autoPrint,
        ),
      );

  Future<void> remove({String slot = receiptId}) =>
      (_db.delete(_db.localPrinters)..where((p) => p.id.equals(slot))).go();
}
