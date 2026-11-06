import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cashiera/core/printing/printer_setting.dart';
import 'package:cashiera/core/printing/printer_transport.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';

PrinterTransport createTransport() => DevicePrinterTransport();

/// Network printers get raw TCP (port 9100). Bluetooth LE and USB go through
/// `flutter_thermal_printer` (USB on Android, Windows and macOS; on Windows
/// a USB printer is addressed by its printer name).
class DevicePrinterTransport implements PrinterTransport {
  new({this.connectTimeout = const Duration(seconds: 5)});

  final Duration connectTimeout;

  bool get _pluginPlatform =>
      Platform.isAndroid ||
      Platform.isIOS ||
      Platform.isWindows ||
      Platform.isMacOS;

  @override
  bool get canDiscover => _pluginPlatform;

  @override
  Future<void> send(PrinterSetting printer, Uint8List bytes) async {
    switch (printer.connection) {
      case PrinterConnection.network:
        await _sendTcp(printer.address, bytes);
      case PrinterConnection.ble || PrinterConnection.usb:
        if (!_pluginPlatform) throw const PrinterException('unsupported');
        await _sendPlugin(printer, bytes);
    }
  }

  Future<void> _sendTcp(String address, Uint8List bytes) async {
    final target = PrinterSetting.parseNetworkAddress(address);
    if (target == null) throw PrinterException('invalid_address', address);
    final (host, port) = target;
    Socket socket;
    try {
      socket = await Socket.connect(host, port, timeout: connectTimeout);
    } on SocketException catch (e) {
      throw PrinterException('connect_failed', e.message);
    }
    try {
      socket.add(bytes);
      await socket.flush().timeout(connectTimeout);
    } on Object catch (e) {
      throw PrinterException('send_failed', '$e');
    } finally {
      await socket.close().timeout(connectTimeout, onTimeout: () => socket);
      socket.destroy();
    }
  }

  Printer _plugin(PrinterSetting p) => Printer(
    address: p.address,
    name: p.name,
    connectionType: p.connection == PrinterConnection.ble
        ? ConnectionType.BLE
        : ConnectionType.USB,
  );

  Future<void> _sendPlugin(PrinterSetting printer, Uint8List bytes) async {
    final device = _plugin(printer);
    final plugin = FlutterThermalPrinter.instance;
    bool connected;
    try {
      connected = await plugin.connect(device).timeout(connectTimeout * 3);
    } on Object catch (e) {
      throw PrinterException('connect_failed', '$e');
    }
    if (!connected) throw const PrinterException('connect_failed');
    try {
      await plugin.printData(device, bytes, longData: true);
    } on Object catch (e) {
      throw PrinterException('send_failed', '$e');
    }
  }

  @override
  Future<List<DiscoveredPrinter>> discover({
    Duration timeout = const Duration(seconds: 6),
  }) async {
    if (!_pluginPlatform) return const [];
    final plugin = FlutterThermalPrinter.instance;
    final found = <String, DiscoveredPrinter>{};
    final sub = plugin.devicesStream.listen((printers) {
      for (final p in printers) {
        final address =
            Platform.isWindows && p.connectionType == ConnectionType.USB
            ? p.name
            : p.address;
        if (address == null || address.isEmpty) continue;
        final connection = switch (p.connectionType) {
          ConnectionType.BLE => PrinterConnection.ble,
          ConnectionType.USB => PrinterConnection.usb,
          _ => null,
        };
        if (connection == null) continue;
        found['${connection.code}:$address'] = DiscoveredPrinter(
          name: (p.name?.isNotEmpty ?? false) ? p.name! : address,
          connection: connection,
          address: address,
        );
      }
    });
    try {
      await plugin.getPrinters(
        connectionTypes: const [ConnectionType.USB, ConnectionType.BLE],
      );
      await Future<void>.delayed(timeout);
    } on Object catch (e) {
      throw PrinterException('unsupported', '$e');
    } finally {
      await sub.cancel();
      await plugin.stopScan();
    }
    return found.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  }
}
