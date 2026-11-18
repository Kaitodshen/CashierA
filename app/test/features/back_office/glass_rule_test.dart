import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/source_rules.dart';

void main() {
  test('back office and reports use glass dialogs, sheets and cards', () {
    final files = [
      for (final dir in ['lib/features/back_office', 'lib/features/reports'])
        for (final f in Directory(dir).listSync(recursive: true))
          if (f is File &&
              f.path.endsWith('.dart') &&
              !f.path.endsWith('.g.dart'))
            f.path,
    ];
    expect(
      filesContaining(files, [
        ...oldContainers,
        'AlertDialog(',
        'showModalBottomSheet',
      ]),
      isEmpty,
    );
  });
}
