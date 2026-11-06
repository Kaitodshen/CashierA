import 'package:cashiera_core/cashiera_core.dart';
import 'package:test/test.dart';

void main() {
  group('Money.format', () {
    test('groups thousands with dots and prefixes Rp', () {
      expect(const Money(25000).format(), 'Rp 25.000');
      expect(const Money(1250000).format(), 'Rp 1.250.000');
      expect(const Money(999).format(), 'Rp 999');
    });

    test('zero and negative amounts', () {
      expect(Money.zero.format(), 'Rp 0');
      expect(const Money(-2000).format(), '-Rp 2.000');
    });

    test('arithmetic stays in whole rupiah', () {
      expect(const Money(4000) + const Money(78000), const Money(82000));
      expect(const Money(4000) - const Money(5000), const Money(-1000));
      expect(const Money(4000) * 3, const Money(12000));
    });
  });

  group('divRoundHalfUp', () {
    test('matches Postgres round(n::numeric / d)', () {
      // PPN inside Rp 25.000 and inside Rp 8.000, at 11%
      expect(divRoundHalfUp(27500000, 11100), 2477);
      expect(divRoundHalfUp(8800000, 11100), 793);
      expect(divRoundHalfUp(5, 2), 3);
      expect(divRoundHalfUp(4, 2), 2);
      expect(divRoundHalfUp(0, 7), 0);
    });

    test('rejects negative numerators and non-positive denominators', () {
      expect(() => divRoundHalfUp(-1, 2), throwsArgumentError);
      expect(() => divRoundHalfUp(1, 0), throwsArgumentError);
    });
  });
}
