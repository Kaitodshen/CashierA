import 'dart:convert';

import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/database/tables.dart';
import 'package:flutter/foundation.dart';

/// A queue item as the UI sees it (decoded payload, no database types).
@immutable
class SyncItem {
  const new({
    required this.id,
    required this.clientUuid,
    required this.entity,
    required this.action,
    required this.payload,
    required this.createdAt,
    required this.retryCount,
    required this.status,
    this.lastError,
    this.nextAttemptAt,
  });

  factory fromEntry(SyncQueueEntry e) => SyncItem(
    id: e.id,
    clientUuid: e.clientUuid,
    entity: e.entity,
    action: e.action,
    payload: (jsonDecode(e.payload) as Map).cast<String, dynamic>(),
    createdAt: e.createdAt,
    retryCount: e.retryCount,
    status: e.status,
    lastError: e.lastError,
    nextAttemptAt: e.nextAttemptAt,
  );

  final int id;
  final String clientUuid;
  final String entity;
  final String action;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;
  final SyncStatus status;
  final String? lastError;
  final DateTime? nextAttemptAt;

  /// Human label, e.g. `order.upsert · PST-T1-261105-0001`.
  String get label {
    final number = payload['order_number'] ?? payload['refund_number'];
    return '$entity.$action${number == null ? '' : ' · $number'}';
  }
}
