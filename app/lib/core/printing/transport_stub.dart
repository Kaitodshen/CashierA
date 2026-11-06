import 'dart:typed_data';

import 'package:cashiera/core/printing/printer_setting.dart';
import 'package:cashiera/core/printing/printer_transport.dart';

/// Browsers cannot reach ESC/POS printers.
PrinterTransport createTransport() => const _UnsupportedTransport();

class _UnsupportedTransport implements PrinterTransport {
  const new();

  @override
  bool get canDiscover => false;

  @override
  Future<void> send(PrinterSetting printer, Uint8List bytes) async =>
      throw const PrinterException('unsupported');

  @override
  Future<List<DiscoveredPrinter>> discover({
    Duration timeout = const Duration(seconds: 6),
  }) async => const [];
}
