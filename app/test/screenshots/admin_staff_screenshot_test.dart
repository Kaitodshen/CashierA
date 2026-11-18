@Tags(['screenshots'])
library;

import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/design_system/theme.dart';
import 'package:cashiera/core/design_system/visual_effects.dart';
import 'package:cashiera/core/design_system/widgets/app_background.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/providers.dart';
import 'package:cashiera/features/back_office/data/back_office_backend.dart';
import 'package:cashiera/features/back_office/data/staff_admin_repository.dart';
import 'package:cashiera/features/back_office/presentation/admin_shell.dart';
import 'package:cashiera/features/back_office/presentation/back_office_providers.dart';
import 'package:cashiera/features/back_office/presentation/set_password_screen.dart';
import 'package:cashiera/features/back_office/presentation/staff_admin_screen.dart';
import 'package:cashiera/features/back_office/presentation/stores_admin_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';

import '../support/fake_staff_admin.dart';
import 'shells_screenshot_test.dart' show loadFonts, phone, shot, tablet;

/// Review screenshots of Settings → Stores, Settings → Staff and the
/// set-password page, written to `test/screenshots/out/` (git-ignored).

class _AcceptingBackend implements BackOfficeBackend {
  @override
  Future<void> acceptInvite(String tokenHash) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AdminStaff person(
  String id,
  String name,
  String role, {
  List<String> stores = const ['s-pst'],
  bool login = false,
  bool confirmed = false,
  bool pin = true,
  String? email,
  String? phone,
}) => AdminStaff(
  id: id,
  fullName: name,
  phone: phone,
  email: email,
  roleCode: role,
  roleName: role,
  storeIds: role == 'owner' ? const [] : stores,
  hasLogin: login,
  loginConfirmed: confirmed,
  hasPin: pin,
  isActive: true,
);

FakeStaffAdmin sample() => FakeStaffAdmin(
  stores: [
    FakeStaffAdmin.pst,
    FakeStaffAdmin.bks,
    const AdminStore(
      id: 's-mks',
      code: 'MKS',
      name: 'CashierA Makassar',
      address: 'Jl. Somba Opu 9',
      phone: '0411-555',
      timezone: 'Asia/Makassar',
      isActive: true,
    ),
  ],
  staff: [
    person(
      'e1',
      'Andi Pratama',
      'owner',
      login: true,
      confirmed: true,
      email: 'owner@toko.id',
    ),
    person(
      'e2',
      'Budi Santoso',
      'manager',
      login: true,
      confirmed: true,
      email: 'budi@toko.id',
      phone: '081211110011',
    ),
    person(
      'e3',
      'Citra Lestari',
      'manager',
      stores: ['s-bks'],
      login: true,
      email: 'citra@toko.id',
    ),
    person('e4', 'Eko Saputra', 'cashier', phone: '081211110021'),
    person('e5', 'Gilang Ramadhan', 'cashier', stores: ['s-bks'], pin: false),
    person('e6', 'Kurniawan Hadi', 'inventory'),
  ],
);

Widget adminApp(String location) => ProviderScope(
  overrides: [
    visualEffectsProvider.overrideWith((ref) => Stream.value(true)),
    staffAdminProvider.overrideWithValue(sample()),
    backOfficeBackendProvider.overrideWithValue(_AcceptingBackend()),
    principalProvider.overrideWith(
      (ref) async => const Principal(
        kind: 'employee',
        employeeId: 'e1',
        fullName: 'Andi Pratama',
        roleCode: 'owner',
        roleName: 'Owner',
        permissions: {'employee.manage', 'settings.manage'},
      ),
    ),
  ],
  child: ToastificationWrapper(
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: const Locale('id'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => AppBackground(child: child!),
      routerConfig: GoRouter(
        initialLocation: location,
        routes: [
          GoRoute(
            path: AppRoutes.adminSetPassword,
            builder: (_, _) => const SetPasswordScreen(tokenHash: 'x'),
          ),
          ShellRoute(
            builder: (_, _, child) => AdminShell(child: child),
            routes: [
              GoRoute(
                path: AppRoutes.adminStores,
                builder: (_, _) => const StoresAdminScreen(),
              ),
              GoRoute(
                path: AppRoutes.adminStaff,
                builder: (_, _) => const StaffAdminScreen(),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
);

void main() {
  setUpAll(loadFonts);

  for (final (name, size) in [('tablet', tablet), ('phone', phone)]) {
    for (final (page, location) in [
      ('stores', AppRoutes.adminStores),
      ('staff', AppRoutes.adminStaff),
      ('set_password', AppRoutes.adminSetPassword),
    ]) {
      shot('$page $name', (t) async {
        t.view
          ..physicalSize = size
          ..devicePixelRatio = 1;
        addTearDown(t.view.reset);
        await t.pumpWidget(adminApp(location));
        await t.pumpAndSettle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('out/admin_${page}_$name.png'),
        );
      });
    }
  }
}
