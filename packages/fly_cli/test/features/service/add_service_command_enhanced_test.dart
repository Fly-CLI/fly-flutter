import 'package:fly_cli/src/features/service/application/add_service_command.dart';
import 'package:fly_cli/src/core/validation/validation_rules.dart';
import 'package:test/test.dart';

import '../../helpers/command_test_helper.dart';

void main() {
  group('AddServiceCommand', () {
    late AddServiceCommand command;

    setUp(() {
      final mockContext = CommandTestHelper.createMockCommandContext();
      command = AddServiceCommand(mockContext);
    });

    group('Basic Properties', () {
      test('should have correct name', () {
        expect(command.name, equals('service'));
      });

      test('should have correct description', () {
        expect(command.description, equals('Add a new service component to the current project'));
      });

      test('should have required arguments', () {
        expect(command.argParser.options.containsKey('feature'), isTrue);
        expect(command.argParser.options.containsKey('type'), isTrue);
        expect(command.argParser.options.containsKey('with-tests'), isTrue);
        expect(command.argParser.options.containsKey('with-mocks'), isTrue);
        expect(command.argParser.options.containsKey('interactive'), isTrue);
        expect(command.argParser.options.containsKey('with-interceptors'), isTrue);
        expect(command.argParser.options.containsKey('base-url'), isTrue);
      });

      test('should have correct default values', () {
        final args = command.argParser.parse([]);
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
        expect(NameValidationRule.isValidServiceName('api_service'), isTrue);
        expect(NameValidationRule.isValidServiceName('user_service'), isTrue);
        expect(NameValidationRule.isValidServiceName('cache_service'), isTrue);
        expect(NameValidationRule.isValidServiceName('service123'), isTrue);
      });

      test('should reject invalid service names', () {
        expect(NameValidationRule.isValidServiceName(''), isFalse);
        expect(NameValidationRule.isValidServiceName('ApiService'), isFalse); // uppercase
        expect(NameValidationRule.isValidServiceName('api-service'), isFalse); // hyphen
        expect(NameValidationRule.isValidServiceName('api.service'), isFalse); // dot
        expect(NameValidationRule.isValidServiceName('123service'), isFalse); // starts with number
        expect(NameValidationRule.isValidServiceName('a'), isFalse); // too short
        expect(NameValidationRule.isValidServiceName('a' * 51), isFalse); // too long
      });
    });

    group('Service Type Validation', () {
      test('should accept valid service types', () {
        final args = command.argParser.parse(['--type', 'api']);
        expect(args['type'], equals('api'));

        final args2 = command.argParser.parse(['--type', 'local']);
        expect(args2['type'], equals('local'));

        final args3 = command.argParser.parse(['--type', 'cache']);
        expect(args3['type'], equals('cache'));

        final args4 = command.argParser.parse(['--type', 'analytics']);
        expect(args4['type'], equals('analytics'));

        final args5 = command.argParser.parse(['--type', 'storage']);
        expect(args5['type'], equals('storage'));
      });

      test('should reject invalid service types', () {
        expect(
          () => command.argParser.parse(['--type', 'invalid']),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('Feature Organization', () {
      test('should default to core feature', () {
        final args = command.argParser.parse([]);
        expect(args['feature'], equals('core'));
      });

      test('should accept custom feature name', () {
        final args = command.argParser.parse(['--feature', 'user_management']);
        expect(args['feature'], equals('user_management'));
      });
    });

    group('Test and Mock Generation', () {
      test('should have with-tests flag', () {
        expect(command.argParser.options.containsKey('with-tests'), isTrue);
      });

      test('should have with-mocks flag', () {
        expect(command.argParser.options.containsKey('with-mocks'), isTrue);
      });

      test('should default to false for with-tests', () {
        final args = command.argParser.parse([]);
        expect(args['with-tests'], equals(false));
      });

      test('should default to false for with-mocks', () {
        final args = command.argParser.parse([]);
        expect(args['with-mocks'], equals(false));
      });

      test('should accept with-tests flag', () {
        final args = command.argParser.parse(['--with-tests']);
        expect(args['with-tests'], equals(true));
      });

      test('should accept with-mocks flag', () {
        final args = command.argParser.parse(['--with-mocks']);
        expect(args['with-mocks'], equals(true));
      });
    });

    group('Interactive Mode', () {
      test('should have interactive flag', () {
        expect(command.argParser.options.containsKey('interactive'), isTrue);
      });

      test('should default to false for interactive', () {
        final args = command.argParser.parse([]);
        expect(args['interactive'], equals(false));
      });

      test('should accept interactive flag', () {
        final args = command.argParser.parse(['--interactive']);
        expect(args['interactive'], equals(true));
      });
    });

    group('API Service Options', () {
      test('should have with-interceptors flag', () {
        expect(command.argParser.options.containsKey('with-interceptors'), isTrue);
      });

      test('should have base-url option', () {
        expect(command.argParser.options.containsKey('base-url'), isTrue);
      });

      test('should default to false for with-interceptors', () {
        final args = command.argParser.parse([]);
        expect(args['with-interceptors'], equals(false));
      });

      test('should accept with-interceptors flag', () {
        final args = command.argParser.parse(['--with-interceptors']);
        expect(args['with-interceptors'], equals(true));
      });

      test('should accept custom base-url', () {
        final args = command.argParser.parse(['--base-url', 'https://api.custom.com']);
        expect(args['base-url'], equals('https://api.custom.com'));
      });
    });

    group('Command Execution Scenarios', () {
      test('should handle basic service creation', () {
        final args = command.argParser.parse(['user_service']);
        expect(args.rest, equals(['user_service']));
      });

      test('should handle service with custom feature', () {
        final args = command.argParser.parse(['--feature', 'auth', 'auth_service']);
        expect(args['feature'], equals('auth'));
        expect(args.rest, equals(['auth_service']));
      });

      test('should handle API service with interceptors', () {
        final args = command.argParser.parse([
          '--type', 'api',
          '--with-interceptors',
          '--base-url', 'https://api.example.com',
          'api_service',
        ]);
        expect(args['type'], equals('api'));
        expect(args['with-interceptors'], equals(true));
        expect(args['base-url'], equals('https://api.example.com'));
        expect(args.rest, equals(['api_service']));
      });

      test('should handle cache service', () {
        final args = command.argParser.parse(['--type', 'cache', 'cache_service']);
        expect(args['type'], equals('cache'));
        expect(args.rest, equals(['cache_service']));
      });

      test('should handle analytics service', () {
        final args = command.argParser.parse(['--type', 'analytics', 'analytics_service']);
        expect(args['type'], equals('analytics'));
        expect(args.rest, equals(['analytics_service']));
      });

      test('should handle storage service', () {
        final args = command.argParser.parse(['--type', 'storage', 'storage_service']);
        expect(args['type'], equals('storage'));
        expect(args.rest, equals(['storage_service']));
      });

      test('should handle service with all options', () {
        final args = command.argParser.parse([
          '--feature', 'user',
          '--type', 'api',
          '--with-tests',
          '--with-mocks',
          '--with-interceptors',
          '--base-url', 'https://api.custom.com',
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
        final args = command.argParser.parse([]);
        expect(args.rest, isEmpty);
      });

      test('should handle empty service name', () {
        final args = command.argParser.parse(['']);
        expect(args.rest, equals(['']));
      });

      test('should handle invalid service name', () {
        final args = command.argParser.parse(['Invalid-Name']);
        expect(args.rest, equals(['Invalid-Name']));
      });
    });

    group('Integration Scenarios', () {
      test('should handle authentication services', () {
        final args = command.argParser.parse([
          '--feature', 'auth',
          '--type', 'api',
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

      test('should handle data services', () {
        final args = command.argParser.parse([
          '--feature', 'data',
          '--type', 'local',
          '--with-tests',
          'data_service',
        ]);
        expect(args['feature'], equals('data'));
        expect(args['type'], equals('local'));
        expect(args['with-tests'], equals(true));
        expect(args.rest, equals(['data_service']));
      });

      test('should handle caching services', () {
        final args = command.argParser.parse([
          '--feature', 'cache',
          '--type', 'cache',
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
      test('should handle service name with underscores', () {
        final args = command.argParser.parse(['user_profile_service']);
        expect(args.rest, equals(['user_profile_service']));
      });

      test('should handle single character service name', () {
        final args = command.argParser.parse(['a']);
        expect(args.rest, equals(['a']));
      });
    });

    group('Command Result Structure', () {
      test('should have proper command result structure', () {
        // This would be tested in integration tests
        expect(command.name, equals('service'));
        expect(command.description, isNotEmpty);
      });
    });

    group('Performance Considerations', () {
      test('should handle repeated parsing efficiently', () {
        expect(() {
          for (var i = 0; i < 100; i++) {
            command.argParser.parse(['test_service_$i']);
          }
        }, returnsNormally,);
      });
    });
  });
}
