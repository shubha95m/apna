import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:apna/app/theme/app_colors.dart';
import 'package:apna/app/theme/app_typography.dart';
import '../providers/auth_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'shubham@family.apna');
  final _passwordController = TextEditingController(text: '123123');
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _errorMessage = null);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final success = await ref.read(authControllerProvider.notifier).login(
          email,
          password,
        );

    if (!mounted) return;
    if (success) {
      context.go('/');
    } else {
      final rawError = ref.read(authControllerProvider).error?.toString() ?? 'Invalid credentials';
      String userFriendlyMsg = rawError;
      if (rawError.contains('invalid_credentials') || rawError.contains('Invalid login credentials')) {
        userFriendlyMsg = 'Invalid cloud credentials. The user account has not yet been confirmed in Supabase.';
      } else if (rawError.contains('rate_limit') || rawError.contains('over_email_send_rate_limit')) {
        userFriendlyMsg = 'Supabase email rate limit exceeded. You can use Offline Local Vault mode.';
      }
      setState(() => _errorMessage = userFriendlyMsg);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMsg), backgroundColor: ApnaColors.error),
      );
    }
  }

  Future<void> _enterOfflineVault({String? email}) async {
    setState(() => _errorMessage = null);
    final targetEmail = (email != null && email.isNotEmpty) ? email : _emailController.text.trim();
    final effectiveEmail = targetEmail.isNotEmpty ? targetEmail : 'shubham@family.apna';
    final success = await ref.read(authControllerProvider.notifier).loginOffline(
          email: effectiveEmail,
          fullName: effectiveEmail.contains('shubham') ? 'Shubham Sharma' : effectiveEmail.split('@').first,
        );
    if (!mounted) return;
    if (success) {
      context.go('/');
    }
  }

  Future<void> _handleBiometric() async {
    setState(() => _errorMessage = null);
    final authenticated = await ref.read(authControllerProvider.notifier).unlockWithBiometrics();
    if (!mounted) return;
    if (authenticated) {
      await _enterOfflineVault();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: ApnaColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: ApnaColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Logo & Title
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: ApnaColors.primary,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: Text('A', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text('Apna Workspace', style: ApnaTypography.headingMedium),
                            const SizedBox(height: 4),
                            const Text(
                              'Secure Login for Personal & Family Vault',
                              style: ApnaTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          hintText: 'name@family.apna',
                          prefixIcon: const Icon(Icons.email_outlined, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Please enter your email';
                          if (!val.contains('@')) return 'Please enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Please enter your password';
                          if (val.length < 6) return 'Password must be at least 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 22),

                      // Inline Error Notification Banner
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: ApnaColors.error.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: ApnaColors.error.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, size: 18, color: ApnaColors.error),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(color: ApnaColors.error, fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                height: 36,
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.lock_open_rounded, size: 16, color: ApnaColors.primary),
                                  label: const Text('Enter in Offline Local Vault Mode', style: TextStyle(color: ApnaColors.primary, fontSize: 12.5, fontWeight: FontWeight.w600)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: ApnaColors.primary),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () => _enterOfflineVault(email: _emailController.text.trim()),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed: isLoading ? null : _handleLogin,
                          style: FilledButton.styleFrom(
                            backgroundColor: ApnaColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isLoading
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Sign In to Workspace', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Biometric Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: isLoading ? null : _handleBiometric,
                          icon: const Icon(Icons.fingerprint_rounded, size: 22, color: ApnaColors.accentDark),
                          label: const Text('Unlock with Biometrics (Touch / Face ID)', style: TextStyle(color: ApnaColors.accentDark, fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: ApnaColors.accentLight),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Quick Demo / Local Vault Button
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: TextButton.icon(
                          onPressed: isLoading ? null : () => _enterOfflineVault(),
                          icon: const Icon(Icons.bolt_rounded, size: 20, color: ApnaColors.accentDark),
                          label: const Text('Quick Demo / Enter Local Vault', style: TextStyle(color: ApnaColors.accentDark, fontWeight: FontWeight.w600, fontSize: 14)),
                          style: TextButton.styleFrom(
                            backgroundColor: ApnaColors.accentLight.withOpacity(0.18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Register Link
                      Center(
                        child: TextButton(
                          onPressed: () => context.go('/register'),
                          child: const Text.rich(
                            TextSpan(
                              text: "Don't have a family workspace yet? ",
                              style: ApnaTypography.bodySmall,
                              children: [
                                TextSpan(
                                  text: 'Create Workspace',
                                  style: TextStyle(color: ApnaColors.blue, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Divider(height: 28),

                      // DPDP Act 2023 Compliance Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: ApnaColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.verified_user_outlined, size: 16, color: ApnaColors.accentDark),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Supabase Auth (Free Tier) • Encrypted Vault • DPDP Act 2023 Compliant',
                                style: TextStyle(fontSize: 10.5, color: ApnaColors.textSecondary, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

