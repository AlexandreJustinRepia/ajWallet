import 'package:flutter_test/flutter_test.dart';
import 'package:aj_wallet/main.dart';
import 'package:aj_wallet/create_account_screen.dart';

void main() {
  testWidgets('Create Account screen shows initial text', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our "New Account" text is shown.
    expect(find.text('New Account'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
  });
}
