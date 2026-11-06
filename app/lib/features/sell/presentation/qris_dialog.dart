import 'dart:async';

import 'package:barcode/barcode.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/payments/payment_gateway.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Draws [data] as a QR code, black on white with a quiet zone.
class QrCodeView extends StatelessWidget {
  const new(this.data, {super.key, this.size = 260});

  final String data;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white,
    padding: const EdgeInsets.all(12),
    child: CustomPaint(size: Size.square(size), painter: _QrPainter(data)),
  );
}

class _QrPainter extends CustomPainter {
  new(this.data);
  final String data;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    for (final e in Barcode.qrCode().make(
      data,
      width: size.width,
      height: size.height,
    )) {
      if (e is BarcodeBar && e.black) {
        canvas.drawRect(Rect.fromLTWH(e.left, e.top, e.width, e.height), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_QrPainter old) => old.data != data;
}

String chargeErrorText(AppLocalizations l10n, Object e) => switch (e) {
  GatewayException(code: 'offline') => l10n.qrisOffline,
  GatewayException(code: 'gateway_not_configured') => l10n.qrisNotConfigured,
  GatewayException(:final code) => l10n.qrisError(code),
  _ => l10n.qrisError('$e'),
};

/// Shows a dynamic QRIS for [amount] and waits. Returns the paid charge, or
/// null when it was cancelled, expired or failed and the cashier closed it.
Future<QrisCharge?> showQrisDialog(
  BuildContext context, {
  required PaymentGateway gateway,
  required String storeId,
  required String paymentMethodId,
  required String orderId,
  required Money amount,
  String? orderNumber,
}) => showDialog<QrisCharge>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _QrisDialog(
    gateway: gateway,
    storeId: storeId,
    paymentMethodId: paymentMethodId,
    orderId: orderId,
    orderNumber: orderNumber,
    amount: amount,
  ),
);

class _QrisDialog extends StatefulWidget {
  const new({
    required this.gateway,
    required this.storeId,
    required this.paymentMethodId,
    required this.orderId,
    required this.amount,
    this.orderNumber,
  });

  final PaymentGateway gateway;
  final String storeId;
  final String paymentMethodId;
  final String orderId;
  final String? orderNumber;
  final Money amount;

  @override
  State<_QrisDialog> createState() => _QrisDialogState();
}

class _QrisDialogState extends State<_QrisDialog> {
  static const _uuid = Uuid();
  QrisCharge? _charge;
  Object? _error;
  bool _busy = false;
  StreamSubscription<QrisCharge>? _watch;
  Timer? _tick;
  bool _closed = false;

  /// Closes once: a paid update and a cancel answer can both arrive.
  void _close([QrisCharge? paid]) {
    if (_closed || !mounted) return;
    _closed = true;
    Navigator.of(context).pop(paid);
  }

  @override
  void initState() {
    super.initState();
    unawaited(_create());
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _charge?.state == ChargeState.pending) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    unawaited(_watch?.cancel());
    super.dispose();
  }

  Future<void> _create() async {
    // Stop following the old charge; no need to wait for it.
    final previous = _watch;
    _watch = null;
    unawaited(previous?.cancel());
    // A QR that only expired by our clock may still be payable: cancel it
    // first, and keep it if the customer paid after all.
    final old = _charge;
    if (old != null && old.state == ChargeState.pending) {
      try {
        final result = await widget.gateway.cancel(old.id);
        if (result.state == ChargeState.paid) {
          if (mounted) _close(result);
          return;
        }
      } on Object catch (e) {
        if (mounted) setState(() => _error = e);
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      _busy = true;
      _error = null;
      _charge = null;
    });
    try {
      final charge = await widget.gateway.createQris(
        QrisRequest(
          chargeId: _uuid.v7(),
          storeId: widget.storeId,
          paymentMethodId: widget.paymentMethodId,
          orderId: widget.orderId,
          orderNumber: widget.orderNumber,
          amount: widget.amount,
        ),
      );
      if (!mounted) return;
      setState(() => _charge = charge);
      _watch = widget.gateway.watch(charge.id).listen(_onUpdate);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onUpdate(QrisCharge c) {
    if (!mounted) return;
    setState(() => _charge = c);
    if (c.state == ChargeState.paid) _close(c);
  }

  Future<void> _cancel() async {
    final charge = _charge;
    if (charge == null || charge.state != ChargeState.pending) {
      _close();
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await widget.gateway.cancel(charge.id);
      if (!mounted) return;
      if (result.state == ChargeState.paid) {
        _close(result);
      } else {
        _close();
      }
    } on Object catch (e) {
      // Not cancelled: keep showing the QR, the customer may still pay.
      if (mounted) {
        setState(() {
          _error = e;
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final charge = _charge;
    final left = charge?.expiresAt?.difference(clock.now());
    final expiredByClock =
        charge?.state == ChargeState.pending && left != null && left.isNegative;
    final state = expiredByClock ? ChargeState.expired : charge?.state;

    final Widget body;
    if (charge == null) {
      body = _error == null
          ? const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          : Text(
              chargeErrorText(l10n, _error!),
              key: const Key('qris-error'),
              style: const TextStyle(color: AppColors.error),
            );
    } else if (state == ChargeState.pending) {
      final mm = left?.inMinutes;
      final ss = left == null
          ? null
          : (left.inSeconds % 60).toString().padLeft(2, '0');
      body = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (charge.qrString != null)
            QrCodeView(charge.qrString!, key: const Key('qris-code')),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.qrisScan),
          if (mm != null) Text(l10n.qrisExpiresIn('$mm:$ss')),
          if (_error != null)
            Text(
              chargeErrorText(l10n, _error!),
              style: const TextStyle(color: AppColors.error),
            ),
          const SizedBox(height: AppSpacing.sm),
          if (left != null)
            LinearProgressIndicator(
              key: const Key('qris-time-left'),
              value: (left.inSeconds / (15 * 60)).clamp(0, 1).toDouble(),
            ),
        ],
      );
    } else {
      body = Text(
        switch (state) {
          ChargeState.expired => l10n.qrisExpired,
          ChargeState.cancelled => l10n.qrisCancelled,
          _ => l10n.qrisFailed,
        },
        key: const Key('qris-final'),
        style: theme.textTheme.titleMedium?.copyWith(color: AppColors.warning),
      );
    }

    final pending = state == ChargeState.pending;
    return AlertDialog(
      title: Text(l10n.qrisTitle(widget.amount.format())),
      content: SizedBox(width: 320, child: Center(child: body)),
      actions: [
        if (!pending && (charge != null || _error != null))
          TextButton(
            key: const Key('qris-new'),
            onPressed: _busy ? null : _create,
            child: Text(l10n.qrisNewQr),
          ),
        if (pending)
          TextButton(
            key: const Key('qris-cancel'),
            onPressed: _busy ? null : _cancel,
            child: Text(l10n.qrisCancel),
          )
        else
          FilledButton(
            key: const Key('qris-close'),
            onPressed: _close,
            child: Text(l10n.commonClose),
          ),
      ],
    );
  }
}
