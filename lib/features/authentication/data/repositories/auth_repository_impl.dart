import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/supabase_auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseAuthDataSource _dataSource;

  AuthRepositoryImpl(this._dataSource);

  @override
  Stream<UserEntity?> get authStateChanges => _dataSource.authStateChanges;

  @override
  UserEntity? get currentUser => _dataSource.currentUser;

  @override
  Future<Result<UserEntity, AppFailure>> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _dataSource.signInWithPassword(email: email, password: password);
      return Success(user);
    } catch (e) {
      return Failure(AuthFailure('Login failed: ${e.toString()}'));
    }
  }

  @override
  Future<Result<UserEntity, AppFailure>> signUpWithEmailPassword({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final user = await _dataSource.signUp(email: email, password: password, fullName: fullName);
      return Success(user);
    } catch (e) {
      return Failure(AuthFailure('Sign up failed: ${e.toString()}'));
    }
  }

  @override
  Future<Result<void, AppFailure>> sendMagicLinkOtp(String email) async {
    try {
      await _dataSource.sendOtp(email);
      return const Success(null);
    } catch (e) {
      return Failure(AuthFailure('Failed to send OTP: ${e.toString()}'));
    }
  }

  @override
  Future<Result<UserEntity, AppFailure>> verifyMagicLinkOtp({
    required String email,
    required String token,
  }) async {
    try {
      final user = await _dataSource.verifyOtp(email: email, token: token);
      return Success(user);
    } catch (e) {
      return Failure(AuthFailure('OTP verification failed: ${e.toString()}'));
    }
  }

  @override
  Future<Result<void, AppFailure>> signOut() async {
    try {
      await _dataSource.signOut();
      return const Success(null);
    } catch (e) {
      return Failure(AuthFailure('Sign out failed: ${e.toString()}'));
    }
  }

  @override
  Future<Result<bool, AppFailure>> authenticateWithBiometrics() async {
    try {
      final success = await _dataSource.authenticateBiometrics();
      return Success(success);
    } catch (e) {
      return Failure(AuthFailure('Biometric authentication failed: ${e.toString()}'));
    }
  }
}

