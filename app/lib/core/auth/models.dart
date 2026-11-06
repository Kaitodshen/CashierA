import 'dart:convert';

import 'package:cashiera/core/database/app_database.dart';

/// Result of `pair_device`.
class PairedDevice {
  const new({
    required this.deviceId,
    required this.deviceCode,
    required this.storeId,
    required this.name,
  });

  factory fromJson(Map<String, dynamic> json) => PairedDevice(
    deviceId: json['device_id'] as String,
    deviceCode: json['device_code'] as String,
    storeId: json['store_id'] as String,
    name: json['name'] as String,
  );

  final String deviceId;
  final String deviceCode;
  final String storeId;
  final String name;
}

/// A staff member as the terminal knows them (from `device_staff()`).
class StaffMember {
  const new({
    required this.employeeId,
    required this.fullName,
    required this.roleCode,
    required this.permissions,
    required this.pinHash,
    this.isActive = true,
  });

  factory fromJson(Map<String, dynamic> json) => StaffMember(
    employeeId: json['employee_id'] as String,
    fullName: json['full_name'] as String,
    roleCode: json['role_code'] as String,
    permissions: {
      for (final p in (json['permissions'] as List? ?? const [])) p as String,
    },
    pinHash: json['pin_hash'] as String?,
    isActive: json['is_active'] as bool? ?? true,
  );

  factory fromRow(LocalStaffRow row) => StaffMember(
    employeeId: row.employeeId,
    fullName: row.fullName,
    roleCode: row.roleCode,
    permissions: {
      for (final p in jsonDecode(row.permissions) as List) p as String,
    },
    pinHash: row.pinHash,
    isActive: row.isActive,
  );

  final String employeeId;
  final String fullName;
  final String roleCode;
  final Set<String> permissions;
  final String? pinHash;
  final bool isActive;

  /// Owners hold every permission (same rule as the database).
  bool can(String permission) =>
      roleCode == 'owner' || permissions.contains(permission);

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((p) => p.isEmpty ? '' : p[0]).join().toUpperCase();
  }
}

/// The terminal's store and its settings, as cached locally.
class StoreSnapshot {
  const new({required this.store, required this.settings});

  final LocalStoreRow store;
  final LocalStoreSettingsRow settings;
}

/// What `current_principal()` says about a back-office sign-in.
class Principal {
  const new({
    required this.kind,
    this.employeeId,
    this.fullName,
    this.roleCode,
    this.roleName,
    this.permissions = const {},
    this.storeIds = const [],
  });

  factory fromJson(Map<String, dynamic> json) {
    final employee = (json['employee'] as Map?)?.cast<String, dynamic>();
    final role = (json['role'] as Map?)?.cast<String, dynamic>();
    return Principal(
      kind: json['kind'] as String? ?? 'none',
      employeeId: employee?['id'] as String?,
      fullName: employee?['full_name'] as String?,
      roleCode: role?['code'] as String?,
      roleName: role?['name'] as String?,
      permissions: {
        for (final p in (json['permissions'] as List? ?? const [])) p as String,
      },
      storeIds: [
        for (final s in (json['store_ids'] as List? ?? const [])) s as String,
      ],
    );
  }

  final String kind;
  final String? employeeId;
  final String? fullName;
  final String? roleCode;
  final String? roleName;
  final Set<String> permissions;
  final List<String> storeIds;

  bool get isEmployee => kind == 'employee';
  bool can(String permission) => permissions.contains(permission);
}

/// A failure the server explained (`<code>: <detail>` from app.fail).
class BackendException implements Exception {
  const new(this.code, this.message);

  /// Splits `pairing_code_invalid: the code is wrong ...` into code + message.
  factory fromMessage(String raw) {
    final match = RegExp(r'^([a-z_]+): (.*)$').firstMatch(raw);
    return match == null
        ? BackendException('error', raw)
        : BackendException(match.group(1)!, match.group(2)!);
  }

  final String code;
  final String message;

  @override
  String toString() => '$code: $message';
}
