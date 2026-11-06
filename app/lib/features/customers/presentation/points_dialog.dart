import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Asks how many points to spend. Returns 0 to remove them, null to cancel.
Future<int?> showPointsDialog(
  BuildContext context, {
  required int balance,
  required int maximum,
  required int current,
  required LoyaltyRules rules,
}) => showDialog<int>(
  context: context,
  builder: (_) => _PointsDialog(
    balance: balance,
    maximum: maximum,
    current: current,
    rules: rules,
  ),
);

class _PointsDialog extends StatefulWidget {
  const new({
    required this.balance,
    required this.maximum,
    required this.current,
    required this.rules,
  });

  final int balance;
  final int maximum;
  final int current;
  final LoyaltyRules rules;

  @override
  State<_PointsDialog> createState() => _PointsDialogState();
}

class _PointsDialogState extends State<_PointsDialog> {
  late final _points = TextEditingController(
    text: widget.current > 0 ? '${widget.current}' : '',
  );
  String? _error;

  @override
  void dispose() {
    _points.dispose();
    super.dispose();
  }

  void _use() {
    final l10n = context.l10n;
    final points = int.tryParse(_points.text) ?? 0;
    if (points <= 0) {
      Navigator.pop(context, 0);
      return;
    }
    if (points > widget.maximum) {
      setState(() => _error = l10n.pointsTooMany(widget.maximum));
      return;
    }
    if (points < widget.rules.minRedeemPoints) {
      setState(
        () => _error = l10n.pointsBelowMin(widget.rules.minRedeemPoints),
      );
      return;
    }
    Navigator.pop(context, points);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final value = widget.rules.pointValue * widget.maximum;
    return AlertDialog(
      title: Text(l10n.pointsTitle),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.pointsBalance(widget.balance)),
            Text(l10n.pointsMax(widget.maximum, value.format())),
            if (widget.rules.minRedeemPoints > 0)
              Text(l10n.pointsMin(widget.rules.minRedeemPoints)),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('points-field'),
                    controller: _points,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: l10n.pointsField,
                      errorText: _error,
                    ),
                    onSubmitted: (_) => _use(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                TextButton(
                  key: const Key('points-max'),
                  onPressed: widget.maximum == 0
                      ? null
                      : () => _points.text = '${widget.maximum}',
                  child: Text(l10n.pointsAll),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        if (widget.current > 0)
          TextButton(
            key: const Key('points-remove'),
            onPressed: () => Navigator.pop(context, 0),
            child: Text(l10n.pointsRemove),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          key: const Key('points-use'),
          onPressed: widget.maximum == 0 ? null : _use,
          child: Text(l10n.pointsUse),
        ),
      ],
    );
  }
}
