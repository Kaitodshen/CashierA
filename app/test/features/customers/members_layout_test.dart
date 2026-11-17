import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/design_system/widgets/data_display.dart';
import 'package:cashiera/features/customers/presentation/customers_screen.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/till_harness.dart';

CustomerRow row(String id, int points) => CustomerRow(
  id: id,
  name: id,
  pointsBalance: points,
  isActive: true,
  updatedAt: at,
);

Future<void> addCustomer(
  AppDatabase db,
  String id,
  String name, {
  int points = 0,
}) => db
    .into(db.localCustomers)
    .insert(
      LocalCustomersCompanion.insert(
        id: id,
        name: name,
        phone: const Value('081200000002'),
        pointsBalance: Value(points),
        isActive: true,
        updatedAt: at,
      ),
    );

void main() {
  test('member totals count the list, its points and its kasbon', () {
    final t = memberTotals(
      [row('a', 120), row('b', 30), row('c', 0)],
      {'a': const Money(15000), 'c': const Money(5000), 'zz': const Money(9)},
    );
    expect(t.members, 3);
    expect(t.points, 150);
    expect(t.owed, const Money(20000));
  });

  testWidgets('members list: stat cards and an initials avatar', (t) async {
    final (db, c) = await openTill(t, const Size(1280, 800));
    await addCustomer(db, 'c-rudi', 'Rudi Hartono', points: 45);
    await go(t, c, AppRoutes.customers);

    expect(find.byType(StatCard), findsNWidgets(3));
    expect(find.byKey(const Key('customer-c-rudi')), findsOneWidget);
    expect(find.text('RH'), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    await finish(t);
  });

  testWidgets('member detail goes back to the list', (t) async {
    final (db, c) = await openTill(t, const Size(1280, 800));
    await addCustomer(db, 'c-rudi', 'Rudi Hartono', points: 45);
    await go(t, c, AppRoutes.customers);

    await tapKey(t, 'customer-c-rudi');
    expect(find.byKey(const Key('customer-points')), findsOneWidget);
    await tapKey(t, 'member-back');
    expect(find.byKey(const Key('customer-search')), findsOneWidget);
    await finish(t);
  });

  testWidgets('long member names fit a phone', (t) async {
    final (db, c) = await openTill(t, const Size(360, 740));
    await addCustomer(db, 'c-long', 'Bapak Raden Mas Hadi Wijaya ' * 3);
    await go(t, c, AppRoutes.customers);
    expect(t.takeException(), isNull);

    // Three stacked stat cards come first on a phone.
    await t.scrollUntilVisible(
      find.byKey(const Key('customer-c-long')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tapKey(t, 'customer-c-long');
    expect(t.takeException(), isNull);
    await finish(t);
  });
}
