import 'package:flutter_test/flutter_test.dart';

import '../../support/source_rules.dart';

void main() {
  test('catalog lists are on glass (no FABs or Material cards)', () {
    const dir = 'lib/features/back_office/presentation';
    expect(
      filesContaining([
        '$dir/products_screen.dart',
        '$dir/categories_screen.dart',
        '$dir/suppliers_screen.dart',
        '$dir/stock_screen.dart',
      ], oldContainers),
      isEmpty,
    );
  });
}
