import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/pos/pos_services.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Payment types a kasbon installment can be paid with.
const kasbonRepaymentMethods = ['cash', 'qris', 'card', 'transfer', 'ewallet'];

/// What a repayment did, for the balance slip.
class RepaymentResult {
  const new({
    required this.customerId,
    required this.amount,
    required this.methodType,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.parts,
    required this.paidAt,
    this.reference,
  });

  final String customerId;
  final Money amount;
  final String methodType;
  final String? reference;
  final Money balanceBefore;
  final Money balanceAfter;

  /// (order id, amount) per kasbon paid, oldest due first.
  final List<RepaymentPart> parts;
  final DateTime paidAt;
}

/// Kasbon of this store's customers: what they owe and their installments
/// (`receivable_payment.create`, one per kasbon paid). Works offline.
class KasbonService {
  new(this._db, {this._uuid = const Uuid()});

  final AppDatabase _db;
  final Uuid _uuid;

  Stream<List<ReceivableRow>> watchOpen(String customerId) =>
      (_db.select(_db.localReceivables)
            ..where(
              (r) =>
                  r.customerId.equals(customerId) &
                  r.status.isIn(const ['open', 'partial']),
            )
            ..orderBy([(r) => OrderingTerm.asc(r.dueDate)]))
          .watch();

  /// Outstanding kasbon per customer of this store (for the customer list).
  Stream<Map<String, Money>> watchOutstanding() =>
      (_db.select(_db.localReceivables)
            ..where((r) => r.status.isIn(const ['open', 'partial'])))
          .watch()
          .map((rows) {
            final out = <String, Money>{};
            for (final r in rows) {
              final left = r.amount - r.paidAmount;
              if (left <= 0) continue;
              final had = out[r.customerId] ?? Money.zero;
              out[r.customerId] = had + Money(left);
            }
            return out;
          });

  Stream<List<ReceivablePaymentRow>> watchPayments(String customerId) =>
      (_db.select(_db.localReceivablePayments)
            ..where((p) => p.customerId.equals(customerId))
            ..orderBy([(p) => OrderingTerm.desc(p.paidAt)]))
          .watch();

  Future<List<KasbonDebt>> debts(String customerId) async => [
    for (final r
        in await (_db.select(_db.localReceivables)..where(
              (r) =>
                  r.customerId.equals(customerId) &
                  r.status.isIn(const ['open', 'partial']),
            ))
            .get())
      KasbonDebt(
        orderId: r.orderId,
        amount: Money(r.amount),
        paid: Money(r.paidAmount),
        dueDate: r.dueDate,
      ),
  ];

  /// Takes [amount] from the customer and spreads it over their kasbon,
  /// the oldest due first. Cash goes into the open shift's drawer.
  Future<RepaymentResult> repay({
    required String customerId,
    required Money amount,
    required String methodType,
    required SaleContext ctx,
    String? reference,
  }) async {
    if (!ctx.staff.can('kasbon.manage')) {
      throw const PosPermissionException('kasbon.manage');
    }
    if (!kasbonRepaymentMethods.contains(methodType)) {
      throw const PosStateException('refund_method');
    }
    if (methodType == 'cash' && ctx.shiftId == null) {
      throw const PosStateException('shift_required');
    }
    final ref = reference?.trim().isEmpty ?? true ? null : reference!.trim();
    return await _db.transaction(() async {
      final plan = allocateRepayment(await debts(customerId), amount);
      if (plan.problem != null) throw RepaymentRejected(plan.problem!);
      final now = clock.now();
      for (final part in plan.parts) {
        final id = _uuid.v7();
        await _db
            .into(_db.localReceivablePayments)
            .insert(
              ReceivablePaymentRow(
                id: id,
                orderId: part.orderId,
                customerId: customerId,
                shiftId: ctx.shiftId,
                amount: part.amount.rupiah,
                methodType: methodType,
                reference: ref,
                employeeName: ctx.staff.fullName,
                paidAt: now,
              ),
            );
        final row = await (_db.select(
          _db.localReceivables,
        )..where((r) => r.orderId.equals(part.orderId))).getSingle();
        final paid = row.paidAmount + part.amount.rupiah;
        await (_db.update(
          _db.localReceivables,
        )..where((r) => r.orderId.equals(part.orderId))).write(
          LocalReceivablesCompanion(
            paidAmount: Value(paid),
            status: Value(paid >= row.amount ? 'paid' : 'partial'),
            updatedAt: Value(now),
          ),
        );
        await _db.syncQueueDao.enqueue(
          entity: 'receivable_payment',
          action: 'create',
          clientUuid: _uuid.v7(),
          payload: {
            'id': id,
            'order_id': part.orderId,
            'amount': part.amount.rupiah,
            'method_type': methodType,
            'reference': ref,
            'employee_id': ctx.staff.employeeId,
            'shift_id': ctx.shiftId,
            'paid_at': now.toUtc().toIso8601String(),
          },
        );
      }
      return RepaymentResult(
        customerId: customerId,
        amount: amount,
        methodType: methodType,
        reference: ref,
        balanceBefore: plan.balanceBefore,
        balanceAfter: plan.balanceAfter,
        parts: plan.parts,
        paidAt: now,
      );
    });
  }
}
