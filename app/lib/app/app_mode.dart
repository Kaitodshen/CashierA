/// Which shell the app is in. Decided by SessionController.
enum AppMode {
  starting,
  setupRequired,
  signedOut,

  /// Paired terminal, nobody on duty: PIN lock screen.
  terminalLocked,

  /// Paired terminal with a PIN-verified staff member.
  terminalUnlocked,

  /// Owner or manager signed in with email.
  backOffice,
}

abstract final class AppRoutes {
  static const splash = '/';
  static const setup = '/setup';
  static const welcome = '/welcome';
  static const pair = '/pair';
  static const lock = '/lock';
  static const pos = '/pos';
  static const catalog = '/pos/catalog';
  static const opname = '/pos/opname';
  static const sell = '/pos/sell';
  static const pay = '/pos/pay';
  static const orders = '/pos/orders';

  /// Receipt of a terminal order; [justSold] right after payment.
  static String receipt(String orderId, {bool justSold = false}) =>
      '/pos/receipt/$orderId${justSold ? '?sale=1' : ''}';

  /// Refund of a terminal order.
  static String refund(String orderId) => '/pos/refund/$orderId';
  static const shift = '/pos/shift';
  static const shiftClose = '/pos/shift/close';

  /// X or Z report of one of this terminal's shifts.
  static String shiftReport(String shiftId) => '/pos/shift/report/$shiftId';
  static const printer = '/pos/printer';
  static const customers = '/pos/customers';

  /// One customer on the terminal.
  static String customer(String id) => '$customers/$id';
  static const sync = '/sync';
  static const adminSignIn = '/admin/sign-in';
  static const admin = '/admin';
  static const adminProducts = '/admin/products';
  static const adminCategories = '/admin/categories';
  static const adminSuppliers = '/admin/suppliers';
  static const adminStock = '/admin/stock';
  static const adminImport = '/admin/import';
  static const adminPromotions = '/admin/promotions';
  static const adminVouchers = '/admin/vouchers';
  static const adminSettings = '/admin/settings';
  static const adminShifts = '/admin/shifts';
  static const adminAudit = '/admin/audit';
  static const adminCustomers = '/admin/customers';
  static const adminKasbon = '/admin/kasbon';
  static const adminLoyalty = '/admin/loyalty';

  /// One customer in the back office.
  static String adminCustomer(String id) => '$adminCustomers/$id';

  /// X or Z report of a shift, from the server.
  static String adminShift(String id) => '$adminShifts/$id';

  /// Promotion editor; `new` creates one.
  static String adminPromotion(String id) => '$adminPromotions/$id';

  /// Product editor; `new` creates a product.
  static String adminProduct(String id) => '$adminProducts/$id';
}

/// The router guard as a pure function: where [location] must go in [mode],
/// or null to stay. Web only hosts the back office (no terminal routes).
String? redirectFor(AppMode mode, String location, {required bool isWeb}) {
  String? to(String path) => location == path ? null : path;

  switch (mode) {
    case AppMode.starting:
      return to(AppRoutes.splash);
    case AppMode.setupRequired:
      return to(AppRoutes.setup);
    case AppMode.signedOut:
      if (isWeb) return to(AppRoutes.adminSignIn);
      const allowed = {
        AppRoutes.welcome,
        AppRoutes.pair,
        AppRoutes.adminSignIn,
      };
      return allowed.contains(location) ? null : AppRoutes.welcome;
    case AppMode.terminalLocked:
      return isWeb ? to(AppRoutes.adminSignIn) : to(AppRoutes.lock);
    case AppMode.terminalUnlocked:
      if (isWeb) return to(AppRoutes.adminSignIn);
      final allowed =
          location == AppRoutes.sync ||
          location == AppRoutes.pos ||
          location.startsWith('${AppRoutes.pos}/');
      return allowed ? null : AppRoutes.pos;
    case AppMode.backOffice:
      final inAdmin =
          location == AppRoutes.admin ||
          (location.startsWith('${AppRoutes.admin}/') &&
              location != AppRoutes.adminSignIn);
      return inAdmin ? null : AppRoutes.admin;
  }
}

bool isTerminalMode(AppMode mode) =>
    mode == AppMode.terminalLocked || mode == AppMode.terminalUnlocked;
