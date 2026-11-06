import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/pos/cart.dart';
import 'package:cashiera/core/printing/printer_setting.dart';
import 'package:cashiera/core/printing/printer_transport.dart';
import 'package:cashiera/core/providers.dart';
import 'package:cashiera/features/sell/presentation/sell_providers.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/till_harness.dart';

const _drawerPulse = [0x1B, 0x70, 0, 25, 250];

bool _hasPulse(List<int> bytes) {
  for (var i = 0; i + 5 <= bytes.length; i++) {
    if (bytes[i] == 0x1B &&
        bytes[i + 1] == 0x70 &&
        bytes[i + 2] == 0 &&
        bytes[i + 3] == 25 &&
        bytes[i + 4] == 250) {
      return true;
    }
  }
  return false;
}

Future<void> _usePrinter(
  ProviderContainer container, {
  bool autoPrint = false,
  bool drawer = true,
}) => container
    .read(printerRepositoryProvider)
    .save(
      PrinterSetting(
        name: 'Kasir LAN',
        connection: PrinterConnection.network,
        address: '192.168.1.50',
        opensCashDrawer: drawer,
        autoPrint: autoPrint,
      ),
    );

/// Sells [qty] Mie Goreng (Rp 3.500 each) for cash [tendered].
Future<LocalOrderRow> _sell(
  ProviderContainer container,
  String id,
  int qty,
  int tendered,
) async {
  final ctx = container.read(saleContextProvider)!;
  final cart = Cart(
    orderId: id,
    startedAt: DateTime.now(),
    lines: [
      CartLine(
        id: 'line-$id',
        variantId: 'v-mie',
        productId: 'p-mie',
        productName: 'Mie Goreng Instan',
        variantName: 'Original',
        sku: 'MIE-GRG-ORI',
        unitCode: 'pcs',
        allowDecimal: false,
        unitPrice: const Money(3500),
        unitCost: const Money(2700),
        isTaxable: true,
        trackStock: true,
        quantity: Qty(qty * 1000),
      ),
    ],
  );
  final bill = calculateBill(
    lines: [for (final l in cart.lines) l.toPricing()],
    settings: ctx.config.pricing,
  );
  return await container
      .read(orderServiceProvider)
      .complete(
        cart: cart,
        bill: bill,
        settlement: settle(bill.grandTotal, [
          Tender(
            id: 'cash-$id',
            methodId: 'm-cash',
            kind: TenderKind.cash,
            amount: Money(tendered),
          ),
        ]),
        ctx: ctx,
      );
}

Future<void> _enter(WidgetTester tester, String key, String text) async {
  await tester.enterText(find.byKey(Key(key)), text);
  await tester.pump();
}

void main() {
  testWidgets('auto-print after a cash sale opens the drawer and marks it '
      'printed', (tester) async {
    final printer = FakePrinterTransport();
    final (db, container) = await openTill(
      tester,
      const Size(1280, 900),
      printer: printer,
    );
    await _usePrinter(container, autoPrint: true);

    await tapKey(tester, 'sell-item-MIE-GRG-ORI');
    await tapKey(tester, 'sell-pay');
    await tapKey(tester, 'pay-method-cash');
    await tapKey(tester, 'pay-quick-1');
    await tapKey(tester, 'pay-finish');

    expect(printer.sent, hasLength(1));
    expect(_hasPulse(printer.sent.single), isTrue);
    expect(printer.text, contains('Mie Goreng Instan Original'));
    expect(printer.text, contains('PST-T1-'));
    expect(await queueKinds(db), [
      'shift.open',
      'order.upsert',
      'order.mark_printed',
    ]);
    expect(find.text('Cetak ulang'), findsOneWidget);

    // A reprint is a copy and is audited.
    await waitForToasts(tester);
    await tapKey(tester, 'receipt-print');
    expect(printer.sent, hasLength(2));
    expect(printer.text, contains('SALINAN'));
    expect(_hasPulse(printer.sent.last), isFalse);
    expect((await queueKinds(db)).last, 'audit.log');
    expect((await lastQueued(db, 'audit.log'))['action'], 'receipt.reprinted');

    await waitForToasts(tester);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a printer that is off never blocks the sale', (tester) async {
    final printer = FakePrinterTransport()
      ..fail = const PrinterException('connect_failed');
    final (db, container) = await openTill(
      tester,
      const Size(1280, 900),
      printer: printer,
    );
    await _usePrinter(container, autoPrint: true);

    await tapKey(tester, 'sell-item-MIE-GRG-ORI');
    await tapKey(tester, 'sell-pay');
    await tapKey(tester, 'pay-method-cash');
    await tapKey(tester, 'pay-quick-0');
    await tapKey(tester, 'pay-finish');

    expect(find.byKey(const Key('receipt-new-sale')), findsOneWidget);
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(
      find.textContaining('Tidak bisa terhubung', findRichText: true),
      findsOneWidget,
    );
    expect(await queueKinds(db), ['shift.open', 'order.upsert']);
    final order = await db.select(db.localOrders).getSingle();
    expect(order.status, 'completed');
    expect(order.printedAt, isNull, reason: 'only marked once it printed');

    await waitForToasts(tester);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('cash out, then close the shift short with a note', (
    tester,
  ) async {
    final printer = FakePrinterTransport();
    final (db, container) = await openTill(
      tester,
      const Size(1280, 1400),
      printer: printer,
    );
    await _usePrinter(container);
    await _sell(container, 'o-1', 3, 20000);
    await go(tester, container, AppRoutes.shift);

    expect(
      tester.widget<Text>(find.byKey(const Key('shift-expected'))).data,
      'Rp 210.500',
    );

    // Too much: refused with what the drawer holds.
    await tapKey(tester, 'shift-cash-out');
    await _enter(tester, 'cash-amount', '300000');
    await _enter(tester, 'cash-reason', 'Setor ke bank');
    await tapKey(tester, 'cash-save');
    await tester.pump(const Duration(milliseconds: 600));
    expect(
      find.text('Uang di laci hanya Rp 210.500.', findRichText: true),
      findsOneWidget,
    );
    await waitForToasts(tester);

    await tapKey(tester, 'shift-cash-out');
    await _enter(tester, 'cash-amount', '10500');
    await _enter(tester, 'cash-reason', 'Setor ke bank');
    await tapKey(tester, 'cash-save');
    expect(
      tester.widget<Text>(find.byKey(const Key('shift-expected'))).data,
      'Rp 200.000',
    );
    expect(printer.sent.single, [0x1B, 0x40, ..._drawerPulse]);
    await waitForToasts(tester);

    // Count by note, then type the total instead.
    await tapKey(tester, 'shift-close');
    final hundred = find.byKey(const Key('denomination-100000'));
    await tester.tap(
      find.descendant(
        of: hundred,
        matching: find.byKey(const Key('denomination-plus')),
      ),
    );
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: hundred,
        matching: find.byKey(const Key('denomination-plus')),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('close-difference'))).data,
      'Pas',
    );
    await tester.tap(find.text('Masukkan total'));
    await tester.pumpAndSettle();
    await _enter(tester, 'close-total', '199500');
    expect(
      tester.widget<Text>(find.byKey(const Key('close-difference'))).data,
      'Kurang Rp 500',
    );

    await tester.ensureVisible(find.byKey(const Key('close-submit')));
    await tapKey(tester, 'close-submit');
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Jelaskan selisihnya.', findRichText: true), findsWidgets);
    await waitForToasts(tester);
    await _enter(tester, 'close-note', 'Uang receh kurang');
    await tester.ensureVisible(find.byKey(const Key('close-submit')));
    await tapKey(tester, 'close-submit');
    await tapKey(tester, 'close-confirm');

    // The Z report, printed and on screen.
    expect(find.text('Laporan Z'), findsWidgets);
    expect(find.text('-Rp 500'), findsOneWidget);
    expect(printer.text, contains('Laporan Z'));
    expect(printer.text, contains('Kas seharusnya'));
    final close = await lastQueued(db, 'shift.close');
    expect(close['counted_cash'], 199500);
    expect(close['client_expected_cash'], 200000);
    expect(close['note'], 'Uang receh kurang');
    expect(await queueKinds(db), [
      'shift.open',
      'order.upsert',
      'cash_movement.create',
      'shift.close',
    ]);
    expect(container.read(openShiftProvider).value, isNull);

    await waitForToasts(tester);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a printed sale is voided with the manager PIN; another is '
      'refunded in part', (tester) async {
    final printer = FakePrinterTransport();
    final (db, container) = await openTill(
      tester,
      const Size(1280, 1400),
      printer: printer,
    );
    await _usePrinter(container);
    final first = await _sell(container, 'o-1', 2, 7000);
    await container.read(orderServiceProvider).markPrinted(first.id);
    final second = await _sell(container, 'o-2', 3, 10500);

    // Void after print: reason, then the manager's PIN.
    await go(tester, container, AppRoutes.receipt(first.id));
    await tapKey(tester, 'receipt-void');
    await _enter(tester, 'text-dialog-field', 'Salah input');
    await tapKey(tester, 'text-dialog-save');
    expect(find.textContaining('setelah struk dicetak'), findsOneWidget);
    await approveAs(tester, manager);
    expect(find.byKey(const Key('receipt-status')), findsOneWidget);
    expect(find.text('VOID - DIBATALKAN'), findsOneWidget);
    final voided = await lastQueued(db, 'order.void');
    expect(voided['approved_by'], 'e-budi');
    expect(voided['voided_by'], 'e-eko');
    expect(_hasPulse(printer.sent.last), isTrue, reason: 'cash goes back');
    await waitForToasts(tester);

    // Refund 1 of 3 in cash, without restocking.
    await go(tester, container, AppRoutes.receipt(second.id));
    await tapKey(tester, 'receipt-refund');
    await tapKey(tester, 'refund-plus');
    expect(
      tester.widget<Text>(find.byKey(const Key('refund-total'))).data,
      'Rp 3.500',
    );
    await tapKey(tester, 'refund-restock');
    await _enter(tester, 'refund-reason', 'Kemasan sobek');
    await tester.ensureVisible(find.byKey(const Key('refund-submit')));
    await tapKey(tester, 'refund-submit');
    await approveAs(tester, manager);

    expect(
      find.byKey(const Key('refund-R-PST-T1-261106-0001')),
      findsOneWidget,
    );
    expect(printer.text, contains('REFUND'));
    expect(printer.text, contains('Disetujui: Budi Santoso'));
    final refund = await lastQueued(db, 'refund.create');
    expect(refund['amount'], 3500);
    expect(refund['restock'], isFalse);
    expect(refund['method_type'], 'cash');
    // Stock: 10 - 2 - 3 + 2 (void); the refund did not restock.
    expect((await db.select(db.stockLevels).getSingle()).quantityMilli, 7000);
    // A refunded sale cannot be voided any more.
    expect(find.byKey(const Key('receipt-void')), findsNothing);

    await waitForToasts(tester);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('printer settings: find, save and test a printer', (
    tester,
  ) async {
    final printer = FakePrinterTransport();
    final (_, container) = await openTill(
      tester,
      const Size(1280, 1200),
      printer: printer,
    );
    await go(tester, container, AppRoutes.printer);
    expect(find.text('Belum ada printer struk.'), findsOneWidget);

    await tapKey(tester, 'printer-search');
    await tester.tap(find.text('RPP02N'));
    await tester.pumpAndSettle();
    await tapKey(tester, 'printer-drawer');
    await tester.ensureVisible(find.byKey(const Key('printer-save')));
    await tapKey(tester, 'printer-save');
    final saved = await container.read(printerRepositoryProvider).current();
    expect(saved!.connection, PrinterConnection.ble);
    expect(saved.address, '66:22:B0:11:22:33');
    expect(saved.opensCashDrawer, isTrue);
    expect(saved.paperMm, 58, reason: 'the store paper width by default');

    await tapKey(tester, 'printer-test');
    expect(printer.text, contains('TES PRINTER'));
    expect(printer.text, contains('Kertas 58 mm - 32 kolom'));
    await waitForToasts(tester);

    // A network address must be usable.
    await tester.tap(find.text('Jaringan'));
    await tester.pumpAndSettle();
    await _enter(tester, 'printer-address', 'printer kasir');
    await tester.ensureVisible(find.byKey(const Key('printer-save')));
    await tapKey(tester, 'printer-save');
    expect(find.text('Alamat printer tidak valid.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
