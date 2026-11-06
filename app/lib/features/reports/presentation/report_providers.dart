import 'package:cashiera/core/providers.dart';
import 'package:cashiera/features/reports/data/reports_repository.dart';
import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'report_providers.g.dart';

@Riverpod(keepAlive: true)
ReportsRepository reportsRepository(Ref ref) =>
    ReportsRepository(ref.watch(supabaseClientProvider));

@riverpod
Future<SalesReport> salesReport(
  Ref ref, {
  required ReportPeriod period,
  String? storeId,
}) => ref.watch(reportsRepositoryProvider).sales(storeId, period);

@riverpod
Future<PaymentsReport> paymentsReport(
  Ref ref, {
  required ReportPeriod period,
  String? storeId,
}) => ref.watch(reportsRepositoryProvider).payments(storeId, period);

@riverpod
Future<ProductsReport> productsReport(
  Ref ref, {
  required ReportPeriod period,
  String? storeId,
}) => ref.watch(reportsRepositoryProvider).products(storeId, period);

@riverpod
Future<List<StaffRow>> staffReport(
  Ref ref, {
  required ReportPeriod period,
  String? storeId,
}) => ref.watch(reportsRepositoryProvider).staff(storeId, period);

@riverpod
Future<TaxReport> taxReport(
  Ref ref, {
  required ReportPeriod period,
  String? storeId,
}) => ref.watch(reportsRepositoryProvider).tax(storeId, period);

@riverpod
Future<StockValueReport> stockValueReport(Ref ref, {String? storeId}) =>
    ref.watch(reportsRepositoryProvider).stockValue(storeId);

/// Today in this browser's time zone (the back office is used locally).
@riverpod
Future<DashboardData> dashboard(Ref ref, {String? storeId}) {
  final now = clock.now();
  return ref
      .watch(reportsRepositoryProvider)
      .dashboard(storeId, DateTime.utc(now.year, now.month, now.day));
}
