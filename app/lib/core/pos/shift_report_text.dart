import 'package:cashiera_core/cashiera_core.dart';
import 'package:intl/intl.dart';

/// Words of the X/Z report, in the till's language.
class ShiftReportLabels {
  const new({
    required this.titleX,
    required this.titleZ,
    required this.terminal,
    required this.opened,
    required this.closed,
    required this.sales,
    required this.transactions,
    required this.gross,
    required this.discounts,
    required this.net,
    required this.service,
    required this.tax,
    required this.rounding,
    required this.total,
    required this.average,
    required this.payments,
    required this.corrections,
    required this.voids,
    required this.cancelled,
    required this.refunds,
    required this.kasbonIssued,
    required this.kasbonRepaid,
    required this.cash,
    required this.openingCash,
    required this.cashSales,
    required this.voidedCash,
    required this.cashRefunds,
    required this.kasbonCash,
    required this.cashIn,
    required this.cashOut,
    required this.expected,
    required this.counted,
    required this.difference,
    required this.topItems,
  });

  final String titleX;
  final String titleZ;
  final String terminal;
  final String opened;
  final String closed;
  final String sales;
  final String transactions;
  final String gross;
  final String discounts;
  final String net;
  final String service;
  final String tax;
  final String rounding;
  final String total;
  final String average;
  final String payments;
  final String corrections;
  final String voids;
  final String cancelled;
  final String refunds;
  final String kasbonIssued;
  final String kasbonRepaid;
  final String cash;
  final String openingCash;
  final String cashSales;
  final String voidedCash;
  final String cashRefunds;
  final String kasbonCash;
  final String cashIn;
  final String cashOut;
  final String expected;
  final String counted;
  final String difference;
  final String topItems;
}

class ReportRow {
  const new(this.label, this.value, {this.strong = false});
  final String label;
  final String value;
  final bool strong;
}

class ReportSection {
  const new(this.title, this.rows);

  /// Null for the header block.
  final String? title;
  final List<ReportRow> rows;
}

/// Selisih with its sign: `+Rp 500`, `-Rp 2.000`, `Rp 0`.
String signedMoney(Money m) => m.rupiah > 0 ? '+${m.format()}' : m.format();

/// The report as titled rows, shared by the screen, the thermal slip and the
/// PDF. [utcOffsetMinutes] is the store's time zone.
List<ReportSection> shiftReportSections(
  ShiftReport r,
  ShiftReportLabels l, {
  required int utcOffsetMinutes,
}) {
  final format = DateFormat('dd/MM/yyyy HH:mm');
  String local(String iso) => format.format(
    DateTime.parse(iso).toUtc().add(Duration(minutes: utcOffsetMinutes)),
  );
  String minus(Money m) => m.rupiah == 0 ? m.format() : '-${m.format()}';
  final c = r.cash;
  final diff = c.difference;

  return [
    ReportSection(null, [
      if (r.deviceCode != null) ReportRow(l.terminal, r.deviceCode!),
      ReportRow(l.opened, [local(r.openedAt), ?r.openedByName].join(' · ')),
      if (r.closedAt != null)
        ReportRow(l.closed, [local(r.closedAt!), ?r.closedByName].join(' · ')),
    ]),
    ReportSection(l.sales, [
      ReportRow(l.transactions, '${r.sales.orders}'),
      ReportRow(l.gross, r.sales.gross.format()),
      if (r.sales.discount.rupiah > 0)
        ReportRow(l.discounts, minus(r.sales.discount)),
      ReportRow(l.net, r.sales.net.format()),
      if (r.sales.serviceCharge.rupiah > 0)
        ReportRow(l.service, r.sales.serviceCharge.format()),
      if (r.sales.tax.rupiah > 0) ReportRow(l.tax, r.sales.tax.format()),
      if (r.sales.rounding.rupiah != 0)
        ReportRow(l.rounding, r.sales.rounding.format()),
      ReportRow(l.total, r.sales.grand.format(), strong: true),
      ReportRow(l.average, r.sales.averageBasket.format()),
    ]),
    ReportSection(l.payments, [
      for (final p in r.payments)
        ReportRow('${p.name} (${p.count})', p.amount.format()),
    ]),
    ReportSection(l.corrections, [
      ReportRow('${l.voids} (${r.voids.orders})', r.voids.total.format()),
      ReportRow(l.cancelled, '${r.cancelledOrders}'),
      ReportRow('${l.refunds} (${r.refunds.count})', r.refunds.amount.format()),
      if (r.kasbon.issued.rupiah > 0)
        ReportRow(l.kasbonIssued, r.kasbon.issued.format()),
      if (r.kasbon.repaid.rupiah > 0)
        ReportRow(l.kasbonRepaid, r.kasbon.repaid.format()),
    ]),
    ReportSection(l.cash, [
      ReportRow(l.openingCash, c.openingCash.format()),
      ReportRow(l.cashSales, c.cashSales.format()),
      if (c.voidedCash.rupiah > 0) ReportRow(l.voidedCash, minus(c.voidedCash)),
      if (c.cashRefunds.rupiah > 0)
        ReportRow(l.cashRefunds, minus(c.cashRefunds)),
      if (c.kasbonCash.rupiah > 0)
        ReportRow(l.kasbonCash, c.kasbonCash.format()),
      if (c.cashIn.rupiah > 0) ReportRow(l.cashIn, c.cashIn.format()),
      if (c.cashOut.rupiah > 0) ReportRow(l.cashOut, minus(c.cashOut)),
      ReportRow(l.expected, c.expected.format(), strong: true),
      if (c.countedCash != null) ReportRow(l.counted, c.countedCash!.format()),
      if (diff != null)
        ReportRow(l.difference, signedMoney(diff), strong: true),
    ]),
    if (r.topItems.isNotEmpty)
      ReportSection(l.topItems, [
        for (final t in r.topItems)
          ReportRow('${t.quantity.toPlain()} x ${t.name}', t.net.format()),
      ]),
  ];
}
