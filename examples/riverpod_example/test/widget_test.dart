import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:riverpod_example/main.dart';

void main() {
  testWidgets('Home screen displays welcome message', (tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: RiverpodExampleApp(),
      ),
    );

    // Wait for the app to load
    await tester.pumpAndSettle();

    // Verify that our welcome message is displayed.
    expect(find.text('Welcome to Riverpod Example!'), findsOneWidget);
    expect(find.text('This is a production-ready Flutter project created with Fly CLI.'), findsOneWidget);
  });

  testWidgets('Counter increments when button is pressed', (tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: RiverpodExampleApp(),
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
    expect(find.text('Count: 1'), findsOneWidget);
  });

  testWidgets('Counter decrements when button is pressed', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: RiverpodExampleApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Tap increment first
    await tester.tap(find.text('Increment'));
    await tester.pump();

    // Then tap decrement
    await tester.tap(find.text('Decrement'));
    await tester.pump();

    // Verify counter is back to 0
    expect(find.text('Count: 0'), findsOneWidget);
  });

  testWidgets('Counter resets when reset button is pressed', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: RiverpodExampleApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Tap increment multiple times
    await tester.tap(find.text('Increment'));
    await tester.pump();
    await tester.tap(find.text('Increment'));
    await tester.pump();

    // Verify counter is at 2
    expect(find.text('Count: 2'), findsOneWidget);

    // Tap reset
    await tester.tap(find.text('Reset'));
    await tester.pump();

    // Verify counter is back to 0
    expect(find.text('Count: 0'), findsOneWidget);
  });

  testWidgets('Add sample todo button works', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: RiverpodExampleApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Find and tap the add sample todo button
    final addTodoButton = find.text('Add Sample Todo');
    expect(addTodoButton, findsOneWidget);
    
    await tester.tap(addTodoButton);
    await tester.pump();

    // Verify that a todo was added (we should see a ListTile)
    expect(find.byType(ListTile), findsOneWidget);
  });

  testWidgets('Navigation to profile screen works', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: RiverpodExampleApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Find and tap the profile button
    final profileButton = find.byIcon(Icons.person);
    expect(profileButton, findsOneWidget);
    
    await tester.tap(profileButton);
    await tester.pumpAndSettle();

    // Verify we're on the profile screen
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('User Information'), findsOneWidget);
  });
}
