import 'package:cashiera_core/src/money.dart';
import 'package:cashiera_core/src/rounding.dart';

/// A quantity in thousandths (`Qty(1250)` = 1.250), so items sold by the kg
/// or litre stay exact. The database stores the same value as numeric(14,3)
/// and the sync payload carries it as a decimal string.
extension type const Qty(int milli) {
  /// Parses `"2"`, `"1.25"` or `"0.250"`. More than three decimals is an error,
  /// because the database would silently round it.
  factory parse(String text) {
    final match = _pattern.firstMatch(text.trim());
    if (match == null) {
      throw FormatException('Not a quantity with up to 3 decimals', text);
    }
    final negative = match.group(1) == '-';
    final whole = int.parse(match.group(2)!);
    final fraction = (match.group(3) ?? '').padRight(3, '0');
    final milli = whole * 1000 + int.parse(fraction);
    return Qty(negative ? -milli : milli);
  }

  /// Nothing.
  static const zero = Qty(0);

  /// One whole unit.
  static const one = Qty(1000);

  static final _pattern = RegExp(r'^(-?)(\d+)(?:\.(\d{1,3}))?$');

  /// The decimal string sent to `sync_push`, always with three decimals.
  String toPayload() {
    final sign = milli < 0 ? '-' : '';
    final abs = milli.abs();
    return '$sign${abs ~/ 1000}.${(abs % 1000).toString().padLeft(3, '0')}';
  }

  /// Short human form for spreadsheets and screens: `12.5`, `10`, `0.125`.
  String toPlain() {
    final payload = toPayload();
    if (!payload.contains('.')) return payload;
    final trimmed = payload.replaceFirst(RegExp(r'0+$'), '');
    return trimmed.endsWith('.')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  /// Line amount for this quantity at [unitPrice], rounded half up exactly
  /// like the database's `round(unit_price * quantity)` check.
  Money times(Money unitPrice) {
    if (milli < 0 || unitPrice.rupiah < 0) {
      throw ArgumentError('Quantity and price must not be negative');
    }
    return Money(divRoundHalfUp(unitPrice.rupiah * milli, 1000));
  }
}
