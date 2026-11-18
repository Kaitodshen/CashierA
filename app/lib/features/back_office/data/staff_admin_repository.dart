import 'package:cashiera/core/auth/models.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// A store as the owner manages it.
@immutable
class AdminStore {
  const new({
    required this.id,
    required this.code,
    required this.name,
    required this.timezone,
    required this.isActive,
    this.address,
    this.phone,
  });

  factory fromJson(Map<String, dynamic> j) => AdminStore(
    id: j['id'] as String,
    code: j['code'] as String,
    name: j['name'] as String,
    address: j['address'] as String?,
    phone: j['phone'] as String?,
    timezone: j['timezone'] as String? ?? 'Asia/Jakarta',
    isActive: j['is_active'] as bool? ?? true,
  );

  final String id;
  final String code;
  final String name;
  final String? address;
  final String? phone;
  final String timezone;
  final bool isActive;
}

/// What the store editor saves. [code] is ignored on update.
@immutable
class StoreInput {
  const new({
    required this.code,
    required this.name,
    required this.timezone,
    this.address,
    this.phone,
    this.isActive = true,
  });

  final String code;
  final String name;
  final String? address;
  final String? phone;
  final String timezone;
  final bool isActive;
}

/// A staff member with their PIN and back-office login state.
@immutable
class AdminStaff {
  const new({
    required this.id,
    required this.fullName,
    required this.roleCode,
    required this.roleName,
    required this.storeIds,
    required this.hasLogin,
    required this.loginConfirmed,
    required this.hasPin,
    required this.isActive,
    this.phone,
    this.email,
  });

  final String id;
  final String fullName;
  final String? phone;
  final String roleCode;
  final String roleName;
  final List<String> storeIds;
  final String? email;
  final bool hasLogin;
  final bool loginConfirmed;
  final bool hasPin;
  final bool isActive;

  bool get isOwner => roleCode == 'owner';
}

/// What the staff editor saves.
@immutable
class StaffInput {
  const new({
    required this.fullName,
    required this.roleCode,
    required this.storeIds,
    this.phone,
    this.isActive = true,
  });

  final String fullName;
  final String? phone;
  final String roleCode;
  final List<String> storeIds;
  final bool isActive;
}

/// Roles the back office may give; owner is never offered.
const staffRoles = ['manager', 'cashier', 'kitchen', 'inventory'];

/// Store codes: 2–5 capital letters or digits.
final storeCodePattern = RegExp(r'^[A-Z0-9]{2,5}$');

/// Stores, staff, PINs and invitations for the back office. Failures come
/// back as [BackendException] with the server's code.
abstract interface class StaffAdmin {
  Future<List<AdminStore>> stores();
  Future<void> addStore(StoreInput input);
  Future<void> updateStore(String id, StoreInput input);

  Future<List<AdminStaff>> staff();
  Future<void> saveStaff(StaffInput input, {String? id});
  Future<void> setActive(String id, {required bool isActive});
  Future<void> setPin(String id, String pin);
  Future<void> invite(String id, String email);
}

class SupabaseStaffAdmin implements StaffAdmin {
  new(this._client, {this._uuid = const Uuid()});

  final SupabaseClient _client;
  final Uuid _uuid;

  @override
  Future<List<AdminStore>> stores() => _guard(() async {
    final rows = await _client
        .from('stores')
        .select('id, code, name, address, phone, timezone, is_active')
        .order('code');
    return rows.map(AdminStore.fromJson).toList();
  });

  Map<String, dynamic> _storeFields(StoreInput s) => {
    'name': s.name.trim(),
    'address': _blankToNull(s.address),
    'phone': _blankToNull(s.phone),
    'timezone': s.timezone,
    'is_active': s.isActive,
  };

  @override
  Future<void> addStore(StoreInput input) => _guard(() async {
    await _client.from('stores').insert({
      'id': _uuid.v7(),
      'code': input.code.trim().toUpperCase(),
      ..._storeFields(input),
    });
  });

  @override
  Future<void> updateStore(String id, StoreInput input) => _guard(() async {
    await _client.from('stores').update(_storeFields(input)).eq('id', id);
  });

  @override
  Future<List<AdminStaff>> staff() => _guard(() async {
    final rows = await _client
        .from('employees')
        .select(
          'id, full_name, phone, email, is_active, auth_user_id, '
          'role:roles(code, name), employee_stores(store_id)',
        )
        .order('full_name');
    final overview = await _client.rpc<List<dynamic>>('staff_overview');
    final state = {
      for (final o in overview.cast<Map<String, dynamic>>())
        o['employee_id'] as String: o,
    };
    return [
      for (final r in rows)
        () {
          final role = (r['role'] as Map).cast<String, dynamic>();
          final o = state[r['id']];
          return AdminStaff(
            id: r['id'] as String,
            fullName: r['full_name'] as String,
            phone: r['phone'] as String?,
            email: r['email'] as String?,
            roleCode: role['code'] as String,
            roleName: role['name'] as String,
            storeIds: [
              for (final s in (r['employee_stores'] as List? ?? const []))
                (s as Map)['store_id'] as String,
            ],
            hasLogin: r['auth_user_id'] != null,
            loginConfirmed: o?['login_confirmed'] as bool? ?? false,
            hasPin: o?['has_pin'] as bool? ?? false,
            isActive: r['is_active'] as bool,
          );
        }(),
    ];
  });

  @override
  Future<void> saveStaff(StaffInput input, {String? id}) => _guard(() async {
    final role = await _client
        .from('roles')
        .select('id')
        .eq('code', input.roleCode)
        .single();
    final fields = {
      'full_name': input.fullName.trim(),
      'phone': _blankToNull(input.phone),
      'role_id': role['id'],
      'is_active': input.isActive,
    };
    final employeeId = id ?? _uuid.v7();
    if (id == null) {
      await _client.from('employees').insert({'id': employeeId, ...fields});
    } else {
      await _client.from('employees').update(fields).eq('id', id);
    }
    final current = id == null
        ? const <String>{}
        : {
            for (final r
                in await _client
                    .from('employee_stores')
                    .select('store_id')
                    .eq('employee_id', employeeId))
              r['store_id'] as String,
          };
    final wanted = input.storeIds.toSet();
    for (final s in current.difference(wanted)) {
      await _client
          .from('employee_stores')
          .delete()
          .eq('employee_id', employeeId)
          .eq('store_id', s);
    }
    final added = wanted.difference(current);
    if (added.isNotEmpty) {
      await _client.from('employee_stores').insert([
        for (final s in added) {'employee_id': employeeId, 'store_id': s},
      ]);
    }
  });

  @override
  Future<void> setActive(String id, {required bool isActive}) =>
      _guard(() async {
        await _client
            .from('employees')
            .update({'is_active': isActive})
            .eq('id', id);
      });

  @override
  Future<void> setPin(String id, String pin) => _guard(() async {
    await _client.rpc<void>(
      'set_employee_pin',
      params: {'p_employee_id': id, 'p_pin': pin},
    );
  });

  @override
  Future<void> invite(String id, String email) async {
    try {
      final res = await _client.functions.invoke(
        'staff-invite',
        body: {'employee_id': id, 'email': email.trim()},
      );
      final body = res.data;
      if (body is Map && body['error'] != null) {
        throw BackendException(
          body['error'] as String,
          body['error'] as String,
        );
      }
    } on FunctionException catch (e) {
      final details = e.details;
      final code = details is Map && details['error'] is String
          ? details['error'] as String
          : 'invite_failed';
      throw BackendException(code, code);
    }
  }
}

String? _blankToNull(String? v) =>
    v == null || v.trim().isEmpty ? null : v.trim();

Future<T> _guard<T>(Future<T> Function() body) async {
  try {
    return await body();
  } on PostgrestException catch (e) {
    if (e.code == '23505') throw BackendException('duplicate_code', e.message);
    throw BackendException.fromMessage(e.message);
  }
}
