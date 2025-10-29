import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
<% if (with_viewmodel) { %>import 'package:flutter_riverpod/flutter_riverpod.dart';
<% } %>import 'package:fly_tools/features/{{feature}}/presentation/{{screen_name}}_screen.dart';
<% if (with_viewmodel) { %>import 'package:fly_tools/features/{{feature}}/providers/{{screen_name}}_provider.dart';
<% } %>

void main() {
  group('{{screen_name.pascalCase()}}Screen', () {
<% if (with_viewmodel) { %>    testWidgets('should display loading indicator when loading', (WidgetTester tester) async {
      // Arrange
      const screen = {{screen_name.pascalCase()}}Screen();

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            {{screen_name}}Provider.overrideWith((ref) => {{screen_name.pascalCase()}}Notifier()..state = const {{screen_name.pascalCase()}}State(isLoading: true)),
          ],
          child: const MaterialApp(home: screen),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display error when error occurs', (WidgetTester tester) async {
      // Arrange
      const screen = {{screen_name.pascalCase()}}Screen();

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            {{screen_name}}Provider.overrideWith((ref) => {{screen_name.pascalCase()}}Notifier()..state = const {{screen_name.pascalCase()}}State(error: 'Test error')),
          ],
          child: const MaterialApp(home: screen),
        ),
      );

      // Assert
      expect(find.text('Error: Test error'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

<% } %><% if (screen_type == 'list') { %>    testWidgets('should display list of items', (WidgetTester tester) async {
      // Arrange
      const screen = {{screen_name.pascalCase()}}Screen();

      // Act
      await tester.pumpWidget(
<% if (with_viewmodel) { %>        ProviderScope(
          overrides: [
            {{screen_name}}Provider.overrideWith((ref) => {{screen_name.pascalCase()}}Notifier()..state = const {{screen_name.pascalCase()}}State(items: ['Item 1', 'Item 2'])),
          ],
          child: const MaterialApp(home: screen),
        ),
<% } else { %>        const MaterialApp(home: screen),
<% } %>      );

      // Assert
      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
    });
<% } %>

<% if (screen_type == 'form') { %>    testWidgets('should display form fields', (WidgetTester tester) async {
      // Arrange
      const screen = {{screen_name.pascalCase()}}Screen();

      // Act
      await tester.pumpWidget(
<% if (with_viewmodel) { %>        ProviderScope(
          child: const MaterialApp(home: screen),
        ),
<% } else { %>        const MaterialApp(home: screen),
<% } %>      );

      // Assert
      expect(find.byType(Form), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Submit'), findsOneWidget);
    });
<% } %>

<% if (screen_type == 'auth') { %>    testWidgets('should display authentication form', (WidgetTester tester) async {
      // Arrange
      const screen = {{screen_name.pascalCase()}}Screen();

      // Act
      await tester.pumpWidget(
<% if (with_viewmodel) { %>        ProviderScope(
          child: const MaterialApp(home: screen),
        ),
<% } else { %>        const MaterialApp(home: screen),
<% } %>      );

      // Assert
      expect(find.text('Authentication'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });
<% } %>

<% if (screen_type == 'settings') { %>    testWidgets('should display settings options', (WidgetTester tester) async {
      // Arrange
      const screen = {{screen_name.pascalCase()}}Screen();

      // Act
      await tester.pumpWidget(
<% if (with_viewmodel) { %>        ProviderScope(
          child: const MaterialApp(home: screen),
        ),
<% } else { %>        const MaterialApp(home: screen),
<% } %>      );

      // Assert
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Privacy'), findsOneWidget);
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });
<% } %>

    testWidgets('should display welcome message for default screen', (WidgetTester tester) async {
      // Arrange
      const screen = {{screen_name.pascalCase()}}Screen();

      // Act
      await tester.pumpWidget(
<% if (with_viewmodel) { %>        ProviderScope(
          child: const MaterialApp(home: screen),
        ),
<% } else { %>        const MaterialApp(home: screen),
<% } %>      );

      // Assert
      expect(find.text('Welcome to {{screen_name.titleCase()}}!'), findsOneWidget);
      expect(find.text('This is the {{screen_name}} screen in the {{feature}} feature.'), findsOneWidget);
    });
  });
}
