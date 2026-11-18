import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/l10n/l10n.dart';

/// The five sections of the back-office sidebar.
enum AdminSection { overview, catalog, sales, members, settings }

/// One page tab under a section; each tab is its own route.
class AdminTab {
  const new(this.route, this.label);

  final String route;
  final String Function(AppLocalizations) label;
}

final Map<AdminSection, List<AdminTab>> _tabs = {
  AdminSection.overview: [
    AdminTab(AppRoutes.admin, (l) => l.navHome),
    AdminTab(AppRoutes.adminReports, (l) => l.navReports),
    AdminTab(AppRoutes.adminShifts, (l) => l.navShifts),
    AdminTab(AppRoutes.adminAudit, (l) => l.navAudit),
  ],
  AdminSection.catalog: [
    AdminTab(AppRoutes.adminProducts, (l) => l.navProducts),
    AdminTab(AppRoutes.adminCategories, (l) => l.navCategories),
    AdminTab(AppRoutes.adminStock, (l) => l.navStock),
    AdminTab(AppRoutes.adminSuppliers, (l) => l.navSuppliers),
    AdminTab(AppRoutes.adminPurchaseOrders, (l) => l.navPurchasing),
    AdminTab(AppRoutes.adminTransfers, (l) => l.navTransfers),
    AdminTab(AppRoutes.adminImport, (l) => l.navImport),
  ],
  AdminSection.sales: [
    AdminTab(AppRoutes.adminPromotions, (l) => l.navPromotions),
    AdminTab(AppRoutes.adminVouchers, (l) => l.navVouchers),
    AdminTab(AppRoutes.adminGatewayPayments, (l) => l.navGatewayPayments),
  ],
  AdminSection.members: [
    AdminTab(AppRoutes.adminCustomers, (l) => l.navCustomers),
    AdminTab(AppRoutes.adminKasbon, (l) => l.navKasbon),
    AdminTab(AppRoutes.adminLoyalty, (l) => l.navLoyalty),
  ],
  AdminSection.settings: [
    AdminTab(AppRoutes.adminSettings, (l) => l.navSettings),
    AdminTab(AppRoutes.adminTables, (l) => l.navTables),
  ],
};

List<AdminTab> adminTabs(AdminSection section) => _tabs[section]!;

/// The section and tab for [location]. The longest matching tab route wins,
/// so `/admin/products/new` is Catalog → Products and `/admin` is Overview
/// → Home.
({AdminSection section, int tab}) adminLocate(String location) {
  var best = (section: AdminSection.overview, tab: 0);
  var bestLength = -1;
  for (final section in AdminSection.values) {
    for (final (i, tab) in adminTabs(section).indexed) {
      final matches =
          location == tab.route || location.startsWith('${tab.route}/');
      if (matches && tab.route.length > bestLength) {
        best = (section: section, tab: i);
        bestLength = tab.route.length;
      }
    }
  }
  return best;
}

String adminSectionLabel(AppLocalizations l10n, AdminSection s) => switch (s) {
  AdminSection.overview => l10n.sectionOverview,
  AdminSection.catalog => l10n.sectionCatalog,
  AdminSection.sales => l10n.sectionSales,
  AdminSection.members => l10n.sectionMembers,
  AdminSection.settings => l10n.sectionSettings,
};
