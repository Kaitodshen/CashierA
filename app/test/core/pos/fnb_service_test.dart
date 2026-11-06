import 'dart:convert';

import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/pos/cart.dart';
import 'package:cashiera/core/pos/order_payload.dart';
import 'package:cashiera/core/pos/pos_config.dart';
import 'package:cashiera/core/pos/pos_services.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:clock/clock.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const store = 'store-tgr';

const config = PosConfig(
  storeId: store,
  storeCode: 'TGR',
  storeName: 'CashierA Tangerang',
  utcOffsetMinutes: 7 * 60,
  pricing: PricingSettings(taxRateBps: 0),
  taxName: 'PPN',
  taxEnabled: false,
  discountApprovalBps: 2000,
  kasbonEnabled: false,
  receiptFooter: 'Terima kasih',
  paperMm: 58,
  business: BusinessInfo(name: 'CashierA'),
  paymentOptions: [],
  fnbMode: true,
);

const waiter = StaffMember(
  employeeId: 'e-indra',
  fullName: 'Indra',
  roleCode: 'cashier',
  permissions: {'pos.sell', 'shift.manage'},
  pinHash: null,
);

const cook = StaffMember(
  employeeId: 'e-dewi',
  fullName: 'Dewi',
  roleCode: 'kitchen',
  permissions: {'kitchen.view'},
  pinHash: null,
);

CartLine line(String id, String name, String? station, {String qty = '1'}) =>
    CartLine(
      id: id,
      variantId: 'v-$id',
      productId: 'p-$id',
      productName: name,
      variantName: 'Default',
      sku: id.toUpperCase(),
      unitCode: 'pcs',
      allowDecimal: false,
      unitPrice: const Money(15000),
      unitCost: const Money(6000),
      isTaxable: true,
      trackStock: false,
      quantity: Qty.parse(qty),
      kitchenStation: station,
    );

Cart dineIn(String orderId, {String table = 't-7'}) => Cart(
  orderId: orderId,
  startedAt: DateTime.utc(2026, 11, 7, 5),
  orderType: 'dine_in',
  tableId: table,
  tableName: 'Meja 7',
  guestCount: 2,
  lines: [
    line('nasi', 'Nasi Goreng', 'kitchen', qty: '2'),
    line('teh', 'Es Teh', 'bar'),
    line('krupuk', 'Kerupuk', null),
  ],
);

Bill price(Cart cart) => calculateBill(
  lines: [for (final l in cart.lines) l.toPricing()],
  settings: config.pricing,
);

void main() {
  late AppDatabase db;
  late OrderService orders;
  late FnbService fnb;
  final now = DateTime.utc(2026, 11, 7, 5, 30);
  const ctx = SaleContext(config: config, deviceCode: 'T1', staff: waiter);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    orders = OrderService(db);
    fnb = FnbService(db);
    for (final (id, name) in [
      ('t-7', 'Meja 7'),
      ('t-10', 'Meja 10'),
      ('t-2', 'Meja 2'),
    ]) {
      await db
          .into(db.mirrorRecords)
          .insert(
            MirrorRecordsCompanion.insert(
              sourceTable: 'dining_tables',
              pk: id,
              data: jsonEncode({
                'id': id,
                'store_id': store,
                'name': name,
                'area': 'Dalam',
                'capacity': 4,
                'status': id == 't-10' ? 'cleaning' : 'available',
                'is_active': true,
              }),
              updatedAt: now,
            ),
          );
    }
  });

  tearDown(() => db.close());

  Future<List<Map<String, dynamic>>> queued(String entity) async => [
    for (final row in await (db.select(
      db.syncQueue,
    )..orderBy([(q) => OrderingTerm.asc(q.id)])).get())
      if (row.entity == entity)
        (jsonDecode(row.payload) as Map).cast<String, dynamic>(),
  ];

  test('a dine-in payload carries the table, guests and stations', () {
    final cart = dineIn('o-1');
    final payload = buildOrderPayload(
      cart: cart,
      bill: price(cart),
      config: config,
      cashierId: waiter.employeeId,
      orderNumber: 'TGR-T1-261107-0001',
      status: OrderStatus.held,
      version: 1,
    );
    expect(payload['order_type'], 'dine_in');
    expect(payload['table_id'], 't-7');
    expect(payload['guest_count'], 2);
    expect(
      [for (final i in payload['items'] as List) (i as Map)['kitchen_station']],
      ['kitchen', 'bar', null],
    );
  });

  test('the cart keeps its table and what was sent through JSON', () {
    final cart = markKitchenSent(dineIn('o-1'));
    final back = Cart.fromJson(
      (jsonDecode(jsonEncode(cart.toJson())) as Map).cast<String, dynamic>(),
    );
    expect(back.tableId, 't-7');
    expect(back.tableName, 'Meja 7');
    expect(back.guestCount, 2);
    expect(back.orderType, 'dine_in');
    expect(back.kitchenSent, {'nasi': 2000, 'teh': 1000});
    expect(back.lines.first.kitchenStation, 'kitchen');
    expect(back.copyWith(clearTable: true).orderType, 'takeaway');
  });

  test('tickets: one per station, then only what was added', () {
    final cart = dineIn('o-1');
    final first = pendingKitchenLines(cart);
    expect(first.keys, ['bar', 'kitchen']);
    expect(first['kitchen']!.single.$2, Qty.parse('2'));
    expect(first['bar']!.single.$1.productName, 'Es Teh');

    final sent = markKitchenSent(cart);
    expect(pendingKitchenLines(sent), isEmpty, reason: 'nothing new');

    final more = sent.copyWith(
      lines: [
        for (final l in sent.lines)
          if (l.id == 'nasi') l.copyWith(quantity: Qty.parse('3')) else l,
      ],
    );
    final second = pendingKitchenLines(more);
    expect(second.keys, ['kitchen'], reason: 'the bar has nothing new');
    expect(second['kitchen']!.single.$2, Qty.one, reason: 'only the 3rd one');
  });

  test('a second bill on an occupied table is refused', () async {
    await withClock(
      Clock.fixed(now),
      () => orders.hold(
        cart: dineIn('o-1'),
        bill: price(dineIn('o-1')),
        ctx: ctx,
      ),
    );
    await expectLater(
      withClock(
        Clock.fixed(now),
        () => orders.hold(
          cart: dineIn('o-2'),
          bill: price(dineIn('o-2')),
          ctx: ctx,
        ),
      ),
      throwsA(
        isA<PosStateException>().having(
          (e) => e.code,
          'code',
          'table_occupied',
        ),
      ),
    );
    // The same bill can be held again (sent to the kitchen twice).
    final again = await withClock(
      Clock.fixed(now),
      () => orders.hold(
        cart: dineIn('o-1')
            .copyWith(orderNumber: 'TGR-T1-261107-0001', version: 1),
        bill: price(dineIn('o-1')),
        ctx: ctx,
      ),
    );
    expect(again.version, 2);
    // Another table is fine.
    await withClock(
      Clock.fixed(now),
      () => orders.hold(
        cart: dineIn('o-3', table: 't-2'),
        bill: price(dineIn('o-3', table: 't-2')),
        ctx: ctx,
      ),
    );
    expect(await queued('order'), hasLength(3));
  });

  test('tables: natural order, local bills shown as occupied', () async {
    await withClock(
      Clock.fixed(now),
      () => orders.hold(
        cart: dineIn('o-1'),
        bill: price(dineIn('o-1')),
        ctx: ctx,
      ),
    );
    final tables = await fnb.tables();
    expect([for (final t in tables) t.name], ['Meja 2', 'Meja 7', 'Meja 10']);
    final seven = tables[1];
    expect(seven.status, 'occupied');
    expect(seven.heldOrder?.id, 'o-1');
    expect(tables[2].status, 'cleaning');

    await expectLater(
      fnb.clearTable(table: seven, staff: waiter),
      throwsA(
        isA<PosStateException>().having(
          (e) => e.code,
          'code',
          'table_has_open_order',
        ),
      ),
    );
    await fnb.clearTable(table: tables[2], staff: waiter);
    expect((await fnb.tables())[2].status, 'available');
    expect(await queued('dining_table'), [
      {'table_id': 't-10', 'status': 'available', 'employee_id': 'e-indra'},
    ]);
  });

  test('kitchen status needs kitchen.view and goes to the outbox', () async {
    await expectLater(
      fnb.setKitchenStatus(
        orderId: 'o-1',
        station: 'kitchen',
        status: 'preparing',
        staff: waiter,
      ),
      throwsA(isA<PosPermissionException>()),
    );
    await fnb.setKitchenStatus(
      orderId: 'o-1',
      station: 'kitchen',
      status: 'preparing',
      staff: cook,
    );
    final sent = (await queued('kitchen')).single;
    expect(sent['order_id'], 'o-1');
    expect(sent['station'], 'kitchen');
    expect(sent['status'], 'preparing');
    expect(sent['employee_id'], 'e-dewi');
  });

  test('a kitchen ticket parses from kitchen_queue', () {
    final t = KitchenTicket.fromJson(const {
      'order_id': 'o-1',
      'order_number': 'TGR-T1-261107-0001',
      'station': 'bar',
      'status': 'new',
      'order_type': 'dine_in',
      'table_name': 'Meja 7',
      'guest_count': 2,
      'note': null,
      'created_at': '2026-11-07T05:00:00Z',
      'updated_at': '2026-11-07T05:00:00Z',
      'items': [
        {
          'name': 'Es Teh',
          'quantity': 1.5,
          'note': 'tanpa gula',
          'modifiers': ['Less ice'],
        },
      ],
    });
    expect(t.nextStatus, 'preparing');
    expect(t.items.single.quantity, Qty.parse('1.5'));
    expect(t.items.single.modifiers, ['Less ice']);
  });
}
