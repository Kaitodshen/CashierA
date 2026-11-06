import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/database/app_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Server calls a POS terminal makes outside the sync queue.
abstract interface class TerminalBackend {
  /// Signs in anonymously (if needed) and redeems the pairing [code].
  Future<PairedDevice> pair(
    String code, {
    required String platform,
    required String appVersion,
  });

  /// Staff of this terminal's store, with PIN hashes (`device_staff()`).
  Future<List<StaffMember>> fetchRoster();

  /// The store row and its settings.
  Future<StoreSnapshot> fetchStore(String storeId);
}

class SupabaseTerminalBackend implements TerminalBackend {
  new(this._client);

  final SupabaseClient _client;

  @override
  Future<PairedDevice> pair(
    String code, {
    required String platform,
    required String appVersion,
  }) => _guard(() async {
    final auth = _client.auth;
    final user = auth.currentUser;
    if (user == null || !user.isAnonymous) {
      if (user != null) await auth.signOut();
      await auth.signInAnonymously();
    }
    final result = await _client.rpc<dynamic>(
      'pair_device',
      params: {
        'p_code': code,
        'p_platform': platform,
        'p_app_version': appVersion,
      },
    );
    return PairedDevice.fromJson((result as Map).cast<String, dynamic>());
  });

  @override
  Future<List<StaffMember>> fetchRoster() => _guard(() async {
    final rows = await _client.rpc<dynamic>('device_staff');
    return [
      for (final row in rows as List)
        StaffMember.fromJson((row as Map).cast<String, dynamic>()),
    ];
  });

  @override
  Future<StoreSnapshot> fetchStore(String storeId) => _guard(() async {
    final store = await _client
        .from('stores')
        .select()
        .eq('id', storeId)
        .single();
    final s = await _client
        .from('store_settings')
        .select()
        .eq('store_id', storeId)
        .single();
    return StoreSnapshot(
      store: LocalStoreRow(
        id: store['id'] as String,
        code: store['code'] as String,
        name: store['name'] as String,
        address: store['address'] as String?,
        phone: store['phone'] as String?,
        timezone: store['timezone'] as String,
        fnbMode: store['fnb_mode'] as bool,
      ),
      settings: LocalStoreSettingsRow(
        storeId: s['store_id'] as String,
        taxEnabled: s['tax_enabled'] as bool,
        taxName: s['tax_name'] as String,
        taxRateBps: s['tax_rate_bps'] as int,
        taxInclusive: s['tax_inclusive'] as bool,
        serviceChargeEnabled: s['service_charge_enabled'] as bool,
        serviceChargeBps: s['service_charge_bps'] as int,
        serviceChargeTaxable: s['service_charge_taxable'] as bool,
        roundingMode: s['rounding_mode'] as String,
        roundingUnit: s['rounding_unit'] as int,
        discountApprovalBps: s['discount_approval_bps'] as int,
        kasbonEnabled: s['kasbon_enabled'] as bool,
        receiptHeader: s['receipt_header'] as String?,
        receiptFooter: s['receipt_footer'] as String,
        receiptPaperMm: s['receipt_paper_mm'] as int,
      ),
    );
  });
}

/// Turns Postgrest / auth errors into [BackendException]s with the server's
/// own error code (e.g. `pairing_code_invalid`).
Future<T> _guard<T>(Future<T> Function() body) async {
  try {
    return await body();
  } on PostgrestException catch (e) {
    throw BackendException.fromMessage(e.message);
  } on AuthException catch (e) {
    throw BackendException(e.code ?? 'auth', e.message);
  }
}
