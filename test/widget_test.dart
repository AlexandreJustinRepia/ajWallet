import 'package:flutter_test/flutter_test.dart';
import 'package:root_exp/main.dart';

void main() {
  testWidgets('Create Account screen shows initial text', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our "New Account" text is shown.
    expect(find.text('New Account'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
  });
}
