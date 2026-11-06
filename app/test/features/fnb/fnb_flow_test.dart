import 'dart:convert';

import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/pos/fnb_service.dart';
import 'package:cashiera/core/printing/printer_setting.dart';
import 'package:cashiera/core/providers.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/till_harness.dart';

const waiter = StaffMember(
  employeeId: 'e-eko',
  fullName: 'Eko Saputra',
  roleCode: 'cashier',
  permissions: {'pos.sell', 'shift.manage', 'kitchen.view'},
  pinHash: '1234',
);

/// Turns the harness store into a cafe: a kitchen dish, a bar drink (by
/// its category), Meja 7, and a kitchen and a bar printer.
Future<void> makeCafe(AppDatabase db) async {
  await (db.update(db.localStores)..where((s) => s.id.equals(store))).write(
    const LocalStoresCompanion(fnbMode: Value(true)),
  );
  await db.batch((b) {
    b
      ..insert(
        db.categories,
        CategoriesCompanion.insert(
          id: 'c-minum',
          name: 'Minuman',
          sortOrder: 1,
          kitchenStation: const Value('bar'),
          isActive: true,
          updatedAt: at,
        ),
      )
      ..insert(
        db.products,
        ProductsCompanion.insert(
          id: 'p-nasi',
          unitId: 'u-pcs',
          name: 'Nasi Goreng',
          productType: 'standard',
          trackStock: false,
          isTaxable: true,
          kitchenStation: const Value('kitchen'),
          isActive: true,
          updatedAt: at,
        ),
      )
      ..insert(
        db.products,
        ProductsCompanion.insert(
          id: 'p-teh',
          categoryId: const Value('c-minum'),
          unitId: 'u-pcs',
          name: 'Es Teh',
          productType: 'standard',
          trackStock: false,
          isTaxable: true,
          isActive: true,
          updatedAt: at,
        ),
      );
    for (final (id, product, sku, price) in [
      ('v-nasi', 'p-nasi', 'NSI-GRG', 25000),
      ('v-teh', 'p-teh', 'TEH-ES', 8000),
    ]) {
      b.insert(
        db.productVariants,
        ProductVariantsCompanion.insert(
          id: id,
          productId: product,
          name: 'Default',
          sku: sku,
          price: price,
          cost: price ~/ 3,
          sortOrder: 1,
          isActive: true,
          updatedAt: at,
        ),
      );
    }
    b.insert(
      db.mirrorRecords,
      MirrorRecordsCompanion.insert(
        sourceTable: 'dining_tables',
        pk: 't-7',
        data: jsonEncode({
          'id': 't-7',
          'store_id': store,
          'name': 'Meja 7',
          'area': 'Dalam',
          'capacity': 4,
          'status': 'available',
          'is_active': true,
        }),
        updatedAt: at,
      ),
    );
  });
  final printers = PrinterRepository(db);
  for (final slot in [PrinterRepository.kitchenId, PrinterRepository.barId]) {
    await printers.save(
      PrinterSetting(
        name: 'Printer $slot',
        connection: PrinterConnection.network,
        address: slot == 'bar' ? '192.168.1.61' : '192.168.1.60',
        paperMm: 80,
      ),
      slot: slot,
    );
  }
}

class FakeKitchenQueue implements KitchenQueueSource {
  new(this.tickets);
  List<KitchenTicket> tickets;
  final stations = <String?>[];

  @override
  Future<List<KitchenTicket>> fetch({String? station}) async {
    stations.add(station);
    return [
      for (final t in tickets)
        if (station == null || t.station == station) t,
    ];
  }

  @override
  Stream<void> changes(String storeId) => const Stream.empty();
}

KitchenTicket ticket(String station, String item, {String status = 'new'}) =>
    KitchenTicket.fromJson({
      'order_id': 'o-1',
      'order_number': 'PST-T1-261106-0001',
      'station': station,
      'status': status,
      'order_type': 'dine_in',
      'table_name': 'Meja 7',
      'guest_count': 2,
      'created_at': at.toIso8601String(),
      'items': [
        {
          'name': item,
          'quantity': 1,
          'note': null,
          'modifiers': const <String>[],
        },
      ],
    });

void main() {
  testWidgets('dine-in: seat Meja 7, send to the kitchen, add more', (
    tester,
  ) async {
    final printer = FakePrinterTransport();
    final (db, container) = await openTill(
      tester,
      const Size(1280, 900),
      staff: waiter,
      printer: printer,
    );
    await makeCafe(db);
    await tester.pumpAndSettle();

    await go(tester, container, AppRoutes.tables);
    expect(find.text('Kosong'), findsOneWidget);
    await tapKey(tester, 'pos-table-Meja 7');
    await tester.enterText(find.byKey(const Key('table-guests')), '2');
    await tapKey(tester, 'table-guests-ok');
    expect(find.text('Meja 7 · 2 tamu'), findsOneWidget);

    await tapKey(tester, 'sell-item-NSI-GRG');
    await tapKey(tester, 'sell-item-TEH-ES');
    await tapKey(tester, 'sell-send-kitchen');

    // One ticket per station, each on its own printer, without prices.
    expect(printer.sent, hasLength(2));
    final tickets = printer.sent.map(latin1.decode).toList();
    final kitchen = tickets.firstWhere((t) => t.contains('DAPUR'));
    final bar = tickets.firstWhere((t) => t.contains('BAR'));
    expect(kitchen, contains('Nasi Goreng'));
    expect(kitchen, isNot(contains('Es Teh')));
    expect(bar, contains('Es Teh'));
    expect(bar, contains('Meja 7'));
    expect(kitchen, isNot(contains('25.000')));

    final order = await lastQueued(db, 'order.upsert');
    expect(order['status'], 'held');
    expect(order['order_type'], 'dine_in');
    expect(order['table_id'], 't-7');
    expect(order['guest_count'], 2);
    expect(
      [for (final i in order['items'] as List) (i as Map)['kitchen_station']],
      ['kitchen', 'bar'],
    );
    await waitForToasts(tester);

    // The table is taken by that bill; tapping it resumes the bill.
    await go(tester, container, AppRoutes.tables);
    expect(find.text('Terisi'), findsOneWidget);
    expect(
      find.byKey(const Key('pos-table-clear-Meja 7')),
      findsNothing,
      reason: 'cannot clear a table with an open bill',
    );
    await tapKey(tester, 'pos-table-Meja 7');
    expect(find.text('PST-T1-261106-0001'), findsWidgets);

    // A second Nasi: only the kitchen gets a ticket, marked as an addition.
    await tapKey(tester, 'sell-item-NSI-GRG');
    await tapKey(tester, 'sell-send-kitchen');
    expect(printer.sent, hasLength(3));
    final extra = latin1.decode(printer.sent.last);
    expect(extra, contains('DAPUR'));
    expect(extra, contains('TAMBAHAN'));
    expect(extra, contains('1 x Nasi Goreng'));
    expect(
      await db.select(db.localOrders).get(),
      hasLength(1),
      reason: 'still one bill on Meja 7',
    );

    await waitForToasts(tester);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('kitchen display: station filter and Mulai → Siap', (
    tester,
  ) async {
    final queue = FakeKitchenQueue([
      ticket('kitchen', 'Nasi Goreng'),
      ticket('bar', 'Es Teh'),
    ]);
    final (db, container) = await openTill(
      tester,
      const Size(1280, 900),
      staff: waiter,
      overrides: [kitchenQueueSourceProvider.overrideWithValue(queue)],
    );
    await makeCafe(db);
    await go(tester, container, AppRoutes.kitchen);

    const kitchenKey = 'ticket-PST-T1-261106-0001-kitchen';
    const barKey = 'ticket-PST-T1-261106-0001-bar';
    expect(find.byKey(const Key(kitchenKey)), findsOneWidget);
    expect(find.byKey(const Key(barKey)), findsOneWidget);

    await tapKey(tester, 'kitchen-station-bar');
    expect(queue.stations.last, 'bar');
    expect(find.byKey(const Key(kitchenKey)), findsNothing);
    await tapKey(tester, 'kitchen-station-all');

    await tapKey(tester, 'ticket-next-PST-T1-261106-0001-kitchen');
    final sent = await lastQueued(db, 'kitchen.status');
    expect(sent['order_id'], 'o-1');
    expect(sent['station'], 'kitchen');
    expect(sent['status'], 'preparing');
    expect(
      find.descendant(
        of: find.byKey(const Key(kitchenKey)),
        matching: find.text('Siap'),
      ),
      findsOneWidget,
      reason: 'shown at once, before the server confirms',
    );

    // Served tickets leave the screen.
    await tapKey(tester, 'ticket-next-PST-T1-261106-0001-kitchen');
    await tapKey(tester, 'ticket-next-PST-T1-261106-0001-kitchen');
    expect((await lastQueued(db, 'kitchen.status'))['status'], 'served');
    expect(find.byKey(const Key(kitchenKey)), findsNothing);
    expect(find.byKey(const Key(barKey)), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
