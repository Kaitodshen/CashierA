import 'dart:async';

import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/auth/pin_verifier.dart';
import 'package:cashiera/core/auth/terminal_backend.dart';
import 'package:cashiera/core/auth/terminal_repository.dart';
import 'package:cashiera/core/catalog/catalog_source.dart';
import 'package:cashiera/core/catalog/stock_service.dart';
import 'package:cashiera/core/catalog/terminal_catalog_repository.dart';
import 'package:cashiera/core/config/env.dart';
import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/database/connection.dart';
import 'package:cashiera/core/pos/pos_config.dart';
import 'package:cashiera/core/pos/pos_services.dart';
import 'package:cashiera/core/printing/printer_service.dart';
import 'package:cashiera/core/printing/printer_setting.dart';
import 'package:cashiera/core/printing/printer_transport.dart';
import 'package:cashiera/core/sync/supabase_sync_transport.dart';
import 'package:cashiera/core/sync/sync_engine.dart';
import 'package:cashiera/core/sync/sync_item.dart';
import 'package:cashiera/core/sync/sync_transport.dart';
import 'package:cashiera/features/back_office/data/back_office_backend.dart';
import 'package:clock/clock.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
AppEnv appEnv(Ref ref) => AppEnv.fromEnvironment();

/// Only read when [AppEnv.isConfigured] (Supabase is initialized in
/// bootstrap).
@Riverpod(keepAlive: true)
SupabaseClient supabaseClient(Ref ref) => Supabase.instance.client;

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase(openAppDatabase());
  ref.onDispose(db.close);
  return db;
}

@Riverpod(keepAlive: true)
TerminalRepository terminalRepository(Ref ref) =>
    TerminalRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
TerminalBackend terminalBackend(Ref ref) =>
    SupabaseTerminalBackend(ref.watch(supabaseClientProvider));

@Riverpod(keepAlive: true)
BackOfficeBackend backOfficeBackend(Ref ref) =>
    SupabaseBackOfficeBackend(ref.watch(supabaseClientProvider));

@Riverpod(keepAlive: true)
PinVerifier pinVerifier(Ref ref) => PinVerifier(ref.watch(appDatabaseProvider));

/// True when the device has any network interface up.
@Riverpod(keepAlive: true)
Stream<bool> online(Ref ref) async* {
  final connectivity = Connectivity();
  bool isUp(List<ConnectivityResult> r) =>
      r.any((c) => c != ConnectivityResult.none);
  yield isUp(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(isUp);
}

@Riverpod(keepAlive: true)
TerminalCatalogRepository terminalCatalog(Ref ref) =>
    TerminalCatalogRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
StockService stockService(Ref ref) =>
    StockService(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
PosConfigRepository posConfigRepository(Ref ref) =>
    PosConfigRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
ShiftService shiftService(Ref ref) =>
    ShiftService(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
OrderService orderService(Ref ref) =>
    OrderService(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
RefundService refundService(Ref ref) =>
    RefundService(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
AuditService auditService(Ref ref) =>
    AuditService(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
CustomerService customerService(Ref ref) =>
    CustomerService(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
PrinterRepository printerRepository(Ref ref) =>
    PrinterRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
PrinterTransport printerTransport(Ref ref) => createPrinterTransport();

@Riverpod(keepAlive: true)
PrinterService printerService(Ref ref) => PrinterService(
  ref.watch(printerRepositoryProvider),
  ref.watch(printerTransportProvider),
);

/// The receipt printer set up on this terminal, or null.
@riverpod
Stream<PrinterSetting?> receiptPrinter(Ref ref) =>
    ref.watch(printerRepositoryProvider).watch();

@Riverpod(keepAlive: true)
CatalogSource catalogSource(Ref ref) =>
    SupabaseCatalogSource(ref.watch(supabaseClientProvider));

/// Active staff of this terminal's store, from the local roster.
@riverpod
Stream<List<StaffMember>> roster(Ref ref) =>
    ref.watch(terminalRepositoryProvider).watchStaff();

@riverpod
Stream<int> syncOutstanding(Ref ref) =>
    ref.watch(appDatabaseProvider).syncQueueDao.watchOutstanding();

@riverpod
Stream<List<SyncItem>> syncItems(Ref ref) => ref
    .watch(appDatabaseProvider)
    .syncQueueDao
    .watchItems()
    .map((rows) => rows.map(SyncItem.fromEntry).toList());

@Riverpod(keepAlive: true)
SyncTransport syncTransport(Ref ref) =>
    SupabaseSyncTransport(ref.watch(supabaseClientProvider));

@Riverpod(keepAlive: true)
SyncEngine syncEngine(Ref ref) => SyncEngine(
  dao: ref.watch(appDatabaseProvider).syncQueueDao,
  transport: ref.watch(syncTransportProvider),
);

/// Runs the outbox while a terminal is active: once at start (after
/// recovering interrupted items), whenever the network comes back, and every
/// 15 seconds. State is the last run's summary.
@Riverpod(keepAlive: true)
class SyncScheduler extends _$SyncScheduler {
  static const interval = Duration(seconds: 15);
  static const keepDone = Duration(days: 7);

  @override
  SyncRunSummary? build() {
    final engine = ref.watch(syncEngineProvider);
    final dao = ref.watch(appDatabaseProvider).syncQueueDao;
    unawaited(() async {
      await engine.recoverInterrupted();
      await dao.pruneDone(clock.now().subtract(keepDone));
      await syncNow();
    }());
    ref.listen(onlineProvider, (previous, next) {
      if (next.value == true && previous?.value != true) unawaited(syncNow());
    });
    final timer = Timer.periodic(interval, (_) => unawaited(syncNow()));
    ref.onDispose(timer.cancel);
    return null;
  }

  Future<SyncRunSummary> syncNow() async {
    final summary = await ref.read(syncEngineProvider).runOnce();
    if (!summary.skippedBecauseBusy && ref.mounted) state = summary;
    return summary;
  }
}
