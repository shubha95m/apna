import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apna/app/app.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Real ApnaApp launches and renders LoginPage when unauthenticated', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ApnaApp(),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Apna Workspace'), findsOneWidget);
    expect(find.text('Sign In to Workspace'), findsOneWidget);
    expect(find.text('Unlock with Biometrics (Touch / Face ID)'), findsOneWidget);
  });
}
