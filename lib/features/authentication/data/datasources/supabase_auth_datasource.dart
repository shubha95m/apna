import 'dart:async';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../app/configuration/supabase_config.dart';
import '../../domain/entities/saved_device_account.dart';
import '../../domain/entities/user_entity.dart';

abstract interface class SupabaseAuthDataSource {
  Stream<UserEntity?> get authStateChanges;
  UserEntity? get currentUser;
  Future<UserEntity> signInWithPassword({required String email, required String password});
  Future<UserEntity> signUp({required String email, required String password, String? fullName});
  Future<UserEntity?> unlockWithBiometrics();
  Future<SavedDeviceAccount?> getSavedDeviceAccount();
  Future<void> clearSavedDeviceAccount();
  Future<void> sendOtp(String email);
  Future<UserEntity> verifyOtp({required String email, required String token});
  Future<void> signOut();
  Future<bool> authenticateBiometrics();
}

class SupabaseAuthDataSourceImpl implements SupabaseAuthDataSource {
  final _localAuth = LocalAuthentication();
  final _authStreamController = StreamController<UserEntity?>.broadcast();
  UserEntity? _cachedUser;

  SupabaseAuthDataSourceImpl() {
    _initialize();
  }

  Future<void> _initialize() async {
    if (SupabaseConfig.isConfigured) {
      try {
        final initialUser = Supabase.instance.client.auth.currentUser;
        if (initialUser != null) {
          _cachedUser = UserEntity(
            id: initialUser.id,
            email: initialUser.email ?? '',
            fullName: initialUser.userMetadata?['full_name'] as String?,
            createdAt: DateTime.parse(initialUser.createdAt),
          );
          _authStreamController.add(_cachedUser);
        }

        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
          final user = data.session?.user;
          if (user != null) {
            _cachedUser = UserEntity(
              id: user.id,
              email: user.email ?? '',
              fullName: user.userMetadata?['full_name'] as String?,
              createdAt: DateTime.parse(user.createdAt),
            );
            _authStreamController.add(_cachedUser);
          } else {
            _cachedUser = null;
            _authStreamController.add(null);
          }
        });
      } catch (_) {}
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges => _authStreamController.stream;

  @override
  UserEntity? get currentUser => _cachedUser;

  @override
  Future<UserEntity> signInWithPassword({required String email, required String password}) async {
    if (!SupabaseConfig.isConfigured) {
      throw const AuthException('Cloud service is unreachable. Please verify network connection.');
    }

    final response = await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user == null) {
      throw const AuthException('Failed to authenticate. User session not created.');
    }

    final resolvedName = (user.userMetadata?['full_name'] as String?)?.trim();
    _cachedUser = UserEntity(
      id: user.id,
      email: user.email ?? email,
      fullName: resolvedName,
      createdAt: DateTime.parse(user.createdAt),
    );

    // Save verified credentials to enable 1-touch PhonePe/GPay biometric unlock on next launch
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('apna_device_user_id', user.id);
    await prefs.setString('apna_device_user_email', user.email ?? email);
    if (resolvedName != null && resolvedName.isNotEmpty) {
      await prefs.setString('apna_device_user_name', resolvedName);
    }
    await prefs.setBool('apna_biometric_enabled', true);

    _authStreamController.add(_cachedUser);
    return _cachedUser!;
  }

  @override
  Future<UserEntity> signUp({required String email, required String password, String? fullName}) async {
    if (!SupabaseConfig.isConfigured) {
      throw const AuthException('Cloud service is unreachable. Please verify network connection.');
    }

    final response = await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName ?? ''},
    );
    final user = response.user;
    if (user == null) {
      throw const AuthException('Registration failed to create user record.');
    }

    _cachedUser = UserEntity(
      id: user.id,
      email: user.email ?? email,
      fullName: fullName,
      createdAt: DateTime.parse(user.createdAt),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('apna_device_user_id', user.id);
    await prefs.setString('apna_device_user_email', user.email ?? email);
    if (fullName != null && fullName.isNotEmpty) {
      await prefs.setString('apna_device_user_name', fullName);
    }
    await prefs.setBool('apna_biometric_enabled', true);

    _authStreamController.add(_cachedUser);
    return _cachedUser!;
  }

  @override
  Future<UserEntity?> unlockWithBiometrics() async {
    final authenticated = await authenticateBiometrics();
    if (!authenticated) return null;

    // 1. Recover active Supabase cloud session
    if (SupabaseConfig.isConfigured) {
      try {
        final currentUser = Supabase.instance.client.auth.currentUser;
        if (currentUser != null) {
          _cachedUser = UserEntity(
            id: currentUser.id,
            email: currentUser.email ?? '',
            fullName: currentUser.userMetadata?['full_name'] as String?,
            createdAt: DateTime.parse(currentUser.createdAt),
          );
          _authStreamController.add(_cachedUser);
          return _cachedUser;
        }
      } catch (_) {}
    }

    // 2. Recover verified account credentials saved on device
    final savedAccount = await getSavedDeviceAccount();
    if (savedAccount != null) {
      _cachedUser = UserEntity(
        id: savedAccount.userId.isNotEmpty ? savedAccount.userId : 'usr-verified',
        email: savedAccount.email,
        fullName: savedAccount.fullName,
        createdAt: DateTime.now(),
      );
      _authStreamController.add(_cachedUser);
      return _cachedUser;
    }

    return null;
  }

  @override
  Future<SavedDeviceAccount?> getSavedDeviceAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('apna_device_user_email');
    final userId = prefs.getString('apna_device_user_id');
    if (email == null || email.isEmpty) return null;

    final name = prefs.getString('apna_device_user_name');
    final enabled = prefs.getBool('apna_biometric_enabled') ?? true;

    return SavedDeviceAccount(
      userId: userId ?? '',
      email: email,
      fullName: name,
      biometricEnabled: enabled,
    );
  }

  @override
  Future<void> clearSavedDeviceAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('apna_device_user_id');
    await prefs.remove('apna_device_user_email');
    await prefs.remove('apna_device_user_name');
    await prefs.remove('apna_biometric_enabled');
  }

  @override
  Future<void> sendOtp(String email) async {
    if (SupabaseConfig.isConfigured) {
      await Supabase.instance.client.auth.signInWithOtp(email: email);
    }
  }

  @override
  Future<UserEntity> verifyOtp({required String email, required String token}) async {
    if (!SupabaseConfig.isConfigured) {
      throw const AuthException('Cloud service is unreachable.');
    }

    final response = await Supabase.instance.client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.magiclink,
    );
    final user = response.user!;
    _cachedUser = UserEntity(
      id: user.id,
      email: user.email ?? email,
      fullName: user.userMetadata?['full_name'] as String?,
      createdAt: DateTime.parse(user.createdAt),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('apna_device_user_id', user.id);
    await prefs.setString('apna_device_user_email', user.email ?? email);
    _authStreamController.add(_cachedUser);
    return _cachedUser!;
  }

  @override
  Future<void> signOut() async {
    if (SupabaseConfig.isConfigured) {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {}
    }
    await clearSavedDeviceAccount();
    _cachedUser = null;
    _authStreamController.add(null);
  }

  @override
  Future<bool> authenticateBiometrics() async {
    final canCheck = await _localAuth.canCheckBiometrics;
    final isSupported = await _localAuth.isDeviceSupported();
    if (!canCheck && !isSupported) return true; // Graceful fallback if device has no biometric sensor

    return await _localAuth.authenticate(
      localizedReason: 'Touch fingerprint sensor to unlock your Apna Workspace',
      options: const AuthenticationOptions(
        biometricOnly: false, // Allows device PIN/pattern fallback on Android if finger fails
        stickyAuth: true,
      ),
    );
  }
}
