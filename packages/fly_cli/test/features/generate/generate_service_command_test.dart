import 'dart:io';

import 'package:fly_cli/src/cli/infrastructure/validation/validation_rules.dart';
import 'package:fly_cli/src/features/commands/application/command_base.dart';
import 'package:fly_cli/src/features/generate/service/generate_service_command.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../../helpers/command_test_helper.dart';
import '../../helpers/mock_logger.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('GenerateServiceCommand', () {
    late GenerateServiceCommand command;
    late MockLogger mockLogger;
    late Directory tempDir;
    late Directory projectDir;

    setUp(() {
      mockLogger = MockLogger();
      final mockContext = CommandTestHelper.createMockCommandContext(
        logger: Logger(),
      );
      command = GenerateServiceCommand(mockContext);
      tempDir = CommandTestHelper.createTempDir();

      // Create a mock Flutter project
      projectDir = Directory(path.join(tempDir.path, 'test_project'));
      projectDir.createSync();

      // Create pubspec.yaml
      final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
      pubspecFile.writeAsStringSync(TestFixtures.samplePubspecContent);
    });

    tearDown(() {
      CommandTestHelper.cleanupTempDir(tempDir);
      mockLogger.clear();
    });

    group('Basic Properties', () {
      test('should have correct name', () {
        expect(command.name, equals('service'));
      });

      test('should have correct description', () {
        expect(
          command.description,
          equals('Generate a new service component to the current project'),
        );
      });

      test('should have required arguments', () {
        final parser = command.argParser;

        expect(parser.options.containsKey('feature'), isTrue);
        expect(parser.options.containsKey('type'), isTrue);
        expect(parser.options.containsKey('with-tests'), isTrue);
        expect(parser.options.containsKey('with-mocks'), isTrue);
        expect(parser.options.containsKey('interactive'), isTrue);
        expect(parser.options.containsKey('with-interceptors'), isTrue);
        expect(parser.options.containsKey('base-url'), isTrue);
        expect(parser.options.containsKey('output'), isTrue);
      });

      test('should have correct default values', () {
        final parser = command.argParser;
        final args = parser.parse([]);

        expect(args['feature'], equals('core'));
        expect(args['type'], equals('api'));
        expect(args['with-tests'], equals(false));
        expect(args['with-mocks'], equals(false));
        expect(args['interactive'], equals(false));
        expect(args['with-interceptors'], equals(false));
        expect(args['base-url'], equals('https://api.example.com'));
      });
    });

    group('Service Name Validation', () {
      test('should accept valid service names', () {
        for (final serviceName in TestFixtures.validServiceNames) {
          expect(
            NameValidationRule.isValidServiceName(serviceName),
            isTrue,
            reason: 'Service name "$serviceName" should be valid',
          );
        }
        // Additional valid names
        expect(NameValidationRule.isValidServiceName('api_service'), isTrue);
        expect(NameValidationRule.isValidServiceName('user_service'), isTrue);
        expect(NameValidationRule.isValidServiceName('cache_service'), isTrue);
        expect(NameValidationRule.isValidServiceName('service123'), isTrue);
      });

      test('should reject invalid service names', () {
        for (final serviceName in TestFixtures.invalidServiceNames) {
          expect(
            NameValidationRule.isValidServiceName(serviceName),
            isFalse,
            reason: 'Service name "$serviceName" should be invalid',
          );
        }
        // Additional invalid names
        expect(NameValidationRule.isValidServiceName(''), isFalse);
        expect(
          NameValidationRule.isValidServiceName('ApiService'),
          isFalse,
        ); // uppercase
        expect(
          NameValidationRule.isValidServiceName('api-service'),
          isFalse,
        ); // hyphen
        expect(
          NameValidationRule.isValidServiceName('api.service'),
          isFalse,
        ); // dot
        expect(
          NameValidationRule.isValidServiceName('123service'),
          isFalse,
        ); // starts with number
        expect(
          NameValidationRule.isValidServiceName('a'),
          isFalse,
        ); // too short
        expect(
          NameValidationRule.isValidServiceName('a' * 51),
          isFalse,
        ); // too long
      });

      test('should reject empty service name', () {
        expect(NameValidationRule.isValidServiceName(''), isFalse);
      });

      test('should reject service name that is too long', () {
        final longName = 'a' * 51; // 51 characters
        expect(NameValidationRule.isValidServiceName(longName), isFalse);
      });

      test('should accept service name that is exactly 50 characters', () {
        final longName = 'a' * 50; // exactly 50 characters
        expect(NameValidationRule.isValidServiceName(longName), isTrue);
      });
    });

    group('Service Type Validation', () {
      test('should accept valid service types', () {
        final parser = command.argParser;

        final args = parser.parse(['--type', 'api']);
        expect(args['type'], equals('api'));

        final args2 = parser.parse(['--type', 'local']);
        expect(args2['type'], equals('local'));

        final args3 = parser.parse(['--type', 'cache']);
        expect(args3['type'], equals('cache'));

        final args4 = parser.parse(['--type', 'analytics']);
        expect(args4['type'], equals('analytics'));

        final args5 = parser.parse(['--type', 'storage']);
        expect(args5['type'], equals('storage'));
      });

      test('should reject invalid service types', () {
        final parser = command.argParser;
        expect(
          () => parser.parse(['--type', 'invalid']),
          throwsA(isA<FormatException>()),
        );
      });

      test('should have type option with allowed values', () {
        final parser = command.argParser;
        final allowed = parser.options['type']!.allowed;

        expect(allowed, contains('api'));
        expect(allowed, contains('local'));
        expect(allowed, contains('cache'));
        expect(allowed, isNot(contains('invalid')));
        expect(allowed, isNot(contains('custom')));
        expect(allowed, isNot(contains('database')));
      });

      test('should accept api type', () {
        final parser = command.argParser;
        final result = parser.parse(['auth', '--type=api']);

        expect(result['type'], equals('api'));
      });

      test('should accept local type', () {
        final parser = command.argParser;
        final result = parser.parse(['storage', '--type=local']);

        expect(result['type'], equals('local'));
      });

      test('should accept cache type', () {
        final parser = command.argParser;
        final result = parser.parse(['cache', '--type=cache']);

        expect(result['type'], equals('cache'));
      });
    });

    group('Feature Organization', () {
      test('should default to core feature', () {
        final parser = command.argParser;
        final args = parser.parse([]);
        expect(args['feature'], equals('core'));
      });

      test('should accept custom feature name', () {
        final parser = command.argParser;
        final result = parser.parse(['auth', '--feature=authentication']);

        expect(result['feature'], equals('authentication'));
      });

      test('should accept custom feature name with separate flag', () {
        final parser = command.argParser;
        final args = parser.parse(['--feature', 'user_management']);
        expect(args['feature'], equals('user_management'));
      });
    });

    group('Test and Mock Generation', () {
      test('should have with-tests flag', () {
        final parser = command.argParser;
        expect(parser.options.containsKey('with-tests'), isTrue);
      });

      test('should have with-mocks flag', () {
        final parser = command.argParser;
        expect(parser.options.containsKey('with-mocks'), isTrue);
      });

      test('should default to false for with-tests', () {
        final parser = command.argParser;
        final args = parser.parse([]);
        expect(args['with-tests'], equals(false));
      });

      test('should default to false for with-mocks', () {
        final parser = command.argParser;
        final args = parser.parse([]);
        expect(args['with-mocks'], equals(false));
      });

      test('should accept with-tests flag', () {
        final parser = command.argParser;
        final result = parser.parse(['auth', '--with-tests']);

        expect(result['with-tests'], equals(true));
      });

      test('should accept with-tests flag with separate flag', () {
        final parser = command.argParser;
        final args = parser.parse(['--with-tests']);
        expect(args['with-tests'], equals(true));
      });

      test('should accept with-mocks flag', () {
        final parser = command.argParser;
        final result = parser.parse(['auth', '--with-mocks']);

        expect(result['with-mocks'], equals(true));
      });

      test('should accept with-mocks flag with separate flag', () {
        final parser = command.argParser;
        final args = parser.parse(['--with-mocks']);
        expect(args['with-mocks'], equals(true));
      });
    });

    group('Interactive Mode', () {
      test('should have interactive flag', () {
        final parser = command.argParser;
        expect(parser.options.containsKey('interactive'), isTrue);
      });

      test('should default to false for interactive', () {
        final parser = command.argParser;
        final args = parser.parse([]);
        expect(args['interactive'], equals(false));
      });

      test('should accept interactive flag', () {
        final parser = command.argParser;
        final args = parser.parse(['--interactive']);
        expect(args['interactive'], equals(true));
      });
    });

    group('API Service Options', () {
      test('should have with-interceptors flag', () {
        final parser = command.argParser;
        expect(parser.options.containsKey('with-interceptors'), isTrue);
      });

      test('should have base-url option', () {
        final parser = command.argParser;
        expect(parser.options.containsKey('base-url'), isTrue);
      });

      test('should default to false for with-interceptors', () {
        final parser = command.argParser;
        final args = parser.parse([]);
        expect(args['with-interceptors'], equals(false));
      });

      test('should default to https://api.example.com for base-url', () {
        final parser = command.argParser;
        final args = parser.parse([]);
        expect(args['base-url'], equals('https://api.example.com'));
      });

      test('should accept with-interceptors flag', () {
        final parser = command.argParser;
        final args = parser.parse(['--with-interceptors']);
        expect(args['with-interceptors'], equals(true));
      });

      test('should accept custom base-url', () {
        final parser = command.argParser;
        final args = parser.parse(['--base-url', 'https://api.custom.com']);
        expect(args['base-url'], equals('https://api.custom.com'));
      });
    });

    group('Command Execution Scenarios', () {
      test('should handle basic service creation', () {
        final parser = command.argParser;
        final result = parser.parse(['auth']);

        expect(result.rest, equals(['auth']));
        expect(result['feature'], equals('core')); // default
        expect(result['type'], equals('api')); // default
        expect(result['with-tests'], equals(false)); // default
        expect(result['with-mocks'], equals(false)); // default
      });

      test('should handle basic service creation with separate syntax', () {
        final parser = command.argParser;
        final args = parser.parse(['user_service']);
        expect(args.rest, equals(['user_service']));
      });

      test('should handle service with custom feature', () {
        final parser = command.argParser;
        final result = parser.parse(['auth', '--feature=authentication']);

        expect(result.rest, equals(['auth']));
        expect(result['feature'], equals('authentication'));
      });

      test('should handle service with custom feature with separate flag', () {
        final parser = command.argParser;
        final args = parser.parse(['--feature', 'auth', 'auth_service']);
        expect(args['feature'], equals('auth'));
        expect(args.rest, equals(['auth_service']));
      });

      test('should handle service with custom type', () {
        final parser = command.argParser;
        final result = parser.parse(['storage', '--type=local']);

        expect(result.rest, equals(['storage']));
        expect(result['type'], equals('local'));
      });

      test('should handle short type option', () {
        final parser = command.argParser;
        final result = parser.parse(['auth', '-t', 'local']);

        expect(result['type'], equals('local'));
      });

      test('should handle service with tests', () {
        final parser = command.argParser;
        final result = parser.parse(['auth', '--with-tests']);

        expect(result.rest, equals(['auth']));
        expect(result['with-tests'], equals(true));
      });

      test('should handle service with mocks', () {
        final parser = command.argParser;
        final result = parser.parse(['auth', '--with-mocks']);

        expect(result.rest, equals(['auth']));
        expect(result['with-mocks'], equals(true));
      });

      test('should handle API service with interceptors', () {
        final parser = command.argParser;
        final args = parser.parse([
          '--type',
          'api',
          '--with-interceptors',
          '--base-url',
          'https://api.example.com',
          'api_service',
        ]);
        expect(args['type'], equals('api'));
        expect(args['with-interceptors'], equals(true));
        expect(args['base-url'], equals('https://api.example.com'));
        expect(args.rest, equals(['api_service']));
      });

      test('should handle cache service', () {
        final parser = command.argParser;
        final args = parser.parse(['--type', 'cache', 'cache_service']);
        expect(args['type'], equals('cache'));
        expect(args.rest, equals(['cache_service']));
      });

      test('should handle analytics service', () {
        final parser = command.argParser;
        final args = parser.parse(['--type', 'analytics', 'analytics_service']);
        expect(args['type'], equals('analytics'));
        expect(args.rest, equals(['analytics_service']));
      });

      test('should handle storage service', () {
        final parser = command.argParser;
        final args = parser.parse(['--type', 'storage', 'storage_service']);
        expect(args['type'], equals('storage'));
        expect(args.rest, equals(['storage_service']));
      });

      test('should handle service with all options', () {
        final parser = command.argParser;
        final result = parser.parse([
          'auth',
          '--feature=authentication',
          '--type=api',
          '--with-tests',
          '--with-mocks',
        ]);

        expect(result.rest, equals(['auth']));
        expect(result['feature'], equals('authentication'));
        expect(result['type'], equals('api'));
        expect(result['with-tests'], equals(true));
        expect(result['with-mocks'], equals(true));
      });

      test('should handle service with all options including new flags', () {
        final parser = command.argParser;
        final args = parser.parse([
          '--feature',
          'user',
          '--type',
          'api',
          '--with-tests',
          '--with-mocks',
          '--with-interceptors',
          '--base-url',
          'https://api.custom.com',
          'user_api_service',
        ]);
        expect(args['feature'], equals('user'));
        expect(args['type'], equals('api'));
        expect(args['with-tests'], equals(true));
        expect(args['with-mocks'], equals(true));
        expect(args['with-interceptors'], equals(true));
        expect(args['base-url'], equals('https://api.custom.com'));
        expect(args.rest, equals(['user_api_service']));
      });
    });

    group('Error Handling', () {
      test('should handle missing service name', () {
        final parser = command.argParser;
        final result = parser.parse([]);

        expect(result.rest, isEmpty);
      });

      test('should handle empty service name', () {
        final parser = command.argParser;
        final result = parser.parse(['']);

        expect(result.rest, equals(['']));
      });

      test('should handle invalid service name', () {
        final parser = command.argParser;
        final result = parser.parse(['Invalid-Service']);

        expect(result.rest, equals(['Invalid-Service']));
      });

      test('should handle invalid service name with separate flag', () {
        final parser = command.argParser;
        final args = parser.parse(['Invalid-Name']);
        expect(args.rest, equals(['Invalid-Name']));
      });

      test('should handle invalid service type', () {
        final parser = command.argParser;

        expect(
          () => parser.parse(['auth', '--type=invalid']),
          throwsA(isA<FormatException>()),
        );
      });

      test('should handle multiple service names', () {
        final parser = command.argParser;
        final result = parser.parse(['auth', 'storage', 'cache']);

        expect(result.rest, equals(['auth', 'storage', 'cache']));
      });
    });

    group('Integration Scenarios', () {
      test('should handle authentication service', () {
        final parser = command.argParser;
        final result = parser.parse([
          'auth',
          '--feature=authentication',
          '--type=api',
          '--with-tests',
          '--with-mocks',
        ]);

        expect(result.rest, equals(['auth']));
        expect(result['feature'], equals('authentication'));
        expect(result['type'], equals('api'));
        expect(result['with-tests'], equals(true));
        expect(result['with-mocks'], equals(true));
      });

      test('should handle authentication services with interceptors', () {
        final parser = command.argParser;
        final args = parser.parse([
          '--feature',
          'auth',
          '--type',
          'api',
          '--with-tests',
          '--with-mocks',
          '--with-interceptors',
          'auth_service',
        ]);
        expect(args['feature'], equals('auth'));
        expect(args['type'], equals('api'));
        expect(args['with-tests'], equals(true));
        expect(args['with-mocks'], equals(true));
        expect(args['with-interceptors'], equals(true));
        expect(args.rest, equals(['auth_service']));
      });

      test('should handle storage service', () {
        final parser = command.argParser;
        final result = parser.parse([
          'storage',
          '--feature=core',
          '--type=local',
          '--with-tests',
        ]);

        expect(result.rest, equals(['storage']));
        expect(result['feature'], equals('core'));
        expect(result['type'], equals('local'));
        expect(result['with-tests'], equals(true));
        expect(result['with-mocks'], equals(false)); // default
      });

      test('should handle data services', () {
        final parser = command.argParser;
        final args = parser.parse([
          '--feature',
          'data',
          '--type',
          'local',
          '--with-tests',
          'data_service',
        ]);
        expect(args['feature'], equals('data'));
        expect(args['type'], equals('local'));
        expect(args['with-tests'], equals(true));
        expect(args.rest, equals(['data_service']));
      });

      test('should handle cache service', () {
        final parser = command.argParser;
        final result = parser.parse([
          'cache',
          '--feature=core',
          '--type=cache',
          '--with-mocks',
        ]);

        expect(result.rest, equals(['cache']));
        expect(result['feature'], equals('core'));
        expect(result['type'], equals('cache'));
        expect(result['with-tests'], equals(false)); // default
        expect(result['with-mocks'], equals(true));
      });

      test('should handle caching services', () {
        final parser = command.argParser;
        final args = parser.parse([
          '--feature',
          'cache',
          '--type',
          'cache',
          '--with-tests',
          'cache_service',
        ]);
        expect(args['feature'], equals('cache'));
        expect(args['type'], equals('cache'));
        expect(args['with-tests'], equals(true));
        expect(args.rest, equals(['cache_service']));
      });
    });

    group('Edge Cases', () {
      test('should handle very long service name', () {
        final longName = 'a' * 50; // exactly 50 characters
        final parser = command.argParser;
        final result = parser.parse([longName]);

        expect(result.rest, equals([longName]));
      });

      test('should handle service name with underscores', () {
        final parser = command.argParser;
        final result = parser.parse(['user_management_service']);

        expect(result.rest, equals(['user_management_service']));
      });

      test(
        'should handle service name with underscores with separate flag',
        () {
          final parser = command.argParser;
          final args = parser.parse(['user_profile_service']);
          expect(args.rest, equals(['user_profile_service']));
        },
      );

      test('should handle single character service name', () {
        final parser = command.argParser;
        final result = parser.parse(['a']);

        expect(result.rest, equals(['a']));
      });

      test(
        'should handle single character service name with separate flag',
        () {
          final parser = command.argParser;
          final args = parser.parse(['a']);
          expect(args.rest, equals(['a']));
        },
      );
    });

    group('Command Result Structure', () {
      test('should have proper command result structure', () {
        expect(command, isA<FlyCommand>());
        expect(command.name, isA<String>());
        expect(command.description, isA<String>());
      });
    });

    group('Performance Considerations', () {
      test('should handle large argument lists efficiently', () {
        final parser = command.argParser;
        final largeArgs = List.generate(100, (i) => 'arg$i');

        expect(() => parser.parse(largeArgs), returnsNormally);
      });

      test('should handle repeated parsing efficiently', () {
        final parser = command.argParser;
        final args = ['test_service', '--feature=test'];

        for (var i = 0; i < 100; i++) {
          expect(() => parser.parse(args), returnsNormally);
        }
      });

      test(
        'should handle repeated parsing efficiently with different syntax',
        () {
          expect(
            () {
              for (var i = 0; i < 100; i++) {
                command.argParser.parse(['test_service_$i']);
              }
            },
            returnsNormally,
          );
        },
      );
    });
  });
}
