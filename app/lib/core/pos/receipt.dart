import 'dart:convert';
import 'dart:typed_data';

import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/pos/pos_config.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Words printed on a receipt, in the till's language.
class ReceiptLabels {
  const new({
    required this.cashier,
    required this.customer,
    required this.subtotal,
    required this.service,
    required this.taxIncluded,
    required this.taxAdded,
    required this.taxBase,
    required this.rounding,
    required this.total,
    required this.change,
    required this.tendered,
    required this.kasbonDue,
    required this.cancelled,
    required this.held,
    required this.voided,
    required this.copy,
    required this.items,
  });

  final String cashier;
  final String customer;
  final String subtotal;
  final String service;

  /// e.g. `Termasuk PPN 11%`.
  final String Function(String taxName, String rate) taxIncluded;
  final String Function(String taxName, String rate) taxAdded;

  /// DPP.
  final String taxBase;
  final String rounding;
  final String total;
  final String change;
  final String tendered;
  final String Function(String date) kasbonDue;
  final String cancelled;
  final String held;
  final String voided;

  /// Printed on reprints.
  final String copy;
  final String Function(int count) items;
}

/// The banner for a receipt that is not a finished sale.
String receiptStatusLabel(String status, ReceiptLabels l) => switch (status) {
  'cancelled' => l.cancelled,
  'voided' => l.voided,
  _ => l.held,
};

class ReceiptLine {
  const new({
    required this.name,
    required this.quantityText,
    required this.amount,
    this.details = const [],
    this.discounts = const [],
  });

  final String name;

  /// `3 x Rp 3.500` or `1.25 kg x Rp 42.000`.
  final String quantityText;
  final Money amount;

  /// Modifiers and the line note.
  final List<String> details;
  final List<(String, Money)> discounts;
}

class ReceiptPayment {
  const new({
    required this.name,
    required this.amount,
    this.tendered,
    this.change,
  });

  final String name;
  final Money amount;
  final Money? tendered;
  final Money? change;
}

/// Everything a receipt shows, read back from the stored `order.upsert`
/// payload, so a reprint shows exactly what was booked.
class ReceiptData {
  const new({
    required this.headerLines,
    required this.orderNumber,
    required this.dateText,
    required this.cashierName,
    required this.lines,
    required this.billDiscounts,
    required this.gross,
    required this.serviceCharge,
    required this.tax,
    required this.taxBase,
    required this.taxInclusive,
    required this.taxName,
    required this.taxRateText,
    required this.rounding,
    required this.grandTotal,
    required this.payments,
    required this.footer,
    required this.status,
    required this.itemCount,
    required this.paperMm,
    this.customerName,
    this.kasbonDueDate,
  });

  factory fromOrder(LocalOrderRow order, PosConfig config) {
    final p = (jsonDecode(order.payloadJson) as Map).cast<String, dynamic>();
    int money(Object? v) => (v as num? ?? 0).toInt();
    final discounts = [
      for (final d in (p['discounts'] as List? ?? const []))
        (d as Map).cast<String, dynamic>(),
    ];
    final methodNames = {for (final o in config.paymentOptions) o.id: o.name};
    final rate = money(p['tax_rate_bps']);

    final lines = <ReceiptLine>[];
    for (final raw in p['items'] as List) {
      final item = (raw as Map).cast<String, dynamic>();
      final qty = Qty.parse(item['quantity'] as String);
      final unit =
          money(item['unit_price']) + money(item['modifiers_unit_total']);
      final variant = item['variant_name'] as String?;
      lines.add(
        ReceiptLine(
          name: variant == null || variant == 'Default'
              ? item['product_name'] as String
              : '${item['product_name']} ${item['variant_name']}',
          quantityText: '${qty.toPlain()} x ${Money(unit).format()}',
          amount: Money(money(item['gross_amount'])),
          details: [
            for (final m in (item['modifiers'] as List? ?? const []))
              '+ ${(m as Map)['modifier_name']}',
            if ((item['note'] as String?)?.isNotEmpty ?? false)
              '"${item['note']}"',
          ],
          discounts: [
            for (final d in discounts)
              if (d['order_item_id'] == item['id'])
                (d['description'] as String, Money(money(d['amount']))),
          ],
        ),
      );
    }

    final local = config.localTime(DateTime.parse(p['ordered_at'] as String));
    // A void changes the order row, not the last snapshot sent.
    final status = order.status;
    return ReceiptData(
      headerLines: [
        if (config.receiptHeader?.trim().isNotEmpty ?? false)
          config.receiptHeader!.trim()
        else
          config.business.name,
        if (config.receiptHeader?.trim() != config.storeName) config.storeName,
        ?config.storeAddress,
        ?config.storePhone,
        if (config.business.npwp != null) 'NPWP ${config.business.npwp}',
      ],
      orderNumber: p['order_number'] as String,
      dateText: DateFormat('dd/MM/yyyy HH:mm').format(local),
      cashierName: order.cashierName,
      customerName: order.customerName,
      lines: lines,
      billDiscounts: [
        for (final d in discounts)
          if (d['order_item_id'] == null)
            (d['description'] as String, Money(money(d['amount']))),
      ],
      gross: Money(money(p['gross_total'])),
      serviceCharge: Money(money(p['service_charge_total'])),
      tax: Money(money(p['tax_total'])),
      taxBase: Money(
        (p['items'] as List)
                .map((i) => (i as Map).cast<String, dynamic>())
                .where((i) => i['is_taxable'] == true)
                .fold(0, (a, i) => a + money(i['net_amount'])) +
            (p['service_charge_taxable'] == true
                ? money(p['service_charge_total'])
                : 0),
      ),
      taxInclusive: p['tax_inclusive'] as bool? ?? true,
      taxName: config.taxName,
      taxRateText: _rateText(rate),
      rounding: Money(money(p['rounding_amount'])),
      grandTotal: Money(money(p['grand_total'])),
      payments: [
        for (final raw in (p['payments'] as List? ?? const []))
          () {
            final pay = (raw as Map).cast<String, dynamic>();
            final cash = pay['method_type'] == 'cash';
            return ReceiptPayment(
              name:
                  methodNames[pay['payment_method_id']] ??
                  (pay['method_type'] as String).toUpperCase(),
              amount: Money(money(pay['amount'])),
              tendered: cash ? Money(money(pay['tendered_amount'])) : null,
              change: cash ? Money(money(pay['change_amount'])) : null,
            );
          }(),
      ],
      footer: config.receiptFooter,
      status: status,
      itemCount: order.itemCount,
      paperMm: config.paperMm,
      kasbonDueDate: p['kasbon_due_date'] as String?,
    );
  }

  final List<String> headerLines;
  final String orderNumber;
  final String dateText;
  final String cashierName;
  final String? customerName;
  final List<ReceiptLine> lines;
  final List<(String, Money)> billDiscounts;
  final Money gross;
  final Money serviceCharge;
  final Money tax;

  /// Taxable amount the tax was computed on (DPP + tax when included).
  final Money taxBase;
  final bool taxInclusive;
  final String taxName;
  final String taxRateText;
  final Money rounding;
  final Money grandTotal;
  final List<ReceiptPayment> payments;
  final String footer;

  /// `held`, `completed`, `cancelled` or `voided`.
  final String status;
  final int itemCount;
  final int paperMm;
  final String? kasbonDueDate;

  Money get changeTotal =>
      payments.fold(Money.zero, (a, p) => a + (p.change ?? Money.zero));
}

String _rateText(int bps) {
  final whole = bps ~/ 100;
  final fraction = bps % 100;
  if (fraction == 0) return '$whole%';
  final decimals = fraction.toString().padLeft(2, '0');
  return '$whole,${decimals.endsWith('0') ? decimals[0] : decimals}%';
}

/// Rows of a receipt as label/value pairs, shared by the screen and the PDF.
List<(String, String, {bool strong})> receiptTotals(
  ReceiptData r,
  ReceiptLabels l,
) => [
  (l.subtotal, r.gross.format(), strong: false),
  for (final (name, amount) in r.billDiscounts)
    (name, '-${amount.format()}', strong: false),
  if (r.serviceCharge.rupiah > 0)
    (l.service, r.serviceCharge.format(), strong: false),
  if (r.tax.rupiah > 0 && !r.taxInclusive)
    (l.taxAdded(r.taxName, r.taxRateText), r.tax.format(), strong: false),
  if (r.rounding.rupiah != 0) (l.rounding, r.rounding.format(), strong: false),
  (l.total, r.grandTotal.format(), strong: true),
  for (final p in r.payments) ...[
    (p.name, (p.tendered ?? p.amount).format(), strong: false),
  ],
  if (r.changeTotal.rupiah > 0)
    (l.change, r.changeTotal.format(), strong: true),
  if (r.tax.rupiah > 0 && r.taxInclusive) ...[
    (l.taxIncluded(r.taxName, r.taxRateText), r.tax.format(), strong: false),
    (l.taxBase, (r.taxBase - r.tax).format(), strong: false),
  ],
];

/// Standard PDF fonts only cover Latin-1; anything else prints as `?`.
String pdfSafe(String s) =>
    String.fromCharCodes(s.runes.map((c) => c <= 0xFF ? c : 0x3F));

/// A receipt on roll paper (58 or 80 mm), in a monospace font like a
/// thermal printer.
Future<Uint8List> buildReceiptPdf(ReceiptData r, ReceiptLabels l) {
  final format = r.paperMm >= 80 ? PdfPageFormat.roll80 : PdfPageFormat.roll57;
  final base = pw.Font.courier();
  final bold = pw.Font.courierBold();
  final small = pw.TextStyle(font: base, fontSize: 7.5);
  final strong = pw.TextStyle(font: bold, fontSize: 8.5);

  pw.Widget row(String left, String right, {bool isStrong = false}) => pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Expanded(
        child: pw.Text(pdfSafe(left), style: isStrong ? strong : small),
      ),
      pw.SizedBox(width: 4),
      pw.Text(pdfSafe(right), style: isStrong ? strong : small),
    ],
  );
  pw.Widget rule() => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Divider(height: 1, borderStyle: pw.BorderStyle.dashed),
  );

  final doc = pw.Document(title: r.orderNumber, author: r.headerLines.first)
    ..addPage(
      pw.Page(
        pageFormat: format.copyWith(
          marginLeft: 3 * PdfPageFormat.mm,
          marginRight: 3 * PdfPageFormat.mm,
          marginTop: 4 * PdfPageFormat.mm,
          marginBottom: 6 * PdfPageFormat.mm,
        ),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            for (final (i, line) in r.headerLines.indexed)
              pw.Text(
                pdfSafe(line),
                textAlign: pw.TextAlign.center,
                style: i == 0 ? strong : small,
              ),
            if (r.status != 'completed') ...[
              pw.SizedBox(height: 4),
              pw.Text(
                pdfSafe(receiptStatusLabel(r.status, l)),
                textAlign: pw.TextAlign.center,
                style: strong,
              ),
            ],
            rule(),
            row(r.orderNumber, r.dateText),
            row(l.cashier, r.cashierName),
            if (r.customerName != null) row(l.customer, r.customerName!),
            rule(),
            for (final line in r.lines) ...[
              pw.Text(pdfSafe(line.name), style: small),
              for (final d in line.details)
                pw.Text(pdfSafe('  $d'), style: small),
              row('  ${line.quantityText}', line.amount.format()),
              for (final (name, amount) in line.discounts)
                row('  $name', '-${amount.format()}'),
            ],
            rule(),
            pw.Text(pdfSafe(l.items(r.itemCount)), style: small),
            for (final (label, value, strong: isStrong) in receiptTotals(r, l))
              row(label, value, isStrong: isStrong),
            if (r.kasbonDueDate != null)
              pw.Text(pdfSafe(l.kasbonDue(r.kasbonDueDate!)), style: small),
            rule(),
            pw.Text(
              pdfSafe(r.footer),
              textAlign: pw.TextAlign.center,
              style: small,
            ),
          ],
        ),
      ),
    );
  return doc.save();
}
