import 'package:fly_cli/src/integrations/mcp/infrastructure/prompts/prompt_template_engine.dart';
import 'package:test/test.dart';

void main() {
  group('PromptTemplateEngine', () {
    group('render', () {
      test('should substitute simple variables', () {
        final template = 'Hello {{name}}!';
        final variables = {'name': 'World'};

        final result = PromptTemplateEngine.render(template, variables);

        expect(result, equals('Hello World!'));
      });

      test('should handle multiple variables', () {
        final template = '{{greeting}} {{name}}';
        final variables = {'greeting': 'Hello', 'name': 'World'};

        final result = PromptTemplateEngine.render(template, variables);

        expect(result, equals('Hello World'));
      });

      test('should handle empty string values', () {
        final template = 'Value: {{value}}';
        final variables = {'value': ''};

        final result = PromptTemplateEngine.render(template, variables);

        expect(result, equals('Value: '));
      });

      test('should handle numeric values', () {
        final template = 'Count: {{count}}';
        final variables = {'count': 42};

        final result = PromptTemplateEngine.render(template, variables);

        expect(result, equals('Count: 42'));
      });

      test('should handle boolean values', () {
        final template = 'Enabled: {{enabled}}';
        final variables = {'enabled': true};

        final result = PromptTemplateEngine.render(template, variables);

        expect(result, equals('Enabled: true'));
      });

      group('sections', () {
        test('should render truthy section', () {
          final template = '{{#flag}}Flag is true{{/flag}}';
          final variables = {'flag': true};

          final result = PromptTemplateEngine.render(template, variables);

          expect(result, equals('Flag is true'));
        });

        test('should not render falsy section', () {
          final template = '{{#flag}}Flag is true{{/flag}}';
          final variables = {'flag': false};

          final result = PromptTemplateEngine.render(template, variables);

          expect(result, equals(''));
        });

        test('should not render missing section variable', () {
          final template = '{{#missing}}This wont show{{/missing}}';
          final variables = <String, dynamic>{};

          final result = PromptTemplateEngine.render(template, variables);

          expect(result, equals(''));
        });

        test('should render non-empty string sections', () {
          final template = '{{#value}}{{value}}{{/value}}';
          final variables = {'value': 'hello'};

          final result = PromptTemplateEngine.render(template, variables);

          expect(result, equals('hello'));
        });

        test('should not render empty string sections', () {
          final template = '{{#value}}{{value}}{{/value}}';
          final variables = {'value': ''};

          final result = PromptTemplateEngine.render(template, variables);

          expect(result, equals(''));
        });
      });

      group('inverse sections', () {
        test('should render inverse when variable is false', () {
          final template = '{{^flag}}Flag is false{{/flag}}';
          final variables = {'flag': false};

          final result = PromptTemplateEngine.render(template, variables);

          expect(result, equals('Flag is false'));
        });

        test('should not render inverse when variable is true', () {
          final template = '{{^flag}}Flag is false{{/flag}}';
          final variables = {'flag': true};

          final result = PromptTemplateEngine.render(template, variables);

          expect(result, equals(''));
        });

        test('should render inverse when variable is missing', () {
          final template = '{{^missing}}Variable missing{{/missing}}';
          final variables = <String, dynamic>{};

          final result = PromptTemplateEngine.render(template, variables);

          expect(result, equals('Variable missing'));
        });
      });

      group('lists', () {
        test('should iterate over lists', () {
          final template = '{{#items}}{{.}}, {{/items}}';
          final variables = {
            'items': ['a', 'b', 'c'],
          };

          final result = PromptTemplateEngine.render(template, variables);

          expect(result, equals('a, b, c, '));
        });

        test('should handle empty lists', () {
          final template = '{{#items}}{{.}}{{/items}}';
          final variables = {'items': []};

          final result = PromptTemplateEngine.render(template, variables);

          expect(result, equals(''));
        });

        test('should handle list with inverse section', () {
          final template = '{{^items}}No items{{/items}}';
          final variables = {'items': []};

          final result = PromptTemplateEngine.render(template, variables);

          expect(result, equals('No items'));
        });
      });

      group('nested structures', () {
        test('should handle nested sections', () {
          final template = '{{#outer}}{{#inner}}Both true{{/inner}}{{/outer}}';
          final variables = {'outer': true, 'inner': true};

          final result = PromptTemplateEngine.render(template, variables);

          expect(result, equals('Both true'));
        });

        test('should handle nested sections with outer true inner false', () {
          final template =
              '{{#outer}}{{#inner}}Both true{{/inner}}{{^inner}}Only outer{{/inner}}{{/outer}}';
          final variables = {'outer': true, 'inner': false};

          final result = PromptTemplateEngine.render(template, variables);

          expect(result, equals('Only outer'));
        });
      });

      group('real-world patterns', () {
        test('should handle fix_lints pattern', () {
          final template =
              'Analyze{{#lintFile}} {{lintFile}}{{/lintFile}}{{^lintFile}} all files{{/lintFile}}';
          final variables = {'lintFile': 'test.dart'};

          final result = PromptTemplateEngine.render(template, variables);

          expect(result, equals('Analyze test.dart'));
        });

        test('should handle fix_lints pattern without file', () {
          final template =
              'Analyze{{#lintFile}} {{lintFile}}{{/lintFile}}{{^lintFile}} all files{{/lintFile}}';
          final variables = <String, dynamic>{};

          final result = PromptTemplateEngine.render(template, variables);

          expect(result, equals('Analyze all files'));
        });

        test('should handle scaffold_api_client pattern', () {
          final template =
              '''{{#isBearerAuth}}Bearer token{{/isBearerAuth}}{{^isBearerAuth}}{{#isBasicAuth}}Basic auth{{/isBasicAuth}}{{^isBasicAuth}}No auth{{/isBasicAuth}}{{/isBearerAuth}}''';
          final variables = {'isBearerAuth': false, 'isBasicAuth': true};

          final result = PromptTemplateEngine.render(template, variables);

          expect(result, equals('Basic auth'));
        });
      });
    });
  });
}
