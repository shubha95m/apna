import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:apna/app/theme/app_colors.dart';
import 'package:apna/app/theme/app_typography.dart';
import '../../domain/entities/saved_device_account.dart';
import '../providers/auth_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _usePasswordFallback = false;
  bool _didAutoPromptBiometric = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _triggerAutoBiometric(SavedDeviceAccount savedAccount) {
    if (_didAutoPromptBiometric) return;
    _didAutoPromptBiometric = true;
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      return; // In widget tests, do not block test runner with pending native biometric prompts
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_usePasswordFallback) {
        _handleBiometricUnlock();
      }
    });
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
        userFriendlyMsg = 'Incorrect email or password. Please verify your credentials.';
      } else if (rawError.contains('rate_limit') || rawError.contains('over_email_send_rate_limit')) {
        userFriendlyMsg = 'Too many attempts. Please wait a moment and try again.';
      }
      setState(() => _errorMessage = userFriendlyMsg);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMsg), backgroundColor: ApnaColors.error),
      );
    }
  }

  Future<void> _handleBiometricUnlock() async {
    setState(() => _errorMessage = null);
    final savedAccount = ref.read(savedDeviceAccountProvider).valueOrNull;
    final success = await ref.read(authControllerProvider.notifier).unlockWithBiometrics();
    if (!mounted) return;
    if (success) {
      context.go('/');
    } else if (savedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in with email and password once to link your fingerprint to this device.'),
          backgroundColor: ApnaColors.primary,
        ),
      );
    }
  }

  Future<void> _switchAccount() async {
    await ref.read(authControllerProvider.notifier).clearSavedDeviceAccount();
    setState(() {
      _usePasswordFallback = true;
      _emailController.clear();
      _passwordController.clear();
      _errorMessage = null;
    });
    ref.invalidate(savedDeviceAccountProvider);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final savedAccountAsync = ref.watch(savedDeviceAccountProvider);

    return Scaffold(
      backgroundColor: ApnaColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: savedAccountAsync.maybeWhen(
              data: (savedAccount) {
                if (savedAccount != null && !_usePasswordFallback) {
                  _triggerAutoBiometric(savedAccount);
                  return _buildPhonePeBiometricUnlockView(context, savedAccount, isLoading);
                }
                return _buildPasswordForm(context, isLoading, savedAccount);
              },
              orElse: () => _buildPasswordForm(context, isLoading, null),
            ),
          ),
        ),
      ),
    );
  }

  /// PhonePe / GPay / Banking style 1-touch Biometric Quick Unlock View
  Widget _buildPhonePeBiometricUnlockView(
    BuildContext context,
    SavedDeviceAccount account,
    bool isLoading,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: ApnaColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 36.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // User Avatar with Initial
            CircleAvatar(
              radius: 36,
              backgroundColor: ApnaColors.primary,
              child: Text(
                account.initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Welcome back,',
              style: TextStyle(
                fontSize: 14,
                color: ApnaColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              account.displayName,
              style: ApnaTypography.headingMedium.copyWith(fontSize: 22),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              account.email,
              style: const TextStyle(fontSize: 13, color: ApnaColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Fingerprint scanner button
            InkWell(
              onTap: isLoading ? null : _handleBiometricUnlock,
              borderRadius: BorderRadius.circular(50),
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ApnaColors.primary.withOpacity(0.08),
                  border: Border.all(color: ApnaColors.primary.withOpacity(0.3), width: 2),
                ),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(strokeWidth: 3, color: ApnaColors.primary),
                        )
                      : const Icon(
                          Icons.fingerprint_rounded,
                          size: 54,
                          color: ApnaColors.primary,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Touch fingerprint sensor to unlock',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: ApnaColors.textSecondary,
              ),
            ),
            const SizedBox(height: 28),

            // Primary Unlock Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: isLoading ? null : _handleBiometricUnlock,
                icon: const Icon(Icons.fingerprint_rounded, size: 20),
                label: const Text(
                  'Unlock with Touch / Face ID',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: ApnaColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Password Fallback Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _usePasswordFallback = true;
                    _emailController.text = account.email;
                  });
                },
                icon: const Icon(Icons.lock_outline_rounded, size: 18, color: ApnaColors.textPrimary),
                label: const Text(
                  'Enter Password Instead',
                  style: TextStyle(color: ApnaColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: ApnaColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Switch Account Button
            TextButton(
              onPressed: isLoading ? null : _switchAccount,
              child: const Text(
                'Use another account',
                style: TextStyle(color: ApnaColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Standard Cloud Login Form (Email & Password)
  Widget _buildPasswordForm(
    BuildContext context,
    bool isLoading,
    SavedDeviceAccount? savedAccount,
  ) {
    return Card(
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
                      'Secure Cloud Login for Personal & Family Vault',
                      style: ApnaTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Back to Biometric button if returning from fingerprint screen
              if (savedAccount != null) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _usePasswordFallback = false),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: Text(
                      'Back to Fingerprint (${savedAccount.firstName})',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Email Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'your.email@example.com',
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
                  child: Row(
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
              const SizedBox(height: 12),

              // Prominent Fingerprint / Biometric Quick Unlock Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : _handleBiometricUnlock,
                  icon: const Icon(Icons.fingerprint_rounded, size: 22, color: ApnaColors.primary),
                  label: Text(
                    savedAccount != null
                        ? 'Unlock with Fingerprint (${savedAccount.displayName})'
                        : 'Unlock with Biometrics (Touch / Face ID)',
                    style: const TextStyle(
                      color: ApnaColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: ApnaColors.primary.withOpacity(0.4), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

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
                        'Supabase Cloud Auth • Encrypted Vault • DPDP Act 2023 Compliant',
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
    );
  }
}
