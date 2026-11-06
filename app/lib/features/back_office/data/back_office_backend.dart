import 'package:cashiera/core/auth/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StoreSummary {
  const new({
    required this.id,
    required this.code,
    required this.name,
    this.address,
    this.timezone = 'Asia/Jakarta',
  });

  final String id;
  final String code;
  final String name;
  final String? address;

  /// Asia/Jakarta (WIB), Asia/Makassar (WITA) or Asia/Jayapura (WIT).
  final String timezone;
}

class PairingCode {
  const new({required this.code, required this.expiresAt});

  final String code;
  final DateTime expiresAt;
}

abstract interface class BackOfficeBackend {
  Future<void> signIn({required String email, required String password});
  Future<void> signOut();
  bool get hasStaffSession;
  Future<Principal> currentPrincipal();
  Future<List<StoreSummary>> listStores();
  Future<PairingCode> createPairingCode(String storeId, String deviceName);
}

class SupabaseBackOfficeBackend implements BackOfficeBackend {
  new(this._client);

  final SupabaseClient _client;

  @override
  bool get hasStaffSession {
    final user = _client.auth.currentUser;
    return user != null && !user.isAnonymous;
  }

  @override
  Future<void> signIn({required String email, required String password}) =>
      _guard(
        () => _client.auth.signInWithPassword(email: email, password: password),
      );

  @override
  Future<void> signOut() => _guard(_client.auth.signOut);

  @override
  Future<Principal> currentPrincipal() => _guard(() async {
    final json = await _client.rpc<dynamic>('current_principal');
    return Principal.fromJson((json as Map).cast<String, dynamic>());
  });

  @override
  Future<List<StoreSummary>> listStores() => _guard(() async {
    final rows = await _client
        .from('stores')
        .select('id, code, name, address, timezone')
        .eq('is_active', true)
        .order('code');
    return [
      for (final r in rows)
        StoreSummary(
          id: r['id'] as String,
          code: r['code'] as String,
          name: r['name'] as String,
          address: r['address'] as String?,
          timezone: r['timezone'] as String? ?? 'Asia/Jakarta',
        ),
    ];
  });

  @override
  Future<PairingCode> createPairingCode(String storeId, String deviceName) =>
      _guard(() async {
        final json = await _client.rpc<dynamic>(
          'create_device_pairing_code',
          params: {'p_store_id': storeId, 'p_device_name': deviceName},
        );
        final map = (json as Map).cast<String, dynamic>();
        return PairingCode(
          code: map['code'] as String,
          expiresAt: DateTime.parse(map['expires_at'] as String).toLocal(),
        );
      });
}

Future<T> _guard<T>(Future<T> Function() body) async {
  try {
    return await body();
  } on PostgrestException catch (e) {
    throw BackendException.fromMessage(e.message);
  } on AuthException catch (e) {
    throw BackendException(e.code ?? 'auth', e.message);
  }
}
