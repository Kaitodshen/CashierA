import 'package:flutter_test/flutter_test.dart';

import '../../support/source_rules.dart';

void main() {
  test('members and settings pages are on glass', () {
    const dir = 'lib/features/back_office/presentation';
    expect(
      filesContaining([
        '$dir/admin_customers_screen.dart',
        '$dir/admin_kasbon_screen.dart',
        '$dir/loyalty_settings_screen.dart',
        '$dir/store_settings_screen.dart',
        '$dir/dining_tables_screen.dart',
      ], oldContainers),
      isEmpty,
    );
  });
}
