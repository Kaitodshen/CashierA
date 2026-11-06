import 'package:cashiera/app/app.dart';
import 'package:cashiera/core/config/env.dart';
import 'package:cashiera/core/providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('without Supabase keys the app shows the setup screen', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('id', 'ID')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appEnvProvider.overrideWithValue(
            const AppEnv(supabaseUrl: '', supabaseAnonKey: ''),
          ),
        ],
        child: const CashierApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Konfigurasi belum lengkap'), findsOneWidget);
  });
}
