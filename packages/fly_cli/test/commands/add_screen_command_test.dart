import 'dart:io';
import 'package:test/test.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

import 'package:fly_cli/src/commands/add_screen_command.dart';
import 'package:fly_cli/src/commands/fly_command.dart';

import '../helpers/command_test_helper.dart';
import '../helpers/mock_logger.dart';
import '../helpers/test_fixtures.dart';

void main() {
  group('AddScreenCommand', () {
    late AddScreenCommand command;
    late MockLogger mockLogger;
    late Directory tempDir;
    late Directory projectDir;

    setUp(() {
      mockLogger = MockLogger();
      command = AddScreenCommand();
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
        expect(command.name, equals('screen'));
      });

      test('should have correct description', () {
        expect(command.description, equals('Add a screen to your project'));
      });

      test('should have required arguments', () {
        final parser = command.argParser;
        
        expect(parser.options.containsKey('feature'), isTrue);
        expect(parser.options.containsKey('with-viewmodel'), isTrue);
        expect(parser.options.containsKey('with-tests'), isTrue);
        expect(parser.options.containsKey('plan'), isTrue);
        expect(parser.options.containsKey('output'), isTrue);
      });

      test('should have correct default values', () {
        final parser = command.argParser;
        
        expect(parser.options['feature']!.defaultsTo, equals('home'));
        expect(parser.options['with-viewmodel']!.defaultsTo, equals(false));
        expect(parser.options['with-tests']!.defaultsTo, equals(false));
      });
    });

    group('Screen Name Validation', () {
      test('should accept valid screen names', () {
        for (final screenName in TestFixtures.validScreenNames) {
          expect(TestFixtures.isValidScreenName(screenName), isTrue,
              reason: 'Screen name "$screenName" should be valid');
        }
      });

      test('should reject invalid screen names', () {
        for (final screenName in TestFixtures.invalidScreenNames) {
          expect(TestFixtures.isValidScreenName(screenName), isFalse,
              reason: 'Screen name "$screenName" should be invalid');
        }
      });

      test('should reject empty screen name', () {
        expect(TestFixtures.isValidScreenName(''), isFalse);
      });

      test('should reject screen name that is too long', () {
        final longName = 'a' * 51; // 51 characters
        expect(TestFixtures.isValidScreenName(longName), isFalse);
      });

      test('should accept screen name that is exactly 50 characters', () {
        final longName = 'a' * 50; // exactly 50 characters
        expect(TestFixtures.isValidScreenName(longName), isTrue);
      });
    });

    group('Feature Organization', () {
      test('should default to home feature', () {
        final parser = command.argParser;
        expect(parser.options['feature']!.defaultsTo, equals('home'));
      });

      test('should accept custom feature name', () {
        final parser = command.argParser;
        final result = parser.parse(['login', '--feature=auth']);
        
        expect(result['feature'], equals('auth'));
      });
    });

    group('ViewModel Generation', () {
      test('should have with-viewmodel flag', () {
        final parser = command.argParser;
        expect(parser.options.containsKey('with-viewmodel'), isTrue);
      });

      test('should default to false for with-viewmodel', () {
        final parser = command.argParser;
        expect(parser.options['with-viewmodel']!.defaultsTo, equals(false));
      });

      test('should accept with-viewmodel flag', () {
        final parser = command.argParser;
        final result = parser.parse(['login', '--with-viewmodel']);
        
        expect(result['with-viewmodel'], equals(true));
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
        final result = parser.parse(['login', '--with-tests']);
        
        expect(result['with-tests'], equals(true));
      });
    });

    group('Command Execution Scenarios', () {
      test('should handle basic screen creation', () {
        final parser = command.argParser;
        final result = parser.parse(['login']);
        
        expect(result.rest, equals(['login']));
        expect(result['feature'], equals('home')); // default
        expect(result['with-viewmodel'], equals(false)); // default
        expect(result['with-tests'], equals(false)); // default
      });

      test('should handle screen with custom feature', () {
        final parser = command.argParser;
        final result = parser.parse(['login', '--feature=auth']);
        
        expect(result.rest, equals(['login']));
        expect(result['feature'], equals('auth'));
      });

      test('should handle screen with viewmodel', () {
        final parser = command.argParser;
        final result = parser.parse(['login', '--with-viewmodel']);
        
        expect(result.rest, equals(['login']));
        expect(result['with-viewmodel'], equals(true));
      });

      test('should handle screen with tests', () {
        final parser = command.argParser;
        final result = parser.parse(['login', '--with-tests']);
        
        expect(result.rest, equals(['login']));
        expect(result['with-tests'], equals(true));
      });

      test('should handle screen with all options', () {
        final parser = command.argParser;
        final result = parser.parse([
          'login',
          '--feature=auth',
          '--with-viewmodel',
          '--with-tests',
        ]);
        
        expect(result.rest, equals(['login']));
        expect(result['feature'], equals('auth'));
        expect(result['with-viewmodel'], equals(true));
        expect(result['with-tests'], equals(true));
      });
    });

    group('Error Handling', () {
      test('should handle missing screen name', () {
        final parser = command.argParser;
        final result = parser.parse([]);
        
        expect(result.rest, isEmpty);
      });

      test('should handle empty screen name', () {
        final parser = command.argParser;
        final result = parser.parse(['']);
        
        expect(result.rest, equals(['']));
      });

      test('should handle invalid screen name', () {
        final parser = command.argParser;
        final result = parser.parse(['Invalid-Screen']);
        
        expect(result.rest, equals(['Invalid-Screen']));
      });

      test('should handle multiple screen names', () {
        final parser = command.argParser;
        final result = parser.parse(['login', 'register', 'profile']);
        
        expect(result.rest, equals(['login', 'register', 'profile']));
      });
    });

    group('Integration Scenarios', () {
      test('should handle authentication screens', () {
        final parser = command.argParser;
        final result = parser.parse([
          'login',
          '--feature=auth',
          '--with-viewmodel',
          '--with-tests',
        ]);
        
        expect(result.rest, equals(['login']));
        expect(result['feature'], equals('authentication'));
        expect(result['with-viewmodel'], equals(true));
        expect(result['with-tests'], equals(true));
      });

      test('should handle user management screens', () {
        final parser = command.argParser;
        final result = parser.parse([
          'user_profile',
          '--feature=user_management',
          '--with-viewmodel',
        ]);
        
        expect(result.rest, equals(['user_profile']));
        expect(result['feature'], equals('user_management'));
        expect(result['with-viewmodel'], equals(true));
        expect(result['with-tests'], equals(false)); // default
      });
    });

    group('Edge Cases', () {
      test('should handle very long screen name', () {
        final longName = 'a' * 50; // exactly 50 characters
        final parser = command.argParser;
        final result = parser.parse([longName]);
        
        expect(result.rest, equals([longName]));
      });

      test('should handle screen name with underscores', () {
        final parser = command.argParser;
        final result = parser.parse(['user_profile_screen']);
        
        expect(result.rest, equals(['user_profile_screen']));
      });

      test('should handle single character screen name', () {
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
        final args = ['test_screen', '--feature=test'];
        
        for (int i = 0; i < 100; i++) {
          expect(() => parser.parse(args), returnsNormally);
        }
      });
    });
  });
}