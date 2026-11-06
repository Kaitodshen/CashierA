/// An amount of Indonesian rupiah. Always whole rupiah: there is no decimal
/// part anywhere in CashierA's money code.
extension type const Money(int rupiah) {
  /// Zero rupiah.
  static const zero = Money(0);

  /// Sum of two amounts.
  Money operator +(Money other) => Money(rupiah + other.rupiah);

  /// Difference of two amounts.
  Money operator -(Money other) => Money(rupiah - other.rupiah);

  /// This amount repeated [times] times.
  Money operator *(int times) => Money(rupiah * times);

  /// Whether the amount is below zero.
  bool get isNegative => rupiah < 0;

  /// Display format used on screens and receipts: `Rp 25.000`, `-Rp 2.000`.
  String format() {
    final digits = rupiah.abs().toString();
    final grouped = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) grouped.write('.');
      grouped.write(digits[i]);
    }
    return '${isNegative ? '-' : ''}Rp $grouped';
  }
}
