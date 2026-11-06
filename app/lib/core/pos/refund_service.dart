import 'dart:convert';

import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/pos/cart.dart';
import 'package:cashiera/core/pos/pos_services.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Payment types a refund can go back on (kasbon is never paid out).
const refundMethodTypes = ['cash', 'qris', 'card', 'transfer', 'ewallet'];

/// One sold line as the refund screen shows it.
class RefundLineInfo {
  const new({
    required this.line,
    required this.name,
    required this.allowDecimal,
    required this.unitCode,
  });

  final RefundableLine line;
  final String name;
  final bool allowDecimal;
  final String unitCode;
}

/// What can still be refunded on an order.
class OrderRefundInfo {
  const new({
    required this.lines,
    required this.refundable,
    required this.refunds,
    required this.paidMethodTypes,
  });

  final List<RefundLineInfo> lines;

  /// Money received (non-kasbon payments) minus earlier refunds.
  final Money refundable;
  final List<RefundRow> refunds;

  /// Method types the customer paid with, kasbon excluded.
  final Set<String> paidMethodTypes;

  bool get fullyRefunded =>
      refundable.rupiah <= 0 ||
      lines.every((l) => l.line.remainingQuantity.milli <= 0);
}

/// Earned points taken back by each refund of a sale, in order: each is
/// ⌊earned × amount / grand total⌋, never more than is left
/// (`app.sync_refund_create`).
List<int> pointsReversedByRefunds({
  required Map<String, dynamic> payload,
  required List<int> refundAmounts,
}) {
  final earned = (payload['points_earned'] as num? ?? 0).toInt();
  final grand = (payload['grand_total'] as num? ?? 0).toInt();
  var taken = 0;
  return [
    for (final amount in refundAmounts)
      () {
        if (earned <= 0 || grand <= 0) return 0;
        final share = earned * amount ~/ grand;
        final points = share < earned - taken ? share : earned - taken;
        taken += points;
        return points < 0 ? 0 : points;
      }(),
  ];
}

/// Gives money back for part or all of a completed sale (`refund.create`).
/// Every refund needs someone with `pos.refund` to enter their PIN.
class RefundService {
  new(this._db, {this._uuid = const Uuid()});

  final AppDatabase _db;
  final Uuid _uuid;

  Stream<List<RefundRow>> watchForOrder(String orderId) =>
      (_db.select(_db.localRefunds)
            ..where((r) => r.orderId.equals(orderId))
            ..orderBy([(r) => OrderingTerm.asc(r.refundedAt)]))
          .watch();

  Future<OrderRefundInfo> info(LocalOrderRow order) async {
    final payload = (jsonDecode(order.payloadJson) as Map)
        .cast<String, dynamic>();
    final cart = Cart.fromJson(
      (jsonDecode(order.cartJson) as Map).cast<String, dynamic>(),
    );
    final cartLines = {for (final l in cart.lines) l.id: l};
    final refunds = await (_db.select(
      _db.localRefunds,
    )..where((r) => r.orderId.equals(order.id))).get();

    final refundedQty = <String, int>{};
    final refundedAmount = <String, int>{};
    for (final r in refunds) {
      for (final raw in jsonDecode(r.itemsJson) as List) {
        final item = (raw as Map).cast<String, dynamic>();
        final id = item['order_item_id'] as String;
        refundedQty[id] =
            (refundedQty[id] ?? 0) +
            Qty.parse(item['quantity'] as String).milli;
        refundedAmount[id] =
            (refundedAmount[id] ?? 0) + (item['amount'] as num).toInt();
      }
    }

    final lines = <RefundLineInfo>[];
    for (final raw in payload['items'] as List) {
      final item = (raw as Map).cast<String, dynamic>();
      final id = item['id'] as String;
      final variant = item['variant_name'] as String?;
      final cartLine = cartLines[id];
      lines.add(
        RefundLineInfo(
          line: RefundableLine(
            id: id,
            net: Money((item['net_amount'] as num).toInt()),
            quantity: Qty.parse(item['quantity'] as String),
            refundedQuantity: Qty(refundedQty[id] ?? 0),
            refundedAmount: Money(refundedAmount[id] ?? 0),
          ),
          name: variant == null || variant == 'Default'
              ? item['product_name'] as String
              : '${item['product_name']} $variant',
          allowDecimal: cartLine?.allowDecimal ?? false,
          unitCode: cartLine?.unitCode ?? 'pcs',
        ),
      );
    }
    final kasbon = await (_db.select(
      _db.localReceivables,
    )..where((r) => r.orderId.equals(order.id))).getSingleOrNull();
    // Money received: the non-kasbon payments plus kasbon already repaid.
    final paid =
        (payload['paid_total'] as num? ?? 0).toInt() +
        (kasbon?.paidAmount ?? 0);
    final refunded = refunds.fold(0, (a, r) => a + r.amount);
    return OrderRefundInfo(
      lines: lines,
      refundable: Money(paid - refunded),
      refunds: refunds,
      paidMethodTypes: {
        for (final p in payload['payments'] as List? ?? const [])
          if ((p as Map)['method_type'] != 'kasbon') p['method_type'] as String,
      },
    );
  }

  /// Refunds [quantities] (order item id → quantity) of [order] on
  /// [methodType]. Cash comes out of the open shift's drawer. With
  /// [restock] the items go back on the shelf.
  Future<RefundRow> refund({
    required LocalOrderRow order,
    required Map<String, Qty> quantities,
    required String methodType,
    required bool restock,
    required String reason,
    required StaffMember approver,
    required SaleContext ctx,
  }) async {
    if (order.status != 'completed') {
      throw const PosStateException('not_completed');
    }
    if (!ctx.staff.can('pos.sell')) {
      throw const PosPermissionException('pos.sell');
    }
    if (!approver.can('pos.refund')) {
      throw const PosPermissionException('pos.refund');
    }
    if (!refundMethodTypes.contains(methodType)) {
      throw const PosStateException('refund_method');
    }
    if (methodType == 'cash' && ctx.shiftId == null) {
      throw const PosStateException('shift_required');
    }
    final why = reason.trim();
    if (why.length < 3) throw const PosStateException('reason_required');

    return await _db.transaction(() async {
      final current = await info(order);
      final plan = planRefund(
        lines: [for (final l in current.lines) l.line],
        quantities: quantities,
        refundable: current.refundable,
      );
      if (plan.problem != null) throw RefundRejected(plan.problem!);

      final now = clock.now();
      final number = await nextDocumentNumber(_db, ctx, now, kind: 'refund');
      final items = [
        for (final i in plan.items)
          {
            'id': _uuid.v7(),
            'order_item_id': i.lineId,
            'quantity': i.quantity.toPayload(),
            'amount': i.amount.rupiah,
          },
      ];
      final row = RefundRow(
        id: _uuid.v7(),
        orderId: order.id,
        shiftId: ctx.shiftId,
        refundNumber: number,
        amount: plan.total.rupiah,
        methodType: methodType,
        restock: restock,
        reason: why,
        itemsJson: jsonEncode(items),
        employeeName: ctx.staff.fullName,
        approvedByName: approver.fullName,
        refundedAt: now,
      );
      final reversed = pointsReversedByRefunds(
        payload: (jsonDecode(order.payloadJson) as Map).cast<String, dynamic>(),
        refundAmounts: [
          for (final r in current.refunds) r.amount,
          plan.total.rupiah,
        ],
      );
      final customerId =
          (jsonDecode(order.payloadJson) as Map)['customer_id'] as String?;
      if (customerId != null && reversed.last > 0) {
        await _db.customUpdate(
          'UPDATE local_customers SET points_balance = points_balance - ? '
          'WHERE id = ?',
          variables: [
            Variable.withInt(reversed.last),
            Variable.withString(customerId),
          ],
          updates: {_db.localCustomers},
        );
      }
      await _db.into(_db.localRefunds).insert(row);

      if (restock) {
        final cart = Cart.fromJson(
          (jsonDecode(order.cartJson) as Map).cast<String, dynamic>(),
        );
        final byId = {for (final l in cart.lines) l.id: l};
        for (final i in plan.items) {
          final line = byId[i.lineId];
          if (line == null || !line.trackStock) continue;
          await _db.customUpdate(
            'UPDATE stock_levels SET quantity_milli = quantity_milli + ? '
            'WHERE variant_id = ?',
            variables: [
              Variable.withInt(i.quantity.milli),
              Variable.withString(line.variantId),
            ],
            updates: {_db.stockLevels},
          );
        }
      }

      await _db.syncQueueDao.enqueue(
        entity: 'refund',
        action: 'create',
        clientUuid: _uuid.v7(),
        payload: {
          'id': row.id,
          'order_id': order.id,
          'refund_number': number,
          'reason': why,
          'amount': plan.total.rupiah,
          'method_type': methodType,
          'restock': restock,
          'employee_id': ctx.staff.employeeId,
          'approved_by': approver.employeeId,
          'shift_id': ctx.shiftId,
          'refunded_at': now.toUtc().toIso8601String(),
          'items': items,
        },
      );
      return row;
    });
  }
}
