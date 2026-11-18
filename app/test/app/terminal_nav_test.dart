import 'package:cashiera/app/shell/terminal_nav.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('routes map to the five sidebar sections', () {
    expect(terminalSectionFor('/pos/sell'), TerminalSection.register);
    expect(terminalSectionFor('/pos/pay'), TerminalSection.register);
    expect(terminalSectionFor('/pos/receipt/abc'), TerminalSection.register);
    expect(terminalSectionFor('/pos/refund/abc'), TerminalSection.register);
    expect(terminalSectionFor('/pos/orders'), TerminalSection.register);
    expect(terminalSectionFor('/pos/tables'), TerminalSection.register);
    expect(terminalSectionFor('/pos/shift'), TerminalSection.overview);
    expect(terminalSectionFor('/pos/shift/close'), TerminalSection.overview);
    expect(
      terminalSectionFor('/pos/shift/report/s1'),
      TerminalSection.overview,
    );
    expect(terminalSectionFor('/pos/catalog'), TerminalSection.catalog);
    expect(terminalSectionFor('/pos/opname'), TerminalSection.catalog);
    expect(terminalSectionFor('/pos/customers'), TerminalSection.members);
    expect(terminalSectionFor('/pos/customers/c-1'), TerminalSection.members);
    expect(terminalSectionFor('/pos/printer'), TerminalSection.settings);
    expect(terminalSectionFor('/sync'), TerminalSection.settings);
    expect(terminalSectionFor('/pos/kitchen'), isNull);
  });

  test('each section opens its screen', () {
    expect(TerminalSection.register.route, '/pos/sell');
    expect(TerminalSection.overview.route, '/pos/shift');
    expect(TerminalSection.catalog.route, '/pos/catalog');
    expect(TerminalSection.members.route, '/pos/customers');
    expect(TerminalSection.settings.route, '/pos/printer');
  });

  test('held badge', () {
    expect(heldBadge(0), '');
    expect(heldBadge(-1), '');
    expect(heldBadge(7), '7');
    expect(heldBadge(99), '99');
    expect(heldBadge(100), '99+');
  });

  test('search only on Register and Catalog', () {
    expect(showsSearch('/pos/sell'), isTrue);
    expect(showsSearch('/pos/catalog'), isTrue);
    expect(showsSearch('/pos/shift'), isFalse);
    expect(showsSearch('/pos/customers'), isFalse);
  });
}
