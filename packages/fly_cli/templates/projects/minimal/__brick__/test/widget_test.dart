import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:{{project_name_snake}}/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const {{project_name_pascal}}App());

    // Verify that our welcome message is displayed.
    expect(find.text('Welcome to {{project_name}}!'), findsOneWidget);
    expect(find.text('This is a minimal Flutter project created with Fly CLI.'), findsOneWidget);
  });
}
