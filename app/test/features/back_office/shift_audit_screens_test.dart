import 'package:cashiera/core/design_system/theme.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/features/back_office/data/back_office_backend.dart';
import 'package:cashiera/features/back_office/data/shift_audit_repository.dart';
import 'package:cashiera/features/back_office/presentation/admin_shifts_screen.dart';
import 'package:cashiera/features/back_office/presentation/audit_screen.dart';
import 'package:cashiera/features/back_office/presentation/back_office_providers.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toastification/toastification.dart';

class FakeShiftAudit implements ShiftAuditRepository {
  final queries = <(AuditQuery, AuditEntry?)>[];
  int pages = 2;

  @override
  Future<List<AuditEntry>> audit(
    AuditQuery q, {
    AuditEntry? after,
    int limit = 50,
  }) async {
    queries.add((q, after));
    final page = queries.where((e) => e.$1.onlyApprovals == q.onlyApprovals);
    final n = page.length;
    if (n > pages) return const [];
    return [
      for (var i = 0; i < (n < pages ? limit : 1); i++)
        AuditEntry(
          id: 'a-$n-$i',
          occurredAt: DateTime.utc(2026, 11, 6, 3, i),
          action: i.isEven ? 'order.voided' : 'pos.drawer_open_no_sale',
          storeName: 'Pusat',
          deviceCode: 'T1',
          actorName: 'Eko Saputra',
          approverName: 'Budi Santoso',
          entityType: 'order',
          details: const {'reason': 'Salah input', 'grand_total': 7000},
        ),
    ];
  }

  @override
  Future<ShiftReport> shiftSummary(String shiftId) async =>
      ShiftReport.fromJson({
        'report': 'Z',
        'shift': {
          'id': shiftId,
          'store_id': 's-1',
          'store_name': 'Pusat',
          'device_code': 'T1',
          'opened_at': '2026-11-06T01:00:00Z',
          'closed_at': '2026-11-06T10:00:00Z',
          'opened_by_name': 'Eko Saputra',
          'closed_by_name': 'Eko Saputra',
          'business_date': '2026-11-06',
        },
        'sales': const {
          'orders': 1,
          'gross_total': 14000,
          'net_total': 14000,
          'grand_total': 14000,
        },
        'voids': const {'orders': 1, 'grand_total': 7000},
        'cash': const {
          'opening_cash': 50000,
          'cash_sales': 10000,
          'voided_cash': 7000,
          'cash_refunds': 3500,
          'cash_in': 25000,
          'cash_out': 5000,
          'expected_cash': 69500,
          'counted_cash': 70000,
          'cash_difference': 500,
        },
      });

  @override
  Future<List<ShiftOverviewRow>> shifts({
    required DateTime from,
    required DateTime to,
    String? storeId,
  }) async => [
    ShiftOverviewRow.fromJson({
      'shift_id': 'sh-1',
      'store_id': 's-1',
      'store_name': 'Pusat',
      'device_code': 'T1',
      'status': 'closed',
      'business_date': '2026-11-06',
      'opened_at': '2026-11-06T01:00:00Z',
      'closed_at': '2026-11-06T10:00:00Z',
      'opened_by_name': 'Eko Saputra',
      'closed_by_name': 'Eko Saputra',
      'opening_cash': 50000,
      'expected_cash': 69500,
      'counted_cash': 69000,
      'cash_difference': -500,
      'order_count': 1,
      'sales_total': 14000,
    }),
  ];
}

Widget app(FakeShiftAudit fake, Widget home) => ProviderScope(
  overrides: [
    shiftAuditProvider.overrideWithValue(fake),
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
  testWidgets('audit log: names, approvals filter and paging', (tester) async {
    tester.view
      ..physicalSize = const Size(1200, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final fake = FakeShiftAudit();
    await tester.pumpWidget(app(fake, const AuditScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Transaksi di-void'), findsWidgets);
    expect(find.text('Laci dibuka tanpa transaksi'), findsWidgets);
    expect(
      find.textContaining('Eko Saputra · disetujui Budi Santoso'),
      findsWidgets,
    );
    expect(find.textContaining('reason: Salah input'), findsWidgets);

    await tester.scrollUntilVisible(
      find.byKey(const Key('audit-more')),
      500,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('audit-more')));
    await tester.pumpAndSettle();
    expect(fake.queries, hasLength(2));
    expect(fake.queries.last.$2?.id, 'a-1-49', reason: 'after the last row');
    expect(find.byKey(const Key('audit-more')), findsNothing);

    await tester.scrollUntilVisible(
      find.byKey(const Key('audit-approvals')),
      -500,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('audit-approvals')));
    await tester.pumpAndSettle();
    expect(fake.queries.last.$1.onlyApprovals, isTrue);
    expect(fake.queries.last.$2, isNull, reason: 'a new query starts over');
  });

  testWidgets('shifts list and the Z report from the server', (tester) async {
    tester.view
      ..physicalSize = const Size(1200, 3600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final fake = FakeShiftAudit();
    await tester.pumpWidget(app(fake, const AdminShiftsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Kurang Rp 500'), findsOneWidget);
    expect(find.textContaining('Penjualan Rp 14.000'), findsOneWidget);

    await tester.pumpWidget(
      app(fake, const AdminShiftReportScreen(shiftId: 'sh-1')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Laporan Z · Pusat'), findsOneWidget);
    expect(find.text('Rp 69.500'), findsOneWidget);
    expect(find.text('+Rp 500'), findsOneWidget);
    // WIB times.
    expect(find.text('06/11/2026 08:00 · Eko Saputra'), findsOneWidget);
  });
}
