import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper class for creating mock BuildContext in tests
class MockBuildContextHelper {
  /// Creates a valid BuildContext using MaterialApp
  static BuildContext createValidContext(WidgetTester tester) {
    return tester.element(find.byType(MaterialApp));
  }

  /// Creates a test widget with context
  static Widget createTestWidget({
    required Widget child,
    ThemeData? theme,
  }) {
    return MaterialApp(
      theme: theme ?? ThemeData.light(),
      home: Scaffold(
        body: child,
      ),
    );
  }
}

