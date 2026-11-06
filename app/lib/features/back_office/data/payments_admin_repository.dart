import 'package:cashiera_core/cashiera_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// One dynamic QRIS charge (`gateway_charge_list`).
class GatewayChargeRow {
  new fromJson(Map<String, dynamic> j)
    : id = j['charge_id'] as String,
      storeCode = j['store_code'] as String,
      orderNumber = j['order_number'] as String?,
      amount = Money((j['amount'] as num).toInt()),
      status = j['status'] as String,
      providerRef = j['provider_ref'] as String?,
      createdAt = DateTime.parse(j['created_at'] as String),
      paidAt = j['paid_at'] == null
          ? null
          : DateTime.parse(j['paid_at'] as String),
      matched = j['matched'] as bool? ?? false;

  final String id;
  final String storeCode;
  final String? orderNumber;
  final Money amount;

  /// pending, paid, failed, expired or cancelled.
  final String status;
  final String? providerRef;
  final DateTime createdAt;
  final DateTime? paidAt;

  /// A sale booked this payment.
  final bool matched;

  /// Money arrived but no sale booked it: reconcile or refund at Midtrans.
  bool get unmatched => status == 'paid' && !matched;
}

class PaymentsAdminRepository {
  new(this._client);

  final SupabaseClient _client;

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<List<GatewayChargeRow>> gatewayCharges({
    required DateTime from,
    required DateTime to,
    String? storeId,
  }) async {
    final rows = await _client.rpc<List<dynamic>>(
      'gateway_charge_list',
      params: {'p_store_id': storeId, 'p_from': _date(from), 'p_to': _date(to)},
    );
    return [
      for (final r in rows)
        GatewayChargeRow.fromJson((r as Map).cast<String, dynamic>()),
    ];
  }
}
