import 'package:cashiera/core/catalog/qty_input.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('whole numbers for pcs items', () {
    final r = parseQtyInput(' 12 ', allowDecimal: false);
    expect(r.qty, Qty.parse('12'));
    expect(r.error, isNull);
  });

  test('a decimal comma is accepted for kg items', () {
    expect(parseQtyInput('12,5', allowDecimal: true).qty, Qty.parse('12.5'));
    expect(parseQtyInput('0.125', allowDecimal: true).qty, Qty.parse('0.125'));
  });

  test('fractions are refused for whole-unit items', () {
    final r = parseQtyInput('1,5', allowDecimal: false);
    expect(r.qty, isNull);
    expect(r.error, QtyInputError.notWhole);
  });

  test('empty, text, negative and zero are invalid', () {
    for (final text in ['', '  ', 'dua', '-3', '0', '1.2.3']) {
      expect(
        parseQtyInput(text, allowDecimal: true).error,
        QtyInputError.invalid,
        reason: '"$text"',
      );
    }
  });

  test('zero is allowed for stock counts', () {
    final r = parseQtyInput('0', allowDecimal: false, allowZero: true);
    expect(r.qty, Qty.parse('0'));
    expect(r.error, isNull);
  });
}
