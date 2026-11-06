import 'package:cashiera/core/design_system/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Numeric keypad for 4-6 digit staff PINs. Digits are never shown, only dots.
/// Physical keyboards (and USB numpads on Windows terminals) work too.
class PinPad extends StatefulWidget {
  const new({
    required this.onSubmitted,
    this.minLength = 4,
    this.maxLength = 6,
    this.enabled = true,
    super.key,
  });

  final ValueChanged<String> onSubmitted;
  final int minLength;
  final int maxLength;
  final bool enabled;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _digits = '';
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _add(String digit) {
    if (!widget.enabled || _digits.length >= widget.maxLength) return;
    setState(() => _digits += digit);
  }

  void _backspace() {
    if (!widget.enabled || _digits.isEmpty) return;
    setState(() => _digits = _digits.substring(0, _digits.length - 1));
  }

  void _submit() {
    if (!widget.enabled || _digits.length < widget.minLength) return;
    final pin = _digits;
    setState(() => _digits = '');
    widget.onSubmitted(pin);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final char = event.character;
    if (char != null && RegExp(r'^\d$').hasMatch(char)) {
      _add(char);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _backspace();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _submit();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKey,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PinDots(filled: _digits.length, total: widget.maxLength),
            const SizedBox(height: AppSpacing.xl),
            for (final row in const [
              ['1', '2', '3'],
              ['4', '5', '6'],
              ['7', '8', '9'],
            ])
              _KeyRow(
                children: [
                  for (final d in row)
                    _PadKey(
                      key: Key('pin-key-$d'),
                      onPressed: widget.enabled ? () => _add(d) : null,
                      child: Text(d),
                    ),
                ],
              ),
            _KeyRow(
              children: [
                _PadKey(
                  key: const Key('pin-key-backspace'),
                  onPressed: widget.enabled ? _backspace : null,
                  child: const Icon(Icons.backspace_outlined),
                ),
                _PadKey(
                  key: const Key('pin-key-0'),
                  onPressed: widget.enabled ? () => _add('0') : null,
                  child: const Text('0'),
                ),
                _PadKey(
                  key: const Key('pin-key-ok'),
                  primary: true,
                  onPressed: widget.enabled ? _submit : null,
                  child: const Icon(Icons.check),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PinDots extends StatelessWidget {
  const new({required this.filled, required this.total});

  final int filled;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: '$filled / $total',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < total; i++)
            AnimatedContainer(
              duration: AppMotion.fast,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < filled ? scheme.primary : Colors.transparent,
                border: Border.all(color: scheme.outline, width: 2),
              ),
            ),
        ],
      ),
    );
  }
}

class _KeyRow extends StatelessWidget {
  const new({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: children,
      ),
    );
  }
}

class _PadKey extends StatelessWidget {
  const new({
    required this.onPressed,
    required this.child,
    this.primary = false,
    super.key,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final style =
        (primary
                ? FilledButton.styleFrom()
                : FilledButton.styleFrom(
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                  ))
            .copyWith(
              minimumSize: const WidgetStatePropertyAll(Size(80, 64)),
              textStyle: const WidgetStatePropertyAll(
                TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              ),
            );
    return FilledButton(onPressed: onPressed, style: style, child: child);
  }
}
