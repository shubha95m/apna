class SupabaseConfig {
  /// Default free tier Supabase project URL.
  /// Replace with your project URL from https://supabase.com/dashboard/project/<your-project-ref>
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://jkmdshurqjjcwshnfihi.supabase.co',
  );

  /// Default free tier Supabase Anon / Public Key.
  /// This key is safe to embed in client apps and is restricted by PostgreSQL Row Level Security (RLS).
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_YPGrNtYbfx5UER0nzeLz5g_n8plHmxe',
  );

  /// Check if live Supabase cloud credentials are configured
  static bool get isConfigured =>
      supabaseUrl != 'https://xyzcompanyproject.supabase.co' &&
      !supabaseAnonKey.contains('dummy_anon_key');
}

