/// Build-time configuration, passed with `--dart-define` (never committed):
///
///     flutter run --dart-define=SUPABASE_URL=https://xyz.supabase.co \
///                 --dart-define=SUPABASE_ANON_KEY=<publishable key>
class AppEnv {
  const new({required this.supabaseUrl, required this.supabaseAnonKey});

  factory fromEnvironment() => const AppEnv(
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  final String supabaseUrl;
  final String supabaseAnonKey;

  bool get isConfigured =>
      Uri.tryParse(supabaseUrl)?.hasScheme == true &&
      supabaseUrl.startsWith('http') &&
      supabaseAnonKey.isNotEmpty;
}
