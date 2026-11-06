import 'package:cashiera/core/pos/cart.dart';
import 'package:cashiera/core/pos/pos_config.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:uuid/uuid.dart';

/// `order.upsert` status values the terminal sends.
enum OrderStatus {
  held,
  completed,
  cancelled;

  String get code => name;
}

/// Who cancelled a held bill, and who approved it if they could not.
class CancelInfo {
  const new({
    required this.cancelledBy,
    required this.reason,
    required this.at,
    this.approvedBy,
  });

  final String cancelledBy;
  final String reason;
  final DateTime at;
  final String? approvedBy;
}

/// Builds the `order.upsert` payload (supabase/README §5) from a priced cart.
/// The money fields come straight from [bill] and [settlement], which follow
/// the same rules as `app.validate_order_totals`.
Map<String, dynamic> buildOrderPayload({
  required Cart cart,
  required Bill bill,
  required PosConfig config,
  required String cashierId,
  required String orderNumber,
  required OrderStatus status,
  required int version,
  String? shiftId,
  Settlement? settlement,
  DateTime? completedAt,
  CancelInfo? cancel,
  Uuid uuid = const Uuid(),
}) {
  String iso(DateTime t) => t.toUtc().toIso8601String();
  final linesById = {for (final l in cart.lines) l.id: l};
  final hasKasbon =
      settlement?.payments.any((p) => p.tender.kind == TenderKind.kasbon) ??
      false;
  final dueDate = hasKasbon
      ? config
            .businessDate(completedAt ?? cart.startedAt)
            .add(Duration(days: config.business.kasbonDueDays))
      : null;

  return {
    'id': cart.orderId,
    'store_id': config.storeId,
    'shift_id': shiftId,
    'cashier_id': cashierId,
    'order_number': orderNumber,
    'order_type': 'takeaway',
    'status': status.code,
    'version': version,
    'customer_id': cart.customer?.id,
    'note': cart.note,
    'ordered_at': iso(cart.startedAt),
    'completed_at': completedAt == null ? null : iso(completedAt),
    'gross_total': bill.gross.rupiah,
    'item_discount_total': bill.itemDiscount.rupiah,
    'bill_discount_total': bill.billDiscount.rupiah,
    'points_redeemed': bill.pointsRedeemed,
    'points_discount': bill.pointsDiscount.rupiah,
    'net_total': bill.net.rupiah,
    'service_charge_total': bill.serviceCharge.rupiah,
    'tax_total': bill.tax.rupiah,
    'tax_inclusive': config.pricing.taxInclusive,
    'tax_rate_bps': config.pricing.taxRateBps,
    'service_charge_bps': config.pricing.serviceChargeBps,
    'service_charge_taxable': config.pricing.serviceChargeTaxable,
    'rounding_amount': bill.rounding.rupiah,
    'grand_total': bill.grandTotal.rupiah,
    'paid_total': settlement?.paidTotal.rupiah ?? 0,
    'change_total': settlement?.changeTotal.rupiah ?? 0,
    'points_earned': cart.customer == null
        ? 0
        : config.business.loyalty.pointsEarned(bill.net),
    'kasbon_due_date': dueDate?.toIso8601String().substring(0, 10),
    'items': [
      for (final (i, b) in bill.lines.indexed)
        _item(linesById[b.id]!, b, i, uuid),
    ],
    'discounts': [
      for (final d in bill.discounts)
        {
          'id': uuid.v7(),
          'order_item_id': d.lineId,
          'source': d.source.code,
          'promotion_id': d.promotionId,
          'voucher_id': d.voucherId,
          'description': d.description,
          'amount': d.amount.rupiah,
          'discount_bps': d.bps,
          'approved_by': d.source == DiscountSource.manual
              ? cart.approvedBy
              : null,
        },
    ],
    'payments': [
      for (final p in settlement?.payments ?? const <SettledPayment>[])
        {
          'id': p.tender.id,
          'payment_method_id': p.tender.methodId,
          'method_type': p.tender.kind.code,
          'amount': p.amount.rupiah,
          'tendered_amount': p.tendered?.rupiah,
          'change_amount': p.change.rupiah,
          'reference': p.tender.reference,
          'status': 'paid',
          'paid_at': completedAt == null ? null : iso(completedAt),
        },
    ],
    if (cancel != null)
      'cancel': {
        'cancelled_by': cancel.cancelledBy,
        'reason': cancel.reason,
        'approved_by': cancel.approvedBy,
        'cancelled_at': iso(cancel.at),
      },
  };
}

Map<String, dynamic> _item(CartLine line, BillLine b, int index, Uuid uuid) => {
  'id': line.id,
  'product_id': line.productId,
  'variant_id': line.variantId,
  'product_name': line.productName,
  'variant_name': line.variantName,
  'sku': line.sku,
  'quantity': line.quantity.toPayload(),
  'unit_price': line.unitPrice.rupiah,
  'modifiers_unit_total': line.modifiersUnitTotal.rupiah,
  'gross_amount': b.gross.rupiah,
  'item_discount_amount': b.itemDiscount.rupiah,
  'bill_discount_amount': b.billDiscount.rupiah,
  'net_amount': b.net.rupiah,
  'tax_amount': b.tax.rupiah,
  'is_taxable': line.isTaxable,
  'unit_cost': line.unitCost.rupiah,
  'cost_amount': line.quantity.times(line.unitCost).rupiah,
  'note': line.note,
  'sort_order': index,
  'modifiers': [
    for (final m in line.modifiers)
      {
        'id': uuid.v7(),
        'modifier_id': m.modifierId,
        'group_name': m.groupName,
        'modifier_name': m.name,
        'price_delta': m.priceDelta.rupiah,
      },
  ],
};
