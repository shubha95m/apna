import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apna/app/app.dart';
import 'package:apna/features/authentication/domain/entities/user_entity.dart';
import 'package:apna/features/authentication/presentation/providers/auth_providers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Real ApnaApp launches and renders password LoginPage when no saved device account exists', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ApnaApp(),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Apna Workspace'), findsOneWidget);
    expect(find.text('Sign In to Workspace'), findsOneWidget);
  });

  testWidgets('Real ApnaApp displays PhonePe/GPay 1-touch Biometric Unlock when saved device account exists', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'apna_device_user_id': 'c8755d35-21d6-43e0-9ded-e887fb83629d',
      'apna_device_user_email': 'shubham.sharma75319@gmail.com',
      'apna_device_user_name': 'Shubham Sharma',
      'apna_biometric_enabled': true,
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: ApnaApp(),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Welcome back,'), findsOneWidget);
    expect(find.text('Shubham Sharma'), findsOneWidget);
    expect(find.text('shubham.sharma75319@gmail.com'), findsOneWidget);
    expect(find.text('Unlock with Touch / Face ID'), findsOneWidget);
    expect(find.text('Touch fingerprint sensor to unlock'), findsOneWidget);
  });

  testWidgets('Auth state transitions from LoginPage to Dashboard on login and back on logout', (WidgetTester tester) async {
    late WidgetRef containerRef;

    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            containerRef = ref;
            return const ApnaApp();
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    // 1. Initial State: Unauthenticated -> LoginPage
    expect(find.text('Sign In to Workspace'), findsOneWidget);

    // 2. Simulate User Login
    final testUser = UserEntity(
      id: 'usr-audit-test',
      email: 'test@apna.dev',
      fullName: 'Audit Test User',
      createdAt: DateTime.now(),
    );
    containerRef.read(authControllerProvider.notifier).state = AsyncValue.data(testUser);

    await tester.pump();
    await tester.pumpAndSettle();

    // 3. User is now authenticated -> Dashboard is visible
    expect(find.text('Sign In to Workspace'), findsNothing);
    expect(find.textContaining('Audit'), findsOneWidget);
    expect(find.text('Pending Tasks'), findsOneWidget);

    // 4. Simulate User Sign Out
    await containerRef.read(authControllerProvider.notifier).signOut();
    await tester.pump();
    await tester.pumpAndSettle();

    // 5. Back to LoginPage
    expect(find.text('Sign In to Workspace'), findsOneWidget);
  });

  testWidgets('Navigation from LoginPage to RegisterPage works cleanly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ApnaApp(),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    // Scroll to and tap "Create Workspace" link
    final createWorkspaceFinder = find.textContaining('Create Workspace');
    expect(createWorkspaceFinder, findsOneWidget);
    await tester.ensureVisible(createWorkspaceFinder);
    await tester.pumpAndSettle();
    await tester.tap(createWorkspaceFinder);
    await tester.pumpAndSettle();

    // Verify on Register Page
    expect(find.text('Create New Workspace'), findsOneWidget);
    expect(find.text('Get Started with Apna'), findsOneWidget);
    expect(find.text('Create Family Workspace'), findsOneWidget);
  });
}
