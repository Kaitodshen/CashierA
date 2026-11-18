import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/design_system/theme.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/features/back_office/data/back_office_backend.dart';
import 'package:cashiera/features/back_office/presentation/back_office_providers.dart';
import 'package:cashiera/features/back_office/presentation/stores_admin_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toastification/toastification.dart';

import '../../support/fake_staff_admin.dart';

int storeReads = 0;

Future<void> pumpStores(
  WidgetTester t,
  FakeStaffAdmin fake, {
  String role = 'owner',
  Size size = const Size(1280, 900),
}) async {
  t.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(t.view.reset);
  storeReads = 0;
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        staffAdminProvider.overrideWithValue(fake),
        principalProvider.overrideWith(
          (ref) async => Principal(
            kind: 'employee',
            employeeId: 'e-1',
            roleCode: role,
            permissions: const {'employee.manage', 'settings.manage'},
          ),
        ),
        backOfficeStoresProvider.overrideWith((ref) async {
          storeReads++;
          return const [StoreSummary(id: 's-pst', code: 'PST', name: 'Pusat')];
        }),
      ],
      child: ToastificationWrapper(
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // Like the other back-office pages, something keeps the shared
          // store list alive, so invalidating it re-reads it.
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                ref.watch(backOfficeStoresProvider);
                return const StoresAdminScreen();
              },
            ),
          ),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

Future<void> fillNewStore(WidgetTester t, String code) async {
  await t.tap(find.byKey(const Key('store-add')));
  await t.pumpAndSettle();
  await t.enterText(find.byKey(const Key('store-code')), code);
  await t.enterText(find.byKey(const Key('store-name')), 'CashierA Depok');
  await t.tap(find.byKey(const Key('store-save')));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('owner adds a store; codes are upper-cased; pickers refresh', (
    t,
  ) async {
    final fake = FakeStaffAdmin();
    await pumpStores(t, fake);
    expect(find.byKey(const Key('store-PST')), findsOneWidget);
    final readsBefore = storeReads;

    await fillNewStore(t, 'dp1');
    expect(fake.added.single.code, 'DP1');
    expect(fake.added.single.name, 'CashierA Depok');
    expect(fake.added.single.timezone, 'Asia/Jakarta');
    expect(storeReads, greaterThan(readsBefore));
    await t.pump(const Duration(seconds: 5));
  });

  testWidgets('a bad or duplicate code is explained', (t) async {
    final fake = FakeStaffAdmin();
    await pumpStores(t, fake);
    await fillNewStore(t, 'A');
    expect(find.text('Kode 2–5 huruf atau angka.'), findsOneWidget);
    expect(fake.added, isEmpty);

    fake.errors['addStore'] = 'duplicate_code';
    await t.enterText(find.byKey(const Key('store-code')), 'PST');
    await t.tap(find.byKey(const Key('store-save')));
    await t.pumpAndSettle();
    expect(find.text('Kode toko ini sudah dipakai.'), findsOneWidget);
    await t.pump(const Duration(seconds: 5));
  });

  testWidgets('owner edits a store but not its code', (t) async {
    final fake = FakeStaffAdmin();
    await pumpStores(t, fake);
    await t.tap(find.byKey(const Key('store-PST')));
    await t.pumpAndSettle();
    final code = t.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('store-code')),
        matching: find.byType(TextField),
      ),
    );
    expect(code.enabled, isFalse);
    await t.enterText(find.byKey(const Key('store-name')), 'Pusat Baru');
    await t.tap(find.byKey(const Key('store-save')));
    await t.pumpAndSettle();
    expect(fake.updated.single.$1, 's-pst');
    expect(fake.updated.single.$2.name, 'Pusat Baru');
    await t.pump(const Duration(seconds: 5));
  });

  testWidgets('a manager sees the stores but cannot change them', (t) async {
    await pumpStores(t, FakeStaffAdmin(), role: 'manager');
    expect(find.byKey(const Key('store-PST')), findsOneWidget);
    expect(find.byKey(const Key('store-add')), findsNothing);
    await t.tap(find.byKey(const Key('store-PST')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('store-save')), findsNothing);
  });

  testWidgets('stores fit a phone', (t) async {
    await pumpStores(
      t,
      FakeStaffAdmin(stores: [FakeStaffAdmin.pst, FakeStaffAdmin.bks]),
      size: const Size(390, 844),
    );
    expect(t.takeException(), isNull);
  });
}
