import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apna/app/app.dart';
import 'package:apna/features/authentication/domain/entities/user_entity.dart';
import 'package:apna/features/authentication/presentation/providers/auth_providers.dart';

void main() {
  testWidgets('Apna App redirects to LoginPage when unauthenticated', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => MockAuthController(null)),
        ],
        child: const ApnaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Apna Workspace'), findsOneWidget);
    expect(find.text('Sign In to Workspace'), findsOneWidget);
  });

  testWidgets('Apna App displays Dashboard when authenticated', (WidgetTester tester) async {
    final mockUser = UserEntity(
      id: 'usr-shubham-001',
      email: 'shubham@family.apna',
      fullName: 'Shubham Sharma',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => MockAuthController(mockUser)),
        ],
        child: const ApnaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Shubham'), findsOneWidget);
    expect(find.text('Pending Tasks'), findsOneWidget);
    expect(find.text('Upcoming Bills'), findsOneWidget);
  });

  testWidgets('ApnaApp launches without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => MockAuthController(null)),
        ],
        child: const ApnaApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Apna Workspace'), findsOneWidget);
  });
}

class MockAuthController extends StateNotifier<AsyncValue<UserEntity?>>
    implements AuthController {
  MockAuthController(UserEntity? initial) : super(AsyncValue.data(initial));

  @override
  Future<bool> login(String email, String password) async {
    state = AsyncValue.data(UserEntity(
      id: 'usr-1',
      email: email,
      fullName: 'Shubham Sharma',
      createdAt: DateTime.now(),
    ));
    return true;
  }

  @override
  Future<bool> register(String email, String password, String fullName) async {
    state = AsyncValue.data(UserEntity(
      id: 'usr-1',
      email: email,
      fullName: fullName,
      createdAt: DateTime.now(),
    ));
    return true;
  }

  @override
  Future<void> logout() async {
    state = const AsyncValue.data(null);
  }

  @override
  Future<void> signOut() => logout();

  @override
  Future<bool> unlockWithBiometrics() async {
    return true;
  }

  @override
  Future<void> clearSavedDeviceAccount() async {
    state = const AsyncValue.data(null);
  }
}
