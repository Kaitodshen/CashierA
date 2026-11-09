import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What is typed or scanned into the top-bar search field. Register and
/// Catalog read it.
class TerminalSearchQuery extends Notifier<String> {
  @override
  String build() => '';

  String get query => state;

  set query(String value) => state = value;
}

final terminalSearchQueryProvider =
    NotifierProvider<TerminalSearchQuery, String>(TerminalSearchQuery.new);
