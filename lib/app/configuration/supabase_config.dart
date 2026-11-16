import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  /// Loads Supabase URL dynamically from .env or --dart-define compile flags.
  /// Never hardcoded in the codebase for security.
  static String get supabaseUrl {
    return dotenv.env['SUPABASE_URL'] ??
        const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  }

  /// Loads Supabase Anon / Publishable Key dynamically from .env or --dart-define.
  /// Safe to use with PostgreSQL Row Level Security (RLS).
  static String get supabaseAnonKey {
    return dotenv.env['SUPABASE_ANON_KEY'] ??
        const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  }

  /// Returns true if valid Supabase cloud credentials are provided.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      supabaseUrl.startsWith('https://') &&
      !supabaseAnonKey.contains('dummy');
}
