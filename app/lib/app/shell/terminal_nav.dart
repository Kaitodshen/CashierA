import 'package:cashiera/app/app_mode.dart';

/// The five items of the terminal sidebar.
enum TerminalSection {
  register(AppRoutes.sell),
  overview(AppRoutes.shift),
  catalog(AppRoutes.catalog),
  members(AppRoutes.customers),
  settings(AppRoutes.printer);

  new(this.route);

  /// The screen the item opens.
  final String route;
}

bool _under(String location, String route) =>
    location == route || location.startsWith('$route/');

/// The sidebar item to highlight for [location]; null when none fits
/// (the kitchen display).
TerminalSection? terminalSectionFor(String location) {
  if (_under(location, AppRoutes.shift)) return TerminalSection.overview;
  if (_under(location, AppRoutes.catalog) ||
      _under(location, AppRoutes.opname)) {
    return TerminalSection.catalog;
  }
  if (_under(location, AppRoutes.customers)) return TerminalSection.members;
  if (_under(location, AppRoutes.printer) || _under(location, AppRoutes.sync)) {
    return TerminalSection.settings;
  }
  const register = [
    AppRoutes.sell,
    AppRoutes.pay,
    AppRoutes.orders,
    AppRoutes.tables,
    '/pos/receipt',
    '/pos/refund',
  ];
  if (register.any((r) => _under(location, r))) {
    return TerminalSection.register;
  }
  return null;
}

/// Whether the top bar shows the search-and-scan field.
bool showsSearch(String location) =>
    location == AppRoutes.sell || location == AppRoutes.catalog;

/// The count on the Held Orders pill: nothing at zero, `99+` above 99.
String heldBadge(int count) {
  if (count <= 0) return '';
  if (count > 99) return '99+';
  return '$count';
}
