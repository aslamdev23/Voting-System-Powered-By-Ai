import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'main.dart';
import 'main_page.dart';

void main() {
  testWidgets('MainPage displays correctly', (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the AppBar title is "Voting App".
    expect(find.text('Voting App'), findsOneWidget);

    // Verify that the booth ID is displayed (assuming boothId is '1').
    expect(find.text('Booth 1'), findsOneWidget);

    // Verify that the current date and time are displayed.
    // Since the date/time updates every second, we can only check for the prefix.
    expect(find.textContaining('Current Date & Time:'), findsOneWidget);

    // Verify that the language dropdown is present with "English" as the default.
    expect(find.text('English'), findsOneWidget);

    // Verify that the chatbot button is present.
    expect(find.byIcon(Icons.chat), findsOneWidget);

    // Tap the chatbot button and verify that the dialog opens.
    await tester.tap(find.byIcon(Icons.chat));
    await tester.pumpAndSettle(); // Wait for the dialog to open.

    // Verify that the chatbot dialog is displayed.
    expect(find.text('Voter Assistance Chatbot'), findsOneWidget);

    // Close the dialog.
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle(); // Wait for the dialog to close.

    // Verify that the dialog is closed.
    expect(find.text('Voter Assistance Chatbot'), findsNothing);
  });
}
