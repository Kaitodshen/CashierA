import 'package:cashiera_core/cashiera_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

Money? _money(Object? v) => v == null ? null : Money((v as num).toInt());

/// A customer as the back office edits it.
class AdminCustomer {
  new({
    required this.id,
    required this.name,
    this.code,
    this.phone,
    this.email,
    this.pointsBalance = 0,
    this.kasbonLimit,
    this.isActive = true,
  });

  factory fromJson(Map<String, dynamic> j) => AdminCustomer(
    id: j['id'] as String,
    code: j['code'] as String?,
    name: j['name'] as String,
    phone: j['phone'] as String?,
    email: j['email'] as String?,
    pointsBalance: (j['points_balance'] as num? ?? 0).toInt(),
    kasbonLimit: _money(j['kasbon_limit']),
    isActive: j['is_active'] as bool? ?? true,
  );

  final String id;
  final String? code;
  String name;
  String? phone;
  String? email;
  final int pointsBalance;

  /// Null = no limit.
  Money? kasbonLimit;
  bool isActive;

  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'phone': phone?.trim().isEmpty ?? true
        ? null
        : phone!.replaceAll(RegExp(r'[\s-]'), ''),
    'email': email?.trim().isEmpty ?? true ? null : email!.trim(),
    'kasbon_limit': kasbonLimit?.rupiah,
    'is_active': isActive,
  };
}

class StatementPayment {
  const new({
    required this.amount,
    required this.methodType,
    required this.paidAt,
    this.employeeName,
  });

  final Money amount;
  final String methodType;
  final DateTime paidAt;
  final String? employeeName;
}

class StatementKasbon {
  const new({
    required this.storeName,
    required this.orderNumber,
    required this.amount,
    required this.paid,
    required this.dueDate,
    required this.status,
    required this.payments,
  });

  final String storeName;
  final String orderNumber;
  final Money amount;
  final Money paid;
  final DateTime dueDate;

  /// `open`, `partial`, `paid` or `void`.
  final String status;
  final List<StatementPayment> payments;

  Money get remaining => status == 'void' || paid.rupiah >= amount.rupiah
      ? Money.zero
      : amount - paid;
}

class LedgerEntry {
  const new({
    required this.entryType,
    required this.points,
    required this.createdAt,
    this.note,
    this.orderNumber,
    this.storeName,
    this.employeeName,
  });

  /// `earn`, `redeem`, `reverse_earn`, `reverse_redeem` or `adjust`.
  final String entryType;
  final int points;
  final DateTime createdAt;
  final String? note;
  final String? orderNumber;
  final String? storeName;
  final String? employeeName;
}

/// `customer_statement`: the customer, their kasbon and points history.
class CustomerStatement {
  const new({
    required this.customer,
    required this.kasbon,
    required this.ledger,
  });

  factory fromJson(Map<String, dynamic> j) {
    Map<String, dynamic> m(Object? v) => (v! as Map).cast<String, dynamic>();
    return CustomerStatement(
      customer: AdminCustomer.fromJson(m(j['customer'])),
      kasbon: [
        for (final raw in j['kasbon'] as List? ?? const [])
          () {
            final k = m(raw);
            return StatementKasbon(
              storeName: k['store_name'] as String,
              orderNumber: k['order_number'] as String,
              amount: _money(k['amount'])!,
              paid: _money(k['paid_amount'])!,
              dueDate: DateTime.parse('${k['due_date']}T00:00:00Z'),
              status: k['status'] as String,
              payments: [
                for (final p in k['payments'] as List? ?? const [])
                  StatementPayment(
                    amount: _money(m(p)['amount'])!,
                    methodType: m(p)['method_type'] as String,
                    paidAt: DateTime.parse(m(p)['paid_at'] as String),
                    employeeName: m(p)['employee_name'] as String?,
                  ),
              ],
            );
          }(),
      ],
      ledger: [
        for (final raw in j['ledger'] as List? ?? const [])
          () {
            final l = m(raw);
            return LedgerEntry(
              entryType: l['entry_type'] as String,
              points: (l['points'] as num).toInt(),
              createdAt: DateTime.parse(l['created_at'] as String),
              note: l['note'] as String?,
              orderNumber: l['order_number'] as String?,
              storeName: l['store_name'] as String?,
              employeeName: l['employee_name'] as String?,
            );
          }(),
      ],
    );
  }

  final AdminCustomer customer;
  final List<StatementKasbon> kasbon;
  final List<LedgerEntry> ledger;

  Money get outstanding => kasbon.fold(Money.zero, (a, k) => a + k.remaining);
}

/// One row of `kasbon_overview`.
class KasbonOverviewRow {
  const new({
    required this.storeName,
    required this.customerId,
    required this.customerName,
    required this.openCount,
    required this.outstanding,
    required this.overdue,
    required this.oldestDue,
    this.customerPhone,
    this.kasbonLimit,
  });

  factory fromJson(Map<String, dynamic> j) => KasbonOverviewRow(
    storeName: j['store_name'] as String,
    customerId: j['customer_id'] as String,
    customerName: j['customer_name'] as String,
    customerPhone: j['customer_phone'] as String?,
    kasbonLimit: _money(j['kasbon_limit']),
    openCount: (j['open_count'] as num).toInt(),
    outstanding: _money(j['outstanding'])!,
    overdue: _money(j['overdue'])!,
    oldestDue: DateTime.parse('${j['oldest_due']}T00:00:00Z'),
  );

  final String storeName;
  final String customerId;
  final String customerName;
  final String? customerPhone;
  final Money? kasbonLimit;
  final int openCount;
  final Money outstanding;
  final Money overdue;
  final DateTime oldestDue;
}

/// Company loyalty and kasbon settings (`business_profile`).
class LoyaltySettings {
  new({
    required this.enabled,
    required this.earnAmount,
    required this.pointValue,
    required this.minRedeemPoints,
    required this.kasbonDueDays,
  });

  factory fromJson(Map<String, dynamic> j) => LoyaltySettings(
    enabled: j['loyalty_enabled'] as bool,
    earnAmount: (j['loyalty_earn_amount'] as num).toInt(),
    pointValue: (j['loyalty_point_value'] as num).toInt(),
    minRedeemPoints: (j['loyalty_min_redeem_points'] as num).toInt(),
    kasbonDueDays: (j['kasbon_default_due_days'] as num).toInt(),
  );

  bool enabled;
  int earnAmount;
  int pointValue;
  int minRedeemPoints;
  int kasbonDueDays;

  Map<String, dynamic> toJson() => {
    'loyalty_enabled': enabled,
    'loyalty_earn_amount': earnAmount,
    'loyalty_point_value': pointValue,
    'loyalty_min_redeem_points': minRedeemPoints,
    'kasbon_default_due_days': kasbonDueDays,
  };
}

class CustomersAdminRepository {
  new(this._client, {this._uuid = const Uuid()});

  final SupabaseClient _client;
  final Uuid _uuid;

  static const _columns =
      'id, code, name, phone, email, points_balance, kasbon_limit, is_active';

  /// Customers matching [query] (name, phone or code), at most 200.
  Future<List<AdminCustomer>> customers(String query) async {
    final q = query.trim().replaceAll(RegExp('[,()%*]'), ' ').trim();
    var select = _client.from('customers').select(_columns);
    if (q.isNotEmpty) {
      select = select.or('name.ilike.*$q*,phone.ilike.*$q*,code.ilike.*$q*');
    }
    final rows = await select.order('name').limit(200);
    return rows.map(AdminCustomer.fromJson).toList();
  }

  /// Creates [c] when [isNew], else updates it.
  Future<void> save(AdminCustomer c, {required bool isNew}) async {
    if (isNew) {
      await _client.from('customers').insert({'id': c.id, ...c.toJson()});
    } else {
      await _client.from('customers').update(c.toJson()).eq('id', c.id);
    }
  }

  String newId() => _uuid.v7();

  Future<CustomerStatement> statement(String customerId) async {
    final json = await _client.rpc<dynamic>(
      'customer_statement',
      params: {'p_customer_id': customerId},
    );
    return CustomerStatement.fromJson((json as Map).cast<String, dynamic>());
  }

  /// Returns the new balance.
  Future<int> adjustPoints(String customerId, int points, String note) async {
    final json = await _client.rpc<dynamic>(
      'adjust_points',
      params: {'p_customer_id': customerId, 'p_points': points, 'p_note': note},
    );
    return ((json as Map)['points_balance'] as num).toInt();
  }

  Future<List<KasbonOverviewRow>> kasbonOverview({String? storeId}) async {
    final rows = await _client.rpc<List<dynamic>>(
      'kasbon_overview',
      params: {'p_store_id': storeId},
    );
    return [
      for (final r in rows)
        KasbonOverviewRow.fromJson((r as Map).cast<String, dynamic>()),
    ];
  }

  Future<LoyaltySettings> loyaltySettings() async {
    final row = await _client
        .from('business_profile')
        .select(
          'loyalty_enabled, loyalty_earn_amount, loyalty_point_value, '
          'loyalty_min_redeem_points, kasbon_default_due_days',
        )
        .eq('id', 1)
        .single();
    return LoyaltySettings.fromJson(row);
  }

  Future<void> saveLoyaltySettings(LoyaltySettings s) =>
      _client.from('business_profile').update(s.toJson()).eq('id', 1);
}
