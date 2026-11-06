import 'dart:typed_data';

import 'package:cashiera/core/printing/printer_setting.dart';
import 'package:cashiera/core/printing/transport_stub.dart'
    if (dart.library.io) 'package:cashiera/core/printing/transport_io.dart'
    as platform;

/// Why printing did not happen.
class PrinterException implements Exception {
  const new(this.code, [this.detail]);

  /// `not_configured`, `unsupported`, `invalid_address`, `connect_failed`,
  /// `send_failed`, `no_drawer`.
  final String code;
  final String? detail;

  @override
  String toString() => detail == null ? code : '$code: $detail';
}

/// A printer found by a scan.
class DiscoveredPrinter {
  const new({
    required this.name,
    required this.connection,
    required this.address,
  });

  final String name;
  final PrinterConnection connection;
  final String address;
}

/// Sends raw ESC/POS bytes to a printer.
abstract interface class PrinterTransport {
  /// Whether this platform can scan for Bluetooth and USB printers.
  bool get canDiscover;

  Future<void> send(PrinterSetting printer, Uint8List bytes);

  /// Bluetooth (BLE) and USB printers seen within [timeout].
  Future<List<DiscoveredPrinter>> discover({
    Duration timeout = const Duration(seconds: 6),
  });
}

/// The transport for this platform: plugin + raw TCP on devices, a stub on
/// the web (the back office prints PDFs instead).
PrinterTransport createPrinterTransport() => platform.createTransport();
