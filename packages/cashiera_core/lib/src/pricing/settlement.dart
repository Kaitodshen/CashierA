import 'package:cashiera_core/src/money.dart';

/// `payment_methods.method_type`.
enum TenderKind {
  cash,
  qris,
  card,
  transfer,
  ewallet,
  kasbon;

  String get code => name;

  static TenderKind fromCode(String code) =>
      values.firstWhere((k) => k.name == code);
}

/// What the cashier entered for one payment. For cash, [amount] is what the
/// customer handed over; for everything else it is the amount charged.
class Tender {
  const new({
    required this.id,
    required this.methodId,
    required this.kind,
    required this.amount,
    this.reference,
    this.provider,
    this.providerRef,
  });

  final String id;
  final String methodId;
  final TenderKind kind;
  final Money amount;
  final String? reference;

  /// Set when a payment gateway confirmed it (`midtrans`); [id] is then the
  /// gateway charge id and [amount] can't change.
  final String? provider;
  final String? providerRef;

  bool get isGateway => provider != null;

  Tender copyWith({Money? amount, String? reference}) => Tender(
    id: id,
    methodId: methodId,
    kind: kind,
    amount: amount ?? this.amount,
    reference: reference ?? this.reference,
    provider: provider,
    providerRef: providerRef,
  );
}

/// A tender as booked on the bill (`payments` row).
class SettledPayment {
  const new({
    required this.tender,
    required this.amount,
    required this.change,
    this.tendered,
  });

  final Tender tender;

  /// Applied to the bill.
  final Money amount;

  /// Cash only: what was handed over.
  final Money? tendered;
  final Money change;
}

enum SettlementProblem {
  invalidAmount,
  nonCashExceedsDue,
  multipleKasbon,
  unneededTender,
}

class Settlement {
  const new({required this.payments, required this.remaining, this.problem});

  final List<SettledPayment> payments;

  /// Still to pay; 0 when the bill is covered.
  final Money remaining;
  final SettlementProblem? problem;

  bool get isComplete => problem == null && remaining.rupiah == 0;

  /// Non-kasbon payments (`orders.paid_total`).
  Money get paidTotal => Money(
    payments
        .where((p) => p.tender.kind != TenderKind.kasbon)
        .fold(0, (a, p) => a + p.amount.rupiah),
  );

  Money get changeTotal =>
      Money(payments.fold(0, (a, p) => a + p.change.rupiah));

  Money get kasbonAmount => Money(
    payments
        .where((p) => p.tender.kind == TenderKind.kasbon)
        .fold(0, (a, p) => a + p.amount.rupiah),
  );
}

/// Books [tenders] against [grandTotal]. Non-cash tenders are charged as
/// entered and may not exceed what is due; cash covers the rest and is the
/// only source of change (the database's `payments_cash_chk`).
Settlement settle(Money grandTotal, List<Tender> tenders) {
  Settlement fail(SettlementProblem p) =>
      Settlement(payments: const [], remaining: grandTotal, problem: p);

  if (tenders.any((t) => t.amount.rupiah <= 0)) {
    return fail(SettlementProblem.invalidAmount);
  }
  if (tenders.where((t) => t.kind == TenderKind.kasbon).length > 1) {
    return fail(SettlementProblem.multipleKasbon);
  }

  final nonCash = tenders.where((t) => t.kind != TenderKind.cash);
  final nonCashTotal = nonCash.fold(0, (a, t) => a + t.amount.rupiah);
  if (nonCashTotal > grandTotal.rupiah) {
    return fail(SettlementProblem.nonCashExceedsDue);
  }

  var dueForCash = grandTotal.rupiah - nonCashTotal;
  final payments = <SettledPayment>[];
  for (final t in tenders) {
    if (t.kind != TenderKind.cash) {
      payments.add(
        SettledPayment(tender: t, amount: t.amount, change: Money.zero),
      );
      continue;
    }
    final applied = t.amount.rupiah < dueForCash ? t.amount.rupiah : dueForCash;
    if (applied == 0) return fail(SettlementProblem.unneededTender);
    dueForCash -= applied;
    payments.add(
      SettledPayment(
        tender: t,
        amount: Money(applied),
        tendered: t.amount,
        change: Money(t.amount.rupiah - applied),
      ),
    );
  }

  return Settlement(payments: payments, remaining: Money(dueForCash));
}
