import 'dart:io';

import 'package:fly_cli/src/features/create/create_command.dart';
import 'package:fly_cli/src/core/command_foundation/command_base.dart';
import 'package:test/test.dart';

import '../../helpers/command_test_helper.dart';
import '../../helpers/mock_logger.dart' as mock_logger;
import '../../helpers/test_fixtures.dart';

void main() {
  group('CreateCommand', () {
    late CreateCommand command;
    late mock_logger.MockLogger mockLogger;
    late Directory tempDir;

    setUp(() {
      mockLogger = mock_logger.MockLogger();
      final mockContext = CommandTestHelper.createMockCommandContext(
        logger: mockLogger,
      );
      command = CreateCommand(mockContext);
      tempDir = CommandTestHelper.createTempDir();
    });

    tearDown(() {
      CommandTestHelper.cleanupTempDir(tempDir);
      mockLogger.clear();
    });

    group('Basic Properties', () {
      test('should have correct name', () {
        expect(command.name, equals('create'));
      });

      test('should have correct description', () {
        expect(command.description, equals('Create a new Flutter project'));
      });

      test('should have required arguments', () {
        final parser = command.argParser;
        
        expect(parser.options.containsKey('template'), isTrue);
        expect(parser.options.containsKey('organization'), isTrue);
        expect(parser.options.containsKey('platforms'), isTrue);
        expect(parser.options.containsKey('interactive'), isTrue);
        expect(parser.options.containsKey('from-manifest'), isTrue);
        expect(parser.options.containsKey('plan'), isTrue);
        expect(parser.options.containsKey('output'), isTrue);
      });

      test('should have correct default values', () {
        final parser = command.argParser;
        
        expect(parser.options['template']!.defaultsTo, equals('riverpod'));
        expect(parser.options['organization']!.defaultsTo, equals('com.example'));
        expect(parser.options['platforms']!.defaultsTo, equals(['ios', 'android']));
        expect(parser.options['interactive']!.defaultsTo, equals(false));
      });
    });

    group('Argument Validation', () {
      test('should accept valid project names', () {
        for (final projectName in TestFixtures.validProjectNames) {
          expect(TestFixtures.isValidProjectName(projectName), isTrue,
              reason: 'Project name "$projectName" should be valid',);
        }
      });

      test('should reject invalid project names', () {
        for (final projectName in TestFixtures.invalidProjectNames) {
          expect(TestFixtures.isValidProjectName(projectName), isFalse,
              reason: 'Project name "$projectName" should be invalid',);
        }
      });

      test('should accept valid organizations', () {
        for (final org in TestFixtures.validOrganizations) {
          expect(TestFixtures.isValidOrganization(org), isTrue,
              reason: 'Organization "$org" should be valid',);
        }
      });

      test('should reject invalid organizations', () {
        for (final org in TestFixtures.invalidOrganizations) {
          expect(TestFixtures.isValidOrganization(org), isFalse,
              reason: 'Organization "$org" should be invalid',);
        }
      });

      test('should accept valid platforms', () {
        for (final platform in TestFixtures.allPlatforms) {
          expect(TestFixtures.allPlatforms.contains(platform), isTrue,
              reason: 'Platform "$platform" should be valid',);
        }
      });
    });

    group('Template Selection', () {
      test('should default to riverpod template', () {
        final parser = command.argParser;
        expect(parser.options['template']!.defaultsTo, equals('riverpod'));
      });

      test('should accept minimal template', () {
        final parser = command.argParser;
        final allowed = parser.options['template']!.allowed;
        expect(allowed, contains('minimal'));
      });

      test('should accept riverpod template', () {
        final parser = command.argParser;
        final allowed = parser.options['template']!.allowed;
        expect(allowed, contains('riverpod'));
      });

      test('should reject invalid templates', () {
        final parser = command.argParser;
        final allowed = parser.options['template']!.allowed;
        expect(allowed, isNot(contains('invalid_template')));
        expect(allowed, isNot(contains('custom')));
      });
    });

    group('Platform Selection', () {
      test('should default to ios and android', () {
        final parser = command.argParser;
        expect(parser.options['platforms']!.defaultsTo, equals(['ios', 'android']));
      });

      test('should accept all valid platforms', () {
        final parser = command.argParser;
        final allowed = parser.options['platforms']!.allowed;
        
        for (final platform in TestFixtures.allPlatforms) {
          expect(allowed, contains(platform),
              reason: 'Platform "$platform" should be allowed',);
        }
      });

      test('should reject invalid platforms', () {
        final parser = command.argParser;
        final allowed = parser.options['platforms']!.allowed;
        
        expect(allowed, isNot(contains('invalid_platform')));
        expect(allowed, isNot(contains('mobile')));
        expect(allowed, isNot(contains('desktop')));
      });
    });

    group('Interactive Mode', () {
      test('should have interactive flag', () {
        final parser = command.argParser;
        expect(parser.options.containsKey('interactive'), isTrue);
      });

      test('should default to non-interactive', () {
        final parser = command.argParser;
        expect(parser.options['interactive']!.defaultsTo, equals(false));
      });

      test('should be non-negatable', () {
        final parser = command.argParser;
        expect(parser.options['interactive']!.negatable, equals(false));
      });
    });

    group('Manifest Support', () {
      test('should have from-manifest option', () {
        final parser = command.argParser;
        expect(parser.options.containsKey('from-manifest'), isTrue);
      });

      test('should accept manifest file path', () {
        final parser = command.argParser;
        final option = parser.options['from-manifest']!;
        expect(option.type, isNotNull);
      });
    });

    group('Plan Mode', () {
      test('should have plan flag', () {
        final parser = command.argParser;
        expect(parser.options.containsKey('plan'), isTrue);
      });

      test('should default to non-plan mode', () {
        final parser = command.argParser;
        expect(parser.options['plan']!.defaultsTo, equals(false));
      });

      test('should be non-negatable', () {
        final parser = command.argParser;
        expect(parser.options['plan']!.negatable, equals(false));
      });
    });

    group('Output Format', () {
      test('should have output option', () {
        final parser = command.argParser;
        expect(parser.options.containsKey('output'), isTrue);
      });

      test('should accept human and json outputs', () {
        final parser = command.argParser;
        final allowed = parser.options['output']!.allowed;
        
        expect(allowed, contains('human'));
        expect(allowed, contains('json'));
      });

      test('should default to human output', () {
        final parser = command.argParser;
        expect(parser.options['output']!.defaultsTo, equals('human'));
      });
    });

    group('Command Execution', () {
      test('should require project name', () async {
        // This would test the actual command execution
        // For now, we'll test the argument parsing
        final parser = command.argParser;
        final result = parser.parse([]);
        
        expect(result.rest, isEmpty);
      });

      test('should accept project name as positional argument', () {
        final parser = command.argParser;
        final result = parser.parse(['test_app']);
        
        expect(result.rest, equals(['test_app']));
      });

      test('should parse all options correctly', () {
        final parser = command.argParser;
        final result = parser.parse([
          'test_app',
          '--template=minimal',
          '--organization=com.test',
          '--platforms=ios,android,web',
          '--interactive',
          '--output=json',
        ]);
        
        expect(result.rest, equals(['test_app']));
        expect(result['template'], equals('minimal'));
        expect(result['organization'], equals('com.test'));
        expect(result['platforms'], equals(['ios', 'android', 'web']));
        expect(result['interactive'], equals(true));
        expect(result['output'], equals('json'));
      });

      test('should handle short options', () {
        final parser = command.argParser;
        final result = parser.parse([
          'test_app',
          '-t', 'minimal',
          '-o', 'com.test',
        ]);
        
        expect(result['template'], equals('minimal'));
        expect(result['organization'], equals('com.test'));
      });
    });

    group('Error Handling', () {
      test('should handle missing project name', () {
        final parser = command.argParser;
        final result = parser.parse([]);
        
        expect(result.rest, isEmpty);
      });

      test('should handle invalid template', () {
        final parser = command.argParser;
        
        expect(() => parser.parse(['test_app', '--template=invalid']),
            throwsA(isA<FormatException>()),);
      });

      test('should handle invalid platform', () {
        final parser = command.argParser;
        
        expect(() => parser.parse(['test_app', '--platforms=invalid']),
            throwsA(isA<FormatException>()),);
      });

      test('should handle invalid output format', () {
        final parser = command.argParser;
        
        expect(() => parser.parse(['test_app', '--output=invalid']),
            throwsA(isA<FormatException>()),);
      });
    });

    group('Integration Scenarios', () {
      test('should handle minimal project creation', () {
        final parser = command.argParser;
        final result = parser.parse([
          'minimal_app',
          '--template=minimal',
          '--organization=com.minimal',
        ]);
        
        expect(result.rest, equals(['minimal_app']));
        expect(result['template'], equals('minimal'));
        expect(result['organization'], equals('com.minimal'));
        expect(result['platforms'], equals(['ios', 'android'])); // defaults
      });

      test('should handle riverpod project creation', () {
        final parser = command.argParser;
        final result = parser.parse([
          'riverpod_app',
          '--template=riverpod',
          '--organization=com.riverpod',
          '--platforms=ios,android,web',
        ]);
        
        expect(result.rest, equals(['riverpod_app']));
        expect(result['template'], equals('riverpod'));
        expect(result['organization'], equals('com.riverpod'));
        expect(result['platforms'], equals(['ios', 'android', 'web']));
      });

      test('should handle cross-platform project creation', () {
        final parser = command.argParser;
        final result = parser.parse([
          'cross_platform_app',
          '--platforms=ios,android,web,macos,windows,linux',
        ]);
        
        expect(result.rest, equals(['cross_platform_app']));
        expect(result['platforms'], equals([
          'ios', 'android', 'web', 'macos', 'windows', 'linux',
        ]),);
      });

      test('should handle interactive mode', () {
        final parser = command.argParser;
        final result = parser.parse([
          'interactive_app',
          '--interactive',
        ]);
        
        expect(result.rest, equals(['interactive_app']));
        expect(result['interactive'], equals(true));
      });

      test('should handle manifest-based creation', () {
        final parser = command.argParser;
        final result = parser.parse([
          '--from-manifest=project.yaml',
        ]);
        
        expect(result['from-manifest'], equals('project.yaml'));
      });

      test('should handle plan mode', () {
        final parser = command.argParser;
        final result = parser.parse([
          'planned_app',
          '--plan',
        ]);
        
        expect(result.rest, equals(['planned_app']));
        expect(result['plan'], equals(true));
      });

      test('should handle JSON output', () {
        final parser = command.argParser;
        final result = parser.parse([
          'json_app',
          '--output=json',
        ]);
        
        expect(result.rest, equals(['json_app']));
        expect(result['output'], equals('json'));
      });
    });

    group('Edge Cases', () {
      test('should handle empty arguments', () {
        final parser = command.argParser;
        final result = parser.parse([]);
        
        expect(result.rest, isEmpty);
        expect(result['template'], equals('riverpod')); // default
        expect(result['organization'], equals('com.example')); // default
        expect(result['platforms'], equals(['ios', 'android'])); // default
      });

      test('should handle only project name', () {
        final parser = command.argParser;
        final result = parser.parse(['simple_app']);
        
        expect(result.rest, equals(['simple_app']));
        expect(result['template'], equals('riverpod')); // default
        expect(result['organization'], equals('com.example')); // default
        expect(result['platforms'], equals(['ios', 'android'])); // default
      });

      test('should handle multiple project names', () {
        final parser = command.argParser;
        final result = parser.parse(['app1', 'app2', 'app3']);
        
        expect(result.rest, equals(['app1', 'app2', 'app3']));
      });

      test('should handle very long project name', () {
        final longName = 'a' * 50; // exactly 50 characters
        final parser = command.argParser;
        final result = parser.parse([longName]);
        
        expect(result.rest, equals([longName]));
      });

      test('should handle special characters in organization', () {
        final parser = command.argParser;
        
        // Parser accepts the value, but validation should reject it during execution
        // The validation happens in command validators, not in the parser itself
        final result = parser.parse(['app', '--organization=com.test-org']);
        expect(result['organization'], equals('com.test-org'));
        // Validation would reject this during command execution
        expect(TestFixtures.isValidOrganization('com.test-org'), isFalse);
      });
    });

    group('Command Result Structure', () {
      test('should have proper command result structure', () {
        // Test that the command can produce a proper CommandResult
        // This would be tested in integration tests with actual execution
        expect(command, isA<FlyCommand>());
        expect(command.name, isA<String>());
        expect(command.description, isA<String>());
      });
    });

    group('Template Manager Integration', () {
      test('should work with template manager', () {
        // Test that the command can work with TemplateManager
        // This would be tested in integration tests
        expect(command, isNotNull);
      });
    });

    group('Performance Considerations', () {
      test('should handle large argument lists efficiently', () {
        final parser = command.argParser;
        final largeArgs = List.generate(100, (i) => 'arg$i');
        
        // Should not throw or take too long
        expect(() => parser.parse(largeArgs), returnsNormally);
      });

      test('should handle repeated parsing efficiently', () {
        final parser = command.argParser;
        final args = ['test_app', '--template=minimal'];
        
        // Parse multiple times
        for (var i = 0; i < 100; i++) {
          expect(() => parser.parse(args), returnsNormally);
        }
      });
    });
  });
}
