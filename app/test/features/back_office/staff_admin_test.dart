import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/design_system/theme.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/features/back_office/data/staff_admin_repository.dart';
import 'package:cashiera/features/back_office/presentation/back_office_providers.dart';
import 'package:cashiera/features/back_office/presentation/staff_admin_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toastification/toastification.dart';

import '../../support/fake_staff_admin.dart';

const owner = AdminStaff(
  id: 'e-owner',
  fullName: 'Andi Pratama',
  roleCode: 'owner',
  roleName: 'Owner',
  storeIds: [],
  hasLogin: true,
  loginConfirmed: true,
  hasPin: false,
  isActive: true,
);
const eko = AdminStaff(
  id: 'e-eko',
  fullName: 'Eko Saputra',
  phone: '0812',
  roleCode: 'cashier',
  roleName: 'Cashier',
  storeIds: ['s-pst'],
  hasLogin: false,
  loginConfirmed: false,
  hasPin: true,
  isActive: true,
);
const gilang = AdminStaff(
  id: 'e-gilang',
  fullName: 'Gilang Ramadhan',
  roleCode: 'cashier',
  roleName: 'Cashier',
  storeIds: ['s-bks'],
  hasLogin: false,
  loginConfirmed: false,
  hasPin: false,
  isActive: true,
);

FakeStaffAdmin fake() => FakeStaffAdmin(
  stores: [FakeStaffAdmin.pst, FakeStaffAdmin.bks],
  staff: [owner, eko, gilang],
);

Future<void> pumpStaff(
  WidgetTester t,
  FakeStaffAdmin admin, {
  bool asOwner = true,
  Size size = const Size(1280, 900),
}) async {
  t.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        staffAdminProvider.overrideWithValue(admin),
        principalProvider.overrideWith(
          (ref) async => asOwner
              ? const Principal(
                  kind: 'employee',
                  employeeId: 'e-owner',
                  roleCode: 'owner',
                  permissions: {'employee.manage'},
                )
              : const Principal(
                  kind: 'employee',
                  employeeId: 'e-budi',
                  roleCode: 'manager',
                  permissions: {'employee.manage'},
                  storeIds: ['s-pst'],
                ),
        ),
      ],
      child: ToastificationWrapper(
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: StaffAdminScreen()),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

Future<void> openAction(WidgetTester t, String id, String action) async {
  await t.tap(find.byKey(Key('staff-actions-$id')));
  await t.pumpAndSettle();
  await t.tap(find.byKey(Key(action)));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('owner adds a cashier to a store; owner is never offered', (
    t,
  ) async {
    final admin = fake();
    await pumpStaff(t, admin);
    expect(find.byKey(const Key('staff-e-eko')), findsOneWidget);

    await t.tap(find.byKey(const Key('staff-add')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('staff-name')), 'Sari Wulandari');
    // The list behind the dialog shows the owner's role chip once.
    final ownersBefore = find.text('Owner').evaluate().length;
    await t.tap(find.byKey(const Key('staff-role')));
    await t.pumpAndSettle();
    // The open menu lists the four staff roles and never Owner.
    expect(find.text('Owner').evaluate().length, ownersBefore);
    for (final label in ['Manager', 'Kasir', 'Dapur', 'Gudang']) {
      expect(find.text(label), findsWidgets);
    }
    expect(staffRoles, hasLength(4));
    await t.tap(find.text('Kasir').last);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('staff-store-PST')));
    await t.tap(find.byKey(const Key('staff-save')));
    await t.pumpAndSettle();

    final (id, input) = admin.saved.single;
    expect(id, isNull);
    expect(input.fullName, 'Sari Wulandari');
    expect(input.roleCode, 'cashier');
    expect(input.storeIds, ['s-pst']);
    await t.pump(const Duration(seconds: 5));
  });

  testWidgets('a PIN is typed twice and the server explains a weak one', (
    t,
  ) async {
    final admin = fake();
    await pumpStaff(t, admin);

    await openAction(t, 'e-eko', 'staff-pin');
    await t.enterText(find.byKey(const Key('pin-1')), '1357');
    await t.enterText(find.byKey(const Key('pin-2')), '1358');
    await t.tap(find.byKey(const Key('pin-save')));
    await t.pumpAndSettle();
    expect(find.text('PIN tidak sama.'), findsOneWidget);
    expect(admin.pins, isEmpty);

    admin.errors['setPin'] = 'weak_pin';
    await t.enterText(find.byKey(const Key('pin-1')), '1111');
    await t.enterText(find.byKey(const Key('pin-2')), '1111');
    await t.tap(find.byKey(const Key('pin-save')));
    await t.pumpAndSettle();
    expect(find.text('PIN terlalu mudah ditebak.'), findsOneWidget);

    admin.errors.remove('setPin');
    await t.enterText(find.byKey(const Key('pin-1')), '2468');
    await t.enterText(find.byKey(const Key('pin-2')), '2468');
    await t.tap(find.byKey(const Key('pin-save')));
    await t.pumpAndSettle();
    expect(admin.pins.single, ('e-eko', '2468'));
    await t.pump(const Duration(seconds: 5));
  });

  testWidgets('invite by email, and a taken email is explained', (t) async {
    final admin = fake();
    await pumpStaff(t, admin);

    admin.errors['invite'] = 'email_taken';
    await openAction(t, 'e-eko', 'staff-invite');
    await t.enterText(find.byKey(const Key('invite-email')), 'eko@toko.id');
    await t.tap(find.byKey(const Key('invite-send')));
    await t.pumpAndSettle();
    expect(find.text('Email ini sudah dipakai orang lain.'), findsOneWidget);

    admin.errors.remove('invite');
    await t.tap(find.byKey(const Key('invite-send')));
    await t.pumpAndSettle();
    expect(admin.invites.single, ('e-eko', 'eko@toko.id'));
    await t.pump(const Duration(seconds: 5));
  });

  testWidgets('deactivating asks first', (t) async {
    final admin = fake();
    await pumpStaff(t, admin);
    await openAction(t, 'e-gilang', 'staff-toggle');
    expect(admin.active, isEmpty);
    await t.tap(find.byKey(const Key('staff-toggle-confirm')));
    await t.pumpAndSettle();
    expect(admin.active.single, ('e-gilang', false));
    await t.pump(const Duration(seconds: 5));
  });

  testWidgets('the owner may set their own PIN, nothing else on their row', (
    t,
  ) async {
    await pumpStaff(t, fake());
    await t.tap(find.byKey(const Key('staff-actions-e-owner')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('staff-pin')), findsOneWidget);
    expect(find.byKey(const Key('staff-invite')), findsNothing);
    expect(find.byKey(const Key('staff-toggle')), findsNothing);
  });

  testWidgets('a manager works only with their own store', (t) async {
    await pumpStaff(t, fake(), asOwner: false);
    expect(find.byKey(const Key('staff-actions-e-eko')), findsOneWidget);
    expect(find.byKey(const Key('staff-actions-e-gilang')), findsNothing);
    expect(find.byKey(const Key('staff-actions-e-owner')), findsNothing);

    await t.tap(find.byKey(const Key('staff-add')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('staff-store-PST')), findsOneWidget);
    expect(find.byKey(const Key('staff-store-BKS')), findsNothing);
  });

  testWidgets('staff fit a phone', (t) async {
    await pumpStaff(t, fake(), size: const Size(390, 844));
    expect(t.takeException(), isNull);
  });
}
