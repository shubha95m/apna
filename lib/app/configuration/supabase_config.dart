import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  /// Production Supabase Project credentials.
  /// Anon key is protected by PostgreSQL Row-Level Security (RLS) policies.
  static const String _defaultUrl = 'https://jkmdshurqjjcwshnfihi.supabase.co';
  static const String _defaultAnonKey = 'sb_publishable_YPGrNtYbfx5UER0nzeLz5g_n8plHmxe';

  /// Evaluates compile-time --dart-define first, then runtime .env, then production defaults.
  /// Zero manual configuration required on mobile installations.
  static String get supabaseUrl {
    const fromCompile = String.fromEnvironment('SUPABASE_URL');
    if (fromCompile.isNotEmpty) return fromCompile;
    if (dotenv.isInitialized) {
      final fromDotenv = dotenv.env['SUPABASE_URL'];
      if (fromDotenv != null && fromDotenv.isNotEmpty) return fromDotenv;
    }
    return _defaultUrl;
  }

  /// Evaluates compile-time --dart-define first, then runtime .env, then production defaults.
  static String get supabaseAnonKey {
    const fromCompile = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (fromCompile.isNotEmpty) return fromCompile;
    if (dotenv.isInitialized) {
      final fromDotenv = dotenv.env['SUPABASE_ANON_KEY'];
      if (fromDotenv != null && fromDotenv.isNotEmpty) return fromDotenv;
    }
    return _defaultAnonKey;
  }

  /// Returns true if valid Supabase cloud credentials are provided.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      supabaseUrl.startsWith('https://');
}
