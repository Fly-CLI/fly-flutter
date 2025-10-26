import 'dart:io';

import 'package:fly_cli/src/features/service/application/add_service_command.dart';
import 'package:fly_cli/src/core/command_foundation/application/command_base.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../../helpers/command_test_helper.dart';
import '../../helpers/test_fixtures.dart';
import '../../helpers/mock_logger.dart';


void main() {
  group('AddServiceCommand', () {
    late AddServiceCommand command;
    late MockLogger mockLogger;
    late Directory tempDir;
    late Directory projectDir;

    setUp(() {
      mockLogger = MockLogger();
      final mockContext = CommandTestHelper.createMockCommandContext(
        logger: mockLogger,
      );
      command = AddServiceCommand(mockContext);
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
        expect(command.description, equals('Add a service to your project'));
      });

      test('should have required arguments', () {
        final parser = command.argParser;
        
        expect(parser.options.containsKey('feature'), isTrue);
        expect(parser.options.containsKey('type'), isTrue);
        expect(parser.options.containsKey('with-tests'), isTrue);
        expect(parser.options.containsKey('with-mocks'), isTrue);
        expect(parser.options.containsKey('plan'), isTrue);
        expect(parser.options.containsKey('output'), isTrue);
      });

      test('should have correct default values', () {
        final parser = command.argParser;
        
        expect(parser.options['feature']!.defaultsTo, equals('core'));
        expect(parser.options['type']!.defaultsTo, equals('api'));
        expect(parser.options['with-tests']!.defaultsTo, equals(false));
        expect(parser.options['with-mocks']!.defaultsTo, equals(false));
      });
    });

    group('Service Name Validation', () {
      test('should accept valid service names', () {
        for (final serviceName in TestFixtures.validServiceNames) {
          expect(TestFixtures.isValidServiceName(serviceName), isTrue,
              reason: 'Service name "$serviceName" should be valid',);
        }
      });

      test('should reject invalid service names', () {
        for (final serviceName in TestFixtures.invalidServiceNames) {
          expect(TestFixtures.isValidServiceName(serviceName), isFalse,
              reason: 'Service name "$serviceName" should be invalid',);
        }
      });

      test('should reject empty service name', () {
        expect(TestFixtures.isValidServiceName(''), isFalse);
      });

      test('should reject service name that is too long', () {
        final longName = 'a' * 51; // 51 characters
        expect(TestFixtures.isValidServiceName(longName), isFalse);
      });

      test('should accept service name that is exactly 50 characters', () {
        final longName = 'a' * 50; // exactly 50 characters
        expect(TestFixtures.isValidServiceName(longName), isTrue);
      });
    });

    group('Feature Organization', () {
      test('should default to core feature', () {
        final parser = command.argParser;
        expect(parser.options['feature']!.defaultsTo, equals('core'));
      });

      test('should accept custom feature name', () {
        final parser = command.argParser;
        final result = parser.parse(['auth', '--feature=authentication']);
        
        expect(result['feature'], equals('authentication'));
      });
    });

    group('Service Type', () {
      test('should have type option', () {
        final parser = command.argParser;
        expect(parser.options.containsKey('type'), isTrue);
      });

      test('should default to api type', () {
        final parser = command.argParser;
        expect(parser.options['type']!.defaultsTo, equals('api'));
      });

      test('should accept valid service types', () {
        final parser = command.argParser;
        final allowed = parser.options['type']!.allowed;
        
        expect(allowed, contains('api'));
        expect(allowed, contains('local'));
        expect(allowed, contains('cache'));
      });

      test('should reject invalid service types', () {
        final parser = command.argParser;
        final allowed = parser.options['type']!.allowed;
        
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

    group('Test Generation', () {
      test('should have with-tests flag', () {
        final parser = command.argParser;
        expect(parser.options.containsKey('with-tests'), isTrue);
      });

      test('should default to false for with-tests', () {
        final parser = command.argParser;
        expect(parser.options['with-tests']!.defaultsTo, equals(false));
      });

      test('should accept with-tests flag', () {
        final parser = command.argParser;
        final result = parser.parse(['auth', '--with-tests']);
        
        expect(result['with-tests'], equals(true));
      });
    });

    group('Mock Generation', () {
      test('should have with-mocks flag', () {
        final parser = command.argParser;
        expect(parser.options.containsKey('with-mocks'), isTrue);
      });

      test('should default to false for with-mocks', () {
        final parser = command.argParser;
        expect(parser.options['with-mocks']!.defaultsTo, equals(false));
      });

      test('should accept with-mocks flag', () {
        final parser = command.argParser;
        final result = parser.parse(['auth', '--with-mocks']);
        
        expect(result['with-mocks'], equals(true));
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

      test('should handle service with custom feature', () {
        final parser = command.argParser;
        final result = parser.parse(['auth', '--feature=authentication']);
        
        expect(result.rest, equals(['auth']));
        expect(result['feature'], equals('authentication'));
      });

      test('should handle service with custom type', () {
        final parser = command.argParser;
        final result = parser.parse(['storage', '--type=local']);
        
        expect(result.rest, equals(['storage']));
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

      test('should handle short type option', () {
        final parser = command.argParser;
        final result = parser.parse(['auth', '-t', 'local']);
        
        expect(result['type'], equals('local'));
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

      test('should handle invalid service type', () {
        final parser = command.argParser;
        
        expect(() => parser.parse(['auth', '--type=invalid']),
            throwsA(isA<FormatException>()),);
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

      test('should handle single character service name', () {
        final parser = command.argParser;
        final result = parser.parse(['a']);
        
        expect(result.rest, equals(['a']));
      });
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
    });
  });
}