import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/features/back_office/presentation/admin_nav.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every back-office page belongs to exactly one tab', () {
    final routes = [
      for (final s in AdminSection.values) ...adminTabs(s).map((t) => t.route),
    ];
    expect(routes.toSet().length, routes.length);
    expect(routes.length, 19);
  });

  test('sections hold the agreed tabs in order', () {
    List<String> r(AdminSection s) => adminTabs(s).map((t) => t.route).toList();
    expect(r(AdminSection.overview), [
      AppRoutes.admin,
      AppRoutes.adminReports,
      AppRoutes.adminShifts,
      AppRoutes.adminAudit,
    ]);
    expect(r(AdminSection.sales), [
      AppRoutes.adminPromotions,
      AppRoutes.adminVouchers,
      AppRoutes.adminGatewayPayments,
    ]);
    expect(r(AdminSection.members), [
      AppRoutes.adminCustomers,
      AppRoutes.adminKasbon,
      AppRoutes.adminLoyalty,
    ]);
    expect(r(AdminSection.settings), [
      AppRoutes.adminSettings,
      AppRoutes.adminTables,
    ]);
    expect(r(AdminSection.catalog).first, AppRoutes.adminProducts);
    expect(r(AdminSection.catalog), hasLength(7));
  });

  test('locate picks the section and tab', () {
    expect(adminLocate('/admin'), (section: AdminSection.overview, tab: 0));
    expect(adminLocate('/admin/reports'), (
      section: AdminSection.overview,
      tab: 1,
    ));
    expect(adminLocate('/admin/products/new'), (
      section: AdminSection.catalog,
      tab: 0,
    ));
    expect(adminLocate('/admin/purchase-orders/po-1'), (
      section: AdminSection.catalog,
      tab: 4,
    ));
    expect(adminLocate('/admin/qris-payments'), (
      section: AdminSection.sales,
      tab: 2,
    ));
    expect(adminLocate('/admin/customers/c-9'), (
      section: AdminSection.members,
      tab: 0,
    ));
    expect(adminLocate('/admin/tables'), (
      section: AdminSection.settings,
      tab: 1,
    ));
  });
}
