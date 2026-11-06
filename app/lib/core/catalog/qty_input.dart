import 'package:cashiera_core/cashiera_core.dart';

enum QtyInputError { invalid, notWhole }

/// Parses what a person typed: `12`, `12.5` or `12,5` (Indonesian keyboards).
/// Returns the quantity, or the reason it was refused.
({Qty? qty, QtyInputError? error}) parseQtyInput(
  String text, {
  required bool allowDecimal,
  bool allowZero = false,
}) {
  final raw = text.trim().replaceAll(',', '.');
  if (raw.isEmpty) return (qty: null, error: QtyInputError.invalid);
  final Qty qty;
  try {
    qty = Qty.parse(raw);
  } on FormatException {
    return (qty: null, error: QtyInputError.invalid);
  }
  if (qty.milli < 0 || (!allowZero && qty.milli == 0)) {
    return (qty: null, error: QtyInputError.invalid);
  }
  if (!allowDecimal && qty.milli % 1000 != 0) {
    return (qty: null, error: QtyInputError.notWhole);
  }
  return (qty: qty, error: null);
}
