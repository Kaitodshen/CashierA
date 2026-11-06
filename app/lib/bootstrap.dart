import 'package:cashiera/app/app.dart';
import 'package:cashiera/core/config/env.dart';
import 'package:cashiera/core/network/secure_session_storage.dart';
import 'package:cashiera/core/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();

  final env = AppEnv.fromEnvironment();
  if (env.isConfigured) {
    await Supabase.initialize(
      url: env.supabaseUrl,
      publishableKey: env.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        localStorage: SecureSessionStorage(),
      ),
    );
  }

  runApp(
    ProviderScope(
      overrides: [appEnvProvider.overrideWithValue(env)],
      child: const CashierApp(),
    ),
  );
}
