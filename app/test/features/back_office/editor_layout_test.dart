import 'package:flutter_test/flutter_test.dart';

import '../../support/source_rules.dart';

void main() {
  test('product editor and import are on glass', () {
    const dir = 'lib/features/back_office/presentation';
    expect(
      filesContaining(
        ['$dir/product_editor_screen.dart', '$dir/import_screen.dart'],
        [...oldContainers, 'DataTable('],
      ),
      isEmpty,
    );
  });
}
