import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/app.dart';
import 'app/configuration/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load gitignored .env file if available
  try {
    await dotenv.load(fileName: '.env').timeout(const Duration(seconds: 2));
  } catch (e) {
    debugPrint('.env load notice (using production vault defaults): $e');
  }

  // 2. Initialize Supabase cloud credentials
  if (SupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      ).timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('Supabase initialization notice: $e');
    }
  }

  runApp(const ProviderScope(child: ApnaApp()));
}
