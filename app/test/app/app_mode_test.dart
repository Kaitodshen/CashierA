import 'package:cashiera/app/app_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const all = [
    AppRoutes.splash,
    AppRoutes.setup,
    AppRoutes.welcome,
    AppRoutes.pair,
    AppRoutes.lock,
    AppRoutes.pos,
    AppRoutes.sync,
    AppRoutes.adminSignIn,
    AppRoutes.admin,
  ];

  /// Where each location ends up (null redirect = stays).
  Map<String, String> resolve(AppMode mode, {bool isWeb = false}) => {
    for (final location in all)
      location: redirectFor(mode, location, isWeb: isWeb) ?? location,
  };

  test('setupRequired always shows setup', () {
    expect(resolve(AppMode.setupRequired).values.toSet(), {AppRoutes.setup});
  });

  test('starting shows the splash', () {
    expect(resolve(AppMode.starting).values.toSet(), {AppRoutes.splash});
  });

  test('signedOut allows welcome, pair and sign-in only', () {
    final r = resolve(AppMode.signedOut);
    expect(r[AppRoutes.pair], AppRoutes.pair);
    expect(r[AppRoutes.adminSignIn], AppRoutes.adminSignIn);
    expect(r[AppRoutes.pos], AppRoutes.welcome);
    expect(r[AppRoutes.admin], AppRoutes.welcome);
    expect(r[AppRoutes.lock], AppRoutes.welcome);
  });

  test('a locked terminal can only show the PIN screen', () {
    expect(resolve(AppMode.terminalLocked).values.toSet(), {AppRoutes.lock});
  });

  test('an unlocked terminal shows POS and sync, nothing else', () {
    final r = resolve(AppMode.terminalUnlocked);
    expect(r[AppRoutes.sync], AppRoutes.sync);
    expect(r[AppRoutes.pos], AppRoutes.pos);
    expect(r[AppRoutes.admin], AppRoutes.pos);
    expect(r[AppRoutes.lock], AppRoutes.pos);
    for (final page in [AppRoutes.catalog, AppRoutes.opname]) {
      expect(redirectFor(AppMode.terminalUnlocked, page, isWeb: false), isNull);
      expect(
        redirectFor(AppMode.terminalLocked, page, isWeb: false),
        AppRoutes.lock,
      );
      expect(
        redirectFor(AppMode.backOffice, page, isWeb: false),
        AppRoutes.admin,
      );
    }
    expect(
      redirectFor(
        AppMode.terminalUnlocked,
        AppRoutes.adminProducts,
        isWeb: false,
      ),
      AppRoutes.pos,
    );
  });

  test('back office stays inside /admin but not on the sign-in page', () {
    final r = resolve(AppMode.backOffice);
    expect(r[AppRoutes.admin], AppRoutes.admin);
    expect(r[AppRoutes.adminSignIn], AppRoutes.admin);
    expect(r[AppRoutes.pos], AppRoutes.admin);
    expect(redirectFor(AppMode.backOffice, '/admin/stores', isWeb: true), null);
    for (final page in [
      AppRoutes.adminProducts,
      AppRoutes.adminProduct('p-1'),
      AppRoutes.adminCategories,
      AppRoutes.adminSuppliers,
      AppRoutes.adminStock,
      AppRoutes.adminImport,
    ]) {
      expect(redirectFor(AppMode.backOffice, page, isWeb: true), isNull);
      expect(redirectFor(AppMode.signedOut, page, isWeb: true), isNotNull);
    }
  });

  test('web never shows terminal screens', () {
    for (final mode in [
      AppMode.signedOut,
      AppMode.terminalLocked,
      AppMode.terminalUnlocked,
    ]) {
      final r = resolve(mode, isWeb: true);
      expect(r.values.toSet(), {AppRoutes.adminSignIn}, reason: '$mode');
    }
  });
}
