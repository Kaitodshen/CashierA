import 'package:cashiera_core/cashiera_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// One row of `shift_overview`.
class ShiftOverviewRow {
  const new({
    required this.shiftId,
    required this.storeId,
    required this.storeName,
    required this.deviceCode,
    required this.status,
    required this.businessDate,
    required this.openedAt,
    required this.openedByName,
    required this.openingCash,
    required this.expectedCash,
    required this.orderCount,
    required this.salesTotal,
    this.closedAt,
    this.closedByName,
    this.countedCash,
    this.cashDifference,
  });

  factory fromJson(Map<String, dynamic> j) {
    Money? money(String k) =>
        j[k] == null ? null : Money((j[k] as num).toInt());
    return ShiftOverviewRow(
      shiftId: j['shift_id'] as String,
      storeId: j['store_id'] as String,
      storeName: j['store_name'] as String,
      deviceCode: j['device_code'] as String,
      status: j['status'] as String,
      businessDate: j['business_date'] as String,
      openedAt: DateTime.parse(j['opened_at'] as String),
      closedAt: j['closed_at'] == null
          ? null
          : DateTime.parse(j['closed_at'] as String),
      openedByName: j['opened_by_name'] as String,
      closedByName: j['closed_by_name'] as String?,
      openingCash: money('opening_cash')!,
      expectedCash: money('expected_cash')!,
      countedCash: money('counted_cash'),
      cashDifference: money('cash_difference'),
      orderCount: (j['order_count'] as num).toInt(),
      salesTotal: money('sales_total')!,
    );
  }

  final String shiftId;
  final String storeId;
  final String storeName;
  final String deviceCode;

  /// `open` or `closed`.
  final String status;
  final String businessDate;
  final DateTime openedAt;
  final DateTime? closedAt;
  final String openedByName;
  final String? closedByName;
  final Money openingCash;
  final Money expectedCash;
  final Money? countedCash;
  final Money? cashDifference;
  final int orderCount;
  final Money salesTotal;
}

/// One row of `audit_entries`.
class AuditEntry {
  const new({
    required this.id,
    required this.occurredAt,
    required this.action,
    this.storeName,
    this.deviceCode,
    this.actorName,
    this.approverName,
    this.entityType,
    this.details = const {},
  });

  factory fromJson(Map<String, dynamic> j) => AuditEntry(
    id: j['id'] as String,
    occurredAt: DateTime.parse(j['occurred_at'] as String),
    action: j['action'] as String,
    storeName: j['store_name'] as String?,
    deviceCode: j['device_code'] as String?,
    actorName: j['actor_name'] as String?,
    approverName: j['approver_name'] as String?,
    entityType: j['entity_type'] as String?,
    details: (j['details'] as Map? ?? const {}).cast<String, dynamic>(),
  );

  final String id;
  final DateTime occurredAt;
  final String action;
  final String? storeName;
  final String? deviceCode;
  final String? actorName;
  final String? approverName;
  final String? entityType;
  final Map<String, dynamic> details;
}

/// What the audit page asks for. [from] and [to] are instants; [to] is
/// exclusive.
class AuditQuery {
  const new({
    required this.from,
    required this.to,
    this.storeId,
    this.onlyApprovals = false,
    this.actionPrefix,
  });

  final String? storeId;
  final DateTime from;
  final DateTime to;
  final bool onlyApprovals;
  final String? actionPrefix;
}

String _date(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

class ShiftAuditRepository {
  new(this._client);

  final SupabaseClient _client;

  /// Shifts with a business date in [from]..[to] (inclusive dates).
  Future<List<ShiftOverviewRow>> shifts({
    required DateTime from,
    required DateTime to,
    String? storeId,
  }) async {
    final rows = await _client.rpc<List<dynamic>>(
      'shift_overview',
      params: {'p_store_id': storeId, 'p_from': _date(from), 'p_to': _date(to)},
    );
    return [
      for (final r in rows)
        ShiftOverviewRow.fromJson((r as Map).cast<String, dynamic>()),
    ];
  }

  Future<ShiftReport> shiftSummary(String shiftId) async {
    final json = await _client.rpc<dynamic>(
      'shift_summary',
      params: {'p_shift_id': shiftId},
    );
    return ShiftReport.fromJson((json as Map).cast<String, dynamic>());
  }

  /// One page of the audit log, newest first; pass the last entry shown as
  /// [after] for the next page.
  Future<List<AuditEntry>> audit(
    AuditQuery q, {
    AuditEntry? after,
    int limit = 50,
  }) async {
    final rows = await _client.rpc<List<dynamic>>(
      'audit_entries',
      params: {
        'p_store_id': q.storeId,
        'p_from': q.from.toUtc().toIso8601String(),
        'p_to': q.to.toUtc().toIso8601String(),
        'p_only_approvals': q.onlyApprovals,
        'p_action_prefix': q.actionPrefix,
        'p_limit': limit,
        'p_before': after?.occurredAt.toUtc().toIso8601String(),
        'p_before_id': after?.id,
      },
    );
    return [
      for (final r in rows)
        AuditEntry.fromJson((r as Map).cast<String, dynamic>()),
    ];
  }
}
