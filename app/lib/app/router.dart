import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/app/shell/terminal_shell.dart';
import 'package:cashiera/core/session/session_controller.dart';
import 'package:cashiera/features/back_office/presentation/admin_customers_screen.dart';
import 'package:cashiera/features/back_office/presentation/admin_kasbon_screen.dart';
import 'package:cashiera/features/back_office/presentation/admin_shell.dart';
import 'package:cashiera/features/back_office/presentation/admin_shifts_screen.dart';
import 'package:cashiera/features/back_office/presentation/audit_screen.dart';
import 'package:cashiera/features/back_office/presentation/back_office_home_screen.dart';
import 'package:cashiera/features/back_office/presentation/categories_screen.dart';
import 'package:cashiera/features/back_office/presentation/dining_tables_screen.dart';
import 'package:cashiera/features/back_office/presentation/gateway_payments_screen.dart';
import 'package:cashiera/features/back_office/presentation/import_screen.dart';
import 'package:cashiera/features/back_office/presentation/loyalty_settings_screen.dart';
import 'package:cashiera/features/back_office/presentation/product_editor_screen.dart';
import 'package:cashiera/features/back_office/presentation/products_screen.dart';
import 'package:cashiera/features/back_office/presentation/promotion_editor_screen.dart';
import 'package:cashiera/features/back_office/presentation/promotions_screen.dart';
import 'package:cashiera/features/back_office/presentation/purchase_orders_screen.dart';
import 'package:cashiera/features/back_office/presentation/sign_in_screen.dart';
import 'package:cashiera/features/back_office/presentation/stock_screen.dart';
import 'package:cashiera/features/back_office/presentation/store_settings_screen.dart';
import 'package:cashiera/features/back_office/presentation/suppliers_screen.dart';
import 'package:cashiera/features/back_office/presentation/transfers_screen.dart';
import 'package:cashiera/features/back_office/presentation/vouchers_screen.dart';
import 'package:cashiera/features/catalog/presentation/catalog_browser_screen.dart';
import 'package:cashiera/features/catalog/presentation/opname_screen.dart';
import 'package:cashiera/features/customers/presentation/customers_screen.dart';
import 'package:cashiera/features/fnb/kitchen_screen.dart';
import 'package:cashiera/features/fnb/tables_screen.dart';
import 'package:cashiera/features/pairing/presentation/pairing_screen.dart';
import 'package:cashiera/features/pin_login/presentation/pin_lock_screen.dart';
import 'package:cashiera/features/printing/printer_screen.dart';
import 'package:cashiera/features/reports/presentation/reports_screen.dart';
import 'package:cashiera/features/sell/presentation/orders_screen.dart';
import 'package:cashiera/features/sell/presentation/payment_screen.dart';
import 'package:cashiera/features/sell/presentation/receipt_screen.dart';
import 'package:cashiera/features/sell/presentation/refund_screen.dart';
import 'package:cashiera/features/sell/presentation/sell_screen.dart';
import 'package:cashiera/features/shift/presentation/close_shift_screen.dart';
import 'package:cashiera/features/shift/presentation/shift_report_screen.dart';
import 'package:cashiera/features/shift/presentation/shift_screen.dart';
import 'package:cashiera/features/startup/presentation/setup_screen.dart';
import 'package:cashiera/features/startup/presentation/splash_screen.dart';
import 'package:cashiera/features/startup/presentation/welcome_screen.dart';
import 'package:cashiera/features/sync_status/presentation/sync_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final mode = ValueNotifier<AppMode>(AppMode.starting);
  ref
    ..listen(sessionControllerProvider, (_, next) {
      mode.value = switch (next) {
        AsyncData(:final value) => value.mode,
        AsyncError() => AppMode.signedOut,
        _ => mode.value,
      };
    }, fireImmediately: true)
    ..onDispose(mode.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: mode,
    redirect: (context, state) =>
        redirectFor(mode.value, state.matchedLocation, isWeb: kIsWeb),
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: AppRoutes.setup, builder: (_, _) => const SetupScreen()),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (_, _) => const WelcomeScreen(),
      ),
      GoRoute(path: AppRoutes.pair, builder: (_, _) => const PairingScreen()),
      GoRoute(path: AppRoutes.lock, builder: (_, _) => const PinLockScreen()),
      // The old home cards are gone: the terminal lands on Register.
      GoRoute(path: AppRoutes.pos, redirect: (_, _) => AppRoutes.sell),
      ShellRoute(
        builder: (_, _, child) => TerminalShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.catalog,
            builder: (_, _) => const CatalogBrowserScreen(),
          ),
          GoRoute(
            path: AppRoutes.opname,
            builder: (_, _) => const OpnameScreen(),
          ),
          GoRoute(path: AppRoutes.sell, builder: (_, _) => const SellScreen()),
          GoRoute(
            path: AppRoutes.pay,
            builder: (_, state) => PaymentScreen(
              key: ValueKey(state.uri.toString()),
              initialMethodId: state.uri.queryParameters['method'],
              initialAmount: int.tryParse(
                state.uri.queryParameters['amount'] ?? '',
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.orders,
            builder: (_, _) => const OrdersScreen(),
          ),
          GoRoute(
            path: '/pos/receipt/:id',
            builder: (_, state) => ReceiptScreen(
              key: ValueKey(state.uri.toString()),
              orderId: state.pathParameters['id']!,
              justSold: state.uri.queryParameters['sale'] == '1',
            ),
          ),
          GoRoute(
            path: '/pos/refund/:id',
            builder: (_, state) =>
                RefundScreen(orderId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: AppRoutes.shift,
            builder: (_, _) => const ShiftScreen(),
          ),
          GoRoute(
            path: AppRoutes.shiftClose,
            builder: (_, _) => const CloseShiftScreen(),
          ),
          GoRoute(
            path: '/pos/shift/report/:id',
            builder: (_, state) =>
                ShiftReportScreen(shiftId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: AppRoutes.printer,
            builder: (_, _) => const PrinterScreen(),
          ),
          GoRoute(
            path: AppRoutes.tables,
            builder: (_, _) => const TablesScreen(),
          ),
          GoRoute(
            path: AppRoutes.kitchen,
            builder: (_, _) => const KitchenScreen(),
          ),
          GoRoute(
            path: AppRoutes.customers,
            builder: (_, _) => const CustomersScreen(),
          ),
          GoRoute(
            path: '${AppRoutes.customers}/:id',
            builder: (_, state) => CustomerDetailScreen(
              key: ValueKey(state.pathParameters['id']),
              customerId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(path: AppRoutes.sync, builder: (_, _) => const SyncScreen()),
        ],
      ),
      GoRoute(
        path: AppRoutes.adminSignIn,
        builder: (_, _) => const SignInScreen(),
      ),
      ShellRoute(
        builder: (_, _, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.admin,
            builder: (_, _) => const BackOfficeHomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminProducts,
            builder: (_, _) => const ProductsScreen(),
          ),
          GoRoute(
            path: '${AppRoutes.adminProducts}/:id',
            builder: (_, state) => ProductEditorScreen(
              key: ValueKey(state.pathParameters['id']),
              productId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.adminCategories,
            builder: (_, _) => const CategoriesScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminSuppliers,
            builder: (_, _) => const SuppliersScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminStock,
            builder: (_, _) => const StockScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminImport,
            builder: (_, _) => const ImportScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminPromotions,
            builder: (_, _) => const PromotionsScreen(),
          ),
          GoRoute(
            path: '${AppRoutes.adminPromotions}/:id',
            builder: (_, state) => PromotionEditorScreen(
              key: ValueKey(state.pathParameters['id']),
              promotionId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.adminVouchers,
            builder: (_, _) => const VouchersScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminSettings,
            builder: (_, _) => const StoreSettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminShifts,
            builder: (_, _) => const AdminShiftsScreen(),
          ),
          GoRoute(
            path: '${AppRoutes.adminShifts}/:id',
            builder: (_, state) =>
                AdminShiftReportScreen(shiftId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: AppRoutes.adminAudit,
            builder: (_, _) => const AuditScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminCustomers,
            builder: (_, _) => const AdminCustomersScreen(),
          ),
          GoRoute(
            path: '${AppRoutes.adminCustomers}/:id',
            builder: (_, state) => AdminCustomerScreen(
              key: ValueKey(state.pathParameters['id']),
              customerId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.adminKasbon,
            builder: (_, _) => const AdminKasbonScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminLoyalty,
            builder: (_, _) => const LoyaltySettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminReports,
            builder: (_, _) => const ReportsScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminPurchaseOrders,
            builder: (_, _) => const PurchaseOrdersScreen(),
          ),
          GoRoute(
            path: '${AppRoutes.adminPurchaseOrders}/:id',
            builder: (_, state) => PurchaseOrderScreen(
              key: ValueKey(state.pathParameters['id']),
              purchaseOrderId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.adminTransfers,
            builder: (_, _) => const TransfersScreen(),
          ),
          GoRoute(
            path: '${AppRoutes.adminTransfers}/:id',
            builder: (_, state) => TransferScreen(
              key: ValueKey(state.pathParameters['id']),
              transferId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.adminGatewayPayments,
            builder: (_, _) => const GatewayPaymentsScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminTables,
            builder: (_, _) => const DiningTablesScreen(),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}
