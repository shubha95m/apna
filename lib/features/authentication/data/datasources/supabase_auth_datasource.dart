import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../app/configuration/supabase_config.dart';
import '../../domain/entities/user_entity.dart';

abstract interface class SupabaseAuthDataSource {
  Stream<UserEntity?> get authStateChanges;
  UserEntity? get currentUser;
  Future<UserEntity> signInWithPassword({required String email, required String password});
  Future<UserEntity> signUp({required String email, required String password, String? fullName});
  Future<UserEntity> signInOffline({required String email, String? fullName});
  Future<void> sendOtp(String email);
  Future<UserEntity> verifyOtp({required String email, required String token});
  Future<void> signOut();
  Future<bool> authenticateBiometrics();
}

class SupabaseAuthDataSourceImpl implements SupabaseAuthDataSource {
  final _localAuth = LocalAuthentication();
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );
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
        return;
      } catch (_) {}
    }

    // Offline / Local Vault Mode
    try {
      final savedEmail = await _secureStorage
          .read(key: 'apna_session_user_email')
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
      final savedName = await _secureStorage
          .read(key: 'apna_session_user_name')
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
      if (savedEmail != null) {
        final emailPart = savedEmail.split('@').first;
        final cleanId = emailPart.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
        final defaultName = emailPart.isNotEmpty ? '${emailPart[0].toUpperCase()}${emailPart.substring(1)}' : 'User';
        _cachedUser = UserEntity(
          id: 'usr-$cleanId-001',
          email: savedEmail,
          fullName: savedName ?? defaultName,
          createdAt: DateTime.now(),
        );
        _authStreamController.add(_cachedUser);
      }
    } catch (_) {}
  }

  @override
  Stream<UserEntity?> get authStateChanges => _authStreamController.stream;

  @override
  UserEntity? get currentUser => _cachedUser;

  @override
  Future<UserEntity> signInWithPassword({required String email, required String password}) async {
    if (SupabaseConfig.isConfigured) {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user!;
      final resolvedName = user.userMetadata?['full_name'] as String?;
      _cachedUser = UserEntity(
        id: user.id,
        email: user.email ?? email,
        fullName: resolvedName,
        createdAt: DateTime.parse(user.createdAt),
      );
      await _secureStorage.write(key: 'apna_session_user_email', value: email);
      if (resolvedName != null) {
        await _secureStorage.write(key: 'apna_session_user_name', value: resolvedName);
      }
      _authStreamController.add(_cachedUser);
      return _cachedUser!;
    }

    // Offline fallback for family development
    if (password.length < 6) {
      throw const AuthException('Password must be at least 6 characters.');
    }

    final emailPart = email.split('@').first;
    final cleanId = emailPart.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final defaultName = emailPart.isNotEmpty ? '${emailPart[0].toUpperCase()}${emailPart.substring(1)}' : 'User';
    _cachedUser = UserEntity(
      id: 'usr-$cleanId-001',
      email: email,
      fullName: defaultName,
      createdAt: DateTime.now(),
    );
    await _secureStorage.write(key: 'apna_session_user_email', value: email);
    await _secureStorage.write(key: 'apna_session_user_name', value: defaultName);
    _authStreamController.add(_cachedUser);
    return _cachedUser!;
  }

  @override
  Future<UserEntity> signUp({required String email, required String password, String? fullName}) async {
    if (SupabaseConfig.isConfigured) {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName ?? ''},
      );
      final user = response.user!;
      _cachedUser = UserEntity(
        id: user.id,
        email: user.email ?? email,
        fullName: fullName,
        createdAt: DateTime.parse(user.createdAt),
      );
      await _secureStorage.write(key: 'apna_session_user_email', value: email);
      if (fullName != null && fullName.isNotEmpty) {
        await _secureStorage.write(key: 'apna_session_user_name', value: fullName);
      }
      _authStreamController.add(_cachedUser);
      return _cachedUser!;
    }

    final emailPart = email.split('@').first;
    final cleanId = emailPart.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final effectiveName = (fullName != null && fullName.isNotEmpty)
        ? fullName
        : (emailPart.isNotEmpty ? '${emailPart[0].toUpperCase()}${emailPart.substring(1)}' : 'User');
    _cachedUser = UserEntity(
      id: 'usr-$cleanId-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      fullName: effectiveName,
      createdAt: DateTime.now(),
    );
    await _secureStorage.write(key: 'apna_session_user_email', value: email);
    await _secureStorage.write(key: 'apna_session_user_name', value: effectiveName);
    _authStreamController.add(_cachedUser);
    return _cachedUser!;
  }

  @override
  Future<UserEntity> signInOffline({required String email, String? fullName}) async {
    final emailPart = email.split('@').first;
    final cleanId = emailPart.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final effectiveName = (fullName != null && fullName.trim().isNotEmpty)
        ? fullName.trim()
        : (emailPart.isNotEmpty ? '${emailPart[0].toUpperCase()}${emailPart.substring(1)}' : 'User');
    _cachedUser = UserEntity(
      id: 'usr-$cleanId-001',
      email: email,
      fullName: effectiveName,
      createdAt: DateTime.now(),
    );
    await _secureStorage.write(key: 'apna_session_user_email', value: email);
    await _secureStorage.write(key: 'apna_session_user_name', value: effectiveName);
    _authStreamController.add(_cachedUser);
    return _cachedUser!;
  }

  @override
  Future<void> sendOtp(String email) async {
    if (SupabaseConfig.isConfigured) {
      await Supabase.instance.client.auth.signInWithOtp(email: email);
    }
  }

  @override
  Future<UserEntity> verifyOtp({required String email, required String token}) async {
    if (SupabaseConfig.isConfigured) {
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
      await _secureStorage.write(key: 'apna_session_user_email', value: email);
      _authStreamController.add(_cachedUser);
      return _cachedUser!;
    }

    _cachedUser = UserEntity(
      id: 'usr-otp-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      fullName: 'Verified Family User',
      createdAt: DateTime.now(),
    );
    await _secureStorage.write(key: 'apna_session_user_email', value: email);
    _authStreamController.add(_cachedUser);
    return _cachedUser!;
  }

  @override
  Future<void> signOut() async {
    if (SupabaseConfig.isConfigured) {
      await Supabase.instance.client.auth.signOut();
    }
    await _secureStorage.delete(key: 'apna_session_user_email');
    await _secureStorage.delete(key: 'apna_session_user_name');
    _cachedUser = null;
    _authStreamController.add(null);
  }

  @override
  Future<bool> authenticateBiometrics() async {
    final canCheck = await _localAuth.canCheckBiometrics;
    final isSupported = await _localAuth.isDeviceSupported();
    if (!canCheck || !isSupported) return true; // Graceful fallback if no hardware biometric

    return await _localAuth.authenticate(
      localizedReason: 'Authenticate to access your Apna encrypted family vault',
      options: const AuthenticationOptions(
        biometricOnly: false,
        stickyAuth: true,
      ),
    );
  }
}

