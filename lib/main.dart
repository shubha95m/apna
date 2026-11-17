import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/app.dart';
import 'app/configuration/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Caught FlutterError: ${details.exceptionAsString()}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Caught PlatformDispatcher error: $error\n$stack');
    return true; // Prevents process crash
  };

  // 1. Load gitignored .env file if available
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('.env load notice (using production vault defaults): $e');
  }

  // 2. Initialize Supabase cloud credentials
  try {
    if (SupabaseConfig.isConfigured) {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
    }
  } catch (e) {
    debugPrint('Supabase initialization notice: $e');
  }

  runApp(const ProviderScope(child: ApnaApp()));
}
