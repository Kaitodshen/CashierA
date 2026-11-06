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
  business: BusinessInfo(
    name: 'CashierA',
    loyalty: LoyaltyRules(
      earnAmount: Money(10000),
      pointValue: Money(100),
      minRedeemPoints: 10,
    ),
  ),
  paymentOptions: [],
);

const cashier = StaffMember(
  employeeId: 'e-eko',
  fullName: 'Eko Saputra',
  roleCode: 'cashier',
  permissions: {'pos.sell', 'pos.void', 'shift.manage', 'kasbon.manage'},
  pinHash: null,
);

const manager = StaffMember(
  employeeId: 'e-budi',
  fullName: 'Budi Santoso',
  roleCode: 'manager',
  permissions: {'pos.sell', 'pos.void', 'pos.refund', 'kasbon.manage'},
  pinHash: null,
);

const rudi = CartCustomer(id: 'c-rudi', name: 'Rudi Hartono');

void main() {
  late AppDatabase db;
  late OrderService orders;
  late KasbonService kasbon;
  late RefundService refunds;
  late ShiftService shifts;
  late SaleContext ctx;
  late ShiftRow shift;
  final now = DateTime.utc(2026, 11, 7, 2);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    orders = OrderService(db);
    kasbon = KasbonService(db);
    refunds = RefundService(db);
    shifts = ShiftService(db);
    await db
        .into(db.localCustomers)
        .insert(
          LocalCustomersCompanion.insert(
            id: rudi.id,
            name: rudi.name,
            pointsBalance: const Value(50),
            isActive: true,
            updatedAt: now,
          ),
        );
    shift = await withClock(
      Clock.fixed(now),
      () => shifts.open(
        storeId: store,
        staff: cashier,
        openingCash: const Money(100000),
      ),
    );
    ctx = SaleContext(
      config: config,
      deviceCode: 'T1',
      staff: cashier,
      shiftId: shift.id,
    );
  });
  tearDown(() => db.close());

  Future<T> at<T>(Future<T> Function() body, {int days = 0}) =>
      withClock(Clock.fixed(now.add(Duration(days: days, minutes: 1))), body);

  CartLine mie(int qty) => CartLine(
    id: 'line-$qty',
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
    trackStock: false,
    quantity: Qty(qty * 1000),
  );

  Tender tender(TenderKind kind, int amount, [String? id]) => Tender(
    id: id ?? 'pay-${kind.code}',
    methodId: 'm-${kind.code}',
    kind: kind,
    amount: Money(amount),
  );

  Future<LocalOrderRow> sell(
    String id,
    int qty,
    List<Tender> Function(Money due) tenders, {
    int points = 0,
    int days = 0,
  }) async {
    final cart = Cart(
      orderId: id,
      startedAt: now,
      lines: [mie(qty)],
      customer: rudi,
      pointsToRedeem: points,
    );
    final bill = calculateBill(
      lines: [for (final l in cart.lines) l.toPricing()],
      settings: config.pricing,
      points: points == 0
          ? null
          : PointsRedemption(
              points: points,
              pointValue: config.business.loyalty.pointValue,
            ),
    );
    return await at(
      () => orders.complete(
        cart: cart,
        bill: bill,
        settlement: settle(bill.grandTotal, tenders(bill.grandTotal)),
        ctx: ctx,
      ),
      days: days,
    );
  }

  Future<int> balance() async =>
      (await db.select(db.localCustomers).getSingle()).pointsBalance;

  Future<List<Map<String, dynamic>>> queued(String kind) async => [
    for (final q in await (db.select(
      db.syncQueue,
    )..orderBy([(q) => OrderingTerm.asc(q.id)])).get())
      if ('${q.entity}.${q.action}' == kind)
        (jsonDecode(q.payload) as Map).cast<String, dynamic>(),
  ];

  group('points', () {
    test(
      'a sale earns ⌊net / Rp 10.000⌋ and redeems what was chosen',
      () async {
        // 10 x 3.500 = 35.000, minus 20 points (Rp 2.000): net 33.000 earns 3.
        final order = await sell(
          'o-1',
          10,
          (due) => [tender(TenderKind.cash, due.rupiah)],
          points: 20,
        );
        final payload = jsonDecode(order.payloadJson) as Map;
        expect(payload['points_redeemed'], 20);
        expect(payload['points_discount'], 2000);
        expect(payload['points_earned'], 3);
        expect(await balance(), 50 - 20 + 3);
      },
    );

    test('more than the balance, or below the minimum, is refused', () async {
      await expectLater(
        sell('o-1', 30, (d) => [tender(TenderKind.cash, d.rupiah)], points: 60),
        throwsA(isA<PosStateException>()),
      );
      await expectLater(
        sell('o-2', 10, (d) => [tender(TenderKind.cash, d.rupiah)], points: 5),
        throwsA(isA<PosStateException>()),
      );
      expect(await balance(), 50);
    });

    test('a void gives redeemed points back and takes earned ones', () async {
      final order = await sell(
        'o-1',
        10,
        (d) => [tender(TenderKind.cash, d.rupiah)],
        points: 20,
      );
      await at(() => orders.voidOrder(order: order, ctx: ctx, reason: 'Salah'));
      expect(await balance(), 50);
    });

    test('a refund takes back earned points in proportion', () async {
      // 30 x 3.500 = 105.000 earns 10. Refunding 10 of 30 (Rp 35.000)
      // takes back ⌊10 x 35.000 / 105.000⌋ = 3.
      final order = await sell(
        'o-1',
        30,
        (d) => [tender(TenderKind.cash, d.rupiah)],
      );
      expect(await balance(), 60);
      await at(
        () => refunds.refund(
          order: order,
          quantities: {'line-30': const Qty(10000)},
          methodType: 'cash',
          restock: false,
          reason: 'Rusak',
          approver: manager,
          ctx: ctx,
        ),
      );
      expect(await balance(), 57);
      expect(
        pointsReversedByRefunds(
          payload: {'points_earned': 10, 'grand_total': 105000},
          refundAmounts: [35000, 35000, 35000],
        ),
        [3, 3, 3],
      );
      expect(
        pointsReversedByRefunds(
          payload: {'points_earned': 10, 'grand_total': 105000},
          refundAmounts: [104999, 1],
        ),
        [9, 0],
      );
    });
  });

  group('kasbon', () {
    test(
      'installments go to the oldest kasbon first, then settle it',
      () async {
        // Rp 35.000 on kasbon, then Rp 7.000 a day later.
        await sell('o-1', 10, (d) => [tender(TenderKind.kasbon, d.rupiah)]);
        await sell(
          'o-2',
          2,
          (d) => [tender(TenderKind.kasbon, d.rupiah)],
          days: 1,
        );
        final debts = await kasbon.debts(rudi.id);
        expect(totalOutstanding(debts), const Money(42000));

        final first = await at(
          () => kasbon.repay(
            customerId: rudi.id,
            amount: const Money(15000),
            methodType: 'cash',
            ctx: ctx,
          ),
          days: 2,
        );
        expect(first.balanceBefore, const Money(42000));
        expect(first.balanceAfter, const Money(27000));
        expect(first.parts.single.orderId, 'o-1');

        await expectLater(
          kasbon.repay(
            customerId: rudi.id,
            amount: const Money(27001),
            methodType: 'transfer',
            ctx: ctx,
          ),
          throwsA(
            isA<RepaymentRejected>().having(
              (e) => e.problem,
              'problem',
              RepaymentProblem.exceedsBalance,
            ),
          ),
        );

        final second = await at(
          () => kasbon.repay(
            customerId: rudi.id,
            amount: const Money(27000),
            methodType: 'transfer',
            reference: ' TRF-01 ',
            ctx: ctx,
          ),
          days: 3,
        );
        expect(second.parts.map((p) => (p.orderId, p.amount.rupiah)), [
          ('o-1', 20000),
          ('o-2', 7000),
        ]);
        expect(second.balanceAfter, Money.zero);
        expect(await kasbon.debts(rudi.id), isEmpty);

        final sent = await queued('receivable_payment.create');
        expect(
          sent.map((p) => (p['order_id'], p['amount'], p['method_type'])),
          [
            ('o-1', 15000, 'cash'),
            ('o-1', 20000, 'transfer'),
            ('o-2', 7000, 'transfer'),
          ],
        );
        expect(sent.last['reference'], 'TRF-01');
        expect(sent.first['shift_id'], shift.id);

        final x = await shifts.report(shift, config: config);
        expect(x.kasbon.repaid, const Money(42000));
        expect(x.kasbon.repaidCash, const Money(15000));
        expect(
          x.cash.expected,
          const Money(115000),
          reason: '100.000 + 15.000',
        );
      },
    );

    test('cash needs a shift; staff need kasbon.manage', () async {
      await sell('o-1', 10, (d) => [tender(TenderKind.kasbon, d.rupiah)]);
      expect(
        () => kasbon.repay(
          customerId: rudi.id,
          amount: const Money(1000),
          methodType: 'cash',
          ctx: const SaleContext(
            config: config,
            deviceCode: 'T1',
            staff: cashier,
          ),
        ),
        throwsA(isA<PosStateException>()),
      );
      expect(
        () => kasbon.repay(
          customerId: rudi.id,
          amount: const Money(1000),
          methodType: 'cash',
          ctx: SaleContext(
            config: config,
            deviceCode: 'T1',
            staff: const StaffMember(
              employeeId: 'e-x',
              fullName: 'X',
              roleCode: 'cashier',
              permissions: {'pos.sell'},
              pinHash: null,
            ),
            shiftId: shift.id,
          ),
        ),
        throwsA(isA<PosPermissionException>()),
      );
    });

    test('a kasbon sale with installments cannot be voided', () async {
      final order = await sell(
        'o-1',
        10,
        (d) => [tender(TenderKind.kasbon, d.rupiah)],
      );
      await at(
        () => kasbon.repay(
          customerId: rudi.id,
          amount: const Money(5000),
          methodType: 'cash',
          ctx: ctx,
        ),
      );
      await expectLater(
        orders.voidOrder(order: order, ctx: ctx, reason: 'Batal'),
        throwsA(
          isA<PosStateException>().having(
            (e) => e.code,
            'code',
            'void_with_kasbon_payments',
          ),
        ),
      );
    });

    test('a void cancels an unpaid kasbon', () async {
      final order = await sell(
        'o-1',
        10,
        (d) => [tender(TenderKind.kasbon, d.rupiah)],
      );
      await at(() => orders.voidOrder(order: order, ctx: ctx, reason: 'Batal'));
      expect(await kasbon.debts(rudi.id), isEmpty);
    });

    test('repaid kasbon becomes refundable', () async {
      // Rp 35.000: Rp 10.000 cash, Rp 25.000 kasbon.
      final order = await sell(
        'o-1',
        10,
        (d) => [
          tender(TenderKind.cash, 10000),
          tender(TenderKind.kasbon, d.rupiah - 10000),
        ],
      );
      expect((await refunds.info(order)).refundable, const Money(10000));
      await at(
        () => kasbon.repay(
          customerId: rudi.id,
          amount: const Money(15000),
          methodType: 'cash',
          ctx: ctx,
        ),
      );
      expect((await refunds.info(order)).refundable, const Money(25000));
    });
  });
}
