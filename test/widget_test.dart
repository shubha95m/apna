import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apna/app/app.dart';

void main() {
  testWidgets('Apna App boots into Dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ApnaApp()));
    await tester.pumpAndSettle();

    expect(find.text('Good Morning, Shubham'), findsOneWidget);
    expect(find.text('Pending Tasks'), findsOneWidget);
    expect(find.text('Upcoming Bills'), findsOneWidget);
  });
}
