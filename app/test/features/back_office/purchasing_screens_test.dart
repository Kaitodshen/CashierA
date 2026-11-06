import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/design_system/theme.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/features/back_office/data/back_office_backend.dart';
import 'package:cashiera/features/back_office/data/catalog_admin_models.dart';
import 'package:cashiera/features/back_office/data/purchasing_repository.dart';
import 'package:cashiera/features/back_office/presentation/back_office_providers.dart';
import 'package:cashiera/features/back_office/presentation/purchase_orders_screen.dart';
import 'package:cashiera/features/back_office/presentation/transfers_screen.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';

const mie = StockVariant(
  id: 'v-mie',
  name: 'Mie Goreng Instan Original',
  sku: 'MIE-GRG-ORI',
  cost: Money(2500),
  unit: 'pcs',
);

class FakePurchasing implements PurchasingRepository {
  Map<String, (Qty, Money?)>? received;
  List<PoLineDraft>? savedLines;
  String? savedSupplier;
  final transitions = <(String, Map<String, Qty>?)>[];

  @override
  Future<List<StockVariant>> stockVariants() async => const [mie];

  @override
  Future<PoDetail> purchaseOrder(String id) async => PoDetail.fromJson({
    'purchase_order_id': id,
    'po_number': 'PO-PST-261107-001',
    'status': 'partially_received',
    'store_id': 's-1',
    'store_name': 'Pusat',
    'supplier_id': 'sup-1',
    'supplier': {'name': 'PT Sumber Pangan Demo', 'phone': '0215550101'},
    'order_date': '2026-11-07',
    'expected_date': '2026-11-10',
    'note': 'Kirim pagi',
    'total_amount': 460000,
    'created_by_name': 'Budi Santoso',
    'items': [
      {
        'id': 'poi-mie',
        'variant_id': 'v-mie',
        'name': 'Mie Goreng Instan Original',
        'sku': 'MIE-GRG-ORI',
        'unit': 'pcs',
        'quantity_ordered': 120,
        'quantity_received': 50,
        'unit_cost': 2500,
        'line_total': 300000,
      },
      {
        'id': 'poi-gula',
        'variant_id': 'v-gula',
        'name': 'Gula Pasir 1 kg',
        'sku': 'SMB-GLA-1KG',
        'unit': 'pcs',
        'quantity_ordered': 10,
        'quantity_received': 0,
        'unit_cost': 16000,
        'line_total': 160000,
      },
    ],
    'receipts': [
      {
        'receipt_number': 'GR-PST-261107-001',
        'received_at': '2026-11-07T03:00:00Z',
        'received_by_name': 'Budi Santoso',
        'lines': 1,
      },
    ],
  });

  @override
  Future<String> receive(
    String purchaseOrderId,
    Map<String, (Qty, Money?)> quantities, {
    String? note,
  }) async {
    received = quantities;
    return 'GR-PST-261107-002';
  }

  @override
  Future<String> savePurchaseOrder({
    required String storeId,
    required String supplierId,
    required List<PoLineDraft> lines,
    String? id,
    DateTime? expectedDate,
    String? note,
  }) async {
    savedLines = lines;
    savedSupplier = supplierId;
    return 'po-new';
  }

  @override
  Future<TransferDetail> transfer(String id) async => TransferDetail.fromJson({
    'transfer_id': id,
    'transfer_number': 'TRF-261107-0001',
    'status': transitions.isEmpty ? 'in_transit' : 'received',
    'note': 'Stok habis',
    'from_store_id': 's-2',
    'from_store': 'BKS · Bekasi',
    'to_store_id': 's-1',
    'to_store': 'PST · Pusat',
    'events': {
      'requested': {'at': '2026-11-07T01:00:00Z', 'by': 'Budi Santoso'},
      'approved': {'at': '2026-11-07T02:00:00Z', 'by': 'Citra Lestari'},
      'shipped': {'at': '2026-11-07T02:30:00Z', 'by': 'Citra Lestari'},
    },
    'items': [
      {
        'variant_id': 'v-mie',
        'name': 'Mie Goreng Instan Original',
        'sku': 'MIE-GRG-ORI',
        'quantity_requested': 10,
        'quantity_shipped': 10,
        'quantity_received': transitions.isEmpty ? null : 9,
        'stock_at_sender': 40,
      },
    ],
  });

  @override
  Future<void> transition(
    String transferId,
    String status, {
    Map<String, Qty>? quantities,
    String? note,
  }) async => transitions.add((status, quantities));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget app(FakePurchasing fake, String location, Set<String> permissions) {
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: '/admin/purchase-orders',
        builder: (_, _) => const Text('list'),
      ),
      GoRoute(
        path: '/admin/purchase-orders/:id',
        builder: (_, state) => Scaffold(
          body: PurchaseOrderScreen(
            key: ValueKey(state.pathParameters['id']),
            purchaseOrderId: state.pathParameters['id']!,
          ),
        ),
      ),
      GoRoute(
        path: '/admin/transfers/:id',
        builder: (_, state) => Scaffold(
          body: TransferScreen(transferId: state.pathParameters['id']!),
        ),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      purchasingProvider.overrideWithValue(fake),
      principalProvider.overrideWith(
        (ref) async => Principal(
          kind: 'employee',
          employeeId: 'e-1',
          roleCode: 'manager',
          permissions: permissions,
        ),
      ),
      backOfficeStoresProvider.overrideWith(
        (ref) async => const [
          StoreSummary(id: 's-1', code: 'PST', name: 'Pusat'),
        ],
      ),
      adminSuppliersProvider.overrideWith(
        (ref) async => const [
          AdminSupplier(id: 'sup-1', name: 'PT Sumber Pangan Demo'),
        ],
      ),
    ],
    child: ToastificationWrapper(
      child: MaterialApp.router(
        theme: AppTheme.backOffice(),
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
}

void main() {
  setUp(() {});

  Future<void> big(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1400, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('receive the rest of a PO: over-receipt refused, new cost', (
    tester,
  ) async {
    await big(tester);
    final fake = FakePurchasing();
    await tester.pumpWidget(
      app(fake, '/admin/purchase-orders/po-1', const {
        'purchase.manage',
        'inventory.receive',
      }),
    );
    await tester.pumpAndSettle();
    expect(find.text('Diterima sebagian'), findsOneWidget);
    expect(
      find.byKey(const Key('po-edit')),
      findsNothing,
      reason: 'lines are locked once goods arrived',
    );
    expect(find.byKey(const Key('po-cancel')), findsNothing);
    expect(find.text('GR-PST-261107-001'), findsOneWidget);

    await tester.tap(find.byKey(const Key('po-receive')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('qty-poi-mie')))
          .controller!
          .text,
      '70',
      reason: 'suggests what is still open',
    );
    await tester.enterText(find.byKey(const Key('qty-poi-mie')), '71');
    await tester.tap(find.byKey(const Key('qty-confirm')));
    await tester.pumpAndSettle();
    expect(find.textContaining('maksimal 70'), findsOneWidget);
    expect(fake.received, isNull);

    await tester.enterText(find.byKey(const Key('qty-poi-mie')), '70');
    await tester.enterText(find.byKey(const Key('cost-poi-gula')), '16500');
    await tester.tap(find.byKey(const Key('qty-confirm')));
    await tester.pumpAndSettle();
    expect(fake.received, {
      'poi-mie': (Qty.parse('70'), null),
      'poi-gula': (Qty.parse('10'), const Money(16500)),
    });
    expect(find.textContaining('GR-PST-261107-002'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('a new PO: supplier, store, item, quantity and cost', (
    tester,
  ) async {
    await big(tester);
    final fake = FakePurchasing();
    await tester.pumpWidget(
      app(fake, '/admin/purchase-orders/new', const {'purchase.manage'}),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('po-save')));
    await tester.pumpAndSettle();
    expect(fake.savedLines, isNull, reason: 'store, supplier and items first');
    await tester.pump(const Duration(seconds: 5));

    await tester.tap(find.byKey(const Key('po-store')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PST · Pusat').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('po-supplier')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PT Sumber Pangan Demo').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('po-add-item')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('variant-v-mie')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('po-qty-v-mie')), '100');
    await tester.enterText(find.byKey(const Key('po-cost-v-mie')), '2400');
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('po-editor-total'))).data,
      'Rp 240.000',
    );

    await tester.tap(find.byKey(const Key('po-save')));
    await tester.pumpAndSettle();
    expect(fake.savedSupplier, 'sup-1');
    final line = fake.savedLines!.single;
    expect(line.variant.id, 'v-mie');
    expect(line.quantity, Qty.parse('100'));
    expect(line.unitCost, const Money(2400));
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('receive a transfer short: 9 of the 10 shipped', (tester) async {
    await big(tester);
    final fake = FakePurchasing();
    await tester.pumpWidget(
      app(fake, '/admin/transfers/t-1', const {'inventory.receive'}),
    );
    await tester.pumpAndSettle();
    expect(find.text('Dikirim'), findsWidgets);
    expect(find.byKey(const Key('transfer-approve')), findsNothing);
    await tester.tap(find.byKey(const Key('transfer-receive')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('qty-v-mie')), '9');
    await tester.tap(find.byKey(const Key('qty-confirm')));
    await tester.pumpAndSettle();
    expect(fake.transitions.single.$1, 'received');
    expect(fake.transitions.single.$2, {'v-mie': Qty.parse('9')});
    final cell = tester.widget<Text>(
      find.byKey(const Key('transfer-received-v-mie')),
    );
    expect(cell.data, '9');
    expect(cell.style?.color, isNotNull, reason: 'the shortfall stands out');
    await tester.pump(const Duration(seconds: 5));
  });
}
