import 'package:cashiera_core/cashiera_core.dart';
import 'package:test/test.dart';

void main() {
  test('equal weights: the remainder goes to the first lines', () {
    expect(allocateLargestRemainder(100, [1, 1, 1]), [34, 33, 33]);
    expect(allocateLargestRemainder(7, [2, 2, 2]), [3, 2, 2]);
  });

  test('exact proportions need no remainder', () {
    expect(allocateLargestRemainder(10, [3, 7]), [3, 7]);
    expect(allocateLargestRemainder(9240, [50000, 30000]), [5775, 3465]);
  });

  test('largest fractional part wins the remainder', () {
    // 10 × [1, 2, 4] / 7 = 1.43, 2.86, 5.71 → floors 1, 2, 5 (8), +1 to 2.86.
    expect(allocateLargestRemainder(10, [1, 2, 4]), [1, 3, 6]);
  });

  test('zero weights get nothing', () {
    expect(allocateLargestRemainder(5, [0, 10]), [0, 5]);
    expect(allocateLargestRemainder(0, [0, 0]), [0, 0]);
  });

  test('shares always add up and never exceed their weight', () {
    final weights = [4000, 12500, 1, 333, 98765, 0, 77];
    final total = weights.reduce((a, b) => a + b);
    for (final amount in [0, 1, 17, 999, 50000, total]) {
      final shares = allocateLargestRemainder(amount, weights);
      expect(shares.reduce((a, b) => a + b), amount);
      for (var i = 0; i < weights.length; i++) {
        expect(shares[i], lessThanOrEqualTo(weights[i]));
      }
    }
  });

  test('refuses to spread money over nothing', () {
    expect(() => allocateLargestRemainder(5, [0, 0]), throwsArgumentError);
    expect(() => allocateLargestRemainder(-1, [1]), throwsArgumentError);
  });
}
