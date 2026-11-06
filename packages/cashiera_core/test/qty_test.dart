import 'package:cashiera_core/cashiera_core.dart';
import 'package:test/test.dart';

void main() {
  group('Qty', () {
    test('parses decimal strings into thousandths', () {
      expect(Qty.parse('1.25').milli, 1250);
      expect(Qty.parse('2').milli, 2000);
      expect(Qty.parse('0.250').milli, 250);
      expect(Qty.parse(' 12.5 ').milli, 12500);
    });

    test('formats the sync payload with exactly three decimals', () {
      expect(Qty.parse('2').toPayload(), '2.000');
      expect(const Qty(1250).toPayload(), '1.250');
      expect(const Qty(-500).toPayload(), '-0.500');
    });

    test('rejects more than three decimals and garbage', () {
      expect(() => Qty.parse('1.2345'), throwsFormatException);
      expect(() => Qty.parse('abc'), throwsFormatException);
      expect(() => Qty.parse(''), throwsFormatException);
    });

    test('times rounds half up like the database line gross', () {
      expect(Qty.parse('0.250').times(const Money(42000)), const Money(10500));
      expect(Qty.parse('2').times(const Money(4000)), const Money(8000));
      // 0.333 kg x Rp 42.000 = 13.986 exactly
      expect(Qty.parse('0.333').times(const Money(42000)), const Money(13986));
      // 0.005 x Rp 100 = 0.5 -> rounds up to 1
      expect(Qty.parse('0.005').times(const Money(100)), const Money(1));
    });
  });
}
