import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/design_system/theme.dart';
import 'package:cashiera/core/l10n/gen/app_localizations_id.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/features/back_office/data/back_office_backend.dart';
import 'package:cashiera/features/back_office/presentation/back_office_providers.dart';
import 'package:cashiera/features/reports/data/report_export.dart';
import 'package:cashiera/features/reports/data/reports_repository.dart';
import 'package:cashiera/features/reports/presentation/dashboard_panel.dart';
import 'package:cashiera/features/reports/presentation/report_providers.dart';
import 'package:cashiera/features/reports/presentation/report_tables.dart';
import 'package:cashiera/features/reports/presentation/reports_screen.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:excel_plus/excel_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toastification/toastification.dart';

Map<String, dynamic> totals({int orders = 4, int grand = 75500}) => {
  'orders': orders,
  'items': 9,
  'gross': grand,
  'discounts': 0,
  'net': grand,
  'service': 0,
  'tax': 3815,
  'rounding': 0,
  'grand': grand,
  'average': orders == 0 ? 0 : grand ~/ orders,
  'refund_count': 1,
  'refunds': 3500,
  'net_sales': grand - 3500,
  'void_count': 1,
  'voids': 7000,
};

final salesJson = <String, dynamic>{
  'totals': totals(),
  'by_day': [
    {'date': '2026-10-01', 'orders': 2, 'grand': 51000, 'refunds': 0},
    {'date': '2026-10-02', 'orders': 2, 'grand': 24500, 'refunds': 0},
    {'date': '2026-10-03', 'orders': 0, 'grand': 0, 'refunds': 0},
    {'date': '2026-10-04', 'orders': 0, 'grand': 0, 'refunds': 3500},
  ],
  'by_hour': [
    for (var h = 0; h < 24; h++) {'hour': h, 'orders': 0, 'grand': 0},
  ],
  'by_store': [
    {
      'store_code': 'PST',
      'store_name': 'Pusat',
      'orders': 3,
      'grand': 72000,
      'refunds': 3500,
    },
    {
      'store_code': 'TGR',
      'store_name': 'Tangerang',
      'orders': 1,
      'grand': 3500,
      'refunds': 0,
    },
  ],
};

class FakeReports implements ReportsRepository {
  final calls = <String>[];

  @override
  Future<SalesReport> sales(String? storeId, ReportPeriod p) async {
    calls.add('sales');
    return SalesReport.fromJson(salesJson);
  }

  @override
  Future<PaymentsReport> payments(String? storeId, ReportPeriod p) async {
    calls.add('payments');
    return PaymentsReport.fromJson(const {
      'methods': [
        {'name': 'Tunai', 'method_type': 'cash', 'count': 3, 'amount': 27500},
        {
          'name': 'Kasbon',
          'method_type': 'kasbon',
          'count': 1,
          'amount': 48000,
        },
      ],
      'refunds': [
        {'method_type': 'cash', 'count': 1, 'amount': 3500},
      ],
      'kasbon': {'issued': 48000, 'repaid': 0},
    });
  }

  @override
  Future<ProductsReport> products(String? storeId, ReportPeriod p) async =>
      ProductsReport.fromJson(const {
        'variants': [
          {
            'name': 'Mie Goreng Instan Original',
            'sku': 'MIE-GRG-ORI',
            'category': 'Mie & Instan',
            'quantity': 5,
            'refunded_quantity': 1,
            'net': 17500,
            'refunded': 3500,
            'cost': 13500,
            'margin': 4000,
          },
        ],
        'variant_count': 1,
        'categories': [
          {
            'name': 'Mie & Instan',
            'quantity': 5,
            'net': 17500,
            'cost': 13500,
            'margin': 4000,
          },
        ],
        'totals': {
          'net': 17500,
          'cost': 13500,
          'margin': 4000,
          'refunded': 3500,
        },
      });

  @override
  Future<List<StaffRow>> staff(String? storeId, ReportPeriod p) async => [
    StaffRow.fromJson(const {
      'name': 'Eko Saputra',
      'orders': 3,
      'grand': 72000,
    }),
  ];

  @override
  Future<TaxReport> tax(String? storeId, ReportPeriod p) async =>
      TaxReport.fromJson(const {
        'by_day': [
          {
            'date': '2026-10-01',
            'base': 14000,
            'dpp': 12613,
            'tax': 1387,
            'exempt': 37000,
          },
        ],
        'totals': {'base': 14000, 'dpp': 12613, 'tax': 1387, 'exempt': 37000},
      });

  @override
  Future<StockValueReport> stockValue(String? storeId) async =>
      StockValueReport.fromJson(const {
        'items': [
          {
            'store_code': 'PST',
            'name': 'Mie Goreng Instan Original',
            'sku': 'MIE-GRG-ORI',
            'quantity': 95,
            'cost': 2700,
            'value': 256500,
          },
        ],
        'totals': {'value': 256500, 'negative_count': 0, 'low_count': 2},
      });

  @override
  Future<DashboardData> dashboard(String? storeId, DateTime today) async {
    calls.add('dashboard:$storeId');
    return DashboardData.fromJson({
      'today': totals(orders: 2, grand: 27500),
      'yesterday': totals(orders: 2, grand: 54500),
      'last7': salesJson['by_day'],
      'top_products': const [
        {
          'name': 'Jus Jeruk 1 L',
          'sku': 'MNM-JUS-1L',
          'quantity': 1,
          'net': 21000,
        },
      ],
      'payments': const [
        {'name': 'Tunai', 'method_type': 'cash', 'count': 2, 'amount': 27500},
      ],
      'open_shifts': 1,
      'low_stock': 3,
      'open_alerts': 0,
      'overdue_kasbon': 7000,
    });
  }
}

Widget app(FakeReports fake, Widget child) => ProviderScope(
  overrides: [
    reportsRepositoryProvider.overrideWithValue(fake),
    backOfficeStoresProvider.overrideWith(
      (ref) async => const [
        StoreSummary(id: 's-1', code: 'PST', name: 'Pusat'),
      ],
    ),
    principalProvider.overrideWith(
      (ref) async => const Principal(
        kind: 'employee',
        roleCode: 'owner',
        permissions: {'reports.view'},
      ),
    ),
  ],
  child: ToastificationWrapper(
    child: MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('id'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  ),
);

void main() {
  final l10n = AppLocalizationsId();

  group('periods', () {
    final today = DateTime.utc(2026, 1, 15);
    test('presets', () {
      expect(
        ReportPeriod.preset(PeriodPreset.last7, today: today),
        ReportPeriod(DateTime.utc(2026, 1, 9), today),
      );
      expect(
        ReportPeriod.preset(PeriodPreset.thisMonth, today: today),
        ReportPeriod(DateTime.utc(2026), today),
      );
      // Last month across the year boundary.
      expect(
        ReportPeriod.preset(PeriodPreset.lastMonth, today: today),
        ReportPeriod(DateTime.utc(2025, 12), DateTime.utc(2025, 12, 31)),
      );
      expect(ReportPeriod.preset(PeriodPreset.yesterday, today: today).days, 1);
    });
  });

  test('percent text and the change against yesterday', () {
    expect(percentText(1, 3), '33,3%');
    expect(percentText(0, 0), '0%');
    expect(changeText(const Money(27500), const Money(55000)), '-50%');
    expect(changeText(const Money(110), const Money(100)), '+10%');
    expect(changeText(const Money(5), Money.zero), isNull);
  });

  test('the sales table reconciles: Σ rows = totals row', () {
    final table = salesByDayTable(
      l10n,
      SalesReport.fromJson(salesJson),
      'Semua toko · 01/10/2026 - 04/10/2026',
    );
    expect(table.rows, hasLength(4), reason: 'the empty day is a row too');
    final grand = table.rows.fold(
      0,
      (a, r) => a + (r[2] as MoneyCell).value.rupiah,
    );
    expect(grand, (table.totals![2] as MoneyCell).value.rupiah);
    expect((table.totals![4] as MoneyCell).value, const Money(72000));
    expect(table.fileName, 'Penjualan Semua toko · 01-10-2026 - 04-10-2026');
  });

  test('Excel keeps numbers as numbers and text as text', () {
    final table = salesByStoreTable(
      l10n,
      SalesReport.fromJson(salesJson),
      'Semua toko · 01/10/2026 - 04/10/2026',
    );
    final xlsx = Excel.decodeBytes(buildReportXlsx(table));
    final sheet = xlsx.tables.values.first;
    final rows = sheet.rows;
    expect((rows[0][0]!.value! as TextCellValue).value.text, table.title);
    expect((rows[3][0]!.value! as TextCellValue).value.text, 'Toko');
    expect((rows[4][0]!.value! as TextCellValue).value.text, 'PST · Pusat');
    expect((rows[4][2]!.value! as IntCellValue).value, 72000);
    expect((rows.last[2]!.value! as IntCellValue).value, 75500);
  });

  test('the PDF builds, wide tables included', () async {
    final products = productsTable(
      l10n,
      await FakeReports().products(
        null,
        ReportPeriod.preset(PeriodPreset.today),
      ),
      'Pusat · 01/10/2026',
    );
    expect(products.columns.length, greaterThan(6));
    final bytes = await buildReportPdf(
      products,
      printedAt: 'Dicetak 01/10/2026',
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  testWidgets('reports: sales with the empty day, then the payments tab', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1400, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final fake = FakeReports();
    await tester.pumpWidget(app(fake, const ReportsScreen()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sales-by-day-chart')), findsOneWidget);
    expect(find.text('03/10/2026'), findsOneWidget, reason: 'no gap');
    expect(find.text('Rp 72.000'), findsWidgets);
    expect(find.textContaining('PST · Pusat'), findsOneWidget);

    await tester.tap(find.text('Pembayaran').first);
    await tester.pumpAndSettle();
    expect(fake.calls, contains('payments'));
    expect(find.text('Tunai'), findsWidgets);
    expect(find.text('36,4%'), findsOneWidget);

    // A new period asks again.
    final before = fake.calls.where((c) => c == 'sales').length;
    await tester.tap(find.byKey(const Key('period-thisMonth')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Penjualan').first);
    await tester.pumpAndSettle();
    expect(fake.calls.where((c) => c == 'sales').length, greaterThan(before));
  });

  testWidgets('dashboard: today against yesterday and what needs attention', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1400, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final fake = FakeReports();
    await tester.pumpWidget(
      app(fake, const SingleChildScrollView(child: DashboardPanel())),
    );
    await tester.pumpAndSettle();
    expect(find.text('Rp 24.000'), findsOneWidget, reason: 'net sales today');
    expect(find.textContaining('Kemarin Rp 51.000 · -53%'), findsOneWidget);
    expect(find.text('1 shift terbuka'), findsOneWidget);
    expect(find.text('3 stok menipis'), findsOneWidget);
    expect(find.text('Kasbon terlambat Rp 7.000'), findsOneWidget);
    expect(find.text('Jus Jeruk 1 L'), findsOneWidget);
    expect(fake.calls, ['dashboard:null']);
  });
}
