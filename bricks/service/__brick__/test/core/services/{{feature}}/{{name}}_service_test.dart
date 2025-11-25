{{#with_tests}}
import 'package:flutter_test/flutter_test.dart';

import '../../../../lib/core/services/{{feature}}/{{name}}_service.dart';

void main() {
  test('{{name.pascalCase()}}Service returns success result', () async {
    final service = {{name.pascalCase()}}Service();

    final result = await service.fetchSummary();

    expect(result.isSuccess, isTrue);
    expect(result.data?['service'], '{{name}}');
  });
}
{{/with_tests}}

