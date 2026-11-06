import 'dart:convert';

import 'package:cashiera/app/app.dart';
import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/app/router.dart';
import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/auth/pin_verifier.dart';
import 'package:cashiera/core/catalog/catalog_sync.dart';
import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/printing/printer_setting.dart';
import 'package:cashiera/core/printing/printer_transport.dart';
import 'package:cashiera/core/providers.dart';
import 'package:cashiera/core/session/session_controller.dart';
import 'package:cashiera/core/sync/sync_engine.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shared setup for terminal widget tests: an in-memory database with one
/// store and one product, a signed-in cashier, no network.

const store = 'store-pst';
final at = DateTime.utc(2026, 11, 6);

const cashier = StaffMember(
  employeeId: 'e-eko',
  fullName: 'Eko Saputra',
  roleCode: 'cashier',
  permissions: {
    'pos.sell',
    'pos.discount',
    'pos.void',
    'shift.manage',
    'shift.cash_movement',
    'kasbon.manage',
  },
  pinHash: null,
);

/// In the local roster with PIN `246802` (checked as plain text in tests).
const manager = StaffMember(
  employeeId: 'e-budi',
  fullName: 'Budi Santoso',
  roleCode: 'manager',
  permissions: {
    'pos.sell',
    'pos.void',
    'pos.void_after_print',
    'pos.refund',
    'pos.open_drawer',
    'pos.discount_override',
    'shift.manage',
    'shift.cash_movement',
  },
  pinHash: '246802',
);

class OnDutySession extends SessionController {
  new(this.staff);
  final StaffMember staff;

  @override
  Future<SessionState> build() async => SessionState(
    AppMode.terminalUnlocked,
    device: LocalDeviceRow(
      deviceId: 'd-1',
      deviceCode: 'T1',
      storeId: store,
      name: 'Kasir 1',
      pairedAt: at,
    ),
    staff: staff,
  );
}

class IdleScheduler extends SyncScheduler {
  @override
  SyncRunSummary? build() => null;

  @override
  Future<SyncRunSummary> syncNow() async =>
      const SyncRunSummary(sent: 0, failed: 0, stoppedByTransientError: false);
}

class IdleCatalogSync extends CatalogSync {
  @override
  CatalogSyncState build() => const CatalogSyncState();
}

/// Records what would have gone to the printer; [fail] makes it refuse.
class FakePrinterTransport implements PrinterTransport {
  final sent = <Uint8List>[];
  PrinterException? fail;

  /// Everything printed so far, as text.
  String get text => sent.map(latin1.decode).join('\n');

  @override
  bool get canDiscover => true;

  @override
  Future<void> send(PrinterSetting printer, Uint8List bytes) async {
    final error = fail;
    if (error != null) throw error;
    sent.add(bytes);
  }

  @override
  Future<List<DiscoveredPrinter>> discover({
    Duration timeout = const Duration(seconds: 6),
  }) async => const [
    DiscoveredPrinter(
      name: 'RPP02N',
      connection: PrinterConnection.ble,
      address: '66:22:B0:11:22:33',
    ),
  ];
}

Future<void> seed(AppDatabase db) async {
  await db.batch((b) {
    b
      ..insert(
        db.localStores,
        LocalStoresCompanion.insert(
          id: store,
          code: 'PST',
          name: 'CashierA Pusat',
          timezone: 'Asia/Jakarta',
          fnbMode: false,
        ),
      )
      ..insert(
        db.localStoreSettings,
        LocalStoreSettingsCompanion.insert(
          storeId: store,
          taxEnabled: true,
          taxName: 'PPN',
          taxRateBps: 1100,
          taxInclusive: true,
          serviceChargeEnabled: false,
          serviceChargeBps: 0,
          serviceChargeTaxable: true,
          roundingMode: 'none',
          roundingUnit: 100,
          discountApprovalBps: 2000,
          kasbonEnabled: true,
          receiptFooter: 'Terima kasih',
          receiptPaperMm: 58,
        ),
      )
      ..insert(
        db.mirrorRecords,
        MirrorRecordsCompanion.insert(
          sourceTable: 'payment_methods',
          pk: 'm-cash',
          data: jsonEncode({
            'id': 'm-cash',
            'code': 'cash',
            'name': 'Tunai',
            'method_type': 'cash',
            'requires_reference': false,
            'sort_order': 10,
            'is_active': true,
          }),
          updatedAt: at,
        ),
      )
      ..insert(
        db.units,
        UnitsCompanion.insert(
          id: 'u-pcs',
          code: 'pcs',
          name: 'Pcs',
          allowDecimal: false,
          updatedAt: at,
        ),
      )
      ..insert(
        db.products,
        ProductsCompanion.insert(
          id: 'p-mie',
          unitId: 'u-pcs',
          name: 'Mie Goreng Instan',
          productType: 'standard',
          trackStock: true,
          isTaxable: true,
          isActive: true,
          updatedAt: at,
        ),
      )
      ..insert(
        db.productVariants,
        ProductVariantsCompanion.insert(
          id: 'v-mie',
          productId: 'p-mie',
          name: 'Original',
          sku: 'MIE-GRG-ORI',
          barcode: const Value('2000000000213'),
          price: 3500,
          cost: 2700,
          sortOrder: 1,
          isActive: true,
          updatedAt: at,
        ),
      )
      ..insert(
        db.stockLevels,
        StockLevelsCompanion.insert(
          variantId: 'v-mie',
          quantityMilli: 10000,
          updatedAt: at,
        ),
      );
    for (final s in [cashier, manager]) {
      b.insert(
        db.localStaff,
        LocalStaffCompanion.insert(
          employeeId: s.employeeId,
          fullName: s.fullName,
          roleCode: s.roleCode,
          permissions: jsonEncode(s.permissions.toList()),
          pinHash: Value(s.pinHash),
          isActive: true,
          syncedAt: at,
        ),
      );
    }
  });
}

/// The till on [size], signed in as [staff], on the cashier screen with a
/// shift opened with Rp 200.000.
Future<(AppDatabase, ProviderContainer)> openTill(
  WidgetTester tester,
  Size size, {
  StaffMember staff = cashier,
  FakePrinterTransport? printer,
}) async {
  tester.platformDispatcher.localesTestValue = const [Locale('id', 'ID')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  await seed(db);

  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      sessionControllerProvider.overrideWith(() => OnDutySession(staff)),
      syncSchedulerProvider.overrideWith(IdleScheduler.new),
      catalogSyncProvider.overrideWith(IdleCatalogSync.new),
      onlineProvider.overrideWith((ref) => Stream.value(false)),
      pinVerifierProvider.overrideWith(
        (ref) => PinVerifier(db, check: (pin, hash) async => pin == hash),
      ),
      printerTransportProvider.overrideWithValue(
        printer ?? FakePrinterTransport(),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const CashierApp()),
  );
  await tester.pumpAndSettle();
  container.read(routerProvider).go(AppRoutes.sell);
  await tester.pumpAndSettle();

  // No shift yet: open one.
  await tester.enterText(find.byKey(const Key('shift-opening-cash')), '200000');
  await tester.tap(find.byKey(const Key('shift-open')));
  await tester.pumpAndSettle();
  return (db, container);
}

Future<void> tapKey(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

Future<void> go(
  WidgetTester tester,
  ProviderContainer container,
  String location,
) async {
  container.read(routerProvider).go(location);
  await tester.pumpAndSettle();
}

/// Picks [approver] in the approval dialog and enters their PIN.
Future<void> approveAs(WidgetTester tester, StaffMember approver) async {
  await tapKey(tester, 'approver-${approver.employeeId}');
  for (final digit in approver.pinHash!.split('')) {
    await tester.tap(find.byKey(Key('pin-key-$digit')));
    await tester.pump();
  }
  await tester.tap(find.byKey(const Key('pin-key-ok')));
  await tester.pumpAndSettle();
}

/// Lets a toast run out so it stops covering the app bar.
Future<void> waitForToasts(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

/// `entity.action` of every queued item, oldest first.
Future<List<String>> queueKinds(AppDatabase db) async => [
  for (final q in await (db.select(
    db.syncQueue,
  )..orderBy([(q) => OrderingTerm.asc(q.id)])).get())
    '${q.entity}.${q.action}',
];

Future<Map<String, dynamic>> lastQueued(AppDatabase db, String kind) async {
  final rows = await (db.select(
    db.syncQueue,
  )..orderBy([(q) => OrderingTerm.desc(q.id)])).get();
  final row = rows.firstWhere((q) => '${q.entity}.${q.action}' == kind);
  return (jsonDecode(row.payload) as Map).cast<String, dynamic>();
}
