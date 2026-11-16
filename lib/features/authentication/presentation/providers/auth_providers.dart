import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/supabase_auth_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

final supabaseAuthDataSourceProvider = Provider<SupabaseAuthDataSource>((ref) {
  return SupabaseAuthDataSourceImpl();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dataSource = ref.watch(supabaseAuthDataSourceProvider);
  return AuthRepositoryImpl(dataSource);
});

final authStateStreamProvider = StreamProvider<UserEntity?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

class AuthController extends StateNotifier<AsyncValue<UserEntity?>> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(AsyncValue.data(_repository.currentUser));

  Future<bool> login(String email, String password) async {
    state = const AsyncValue.loading();
    final result = await _repository.signInWithEmailPassword(email: email, password: password);
    return result.fold(
      (user) {
        state = AsyncValue.data(user);
        return true;
      },
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> register(String email, String password, String fullName) async {
    state = const AsyncValue.loading();
    final result = await _repository.signUpWithEmailPassword(
      email: email,
      password: password,
      fullName: fullName,
    );
    return result.fold(
      (user) {
        state = AsyncValue.data(user);
        return true;
      },
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
    );
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    await _repository.signOut();
    state = const AsyncValue.data(null);
  }

  Future<bool> unlockWithBiometrics() async {
    final result = await _repository.authenticateWithBiometrics();
    return result.dataOrNull ?? false;
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<UserEntity?>>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthController(repository);
});

