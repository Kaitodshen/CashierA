import 'dart:async';
import 'dart:convert';

import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/sync/sync_transport.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sends queue items to the `sync_push` RPC.
class SupabaseSyncTransport implements SyncTransport {
  new(this._client, {this.timeout = const Duration(seconds: 20)});

  final SupabaseClient _client;
  final Duration timeout;

  @override
  Future<SyncResponse> push(SyncQueueEntry item) async {
    try {
      final response = await _client
          .rpc<dynamic>(
            'sync_push',
            params: {
              'p_client_uuid': item.clientUuid,
              'p_entity': item.entity,
              'p_action': item.action,
              'p_payload': jsonDecode(item.payload),
            },
          )
          .timeout(timeout);
      return SyncResponse.fromJson((response as Map).cast<String, dynamic>());
    } on FormatException {
      rethrow;
    } on PostgrestException catch (e) {
      // Business rules come back as {"status":"rejected"}; an exception here is
      // a server-side failure (deadlock, timeout, 5xx), so it is retryable.
      throw SyncTransientException('${e.code ?? 'postgrest'}: ${e.message}');
    } on TimeoutException {
      throw const SyncTransientException('timeout');
    } on Exception catch (e) {
      throw SyncTransientException(e.toString());
    }
  }
}
