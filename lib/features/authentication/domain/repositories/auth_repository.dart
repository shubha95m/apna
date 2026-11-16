import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/user_entity.dart';

abstract interface class AuthRepository {
  Stream<UserEntity?> get authStateChanges;
  UserEntity? get currentUser;
  Future<Result<UserEntity, AppFailure>> signInWithEmailPassword({
    required String email,
    required String password,
  });
  Future<Result<UserEntity, AppFailure>> signUpWithEmailPassword({
    required String email,
    required String password,
    String? fullName,
  });
  Future<Result<void, AppFailure>> sendMagicLinkOtp(String email);
  Future<Result<UserEntity, AppFailure>> verifyMagicLinkOtp({
    required String email,
    required String token,
  });
  Future<Result<void, AppFailure>> signOut();
  Future<Result<bool, AppFailure>> authenticateWithBiometrics();
}

