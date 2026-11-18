import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/design_system/theme.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/providers.dart';
import 'package:cashiera/core/session/session_controller.dart';
import 'package:cashiera/features/back_office/data/back_office_backend.dart';
import 'package:cashiera/features/back_office/presentation/set_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';

class FakeBackend implements BackOfficeBackend {
  bool acceptFails = false;
  final accepted = <String>[];
  final passwords = <String>[];

  @override
  Future<void> acceptInvite(String tokenHash) async {
    if (acceptFails) throw const BackendException('otp_expired', 'expired');
    accepted.add(tokenHash);
  }

  @override
  Future<void> setPassword(String password) async => passwords.add(password);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class SignedOutSession extends SessionController {
  int entered = 0;

  @override
  Future<SessionState> build() async => const SessionState(AppMode.signedOut);

  @override
  void enterBackOffice() => entered++;
}

late SignedOutSession session;

Future<void> pumpSetPassword(
  WidgetTester t,
  FakeBackend backend, {
  String? token = 'hash-123',
  Size size = const Size(1280, 800),
}) async {
  t.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(t.view.reset);
  session = SignedOutSession();
  final router = GoRouter(
    initialLocation: AppRoutes.adminSetPassword,
    routes: [
      GoRoute(
        path: AppRoutes.adminSetPassword,
        builder: (_, _) => SetPasswordScreen(tokenHash: token),
      ),
      GoRoute(
        path: AppRoutes.admin,
        builder: (_, _) => const Text('BACK OFFICE'),
      ),
      GoRoute(
        path: AppRoutes.adminSignIn,
        builder: (_, _) => const Text('SIGN IN'),
      ),
    ],
  );
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        backOfficeBackendProvider.overrideWithValue(backend),
        sessionControllerProvider.overrideWith(() => session),
      ],
      child: ToastificationWrapper(
        child: MaterialApp.router(
          theme: AppTheme.light(),
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

Future<void> submit(WidgetTester t, String a, String b) async {
  await t.enterText(find.byKey(const Key('set-password-1')), a);
  await t.enterText(find.byKey(const Key('set-password-2')), b);
  await t.tap(find.byKey(const Key('set-password-save')));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('an expired link says so and offers the sign-in page', (t) async {
    final backend = FakeBackend()..acceptFails = true;
    await pumpSetPassword(t, backend);
    expect(
      find.text(
        'Link undangan sudah tidak berlaku. '
        'Minta owner mengirim undangan baru.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('set-password-1')), findsNothing);
  });

  testWidgets('a link without a token is treated as expired', (t) async {
    final backend = FakeBackend();
    await pumpSetPassword(t, backend, token: null);
    expect(backend.accepted, isEmpty);
    expect(find.byKey(const Key('set-password-1')), findsNothing);
  });

  testWidgets('short and mismatched passwords are refused, then it signs in', (
    t,
  ) async {
    final backend = FakeBackend();
    await pumpSetPassword(t, backend);
    expect(backend.accepted, ['hash-123']);

    await submit(t, 'abc1234', 'abc1234');
    expect(find.text('Password minimal 8 karakter.'), findsOneWidget);
    await submit(t, 'abcd1234', 'abcd1235');
    expect(find.text('Password tidak sama.'), findsOneWidget);
    expect(backend.passwords, isEmpty);

    await submit(t, 'abcd1234', 'abcd1234');
    expect(backend.passwords, ['abcd1234']);
    expect(session.entered, 1);
    expect(find.text('BACK OFFICE'), findsOneWidget);
  });

  testWidgets('the form fits a short phone', (t) async {
    await pumpSetPassword(t, FakeBackend(), size: const Size(390, 640));
    expect(t.takeException(), isNull);
  });
}
