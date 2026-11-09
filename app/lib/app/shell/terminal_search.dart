import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What is typed or scanned into the top-bar field: the live `query` and
/// every Enter (`submissions` counts them so the same code twice still
/// fires).
typedef TerminalSearchState = ({
  String query,
  int submissions,
  String lastSubmitted,
});

/// The one search-and-scan field of Register and Catalog, in the top bar.
class TerminalSearch extends Notifier<TerminalSearchState> {
  @override
  TerminalSearchState build() => (query: '', submissions: 0, lastSubmitted: '');

  void type(String text) => state = (
    query: text,
    submissions: state.submissions,
    lastSubmitted: state.lastSubmitted,
  );

  void submit(String text) => state = (
    query: text,
    submissions: state.submissions + 1,
    lastSubmitted: text,
  );

  void clear() => state = (
    query: '',
    submissions: state.submissions,
    lastSubmitted: state.lastSubmitted,
  );
}

final terminalSearchProvider =
    NotifierProvider<TerminalSearch, TerminalSearchState>(TerminalSearch.new);
