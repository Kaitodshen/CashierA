import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/providers.dart';
import 'package:cashiera/features/back_office/data/back_office_backend.dart';
import 'package:cashiera/features/back_office/data/catalog_admin_models.dart';
import 'package:cashiera/features/back_office/data/catalog_admin_repository.dart';
import 'package:cashiera/features/back_office/data/customers_admin_repository.dart';
import 'package:cashiera/features/back_office/data/pos_admin_repository.dart';
import 'package:cashiera/features/back_office/data/shift_audit_repository.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'back_office_providers.g.dart';

@riverpod
Future<Principal> principal(Ref ref) =>
    ref.watch(backOfficeBackendProvider).currentPrincipal();

@riverpod
Future<List<StoreSummary>> backOfficeStores(Ref ref) =>
    ref.watch(backOfficeBackendProvider).listStores();

@Riverpod(keepAlive: true)
CatalogAdminRepository catalogAdmin(Ref ref) =>
    CatalogAdminRepository(ref.watch(supabaseClientProvider));

@riverpod
Future<List<AdminCategory>> adminCategories(Ref ref) =>
    ref.watch(catalogAdminProvider).categories();

@riverpod
Future<List<AdminUnit>> adminUnits(Ref ref) =>
    ref.watch(catalogAdminProvider).units();

@riverpod
Future<List<AdminSupplier>> adminSuppliers(Ref ref) =>
    ref.watch(catalogAdminProvider).suppliers();

@riverpod
Future<List<ProductSummary>> adminProducts(
  Ref ref, {
  String search = '',
  String? categoryId,
}) => ref
    .watch(catalogAdminProvider)
    .products(search: search, categoryId: categoryId);

@riverpod
Future<List<StockRow>> stockOverview(Ref ref, String storeId) =>
    ref.watch(catalogAdminProvider).stockOverview(storeId);

@riverpod
Future<List<AlertRow>> storeAlerts(Ref ref, String storeId) =>
    ref.watch(catalogAdminProvider).openAlerts(storeId);

@riverpod
Future<List<MovementRow>> stockMovements(
  Ref ref,
  String storeId,
  String variantId,
) => ref.watch(catalogAdminProvider).movements(storeId, variantId);

@Riverpod(keepAlive: true)
PosAdminRepository posAdmin(Ref ref) =>
    PosAdminRepository(ref.watch(supabaseClientProvider));

@riverpod
Future<StoreSettingsDraft> adminStoreSettings(Ref ref, String storeId) =>
    ref.watch(posAdminProvider).storeSettings(storeId);

@riverpod
Future<List<StorePaymentMethod>> adminPaymentMethods(Ref ref, String storeId) =>
    ref.watch(posAdminProvider).paymentMethods(storeId);

@riverpod
Future<List<Promotion>> adminPromotions(Ref ref) =>
    ref.watch(posAdminProvider).promotions();

@riverpod
Future<List<AdminVoucher>> adminVouchers(Ref ref) =>
    ref.watch(posAdminProvider).vouchers();

@riverpod
Future<ScopeOptions> promotionScopeOptions(Ref ref) =>
    ref.watch(posAdminProvider).scopeOptions();

@Riverpod(keepAlive: true)
ShiftAuditRepository shiftAudit(Ref ref) =>
    ShiftAuditRepository(ref.watch(supabaseClientProvider));

/// Shifts with a business date from [from] to [to]; [storeId] null = all.
@riverpod
Future<List<ShiftOverviewRow>> adminShifts(
  Ref ref, {
  required DateTime from,
  required DateTime to,
  String? storeId,
}) =>
    ref.watch(shiftAuditProvider).shifts(from: from, to: to, storeId: storeId);

@riverpod
Future<ShiftReport> adminShiftReport(Ref ref, String shiftId) =>
    ref.watch(shiftAuditProvider).shiftSummary(shiftId);

@Riverpod(keepAlive: true)
CustomersAdminRepository customersAdmin(Ref ref) =>
    CustomersAdminRepository(ref.watch(supabaseClientProvider));

@riverpod
Future<List<AdminCustomer>> adminCustomers(Ref ref, String query) =>
    ref.watch(customersAdminProvider).customers(query);

@riverpod
Future<CustomerStatement> adminCustomerStatement(Ref ref, String customerId) =>
    ref.watch(customersAdminProvider).statement(customerId);

@riverpod
Future<List<KasbonOverviewRow>> adminKasbon(Ref ref, {String? storeId}) =>
    ref.watch(customersAdminProvider).kasbonOverview(storeId: storeId);

@riverpod
Future<LoyaltySettings> adminLoyaltySettings(Ref ref) =>
    ref.watch(customersAdminProvider).loyaltySettings();
