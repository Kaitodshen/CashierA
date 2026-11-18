import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/design_system/widgets/data_display.dart';
import 'package:cashiera/features/shift/presentation/overview_widgets.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/till_harness.dart';

ShiftReport report() => ShiftReport.fromJson(const {
  'report': 'X',
  'shift': {'id': 's1', 'opened_at': '2026-11-06T01:00:00Z'},
  'sales': {'orders': 3, 'grand_total': 60000, 'average_basket': 20000},
  'payments': [
    {
      'payment_method_id': 'm-cash',
      'name': 'Tunai',
      'method_type': 'cash',
      'count': 1,
      'amount': 10000,
    },
    {
      'payment_method_id': 'm-qris',
      'name': 'QRIS',
      'method_type': 'qris',
      'count': 1,
      'amount': 30000,
    },
    {
      'payment_method_id': 'm-card',
      'name': 'Kartu',
      'method_type': 'card',
      'count': 1,
      'amount': 20000,
    },
  ],
  'cash': {'opening_cash': 200000},
});

void main() {
  test('overview numbers come from the X report', () {
    final n = overviewNumbers(report());
    expect(n.gross, const Money(60000));
    expect(n.orders, 3);
    expect(n.averageBasket, const Money(20000));
    expect(n.openingCash, const Money(200000));
    expect(n.nonCash, const Money(50000)); // QRIS + card
  });

  testWidgets('an open shift with no sales shows four cards at Rp 0', (
    t,
  ) async {
    final (_, c) = await openTill(t, const Size(1280, 900));
    await go(t, c, AppRoutes.shift);
    expect(find.byType(StatCard), findsNWidgets(4));
    expect(
      t.widget<Text>(find.byKey(const Key('shift-expected'))).data,
      'Rp 200.000',
    );
    expect(find.text('Rp 0'), findsWidgets);
    expect(t.takeException(), isNull);
  });

  testWidgets('a sale shows up in recent orders', (t) async {
    final (_, c) = await openTill(t, const Size(1280, 900));
    await tapKey(t, 'sell-item-MIE-GRG-ORI');
    await tapKey(t, 'sell-pay');
    await tapKey(t, 'pay-method-cash');
    await tapKey(t, 'pay-quick-0');
    await tapKey(t, 'pay-finish');
    await go(t, c, AppRoutes.shift);
    expect(find.byKey(const Key('overview-recent')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('overview-recent')),
        matching: find.textContaining(RegExp('^PST-T1-')),
      ),
      findsOneWidget,
    );
    await finish(t);
  });

  testWidgets('phone: the dashboard does not overflow', (t) async {
    final (_, c) = await openTill(t, const Size(360, 740));
    await go(t, c, AppRoutes.shift);
    expect(t.takeException(), isNull);
  });
}
