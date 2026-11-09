import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/design_system/theme.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/features/back_office/data/back_office_backend.dart';
import 'package:cashiera/features/back_office/data/customers_admin_repository.dart';
import 'package:cashiera/features/back_office/presentation/admin_customers_screen.dart';
import 'package:cashiera/features/back_office/presentation/admin_kasbon_screen.dart';
import 'package:cashiera/features/back_office/presentation/back_office_providers.dart';
import 'package:cashiera/features/back_office/presentation/loyalty_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toastification/toastification.dart';

class FakeCustomersAdmin implements CustomersAdminRepository {
  int balance = 120;
  final adjustments = <(int, String)>[];
  LoyaltySettings? saved;

  @override
  Future<int> adjustPoints(String customerId, int points, String note) async {
    adjustments.add((points, note));
    return balance += points;
  }

  @override
  Future<List<AdminCustomer>> customers(String query) async => [
    AdminCustomer(id: 'c-1', code: 'C000001', name: 'Sari Wulandari'),
  ];

  @override
  Future<List<KasbonOverviewRow>> kasbonOverview({String? storeId}) async => [
    KasbonOverviewRow.fromJson({
      'store_name': 'Pusat',
      'customer_id': 'c-4',
      'customer_name': 'Toko Berkah Jaya',
      'customer_phone': '081200000004',
      'kasbon_limit': 20000,
      'open_count': 2,
      'outstanding': 27000,
      'overdue': 7000,
      'oldest_due': '2026-11-01',
    }),
    KasbonOverviewRow.fromJson({
      'store_name': 'Pusat',
      'customer_id': 'c-2',
      'customer_name': 'Rudi Hartono',
      'open_count': 1,
      'outstanding': 10000,
      'overdue': 0,
      'oldest_due': '2026-12-01',
    }),
  ];

  @override
  Future<LoyaltySettings> loyaltySettings() async => LoyaltySettings(
    enabled: true,
    earnAmount: 10000,
    pointValue: 100,
    minRedeemPoints: 0,
    kasbonDueDays: 30,
  );

  @override
  String newId() => 'c-new';

  @override
  Future<void> save(AdminCustomer c, {required bool isNew}) async {}

  @override
  Future<void> saveLoyaltySettings(LoyaltySettings s) async => saved = s;

  @override
  Future<CustomerStatement> statement(String customerId) async =>
      CustomerStatement.fromJson({
        'customer': {
          'id': customerId,
          'code': 'C000001',
          'name': 'Sari Wulandari',
          'points_balance': balance,
          'is_active': true,
        },
        'kasbon': [
          {
            'store_name': 'Pusat',
            'order_number': 'PST-T1-261107-0010',
            'amount': 35000,
            'paid_amount': 15000,
            'due_date': '2026-12-07',
            'status': 'partial',
            'payments': [
              {
                'amount': 15000,
                'method_type': 'cash',
                'paid_at': '2026-11-07T03:00:00Z',
                'employee_name': 'Eko Saputra',
              },
            ],
          },
        ],
        'ledger': [
          {
            'entry_type': 'earn',
            'points': 3,
            'created_at': '2026-11-07T02:00:00Z',
            'order_number': 'PST-T1-261107-0002',
          },
        ],
      });
}

Widget app(
  FakeCustomersAdmin fake,
  Widget home, {
  String role = 'manager',
  Set<String> permissions = const {'customer.manage', 'loyalty.adjust'},
}) => ProviderScope(
  overrides: [
    customersAdminProvider.overrideWithValue(fake),
    principalProvider.overrideWith(
      (ref) async => Principal(
        kind: 'employee',
        employeeId: 'e-1',
        roleCode: role,
        permissions: permissions,
      ),
    ),
    backOfficeStoresProvider.overrideWith(
      (ref) async => const [
        StoreSummary(id: 's-1', code: 'PST', name: 'Pusat'),
      ],
    ),
  ],
  child: ToastificationWrapper(
    child: MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('id'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: home),
    ),
  ),
);

void main() {
  setUp(() {});

  testWidgets('customer statement and a points adjustment', (tester) async {
    tester.view
      ..physicalSize = const Size(1200, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final fake = FakeCustomersAdmin();
    await tester.pumpWidget(
      app(fake, const AdminCustomerScreen(customerId: 'c-1')),
    );
    await tester.pumpAndSettle();
    expect(find.text('120 poin'), findsOneWidget);
    expect(find.text('Kasbon Rp 20.000'), findsOneWidget);
    expect(find.textContaining('PST-T1-261107-0010 · Dicicil'), findsOneWidget);
    expect(find.text('Poin didapat'), findsOneWidget);

    await tester.tap(find.byKey(const Key('admin-adjust-points')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('adjust-points')), '-20');
    await tester.enterText(find.byKey(const Key('adjust-note')), 'x');
    await tester.tap(find.byKey(const Key('adjust-save')));
    await tester.pumpAndSettle();
    expect(find.text('Tulis alasan, minimal 3 huruf.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('adjust-note')), 'Salah input');
    await tester.tap(find.byKey(const Key('adjust-save')));
    await tester.pumpAndSettle();
    expect(fake.adjustments, [(-20, 'Salah input')]);
    expect(find.text('100 poin'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('without loyalty.adjust there is no adjust button', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        FakeCustomersAdmin(),
        const AdminCustomerScreen(customerId: 'c-1'),
        permissions: const {'customer.manage'},
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('admin-adjust-points')), findsNothing);
  });

  testWidgets('kasbon overview: totals, overdue and over the limit', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(FakeCustomersAdmin(), const AdminKasbonScreen()),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('admin-kasbon-total'))).data,
      'Total Rp 37.000 · terlambat Rp 7.000',
    );
    expect(find.textContaining('Terlambat Rp 7.000'), findsOneWidget);
    expect(find.textContaining('Batas Rp 20.000'), findsOneWidget);
  });

  testWidgets('loyalty settings: the owner saves, others only read', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1000, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final fake = FakeCustomersAdmin();
    await tester.pumpWidget(
      app(fake, const LoyaltySettingsScreen(), role: 'owner'),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('loyalty-earn')), '5000');
    await tester.enterText(find.byKey(const Key('loyalty-days')), '400');
    await tester.tap(find.byKey(const Key('loyalty-save')));
    await tester.pumpAndSettle();
    expect(find.text('Isi angka 1–365.'), findsOneWidget);
    expect(fake.saved, isNull);
    await tester.enterText(find.byKey(const Key('loyalty-days')), '14');
    await tester.tap(find.byKey(const Key('loyalty-save')));
    await tester.pumpAndSettle();
    expect(fake.saved!.earnAmount, 5000);
    expect(fake.saved!.kasbonDueDays, 14);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('loyalty settings are read-only for a manager', (tester) async {
    tester.view
      ..physicalSize = const Size(1000, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      app(FakeCustomersAdmin(), const LoyaltySettingsScreen()),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Hanya pemilik yang bisa mengubah pengaturan ini.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('loyalty-save')), findsNothing);
  });
}
