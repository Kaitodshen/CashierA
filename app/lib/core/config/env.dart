/// Build-time configuration, passed with `--dart-define` (never committed):
///
///     flutter run --dart-define=SUPABASE_URL=https://xyz.supabase.co \
///                 --dart-define=SUPABASE_ANON_KEY=<publishable key> \
///                 --dart-define=PAYMENT_GATEWAY=midtrans
class AppEnv {
  const new({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    this.paymentGateway = '',
  });

  factory fromEnvironment() => const AppEnv(
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
    // ignore: avoid_redundant_argument_values, set by --dart-define
    paymentGateway: String.fromEnvironment('PAYMENT_GATEWAY'),
  );

  final String supabaseUrl;
  final String supabaseAnonKey;

  /// Dynamic QRIS: `midtrans` (Edge Functions), `mock` (demo, pays itself
  /// after a few seconds) or empty (gateway methods hidden).
  final String paymentGateway;

  bool get isConfigured =>
      Uri.tryParse(supabaseUrl)?.hasScheme == true &&
      supabaseUrl.startsWith('http') &&
      supabaseAnonKey.isNotEmpty;
}
