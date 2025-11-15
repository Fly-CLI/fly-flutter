{{#is_project}}
{{#with_tests}}
{{#features}}
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:{{project_name.snakeCase()}}/features/{{feature}}/presentation/{{feature}}_screen.dart';

void main() {
  testWidgets('{{feature.pascalCase()}}Screen emits accessible semantics', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: {{feature.pascalCase()}}Screen(),
        ),
      ),
    );

    final semantics = tester.getSemantics(find.byType(Semantics));
    expect(semantics.label, contains('{{feature.pascalCase()}}Screen'));

    handle.dispose();
  });
}
{{/features}}
{{/with_tests}}
{{/is_project}}
