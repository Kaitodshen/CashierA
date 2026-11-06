import 'dart:convert';

import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/pos/pos_services.dart';
import 'package:cashiera/core/pos/receipt.dart';
import 'package:cashiera/core/printing/printer_service.dart';
import 'package:cashiera/core/printing/slips.dart';

/// Prints sale receipts on the thermal printer. The first print marks the
/// order printed (so later voids need approval) only after the bytes were
/// sent; every later print is a copy and goes to the audit log.
class ReceiptPrinting {
  new({required this._printers, required this._orders, required this._audit});

  final PrinterService _printers;
  final OrderService _orders;
  final AuditService _audit;

  /// Whether [order] was paid partly in cash (the drawer should open).
  static bool tookCash(LocalOrderRow order) {
    final payload = jsonDecode(order.payloadJson) as Map;
    return (payload['payments'] as List? ?? const []).any(
      (p) => (p as Map)['method_type'] == 'cash',
    );
  }

  /// The customer got [order]'s receipt as a PDF (shared, e-mailed,
  /// WhatsApp): the first time it counts as printed, so a later void needs
  /// approval; after that it is a copy and is audited.
  Future<void> shared({
    required LocalOrderRow order,
    required StaffMember staff,
    required String storeId,
  }) async {
    if (order.status != 'completed') return;
    if (order.printedAt == null) {
      await _orders.markPrinted(order.id);
      return;
    }
    await _audit.log(
      storeId: storeId,
      action: AuditService.receiptReprinted,
      actor: staff,
      entityType: 'order',
      entityId: order.id,
      details: {'order_number': order.orderNumber, 'channel': 'pdf'},
    );
  }

  /// Throws a `PrinterException` when nothing was printed; the order is then
  /// left as it was.
  Future<void> printOrder({
    required LocalOrderRow order,
    required ReceiptData receipt,
    required ReceiptLabels labels,
    required StaffMember staff,
    required String storeId,
    bool openDrawer = false,
  }) async {
    final copy = order.printedAt != null;
    await _printers.print(
      receiptDocument(receipt, labels, openDrawer: openDrawer, copy: copy),
    );
    if (!copy) {
      await _orders.markPrinted(order.id);
    } else {
      await _audit.log(
        storeId: storeId,
        action: AuditService.receiptReprinted,
        actor: staff,
        entityType: 'order',
        entityId: order.id,
        details: {'order_number': order.orderNumber},
      );
    }
  }
}
