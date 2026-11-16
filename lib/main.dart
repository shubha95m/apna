import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/app.dart';
import 'app/configuration/supabase_config.dart';
import 'features/legal_consent/presentation/consent_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load gitignored .env file
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('.env load notice (using fallback/offline vault): $e');
  }

  // 2. Initialize Supabase if credentials are provided in .env
  if (SupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
    } catch (e) {
      debugPrint('Supabase initialization notice: $e');
    }
  }

  runApp(const ProviderScope(child: ApnaRoot()));
}

class ApnaRoot extends StatefulWidget {
  const ApnaRoot({super.key});

  @override
  State<ApnaRoot> createState() => _ApnaRootState();
}

class _ApnaRootState extends State<ApnaRoot> {
  bool _consentChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifyLegalConsent();
    });
  }

  void _verifyLegalConsent() {
    // If first run, present DPDP Act 2023 Consent Gatekeeper Dialog
    if (!_consentChecked) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => IndiaLegalConsentDialog(
          onConsentGranted: (consent) {
            setState(() {
              _consentChecked = true;
            });
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const ApnaApp();
  }
}
