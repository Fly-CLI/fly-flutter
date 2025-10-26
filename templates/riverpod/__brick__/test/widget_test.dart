import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:{{project_name_snake}}/main.dart';
import 'package:{{project_name_snake}}/features/home/providers/home_provider.dart';

void main() {
  testWidgets('Home screen displays welcome message', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: {{project_name_pascal}}App(),
      ),
    );

    // Wait for the app to load
    await tester.pumpAndSettle();

    // Verify that our welcome message is displayed.
    expect(find.text('Welcome to {{project_name}}!'), findsOneWidget);
    expect(find.text('This is a Riverpod Flutter project created with Fly CLI.'), findsOneWidget);
  });

  testWidgets('Counter increments when button is pressed', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: {{project_name_pascal}}App(),
      ),
    );

    // Wait for the app to load
    await tester.pumpAndSettle();

    // Find the increment button and tap it
    final incrementButton = find.text('Increment');
    expect(incrementButton, findsOneWidget);
    
    await tester.tap(incrementButton);
    await tester.pump();

    // Verify counter has incremented
    expect(find.text('Counter: 1'), findsOneWidget);
  });
}
