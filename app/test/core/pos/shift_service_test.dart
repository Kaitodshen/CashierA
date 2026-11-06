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
  paymentOptions: [
    PaymentOption(
      id: 'm-cash',
      code: 'cash',
      name: 'Tunai',
      kind: TenderKind.cash,
      requiresReference: false,
    ),
    PaymentOption(
      id: 'm-card',
      code: 'debit_card',
      name: 'Kartu Debit',
      kind: TenderKind.card,
      requiresReference: true,
    ),
    PaymentOption(
      id: 'm-kasbon',
      code: 'kasbon',
      name: 'Kasbon',
      kind: TenderKind.kasbon,
      requiresReference: false,
    ),
  ],
);

const cashier = StaffMember(
  employeeId: 'e-eko',
  fullName: 'Eko Saputra',
  roleCode: 'cashier',
  permissions: {
    'pos.sell',
    'pos.void',
    'shift.manage',
    'shift.cash_movement',
    'kasbon.manage',
  },
  pinHash: null,
);

const trainee = StaffMember(
  employeeId: 'e-fitri',
  fullName: 'Fitri Handayani',
  roleCode: 'cashier',
  permissions: {'pos.sell', 'shift.manage'},
  pinHash: null,
);

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
    'shift.manage',
    'shift.cash_movement',
  },
  pinHash: null,
);

CartLine mie(int qty) => CartLine(
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
  quantity: Qty(qty * 1000),
);

Tender cash(int amount) => Tender(
  id: 'pay-cash',
  methodId: 'm-cash',
  kind: TenderKind.cash,
  amount: Money(amount),
);

Tender card(int amount) => Tender(
  id: 'pay-card',
  methodId: 'm-card',
  kind: TenderKind.card,
  amount: Money(amount),
  reference: 'APR9',
);

Tender kasbon(int amount) => Tender(
  id: 'pay-kasbon',
  methodId: 'm-kasbon',
  kind: TenderKind.kasbon,
  amount: Money(amount),
);

void main() {
  late AppDatabase db;
  late OrderService orders;
  late ShiftService shifts;
  late RefundService refunds;
  late AuditService audit;
  // 08:30 WIB.
  final now = DateTime.utc(2026, 11, 6, 1, 30);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    orders = OrderService(db);
    shifts = ShiftService(db);
    refunds = RefundService(db);
    audit = AuditService(db);
    await db
        .into(db.stockLevels)
        .insert(
          StockLevelsCompanion.insert(
            variantId: 'v-mie',
            quantityMilli: 20000,
            updatedAt: now,
          ),
        );
  });

  tearDown(() => db.close());

  Future<T> at<T>(Future<T> Function() body, [int minutes = 0]) =>
      withClock(Clock.fixed(now.add(Duration(minutes: minutes))), body);

  Future<List<(String, Map<String, dynamic>)>> queue() async => [
    for (final row in await (db.select(
      db.syncQueue,
    )..orderBy([(q) => OrderingTerm.asc(q.id)])).get())
      (
        '${row.entity}.${row.action}',
        (jsonDecode(row.payload) as Map).cast<String, dynamic>(),
      ),
  ];

  Future<(ShiftRow, SaleContext)> openShift({
    int opening = 100000,
    StaffMember staff = cashier,
  }) async {
    final shift = await at(
      () => shifts.open(
        storeId: store,
        staff: staff,
        openingCash: Money(opening),
      ),
    );
    return (
      shift,
      SaleContext(
        config: config,
        deviceCode: 'T1',
        staff: staff,
        shiftId: shift.id,
      ),
    );
  }

  Future<LocalOrderRow> sell(
    SaleContext ctx,
    String id,
    int qty,
    List<Tender> tenders, {
    CartCustomer? customer,
  }) async {
    final cart = Cart(
      orderId: id,
      startedAt: now,
      lines: [mie(qty)],
      customer: customer,
    );
    final bill = calculateBill(
      lines: [for (final l in cart.lines) l.toPricing()],
      settings: config.pricing,
    );
    return await at(
      () => orders.complete(
        cart: cart,
        bill: bill,
        settlement: settle(bill.grandTotal, tenders),
        ctx: ctx,
      ),
      1,
    );
  }

  Future<int> stock() async =>
      (await db.select(db.stockLevels).getSingle()).quantityMilli;

  group('cash in and out', () {
    test('a cash out cannot take more than the drawer holds', () async {
      final (shift, ctx) = await openShift(opening: 50000);
      await sell(ctx, 'o-1', 2, [cash(10000)]);
      await expectLater(
        shifts.cashMovement(
          shift: shift,
          staff: cashier,
          isIn: false,
          amount: const Money(57001),
          reason: 'Setor ke bank',
          config: config,
          approver: manager,
        ),
        throwsA(
          isA<DrawerShortException>().having(
            (e) => e.available,
            'available',
            const Money(57000),
          ),
        ),
      );
      final row = await at(
        () => shifts.cashMovement(
          shift: shift,
          staff: cashier,
          isIn: false,
          amount: const Money(57000),
          reason: 'Setor ke bank',
          config: config,
          approver: manager,
        ),
      );
      expect(row.movementType, 'out');
      final (kind, payload) = (await queue()).last;
      expect(kind, 'cash_movement.create');
      expect(payload['amount'], 57000);
      expect(payload['approved_by'], 'e-budi');
      expect(payload['reason'], 'Setor ke bank');
    });

    test(
      'it opens the drawer: without pos.open_drawer it needs an approver',
      () async {
        final (shift, _) = await openShift();
        await expectLater(
          shifts.cashMovement(
            shift: shift,
            staff: cashier,
            isIn: true,
            amount: const Money(1),
            reason: 'Buka laci',
            config: config,
          ),
          throwsA(
            isA<PosStateException>().having(
              (e) => e.code,
              'code',
              'approval_required',
            ),
          ),
        );
        await expectLater(
          shifts.cashMovement(
            shift: shift,
            staff: cashier,
            isIn: true,
            amount: const Money(1),
            reason: 'Buka laci',
            config: config,
            approver: trainee,
          ),
          throwsA(isA<PosPermissionException>()),
        );
        // A manager records it alone, without an approver.
        await at(
          () => shifts.cashMovement(
            shift: shift,
            staff: manager,
            isIn: true,
            amount: const Money(1000),
            reason: 'Uang kecil',
            config: config,
          ),
        );
        final (_, payload) = (await queue()).last;
        expect(payload['approved_by'], isNull);
      },
    );

    test('needs a reason and the permission', () async {
      final (shift, _) = await openShift();
      expect(
        () => shifts.cashMovement(
          shift: shift,
          staff: cashier,
          isIn: true,
          amount: const Money(1000),
          reason: ' x ',
          config: config,
          approver: manager,
        ),
        throwsA(isA<PosStateException>()),
      );
      expect(
        () => shifts.cashMovement(
          shift: shift,
          staff: trainee,
          isIn: true,
          amount: const Money(1000),
          reason: 'Uang kecil',
          config: config,
        ),
        throwsA(isA<PosPermissionException>()),
      );
    });
  });

  group('closing', () {
    test('queues the close after the sales with the terminal figure', () async {
      final (shift, ctx) = await openShift();
      await sell(ctx, 'o-1', 2, [cash(10000)]);
      await sell(ctx, 'o-2', 4, [card(4000), cash(20000)]);
      await at(
        () => shifts.cashMovement(
          shift: shift,
          staff: cashier,
          isIn: true,
          amount: const Money(25000),
          reason: 'Tambah kembalian',
          config: config,
          approver: manager,
        ),
      );
      // A held bill stays held.
      final heldCart = Cart(orderId: 'o-held', startedAt: now, lines: [mie(1)]);
      await at(
        () => orders.hold(
          cart: heldCart,
          bill: calculateBill(
            lines: [for (final l in heldCart.lines) l.toPricing()],
            settings: config.pricing,
          ),
          ctx: ctx,
        ),
      );

      final z = await at(
        () => shifts.close(
          shift: shift,
          staff: cashier,
          counted: const Money(141500),
          config: config,
          deviceCode: 'T1',
          note: '  ',
        ),
        60,
      );
      // 100000 + 7000 + 10000 + 25000
      expect(z.kind, ShiftReportKind.z);
      expect(z.cash.expected, const Money(142000));
      expect(z.cash.difference, const Money(-500));
      expect(z.deviceCode, 'T1');
      expect(z.closedByName, 'Eko Saputra');
      expect(z.payments.map((p) => (p.name, p.amount.rupiah)), [
        ('Tunai', 17000),
        ('Kartu Debit', 4000),
      ]);

      final q = await queue();
      expect(q.map((e) => e.$1), [
        'shift.open',
        'order.upsert',
        'order.upsert',
        'cash_movement.create',
        'order.upsert',
        'shift.close',
      ]);
      final close = q.last.$2;
      expect(close['client_expected_cash'], 142000);
      expect(close['counted_cash'], 141500);
      expect(close['note'], isNull);

      final saved = (await shifts.find(shift.id))!;
      expect(saved.status, 'closed');
      expect(saved.expectedCash, 142000);
      expect((await orders.find('o-held'))!.status, 'held');

      await expectLater(
        shifts.close(
          shift: shift,
          staff: cashier,
          counted: Money.zero,
          config: config,
        ),
        throwsA(isA<PosStateException>()),
      );
      await expectLater(
        shifts.cashMovement(
          shift: shift,
          staff: cashier,
          isIn: true,
          amount: const Money(1),
          reason: 'Terlambat',
          config: config,
          approver: manager,
        ),
        throwsA(isA<PosStateException>()),
      );
    });
  });

  group('void', () {
    test('a printed sale from the last shift comes off this one', () async {
      final (first, ctx1) = await openShift();
      final sale = await sell(ctx1, 'o-1', 2, [cash(10000)]);
      await orders.markPrinted(sale.id);
      await at(
        () => shifts.close(
          shift: first,
          staff: cashier,
          counted: const Money(107000),
          config: config,
        ),
        30,
      );
      final (second, ctx2) = await openShift(opening: 50000);
      final printed = (await orders.find('o-1'))!;
      expect(await stock(), 18000);

      await expectLater(
        orders.voidOrder(order: printed, ctx: ctx2, reason: 'Salah input'),
        throwsA(
          isA<PosStateException>().having(
            (e) => e.code,
            'code',
            'approval_required',
          ),
        ),
      );
      await expectLater(
        orders.voidOrder(
          order: printed,
          ctx: ctx2,
          reason: 'Salah input',
          approver: cashier,
        ),
        throwsA(isA<PosPermissionException>()),
      );
      await at(
        () => orders.voidOrder(
          order: printed,
          ctx: ctx2,
          reason: 'Salah input',
          approver: manager,
        ),
        40,
      );

      final voided = (await orders.find('o-1'))!;
      expect(voided.status, 'voided');
      expect(voided.voidedShiftId, second.id);
      expect(await stock(), 20000, reason: 'the stock came back');
      final (kind, payload) = (await queue()).last;
      expect(kind, 'order.void');
      expect(payload['voided_by'], 'e-eko');
      expect(payload['approved_by'], 'e-budi');
      expect(payload['shift_id'], second.id);
      expect(payload['receipt_printed_at'], isNotNull);

      final x = await shifts.report(second, config: config);
      expect(x.cash.expected, const Money(43000));
      expect(x.voids.orders, 1);
      final z = await shifts.report(
        (await shifts.find(first.id))!,
        config: config,
      );
      expect(z.cash.expected, const Money(107000), reason: 'A is untouched');
    });

    test('without pos.void the approver voids on their behalf', () async {
      final (_, ctx) = await openShift(staff: trainee);
      final sale = await sell(ctx, 'o-1', 1, [cash(3500)]);
      expect(
        () => orders.voidOrder(order: sale, ctx: ctx, reason: 'Batal'),
        throwsA(isA<PosPermissionException>()),
      );
      await at(
        () => orders.voidOrder(
          order: sale,
          ctx: ctx,
          reason: 'Batal',
          approver: manager,
        ),
      );
      final (_, payload) = (await queue()).last;
      expect(payload['voided_by'], 'e-budi');
    });
  });

  group('refund', () {
    test('two partial refunds add up, with a number and restock', () async {
      final (shift, ctx) = await openShift(opening: 50000);
      final sale = await sell(ctx, 'o-1', 3, [cash(20000)]);
      expect(await stock(), 17000);

      final first = await at(
        () => refunds.refund(
          order: sale,
          quantities: {'line-mie': Qty.one},
          methodType: 'cash',
          restock: true,
          reason: 'Kemasan sobek',
          approver: manager,
          ctx: ctx,
        ),
        5,
      );
      expect(first.refundNumber, 'R-PST-T1-261106-0001');
      expect(first.amount, 3500);
      expect(await stock(), 18000);

      final info = await refunds.info(sale);
      expect(info.refundable, const Money(7000));
      expect(info.lines.single.line.remainingQuantity, const Qty(2000));

      final second = await at(
        () => refunds.refund(
          order: sale,
          quantities: {'line-mie': const Qty(2000)},
          methodType: 'cash',
          restock: false,
          reason: 'Kemasan sobek',
          approver: manager,
          ctx: ctx,
        ),
        6,
      );
      expect(second.refundNumber, 'R-PST-T1-261106-0002');
      expect(first.amount + second.amount, 10500);
      expect(await stock(), 18000, reason: 'no restock the second time');
      expect((await refunds.info(sale)).fullyRefunded, isTrue);

      final (kind, payload) = (await queue()).last;
      expect(kind, 'refund.create');
      expect(payload['amount'], 7000);
      expect(payload['approved_by'], 'e-budi');
      expect(payload['shift_id'], shift.id);
      final item = (payload['items'] as List).single as Map;
      expect(item['order_item_id'], 'line-mie');
      expect(item['quantity'], '2.000');

      final x = await shifts.report(shift, config: config);
      expect(x.refunds.cash, const Money(10500));
      expect(x.cash.expected, const Money(50000));
      expect(x.topItems.single.quantity, Qty.zero);

      await expectLater(
        orders.voidOrder(order: sale, ctx: ctx, reason: 'Batal'),
        throwsA(
          isA<PosStateException>().having(
            (e) => e.code,
            'code',
            'void_after_refund',
          ),
        ),
      );
    });

    test('only money received comes back; approver needs pos.refund', () async {
      final (_, ctx) = await openShift();
      final sale = await sell(ctx, 'o-1', 4, [
        cash(4000),
        kasbon(10000),
      ], customer: const CartCustomer(id: 'c-1', name: 'Maya'));
      await expectLater(
        refunds.refund(
          order: sale,
          quantities: {'line-mie': Qty.one},
          methodType: 'cash',
          restock: true,
          reason: 'Rusak',
          approver: cashier,
          ctx: ctx,
        ),
        throwsA(isA<PosPermissionException>()),
      );
      await expectLater(
        refunds.refund(
          order: sale,
          quantities: {'line-mie': const Qty(2000)},
          methodType: 'cash',
          restock: true,
          reason: 'Rusak',
          approver: manager,
          ctx: ctx,
        ),
        throwsA(
          isA<RefundRejected>().having(
            (e) => e.problem,
            'problem',
            RefundProblem.exceedsPaid,
          ),
        ),
      );
      expect((await refunds.info(sale)).paidMethodTypes, {'cash'});
      await expectLater(
        refunds.refund(
          order: sale,
          quantities: {'line-mie': Qty.one},
          methodType: 'kasbon',
          restock: true,
          reason: 'Rusak',
          approver: manager,
          ctx: ctx,
        ),
        throwsA(isA<PosStateException>()),
      );
    });
  });

  test('opening the drawer without a sale needs pos.open_drawer', () async {
    expect(
      () => audit.log(
        storeId: store,
        action: AuditService.drawerNoSale,
        actor: cashier,
        approver: cashier,
      ),
      throwsA(isA<PosPermissionException>()),
    );
    await audit.log(
      storeId: store,
      action: AuditService.drawerNoSale,
      actor: cashier,
      approver: manager,
      details: {'reason': 'Tukar uang'},
    );
    final (kind, payload) = (await queue()).single;
    expect(kind, 'audit.log');
    expect(payload['action'], 'pos.drawer_open_no_sale');
    expect(payload['approver_employee_id'], 'e-budi');
    expect(payload['details'], {'reason': 'Tukar uang'});
  });
}
