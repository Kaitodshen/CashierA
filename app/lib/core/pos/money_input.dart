/// Whole rupiah as typed: `25000`, `25.000` or `Rp 25.000`.
int? parseRupiah(String text) {
  final digits = text.replaceAll(RegExp('[^0-9]'), '');
  if (digits.isEmpty || digits.length > 12) return null;
  return int.parse(digits);
}

/// A percentage as typed (`10`, `12,5`, `7.25 %`) in basis points, from
/// 0,01% to 100%; null otherwise.
int? parsePercentBps(String text) {
  final match = RegExp(r'^\s*(\d{1,3})(?:[.,](\d{1,2}))?\s*%?\s*$')
      .firstMatch(text);
  if (match == null) return null;
  final bps =
      int.parse(match.group(1)!) * 100 +
      int.parse((match.group(2) ?? '').padRight(2, '0'));
  return bps > 0 && bps <= 10000 ? bps : null;
}

/// Like [parsePercentBps] but also accepts 0 (settings such as "no service
/// charge" or "approve every discount").
int? parsePercentOrZero(String text) =>
    RegExp(r'^\s*0+([.,]0*)?\s*%?\s*$').hasMatch(text)
    ? 0
    : parsePercentBps(text);

/// `1100` → `11`, `1250` → `12,5`, `725` → `7,25`.
String bpsToPercentText(int bps) {
  if (bps % 100 == 0) return '${bps ~/ 100}';
  final decimals = (bps % 100).toString().padLeft(2, '0');
  return '${bps ~/ 100},${decimals.endsWith('0') ? decimals[0] : decimals}';
}
