import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_project/features/home/presentation/home_screen.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('should display list of items', (WidgetTester tester) async {
      // Arrange
      const screen = HomeScreen();

      // Act
      await tester.pumpWidget(
        const MaterialApp(home: screen),
      );

      // Assert
      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
    });
  });
}
