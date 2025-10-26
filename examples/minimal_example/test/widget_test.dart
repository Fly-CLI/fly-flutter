import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:minimal_example/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MinimalExampleApp());

    // Verify that our welcome message is displayed.
    expect(find.text('Welcome to Minimal Example!'), findsOneWidget);
    expect(find.text('This is a minimal Flutter project created with Fly CLI.'), findsOneWidget);

    // Verify that the counter starts at 0.
    expect(find.text('0'), findsOneWidget);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that the counter has incremented.
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('App title is correct', (WidgetTester tester) async {
    await tester.pumpWidget(const MinimalExampleApp());
    
    expect(find.text('Minimal Example'), findsOneWidget);
  });

  testWidgets('Counter increments multiple times', (WidgetTester tester) async {
    await tester.pumpWidget(const MinimalExampleApp());

    // Tap the '+' icon multiple times
    for (int i = 0; i < 5; i++) {
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
    }

    // Verify that the counter has incremented correctly
    expect(find.text('5'), findsOneWidget);
  });
}
