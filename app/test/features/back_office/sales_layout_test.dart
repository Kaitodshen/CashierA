import 'package:flutter_test/flutter_test.dart';

import '../../support/source_rules.dart';

void main() {
  test('sales pages are on glass', () {
    const dir = 'lib/features/back_office/presentation';
    expect(
      filesContaining([
        '$dir/promotions_screen.dart',
        '$dir/promotion_editor_screen.dart',
        '$dir/vouchers_screen.dart',
        '$dir/gateway_payments_screen.dart',
      ], oldContainers),
      isEmpty,
    );
  });
}
