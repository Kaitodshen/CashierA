import 'package:cashiera/features/sell/presentation/quick_cash.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exact amount first, then the next 10k, 50k and 100k', () {
    expect(quickCashAmounts(500888), [500888, 510000, 550000, 600000]);
    expect(quickCashAmounts(3500), [3500, 10000, 50000, 100000]);
  });

  test('round amounts are not repeated', () {
    expect(quickCashAmounts(50000), [50000, 100000]);
    expect(quickCashAmounts(100000), [100000]);
  });

  test('nothing to pay, no amounts', () {
    expect(quickCashAmounts(0), isEmpty);
    expect(quickCashAmounts(-5), isEmpty);
  });
}
