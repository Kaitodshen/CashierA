import 'dart:async';

import 'package:cashiera_core/cashiera_core.dart';
import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Where a gateway charge stands (`gateway_charges.status`).
enum ChargeState {
  pending,
  paid,
  failed,
  expired,
  cancelled;

  static ChargeState fromCode(String? code) =>
      values.where((s) => s.name == code).firstOrNull ?? pending;

  bool get isFinal => this != pending;
}

/// What the terminal asks for: [chargeId] becomes the payment id.
@immutable
class QrisRequest {
  const new({
    required this.chargeId,
    required this.storeId,
    required this.paymentMethodId,
    required this.orderId,
    required this.amount,
    this.orderNumber,
  });

  final String chargeId;
  final String storeId;
  final String paymentMethodId;
  final String orderId;
  final String? orderNumber;
  final Money amount;

  Map<String, dynamic> toJson() => {
    'id': chargeId,
    'store_id': storeId,
    'payment_method_id': paymentMethodId,
    'order_id': orderId,
    'order_number': orderNumber,
    'amount': amount.rupiah,
  };
}

@immutable
class QrisCharge {
  const new({
    required this.id,
    required this.state,
    required this.amount,
    this.qrString,
    this.expiresAt,
    this.providerRef,
  });

  factory fromJson(Map<String, dynamic> j) => QrisCharge(
    id: j['id'] as String,
    state: ChargeState.fromCode(j['status'] as String?),
    amount: Money((j['amount'] as num? ?? 0).toInt()),
    qrString: j['qr_string'] as String?,
    expiresAt: j['expires_at'] == null
        ? null
        : DateTime.parse(j['expires_at'] as String),
    providerRef: j['provider_ref'] as String?,
  );

  final String id;
  final ChargeState state;
  final Money amount;
  final String? qrString;
  final DateTime? expiresAt;

  /// The gateway's transaction id, once known.
  final String? providerRef;

  QrisCharge copyWith({ChargeState? state, String? providerRef}) => QrisCharge(
    id: id,
    state: state ?? this.state,
    amount: amount,
    qrString: qrString,
    expiresAt: expiresAt,
    providerRef: providerRef ?? this.providerRef,
  );
}

/// A gateway call that failed; [code] is the server's error code
/// (`gateway_not_configured`, `permission_denied`, `offline`, ...).
class GatewayException implements Exception {
  const new(this.code, [this.message]);
  final String code;
  final String? message;

  @override
  String toString() => message == null ? code : '$code: $message';
}

/// Dynamic QRIS. The server key stays in the Edge Functions; the terminal
/// only opens, watches and cancels charges.
abstract interface class PaymentGateway {
  /// Opens the charge (or returns it again for the same id) with its QR.
  Future<QrisCharge> createQris(QrisRequest request);

  /// The charge's state as it changes, starting with the current one.
  Stream<QrisCharge> watch(String chargeId);

  /// Cancels a pending charge. The result can be `paid` when the customer
  /// paid just before: use it as paid.
  Future<QrisCharge> cancel(String chargeId);
}

/// Development and tests: charges live in memory. [autoPayAfter] pays every
/// charge after that delay (demo mode); [markPaid] and [expire] drive it by
/// hand.
class MockGateway implements PaymentGateway {
  new({this.autoPayAfter, this.expiresIn = const Duration(minutes: 15)});

  final Duration? autoPayAfter;
  final Duration expiresIn;
  final _charges = <String, QrisCharge>{};
  final _streams = <String, StreamController<QrisCharge>>{};
  final requests = <QrisRequest>[];

  /// What [cancel] finds at the gateway: true = the customer already paid.
  bool paidBeforeCancel = false;

  StreamController<QrisCharge> _stream(String id) =>
      _streams.putIfAbsent(id, StreamController<QrisCharge>.broadcast);

  void _set(QrisCharge c) {
    _charges[c.id] = c;
    _stream(c.id).add(c);
  }

  @override
  Future<QrisCharge> createQris(QrisRequest request) async {
    requests.add(request);
    final existing = _charges[request.chargeId];
    if (existing != null) return existing;
    final charge = QrisCharge(
      id: request.chargeId,
      state: ChargeState.pending,
      amount: request.amount,
      qrString:
          '00020101021226MOCK${request.chargeId}5303360'
          '54${request.amount.rupiah}6304ABCD',
      expiresAt: clock.now().add(expiresIn),
    );
    _charges[charge.id] = charge;
    if (autoPayAfter case final delay?) {
      Timer(delay, () => markPaid(charge.id));
    }
    return charge;
  }

  void markPaid(String id) {
    final c = _charges[id];
    if (c == null || c.state != ChargeState.pending) return;
    _set(c.copyWith(state: ChargeState.paid, providerRef: 'MOCK-$id'));
  }

  void expire(String id) {
    final c = _charges[id];
    if (c == null || c.state != ChargeState.pending) return;
    _set(c.copyWith(state: ChargeState.expired));
  }

  @override
  Stream<QrisCharge> watch(String chargeId) {
    StreamSubscription<QrisCharge>? inner;
    late final StreamController<QrisCharge> out;
    out = StreamController<QrisCharge>(
      onListen: () {
        if (_charges[chargeId] case final current?) out.add(current);
        inner = _stream(chargeId).stream.listen(out.add);
      },
      onCancel: () => inner?.cancel(),
    );
    return out.stream;
  }

  @override
  Future<QrisCharge> cancel(String chargeId) async {
    final c = _charges[chargeId];
    if (c == null) throw const GatewayException('charge_not_found');
    if (c.state != ChargeState.pending) return c;
    if (paidBeforeCancel) {
      markPaid(chargeId);
    } else {
      _set(c.copyWith(state: ChargeState.cancelled));
    }
    return _charges[chargeId]!;
  }
}

/// Production: the `qris-create` / `qris-cancel` Edge Functions, and the
/// charge row (Realtime, with a poll every [pollEvery] as a fallback).
class SupabaseGateway implements PaymentGateway {
  new(this._client, {this.pollEvery = const Duration(seconds: 3)});

  final SupabaseClient _client;
  final Duration pollEvery;

  Future<QrisCharge> _invoke(String fn, Map<String, dynamic> body) async {
    try {
      final res = await _client.functions.invoke(fn, body: body);
      return QrisCharge.fromJson((res.data as Map).cast<String, dynamic>());
    } on FunctionException catch (e) {
      final details = e.details;
      final code = details is Map ? details['error'] as String? : null;
      final message = details is Map ? details['message'] as String? : null;
      throw GatewayException(
        code ?? 'gateway_error',
        message ?? e.reasonPhrase,
      );
    } on GatewayException {
      rethrow;
    } on Exception catch (e) {
      // No network (SocketException / ClientException) or a timeout.
      throw GatewayException('offline', '$e');
    }
  }

  Future<QrisCharge> _status(String id) async {
    final json = await _client.rpc<dynamic>(
      'gateway_charge_status',
      params: {'p_id': id},
    );
    return QrisCharge.fromJson((json as Map).cast<String, dynamic>());
  }

  @override
  Future<QrisCharge> createQris(QrisRequest request) =>
      _invoke('qris-create', request.toJson());

  @override
  Future<QrisCharge> cancel(String chargeId) =>
      _invoke('qris-cancel', {'id': chargeId});

  @override
  Stream<QrisCharge> watch(String chargeId) {
    late final StreamController<QrisCharge> out;
    Timer? timer;
    RealtimeChannel? channel;
    ChargeState? last;
    Future<void> check() async {
      try {
        final c = await _status(chargeId);
        if (c.state != last) {
          last = c.state;
          out.add(c);
        }
        if (c.state.isFinal) timer?.cancel();
      } on Object catch (_) {
        // Offline for a moment: the next poll tries again.
      }
    }

    out = StreamController<QrisCharge>(
      onListen: () {
        unawaited(check());
        timer = Timer.periodic(pollEvery, (_) => unawaited(check()));
        channel = _client
            .channel('charge:$chargeId')
            .onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'gateway_charges',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'id',
                value: chargeId,
              ),
              callback: (_) => unawaited(check()),
            )
            .subscribe();
      },
      onCancel: () async {
        timer?.cancel();
        if (channel != null) await _client.removeChannel(channel!);
      },
    );
    return out.stream;
  }
}
