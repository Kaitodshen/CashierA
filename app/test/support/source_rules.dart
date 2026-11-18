import 'dart:io';

/// Files (paths relative to `app/`) that still contain one of [patterns].
/// Used by the redesign rule tests: old Material containers must not come
/// back once a page is on glass.
List<String> filesContaining(List<String> files, List<String> patterns) => [
  for (final path in files)
    if (patterns.any(File(path).readAsStringSync().contains)) path,
];

/// The old containers the glass design replaces: Material cards and
/// floating action buttons (list tiles are fine inside glass). `Card(` is
/// matched with a leading space or open paren so `GlassCard(` and
/// `StatCard(` do not count.
const oldContainers = ['FloatingActionButton', ' Card(', '(Card('];
