import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/design_system/widgets/data_display.dart';
import 'package:cashiera/core/pos/fnb_service.dart';
import 'package:cashiera/core/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/till_harness.dart';
import 'fnb_flow_test.dart' show FakeKitchenQueue, makeCafe, waiter;

KitchenTicket longTicket() => KitchenTicket.fromJson({
  'order_id': 'o-9',
  'order_number': 'PST-T1-261106-0009',
  'station': 'kitchen',
  'status': 'new',
  'order_type': 'dine_in',
  'table_name': 'Meja Teras Belakang Dekat Taman',
  'guest_count': 4,
  'created_at': at.toIso8601String(),
  'note': 'Tamu ulang tahun, keluarkan bersamaan ' * 2,
  'items': [
    {
      'name': 'Nasi Goreng Kampung Spesial Telur Mata Sapi Ekstra Pedas ' * 2,
      'quantity': 2,
      'note': 'Tanpa bawang, sambal dipisah, kerupuk dua bungkus ' * 2,
      'modifiers': const <String>['Level 5', 'Extra telur'],
    },
  ],
});

void main() {
  testWidgets('tables: glass tiles with a status chip', (t) async {
    final (db, c) = await openTill(t, const Size(1280, 900), staff: waiter);
    await makeCafe(db);
    await t.pumpAndSettle();
    await go(t, c, AppRoutes.tables);

    expect(find.byType(AppBar), findsNothing);
    expect(
      find.ancestor(
        of: find.byKey(const Key('pos-table-status-Meja 7')),
        matching: find.byType(StatusChip),
      ),
      findsOneWidget,
    );
    await finish(t);
  });

  testWidgets('kitchen: a long ticket fits a phone', (t) async {
    final queue = FakeKitchenQueue([longTicket()]);
    final (db, c) = await openTill(
      t,
      const Size(360, 740),
      staff: waiter,
      overrides: [kitchenQueueSourceProvider.overrideWithValue(queue)],
    );
    await makeCafe(db);
    await go(t, c, AppRoutes.kitchen);

    expect(find.byType(AppBar), findsNothing);
    expect(
      find.byKey(const Key('ticket-PST-T1-261106-0009-kitchen')),
      findsOneWidget,
    );
    expect(t.takeException(), isNull);
    await finish(t);
  });
}
