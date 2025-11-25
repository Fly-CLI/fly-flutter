{{#with_tests}}
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../lib/features/{{feature}}/presentation/screen/{{name}}_screen.dart';

void main() {
  testWidgets('{{name.pascalCase()}}Screen renders semantics', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: {{name.pascalCase()}}Screen(),
        ),
      ),
    );

    expect(find.byType(Semantics), findsWidgets);
    handle.dispose();
  });
}
{{/with_tests}}

