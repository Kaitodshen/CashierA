import 'package:cashiera/core/printing/printer_setting.dart';
import 'package:cashiera/core/printing/printer_transport.dart';
import 'package:cashiera_core/cashiera_core.dart';

/// Prints slips on the terminal's receipt printer and opens the drawer.
/// Nothing here blocks a sale: callers show the error and offer the PDF.
class PrinterService {
  new(this._repository, this._transport);

  final PrinterRepository _repository;
  final PrinterTransport _transport;

  PrinterTransport get transport => _transport;

  Future<PrinterSetting> _printer(PrinterSetting? using) async {
    final printer = using ?? await _repository.current();
    if (printer == null) throw const PrinterException('not_configured');
    return printer;
  }

  /// Sends [doc] laid out for the printer's paper. Throws
  /// [PrinterException] when it could not be sent.
  Future<void> print(ReceiptDocument doc, {PrinterSetting? using}) async {
    final printer = await _printer(using);
    await _transport.send(
      printer,
      EscPosEncoder.forPaper(printer.paperMm).encode(
        printer.opensCashDrawer
            ? doc
            : ReceiptDocument([
                for (final b in doc.blocks)
                  if (b is! PrintDrawer) b,
              ]),
      ),
    );
  }

  /// Pulses the drawer without printing.
  Future<void> kickDrawer({PrinterSetting? using}) async {
    final printer = await _printer(using);
    if (!printer.opensCashDrawer) throw const PrinterException('no_drawer');
    await _transport.send(printer, EscPosEncoder.drawerKick());
  }
}
