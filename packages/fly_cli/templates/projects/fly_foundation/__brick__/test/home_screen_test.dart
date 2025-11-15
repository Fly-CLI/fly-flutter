import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:{{project_name.snakeCase()}}/features/home/presentation/home_screen.dart';

void main() {
  testWidgets('HomeScreen emits accessible semantics', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    final semantics = tester.getSemantics(find.byType(Semantics));
    expect(semantics.label, contains('HomeScreen'));

    handle.dispose();
  });
}
