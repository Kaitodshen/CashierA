import 'dart:convert';

import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/pos/cart.dart';
import 'package:cashiera/core/pos/pos_config.dart';
import 'package:cashiera/core/pos/pos_services.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:clock/clock.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const store = 'store-pst';

const config = PosConfig(
  storeId: store,
  storeCode: 'PST',
  storeName: 'CashierA Pusat',
  utcOffsetMinutes: 7 * 60,
  pricing: PricingSettings(taxRateBps: 1100),
  taxName: 'PPN',
  taxEnabled: true,
  discountApprovalBps: 2000,
  kasbonEnabled: true,
  receiptFooter: 'Terima kasih',
  paperMm: 58,
  business: BusinessInfo(name: 'CashierA'),
  paymentOptions: [],
);

const cashier = StaffMember(
  employeeId: 'e-eko',
  fullName: 'Eko Saputra',
  roleCode: 'cashier',
  permissions: {
    'pos.sell',
    'pos.discount',
    'shift.manage',
    'customer.manage',
    'kasbon.manage',
  },
  pinHash: null,
);

CartLine mie({String qty = '3'}) => CartLine(
  id: 'line-mie',
  variantId: 'v-mie',
  productId: 'p-mie',
  productName: 'Mie Goreng Instan',
  variantName: 'Original',
  sku: 'MIE-GRG-ORI',
  unitCode: 'pcs',
  allowDecimal: false,
  unitPrice: const Money(3500),
  unitCost: const Money(2700),
  isTaxable: true,
  trackStock: true,
  quantity: Qty.parse(qty),
);

Tender cash(int amount) => Tender(
  id: 'pay-cash',
  methodId: 'm-cash',
  kind: TenderKind.cash,
  amount: Money(amount),
);

Bill price(Cart cart) => calculateBill(
  lines: [for (final l in cart.lines) l.toPricing()],
  settings: config.pricing,
  billDiscount: cart.billDiscount,
);

void main() {
  late AppDatabase db;
  late OrderService orders;
  late ShiftService shifts;
  // 2026-11-06 01:30 UTC = 08:30 WIB.
  final now = DateTime.utc(2026, 11, 6, 1, 30);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    orders = OrderService(db);
    shifts = ShiftService(db);
    await db
        .into(db.stockLevels)
        .insert(
          StockLevelsCompanion.insert(
            variantId: 'v-mie',
            quantityMilli: 10000,
            updatedAt: now,
          ),
        );
  });

  tearDown(() => db.close());

  Future<List<Map<String, dynamic>>> queued(String entity) async => [
    for (final row in await (db.select(
      db.syncQueue,
    )..orderBy([(q) => OrderingTerm.asc(q.id)])).get())
      if (row.entity == entity)
        (jsonDecode(row.payload) as Map).cast<String, dynamic>(),
  ];

  Future<SaleContext> context() async {
    final shift = await withClock(
      Clock.fixed(now),
      () => shifts.open(
        storeId: store,
        staff: cashier,
        openingCash: const Money(200000),
      ),
    );
    return SaleContext(
      config: config,
      deviceCode: 'T1',
      staff: cashier,
      shiftId: shift.id,
    );
  }

  test('opening a shift queues shift.open once', () async {
    await context();
    await withClock(
      Clock.fixed(now),
      () => shifts.open(
        storeId: store,
        staff: cashier,
        openingCash: const Money(5),
      ),
    );
    final opened = await queued('shift');
    expect(opened, hasLength(1), reason: 'a second open returns the first');
    expect(opened.single['opening_cash'], 200000);
  });

  test('hold, then finish: one order, two versions, stock once', () async {
    final ctx = await context();
    var cart = Cart(orderId: 'order-1', startedAt: now, lines: [mie()]);

    cart = await withClock(
      Clock.fixed(now),
      () => orders.hold(cart: cart, bill: price(cart), ctx: ctx),
    );
    expect(cart.orderNumber, 'PST-T1-261106-0001');
    expect(cart.version, 1);

    final bill = price(cart);
    final done = await withClock(
      Clock.fixed(now.add(const Duration(minutes: 3))),
      () => orders.complete(
        cart: cart,
        bill: bill,
        settlement: settle(bill.grandTotal, [cash(20000)]),
        ctx: ctx,
      ),
    );
    expect(done.status, 'completed');
    expect(done.version, 2);

    final sent = await queued('order');
    expect(sent.map((p) => p['id']), ['order-1', 'order-1']);
    expect(sent.map((p) => p['status']), ['held', 'completed']);
    expect(sent.map((p) => p['version']), [1, 2]);
    expect(sent.first['payments'], isEmpty);
    final payment = (sent.last['payments'] as List).single as Map;
    expect(payment['amount'], 10500);
    expect(payment['tendered_amount'], 20000);
    expect(payment['change_amount'], 9500);
    expect(sent.last['shift_id'], ctx.shiftId);
    expect(sent.last['order_number'], 'PST-T1-261106-0001');

    expect(await db.select(db.localOrders).get(), hasLength(1));
    final stock = await db.select(db.stockLevels).getSingle();
    expect(stock.quantityMilli, 7000, reason: '10 - 3, deducted once');
  });

  test('order numbers count per business date in store time', () async {
    final ctx = await context();
    Future<String> sell(String id, DateTime at) async {
      final cart = Cart(
        orderId: id,
        startedAt: at,
        lines: [mie(qty: '1')],
      );
      final bill = price(cart);
      final row = await withClock(
        Clock.fixed(at),
        () => orders.complete(
          cart: cart,
          bill: bill,
          settlement: settle(bill.grandTotal, [cash(3500)]),
          ctx: ctx,
        ),
      );
      return row.orderNumber;
    }

    expect(await sell('a', now), 'PST-T1-261106-0001');
    expect(await sell('b', now), 'PST-T1-261106-0002');
    // 17:30 UTC on the 6th is already 00:30 on the 7th in Jakarta.
    expect(
      await sell('c', DateTime.utc(2026, 11, 6, 17, 30)),
      'PST-T1-261107-0001',
    );
  });

  test('a sale needs an open shift and full payment', () async {
    const noShift = SaleContext(
      config: config,
      deviceCode: 'T1',
      staff: cashier,
    );
    final cart = Cart(orderId: 'x', startedAt: now, lines: [mie()]);
    final bill = price(cart);
    await expectLater(
      orders.complete(
        cart: cart,
        bill: bill,
        settlement: settle(bill.grandTotal, [cash(20000)]),
        ctx: noShift,
      ),
      throwsA(
        isA<PosStateException>().having(
          (e) => e.code,
          'code',
          'shift_required',
        ),
      ),
    );
    final ctx = await context();
    await expectLater(
      orders.complete(
        cart: cart,
        bill: bill,
        settlement: settle(bill.grandTotal, [cash(5000)]),
        ctx: ctx,
      ),
      throwsA(
        isA<PosStateException>().having((e) => e.code, 'code', 'not_paid'),
      ),
    );
    expect(await queued('order'), isEmpty, reason: 'nothing half-saved');
  });

  test('kasbon needs a customer', () async {
    final ctx = await context();
    final cart = Cart(orderId: 'k', startedAt: now, lines: [mie()]);
    final bill = price(cart);
    final kasbon = settle(bill.grandTotal, [
      Tender(
        id: 'pay-k',
        methodId: 'm-kasbon',
        kind: TenderKind.kasbon,
        amount: bill.grandTotal,
      ),
    ]);
    await expectLater(
      orders.complete(cart: cart, bill: bill, settlement: kasbon, ctx: ctx),
      throwsA(
        isA<PosStateException>().having(
          (e) => e.code,
          'code',
          'kasbon_requires_customer',
        ),
      ),
    );

    final withCustomer = cart.copyWith(
      customer: const CartCustomer(id: 'c-1', name: 'Bu Sari'),
    );
    await withClock(
      Clock.fixed(now),
      () => orders.complete(
        cart: withCustomer,
        bill: bill,
        settlement: kasbon,
        ctx: ctx,
      ),
    );
    final sent = (await queued('order')).single;
    expect(sent['customer_id'], 'c-1');
    expect(sent['paid_total'], 0);
    expect(sent['kasbon_due_date'], '2026-12-06', reason: '30 days');
  });

  test('a big manual discount needs an approver', () async {
    final ctx = await context();
    final cart = Cart(
      orderId: 'd',
      startedAt: now,
      lines: [mie()],
      billDiscount: const DiscountSpec.percent(2500),
    );
    final bill = price(cart);
    final settlement = settle(bill.grandTotal, [cash(10000)]);
    await expectLater(
      orders.complete(cart: cart, bill: bill, settlement: settlement, ctx: ctx),
      throwsA(
        isA<PosStateException>().having(
          (e) => e.code,
          'code',
          'approval_required',
        ),
      ),
    );
    await withClock(
      Clock.fixed(now),
      () => orders.complete(
        cart: cart.copyWith(approvedBy: 'e-budi'),
        bill: bill,
        settlement: settlement,
        ctx: ctx,
      ),
    );
    final discount =
        ((await queued('order')).single['discounts'] as List).single as Map;
    expect(discount['source'], 'manual');
    expect(discount['approved_by'], 'e-budi');
    expect(discount['amount'], 2625);
  });

  test('cancelling a held bill sends a newer cancelled snapshot', () async {
    final ctx = await context();
    final cart = Cart(orderId: 'h', startedAt: now, lines: [mie()]);
    await withClock(
      Clock.fixed(now),
      () => orders.hold(cart: cart, bill: price(cart), ctx: ctx),
    );
    final held = (await orders.find('h'))!;
    await expectLater(
      orders.cancelHeld(order: held, ctx: ctx, reason: 'Batal beli'),
      throwsA(isA<PosPermissionException>()),
      reason: 'the cashier has no pos.void in this test',
    );
    await orders.cancelHeld(
      order: held,
      ctx: ctx,
      reason: 'Batal beli',
      approvedBy: 'e-budi',
    );
    final last = (await queued('order')).last;
    expect(last['status'], 'cancelled');
    expect(last['version'], 2);
    expect((last['cancel'] as Map)['cancelled_by'], 'e-budi');
    expect((await orders.find('h'))!.status, 'cancelled');
  });

  test('carts survive a round trip through JSON', () {
    final cart = Cart(
      orderId: 'o',
      startedAt: now,
      orderNumber: 'PST-T1-261106-0009',
      version: 3,
      lines: [
        mie().copyWith(
          manualDiscount: const DiscountSpec.fixed(500),
          note: 'pedas',
        ),
      ],
      customer: const CartCustomer(id: 'c', name: 'Pak Budi', phone: '0812'),
      billDiscount: const DiscountSpec.percent(500),
      voucherCode: 'HEMAT10',
    );
    final back = Cart.fromJson(
      (jsonDecode(jsonEncode(cart.toJson())) as Map).cast<String, dynamic>(),
    );
    expect(back.toJson(), cart.toJson());
  });

  test('customers added on the till are local at once and queued', () async {
    final added = await CustomerService(db).quickAdd(
      staff: cashier,
      storeId: store,
      name: '  Bu Sari ',
      phone: '0812-3456-7890',
    );
    expect(added.name, 'Bu Sari');
    expect(added.phone, '081234567890');
    final row = await db.select(db.localCustomers).getSingle();
    expect(row.id, added.id);
    expect((await queued('customer')).single['employee_id'], 'e-eko');
    expect(
      () => CustomerService(db)
          .quickAdd(staff: cashier, storeId: store, name: 'X', phone: '12ab'),
      throwsArgumentError,
    );
  });
}
