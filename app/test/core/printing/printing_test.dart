import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/pos/shift_report_text.dart';
import 'package:cashiera/core/printing/printer_service.dart';
import 'package:cashiera/core/printing/printer_setting.dart';
import 'package:cashiera/core/printing/printer_transport.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/till_harness.dart';

const labels = ShiftReportLabels(
  titleX: 'X',
  titleZ: 'Z',
  terminal: 'Terminal',
  opened: 'Dibuka',
  closed: 'Ditutup',
  sales: 'Penjualan',
  transactions: 'Transaksi',
  gross: 'Kotor',
  discounts: 'Diskon',
  net: 'Bersih',
  service: 'Layanan',
  tax: 'Pajak',
  rounding: 'Pembulatan',
  total: 'Total',
  average: 'Rata-rata',
  payments: 'Pembayaran',
  corrections: 'Koreksi',
  voids: 'Void',
  cancelled: 'Batal',
  refunds: 'Refund',
  kasbonIssued: 'Kasbon baru',
  kasbonRepaid: 'Kasbon dibayar',
  cash: 'Kas',
  openingCash: 'Kas awal',
  cashSales: 'Tunai',
  voidedCash: 'Void tunai',
  cashRefunds: 'Refund tunai',
  kasbonCash: 'Kasbon tunai',
  cashIn: 'Masuk',
  cashOut: 'Keluar',
  expected: 'Seharusnya',
  counted: 'Dihitung',
  difference: 'Selisih',
  topItems: 'Terlaris',
);

void main() {
  test('network addresses: host, optional port, 9100 by default', () {
    expect(PrinterSetting.parseNetworkAddress('192.168.1.50'), (
      '192.168.1.50',
      9100,
    ));
    expect(PrinterSetting.parseNetworkAddress(' printer.local:9101 '), (
      'printer.local',
      9101,
    ));
    expect(PrinterSetting.parseNetworkAddress('printer kasir'), isNull);
    expect(PrinterSetting.parseNetworkAddress('10.0.0.5:70000'), isNull);
    expect(PrinterSetting.parseNetworkAddress(''), isNull);
  });

  group('PrinterService', () {
    late AppDatabase db;
    late FakePrinterTransport transport;
    late PrinterService service;
    late PrinterRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      transport = FakePrinterTransport();
      repo = PrinterRepository(db);
      service = PrinterService(repo, transport);
    });
    tearDown(() => db.close());

    const doc = ReceiptDocument([PrintDrawer(), PrintText('Halo')]);

    test('without a printer nothing is sent', () async {
      await expectLater(
        service.print(doc),
        throwsA(
          isA<PrinterException>().having(
            (e) => e.code,
            'code',
            'not_configured',
          ),
        ),
      );
      expect(transport.sent, isEmpty);
    });

    test(
      'the drawer pulse is dropped when the printer has no drawer',
      () async {
        await repo.save(
          const PrinterSetting(
            name: 'P',
            connection: PrinterConnection.network,
            address: '10.0.0.5',
          ),
        );
        await service.print(doc);
        expect(transport.sent.single.contains(0x70), isFalse);
        await expectLater(
          service.kickDrawer(),
          throwsA(
            isA<PrinterException>().having((e) => e.code, 'code', 'no_drawer'),
          ),
        );
      },
    );

    test('80 mm paper prints 48 columns', () async {
      await repo.save(
        const PrinterSetting(
          name: 'P',
          connection: PrinterConnection.network,
          address: '10.0.0.5',
          paperMm: 80,
          opensCashDrawer: true,
        ),
      );
      await service.print(const ReceiptDocument([PrintRule()]));
      expect(transport.text, contains('-' * 48));
      await service.kickDrawer();
      expect(transport.sent.last, EscPosEncoder.drawerKick());
    });
  });

  test('report sections: minus signs, signed difference, hidden zeros', () {
    final report = ShiftReport.build(
      shift: const ShiftInfo(
        id: 's',
        openingCash: Money(100000),
        openedAt: '2026-11-06T01:00:00Z',
        closedAt: '2026-11-06T10:00:00Z',
        deviceCode: 'T1',
        openedByName: 'Eko',
        closedByName: 'Eko',
        countedCash: Money(100500),
      ),
      orders: const [],
      refunds: const [],
      movements: const [
        ShiftCashMovement(shiftId: 's', isIn: false, amount: Money(1000)),
        ShiftCashMovement(shiftId: 's', isIn: true, amount: Money(1000)),
      ],
      methods: const {},
    );
    final sections = shiftReportSections(report, labels, utcOffsetMinutes: 420);
    final header = sections.first.rows;
    expect(header.map((r) => (r.label, r.value)), [
      ('Terminal', 'T1'),
      ('Dibuka', '06/11/2026 08:00 · Eko'),
      ('Ditutup', '06/11/2026 17:00 · Eko'),
    ]);
    final cash = sections.firstWhere((s) => s.title == 'Kas').rows;
    expect(
      {for (final r in cash) r.label: r.value},
      {
        'Kas awal': 'Rp 100.000',
        'Tunai': 'Rp 0',
        'Masuk': 'Rp 1.000',
        'Keluar': '-Rp 1.000',
        'Seharusnya': 'Rp 100.000',
        'Dihitung': 'Rp 100.500',
        'Selisih': '+Rp 500',
      },
    );
    expect(sections.any((s) => s.title == 'Terlaris'), isFalse);
    final sales = sections.firstWhere((s) => s.title == 'Penjualan').rows;
    expect(sales.map((r) => r.label), contains('Total'));
    expect(sales.map((r) => r.label), isNot(contains('Diskon')));
    expect(signedMoney(const Money(-2000)), '-Rp 2.000');
    expect(signedMoney(Money.zero), 'Rp 0');
  });
}
