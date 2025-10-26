import 'package:test/test.dart';
import 'package:fly_cli/src/security/template_validator.dart';

void main() {
  group('TemplateValidator', () {
    late TemplateValidator validator;

    setUp(() {
      validator = TemplateValidator();
    });

    group('Hardcoded Secrets Detection', () {
      test('detects API keys', () {
        final template = TemplateContent(
          name: 'test',
          files: {
            'config.dart': 'final apiKey = "secret_key_12345";',
          },
          imports: [],
          dependencies: [],
        );

        final issues = validator.validate(template);
        expect(issues.hasIssues, true);
        expect(issues.hasCritical, true);
      });

      test('detects passwords', () {
        final template = TemplateContent(
          name: 'test',
          files: {
            'auth.dart': 'final password = "mypassword123";',
          },
          imports: [],
          dependencies: [],
        );

        final issues = validator.validate(template);
        expect(issues.hasIssues, true);
        expect(issues.hasCritical, true);
      });

      test('detects OpenAI API keys', () {
        final template = TemplateContent(
          name: 'test',
          files: {
            'config.dart': 'const openaiKey = "sk-1234567890123456789012345678901234";',
          },
          imports: [],
          dependencies: [],
        );

        final issues = validator.validate(template);
        expect(issues.hasIssues, true);
      });

      test('detects GitHub tokens', () {
        final template = TemplateContent(
          name: 'test',
          files: {
            'secrets.dart': 'final token = "ghp_123456789012345678901234567890123456";',
          },
          imports: [],
          dependencies: [],
        );

        final issues = validator.validate(template);
        expect(issues.hasIssues, true);
      });

      test('detects AWS access keys', () {
        final template = TemplateContent(
          name: 'test',
          files: {
            'aws.dart': 'final key = "AKIAIOSFODNN7EXAMPLE";',
          },
          imports: [],
          dependencies: [],
        );

        final issues = validator.validate(template);
        expect(issues.hasIssues, true);
      });
    });

    group('Suspicious Imports Detection', () {
      test('flags dart:io import', () {
        final template = TemplateContent(
          name: 'test',
          files: {'main.dart': ''},
          imports: ['dart:io'],
          dependencies: [],
        );

        final issues = validator.validate(template);
        expect(issues.hasIssues, true);
        expect(issues.hasHigh, true);
      });

      test('flags dart:ffi import', () {
        final template = TemplateContent(
          name: 'test',
          files: {'main.dart': ''},
          imports: ['dart:ffi'],
          dependencies: [],
        );

        final issues = validator.validate(template);
        expect(issues.hasIssues, true);
      });

      test('does not flag safe imports', () {
        final template = TemplateContent(
          name: 'test',
          files: {'main.dart': ''},
          imports: ['dart:async', 'package:flutter/material.dart'],
          dependencies: [],
        );

        final issues = validator.validate(template);
        expect(issues.hasIssues, false);
      });
    });

    group('File System Access Detection', () {
      test('detects file operations', () {
        final template = TemplateContent(
          name: 'test',
          files: {
            'file_op.dart': 'final file = File("path/to/file.txt");',
          },
          imports: [],
          dependencies: [],
        );

        final issues = validator.validate(template);
        expect(issues.hasIssues, true);
        expect(issues.issues.any((i) => i.type == 'file_system_access'), true);
      });

      test('detects directory operations', () {
        final template = TemplateContent(
          name: 'test',
          files: {
            'dir_op.dart': 'final dir = Directory("/some/path");',
          },
          imports: [],
          dependencies: [],
        );

        final issues = validator.validate(template);
        expect(issues.hasIssues, true);
      });
    });

    group('Network Calls Detection', () {
      test('detects HTTP calls', () {
        final template = TemplateContent(
          name: 'test',
          files: {
            'api.dart': 'final response = await http.get(uri);',
          },
          imports: [],
          dependencies: [],
        );

        final issues = validator.validate(template);
        expect(issues.hasIssues, true);
        expect(issues.issues.any((i) => i.type == 'network_call'), true);
      });

      test('detects HttpClient usage', () {
        final template = TemplateContent(
          name: 'test',
          files: {
            'client.dart': 'final client = HttpClient();',
          },
          imports: [],
          dependencies: [],
        );

        final issues = validator.validate(template);
        expect(issues.hasIssues, true);
      });
    });

    group('Package Source Validation', () {
      test('flags Git dependencies', () {
        final template = TemplateContent(
          name: 'test',
          files: {},
          imports: [],
          dependencies: ['git:https://github.com/user/repo.git'],
        );

        final issues = validator.validate(template);
        expect(issues.hasIssues, true);
        expect(issues.issues.any((i) => i.type == 'git_dependency'), true);
      });

      test('flags unsecured HTTP dependencies', () {
        final template = TemplateContent(
          name: 'test',
          files: {},
          imports: [],
          dependencies: ['http://example.com/package'],
        );

        final issues = validator.validate(template);
        expect(issues.hasIssues, true);
        expect(issues.hasHigh, true);
      });

      test('allows pub.dev packages', () {
        final template = TemplateContent(
          name: 'test',
          files: {},
          imports: [],
          dependencies: ['package:flutter/material.dart'],
        );

        final issues = validator.validate(template);
        expect(issues.hasIssues, false);
      });
    });

    group('Shell Commands Detection', () {
      test('detects Process.run calls', () {
        final template = TemplateContent(
          name: 'test',
          files: {
            'script.dart': 'final result = await Process.run("ls", []);',
          },
          imports: [],
          dependencies: [],
        );

        final issues = validator.validate(template);
        expect(issues.hasIssues, true);
        expect(issues.hasCritical, true);
        expect(issues.issues.any((i) => i.type == 'shell_command'), true);
      });

      test('detects Process.start calls', () {
        final template = TemplateContent(
          name: 'test',
          files: {
            'process.dart': 'final process = await Process.start("cmd", []);',
          },
          imports: [],
          dependencies: [],
        );

        final issues = validator.validate(template);
        expect(issues.hasIssues, true);
        expect(issues.hasCritical, true);
      });
    });

    group('Multiple Issue Detection', () {
      test('detects multiple types of issues', () {
        final template = TemplateContent(
          name: 'test',
          files: {
            'bad.dart': '''
              final apiKey = "secret";
              final file = File("file.txt");
              final result = await Process.run("ls", []);
            ''',
          },
          imports: ['dart:io', 'dart:ffi'],
          dependencies: ['git:https://github.com/user/repo.git'],
        );

        final issues = validator.validate(template);
        expect(issues.hasIssues, true);
        expect(issues.hasCritical, true);
        expect(issues.hasHigh, true);
        expect(issues.issues.length, greaterThan(5));
      });
    });

    group('Clean Template Validation', () {
      test('passes clean template without issues', () {
        final template = TemplateContent(
          name: 'clean_template',
          files: {
            'main.dart': '''
              import 'package:flutter/material.dart';
              
              void main() {
                runApp(const MyApp());
              }
            ''',
          },
          imports: ['package:flutter/material.dart'],
          dependencies: ['flutter', 'path'],
        );

        final issues = validator.validate(template);
        expect(issues.hasIssues, false);
        expect(issues.issues, isEmpty);
      });
    });
  });
} 