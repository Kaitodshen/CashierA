@Tags(['screenshots'])
library;

import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/design_system/theme.dart';
import 'package:cashiera/core/design_system/widgets/app_background.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/providers.dart';
import 'package:cashiera/features/startup/presentation/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/fnb/fnb_flow_test.dart'
    show FakeKitchenQueue, makeCafe, ticket, waiter;
import '../support/till_harness.dart';
import 'shells_screenshot_test.dart' show loadFonts, phone, shot, tablet;
import 'terminal_screens_screenshot_test.dart' show sampleData;

/// Review screenshots of the phase 2b terminal flows, written to
/// `test/screenshots/out/` (git-ignored). Not goldens: nothing is compared.

Future<void> snap(WidgetTester t, String name) => expectLater(
  find.byType(MaterialApp),
  matchesGoldenFile('out/flow_$name.png'),
);

Future<void> tapVisible(WidgetTester t, String key) async {
  await t.ensureVisible(find.byKey(Key(key)));
  await t.pumpAndSettle();
  await tapKey(t, key);
}

/// Two items in the cart, then one tender on the payment screen.
Future<void> toPayment(WidgetTester t, ProviderContainer c) async {
  await tapKey(t, 'sell-item-MIE-GRG-ORI');
  await tapKey(t, 'sell-item-TEH-BTL-350');
  await go(t, c, AppRoutes.pay);
  await tapVisible(t, 'pay-method-cash');
  await t.enterText(find.byKey(const Key('pay-amount')), '5000');
  await tapVisible(t, 'pay-add');
  await tapVisible(t, 'pay-method-cash');
}

Future<void> sellOne(WidgetTester t, ProviderContainer c) async {
  await tapKey(t, 'sell-item-MIE-GRG-ORI');
  await go(t, c, AppRoutes.pay);
  await tapVisible(t, 'pay-method-cash');
  await tapVisible(t, 'pay-quick-1');
  await tapVisible(t, 'pay-finish');
  await waitForToasts(t);
}

void main() {
  setUpAll(loadFonts);

  for (final (name, size) in [('tablet', tablet), ('phone', phone)]) {
    shot('welcome $name', (t) async {
      t.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            locale: const Locale('id'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => AppBackground(child: child!),
            home: const WelcomeScreen(),
          ),
        ),
      );
      await t.pumpAndSettle();
      await snap(t, 'welcome_$name');
    });

    shot('pin lock $name', (t) async {
      await openTill(t, size);
      if (size == phone) await tapKey(t, 'terminal-more');
      await tapKey(t, 'terminal-lock');
      await tapKey(t, 'staff-e-eko');
      await snap(t, 'pin_lock_$name');
      await finish(t);
    });

    shot('payment $name', (t) async {
      final (db, c) = await openTill(t, size);
      await sampleData(db);
      await t.pumpAndSettle();
      await toPayment(t, c);
      await t.scrollUntilVisible(
        find.byKey(const Key('pay-due')),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      await snap(t, 'payment_$name');
      await finish(t);
    });

    shot('receipt and orders $name', (t) async {
      final (db, c) = await openTill(t, size);
      await sampleData(db);
      await t.pumpAndSettle();
      await sellOne(t, c);
      await snap(t, 'receipt_$name');
      await go(t, c, AppRoutes.orders);
      await snap(t, 'orders_$name');
      await finish(t);
    });

    shot('close shift $name', (t) async {
      final (_, c) = await openTill(t, size);
      await go(t, c, AppRoutes.shiftClose);
      await snap(t, 'close_shift_$name');
      await finish(t);
    });

    shot('tables and kitchen $name', (t) async {
      final queue = FakeKitchenQueue([
        ticket('kitchen', 'Nasi Goreng'),
        ticket('bar', 'Es Teh'),
      ]);
      final (db, c) = await openTill(
        t,
        size,
        staff: waiter,
        overrides: [kitchenQueueSourceProvider.overrideWithValue(queue)],
      );
      await makeCafe(db);
      await go(t, c, AppRoutes.tables);
      await snap(t, 'tables_$name');
      await go(t, c, AppRoutes.kitchen);
      await snap(t, 'kitchen_$name');
      await finish(t);
    });

    shot('discount dialog $name', (t) async {
      await openTill(t, size);
      await tapKey(t, 'sell-item-MIE-GRG-ORI');
      if (size == tablet) {
        await tapKey(t, 'sell-bill-discount');
        await snap(t, 'discount_dialog_$name');
      }
      await finish(t);
    });
  }
}
