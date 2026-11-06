import 'package:cashiera/core/database/app_database.dart';

/// What `sync_push` answered (see supabase/README.md §5).
sealed class SyncResponse {
  const new();

  factory fromJson(Map<String, dynamic> json) {
    final result = (json['result'] as Map?)?.cast<String, dynamic>() ?? {};
    return switch (json['status']) {
      'applied' => SyncApplied(result),
      'duplicate' => SyncDuplicate(result),
      'rejected' => SyncRejected(
        code: json['code'] as String? ?? 'unknown',
        message: json['message'] as String? ?? '',
      ),
      final other => throw FormatException('Unknown sync status', '$other'),
    };
  }
}

final class SyncApplied extends SyncResponse {
  const new(this.result);
  final Map<String, dynamic> result;
}

final class SyncDuplicate extends SyncResponse {
  const new(this.result);
  final Map<String, dynamic> result;
}

/// A business rule failed. Retrying the same payload will fail again, so the
/// item waits for a person (manual retry after fixing the cause).
final class SyncRejected extends SyncResponse {
  const new({required this.code, required this.message});
  final String code;
  final String message;
}

/// Network down, timeout, 5xx, deadlock: try again later with backoff.
class SyncTransientException implements Exception {
  const new(this.message);
  final String message;

  @override
  String toString() => 'SyncTransientException: $message';
}

// The transport only sends; ordering and retries belong to SyncEngine.
abstract interface class SyncTransport {
  Future<SyncResponse> push(SyncQueueEntry item);
}
