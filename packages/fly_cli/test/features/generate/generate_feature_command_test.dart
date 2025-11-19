import 'dart:io';

import 'package:fly_cli/src/core/command/foundation/application/command_base.dart';
import 'package:fly_cli/src/core/validation/validation_rules.dart';
import 'package:fly_cli/src/features/generate/feature/generate_feature_command.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../../helpers/command_test_helper.dart';
import '../../helpers/mock_logger.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('GenerateFeatureCommand', () {
    late GenerateFeatureCommand command;
    late MockLogger mockLogger;
    late Directory tempDir;
    late Directory projectDir;

    setUp(() {
      mockLogger = MockLogger();
      final mockContext = CommandTestHelper.createMockCommandContext(
        logger: Logger(),
      );
      command = GenerateFeatureCommand(mockContext);
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
        expect(command.name, equals('feature'));
      });

      test('should have correct description', () {
        expect(
          command.description,
          equals(
            'Generate a new feature (screen) component for the current project',
          ),
        );
      });

      test('should have required arguments', () {
        final parser = command.argParser;

        expect(parser.options.containsKey('feature'), isTrue);
        expect(parser.options.containsKey('type'), isTrue);
        expect(parser.options.containsKey('with-viewmodel'), isTrue);
        expect(parser.options.containsKey('with-tests'), isTrue);
        expect(parser.options.containsKey('interactive'), isTrue);
        expect(parser.options.containsKey('with-validation'), isTrue);
        expect(parser.options.containsKey('with-navigation'), isTrue);
        expect(parser.options.containsKey('output'), isTrue);
      });

      test('should have correct default values', () {
        final parser = command.argParser;
        final args = parser.parse([]);

        expect(args['feature'], equals('home'));
        expect(args['type'], equals('list'));
        expect(args['with-viewmodel'], equals(false));
        expect(args['with-tests'], equals(false));
        expect(args['interactive'], equals(false));
        expect(args['with-validation'], equals(false));
        expect(args['with-navigation'], equals(true));
      });
    });

    group('Screen Name Validation', () {
      test('should accept valid screen names', () {
        for (final screenName in TestFixtures.validScreenNames) {
          expect(
            NameValidationRule.isValidScreenName(screenName),
            isTrue,
            reason: 'Screen name "$screenName" should be valid',
          );
        }
        // Additional valid names
        expect(NameValidationRule.isValidScreenName('user_profile'), isTrue);
        expect(NameValidationRule.isValidScreenName('settings_screen'), isTrue);
        expect(NameValidationRule.isValidScreenName('screen123'), isTrue);
      });

      test('should reject invalid screen names', () {
        for (final screenName in TestFixtures.invalidScreenNames) {
          expect(
            NameValidationRule.isValidScreenName(screenName),
            isFalse,
            reason: 'Screen name "$screenName" should be invalid',
          );
        }
        // Additional invalid names
        expect(NameValidationRule.isValidScreenName(''), isFalse);
        expect(NameValidationRule.isValidScreenName('Home'), isFalse); // uppercase
        expect(NameValidationRule.isValidScreenName('user-profile'),
            isFalse); // hyphen
        expect(NameValidationRule.isValidScreenName('user.profile'),
            isFalse); // dot
        expect(NameValidationRule.isValidScreenName('123screen'),
            isFalse); // starts with number
        expect(NameValidationRule.isValidScreenName('a'), isFalse); // too short
        expect(NameValidationRule.isValidScreenName('a' * 51),
            isFalse); // too long
      });

      test('should reject empty screen name', () {
        expect(NameValidationRule.isValidScreenName(''), isFalse);
      });

      test('should reject screen name that is too long', () {
        final longName = 'a' * 51; // 51 characters
        expect(NameValidationRule.isValidScreenName(longName), isFalse);
      });

      test('should accept screen name that is exactly 50 characters', () {
        final longName = 'a' * 50; // exactly 50 characters
        expect(NameValidationRule.isValidScreenName(longName), isTrue);
      });
    });

    group('Screen Type Validation', () {
      test('should accept valid screen types', () {
        final parser = command.argParser;

        final args = parser.parse(['--type', 'list']);
        expect(args['type'], equals('list'));

        final args2 = parser.parse(['--type', 'detail']);
        expect(args2['type'], equals('detail'));

        final args3 = parser.parse(['--type', 'form']);
        expect(args3['type'], equals('form'));

        final args4 = parser.parse(['--type', 'auth']);
        expect(args4['type'], equals('auth'));

        final args5 = parser.parse(['--type', 'settings']);
        expect(args5['type'], equals('settings'));
      });

      test('should reject invalid screen types', () {
        final parser = command.argParser;
        expect(
          () => parser.parse(['--type', 'invalid']),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('Feature Organization', () {
      test('should default to home feature', () {
        final parser = command.argParser;
        final args = parser.parse([]);
        expect(args['feature'], equals('home'));
      });

      test('should accept custom feature name', () {
        final parser = command.argParser;
        final result = parser.parse(['login', '--feature=auth']);

        expect(result['feature'], equals('auth'));
      });

      test('should accept custom feature name with separate flag', () {
        final parser = command.argParser;
        final args = parser.parse(['--feature', 'user_management']);
        expect(args['feature'], equals('user_management'));
      });
    });

    group('ViewModel Generation', () {
      test('should have with-viewmodel flag', () {
        final parser = command.argParser;
        expect(parser.options.containsKey('with-viewmodel'), isTrue);
      });

      test('should default to false for with-viewmodel', () {
        final parser = command.argParser;
        final args = parser.parse([]);
        expect(args['with-viewmodel'], equals(false));
      });

      test('should accept with-viewmodel flag', () {
        final parser = command.argParser;
        final result = parser.parse(['login', '--with-viewmodel']);

        expect(result['with-viewmodel'], equals(true));
      });

      test('should accept with-viewmodel flag with separate flag', () {
        final parser = command.argParser;
        final args = parser.parse(['--with-viewmodel', 'profile_screen']);
        expect(args['with-viewmodel'], equals(true));
      });
    });

    group('Test Generation', () {
      test('should have with-tests flag', () {
        final parser = command.argParser;
        expect(parser.options.containsKey('with-tests'), isTrue);
      });

      test('should default to false for with-tests', () {
        final parser = command.argParser;
        final args = parser.parse([]);
        expect(args['with-tests'], equals(false));
      });

      test('should accept with-tests flag', () {
        final parser = command.argParser;
        final result = parser.parse(['login', '--with-tests']);

        expect(result['with-tests'], equals(true));
      });

      test('should accept with-tests flag with separate flag', () {
        final parser = command.argParser;
        final args = parser.parse(['--with-tests', 'settings_screen']);
        expect(args['with-tests'], equals(true));
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

    group('Additional Options', () {
      test('should have with-validation flag', () {
        final parser = command.argParser;
        expect(
            parser.options.containsKey('with-validation'), isTrue);
      });

      test('should have with-navigation flag', () {
        final parser = command.argParser;
        expect(
            parser.options.containsKey('with-navigation'), isTrue);
      });

      test('should default to true for with-navigation', () {
        final parser = command.argParser;
        final args = parser.parse([]);
        expect(args['with-navigation'], equals(true));
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

      test('should handle basic screen creation with separate syntax', () {
        final parser = command.argParser;
        final args = parser.parse(['home_screen']);
        expect(args.rest, equals(['home_screen']));
      });

      test('should handle screen with custom feature', () {
        final parser = command.argParser;
        final result = parser.parse(['login', '--feature=auth']);

        expect(result.rest, equals(['login']));
        expect(result['feature'], equals('auth'));
      });

      test('should handle screen with custom feature with separate flag', () {
        final parser = command.argParser;
        final args =
            parser.parse(['--feature', 'auth', 'login_screen']);
        expect(args['feature'], equals('auth'));
        expect(args.rest, equals(['login_screen']));
      });

      test('should handle screen with viewmodel', () {
        final parser = command.argParser;
        final result = parser.parse(['login', '--with-viewmodel']);

        expect(result.rest, equals(['login']));
        expect(result['with-viewmodel'], equals(true));
      });

      test('should handle screen with viewmodel with separate flag', () {
        final parser = command.argParser;
        final args =
            parser.parse(['--with-viewmodel', 'profile_screen']);
        expect(args['with-viewmodel'], equals(true));
        expect(args.rest, equals(['profile_screen']));
      });

      test('should handle screen with tests', () {
        final parser = command.argParser;
        final result = parser.parse(['login', '--with-tests']);

        expect(result.rest, equals(['login']));
        expect(result['with-tests'], equals(true));
      });

      test('should handle screen with tests with separate flag', () {
        final parser = command.argParser;
        final args =
            parser.parse(['--with-tests', 'settings_screen']);
        expect(args['with-tests'], equals(true));
        expect(args.rest, equals(['settings_screen']));
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

      test('should handle screen with all options including new flags', () {
        final parser = command.argParser;
        final args = parser.parse([
          '--feature',
          'user',
          '--type',
          'form',
          '--with-viewmodel',
          '--with-tests',
          '--with-validation',
          'user_form_screen',
        ]);
        expect(args['feature'], equals('user'));
        expect(args['type'], equals('form'));
        expect(args['with-viewmodel'], equals(true));
        expect(args['with-tests'], equals(true));
        expect(args['with-validation'], equals(true));
        expect(args.rest, equals(['user_form_screen']));
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

      test('should handle invalid screen name with separate flag', () {
        final parser = command.argParser;
        final args = parser.parse(['Invalid-Name']);
        expect(args.rest, equals(['Invalid-Name']));
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
        expect(result['feature'], equals('auth'));
        expect(result['with-viewmodel'], equals(true));
        expect(result['with-tests'], equals(true));
      });

      test('should handle authentication screens with type', () {
        final parser = command.argParser;
        final args = parser.parse([
          '--feature',
          'auth',
          '--type',
          'auth',
          '--with-viewmodel',
          '--with-tests',
          'login_screen',
        ]);
        expect(args['feature'], equals('auth'));
        expect(args['type'], equals('auth'));
        expect(args['with-viewmodel'], equals(true));
        expect(args['with-tests'], equals(true));
        expect(args.rest, equals(['login_screen']));
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

      test('should handle user management screens with type', () {
        final parser = command.argParser;
        final args = parser.parse([
          '--feature',
          'user',
          '--type',
          'list',
          '--with-viewmodel',
          '--with-tests',
          'user_list_screen',
        ]);
        expect(args['feature'], equals('user'));
        expect(args['type'], equals('list'));
        expect(args['with-viewmodel'], equals(true));
        expect(args['with-tests'], equals(true));
        expect(args.rest, equals(['user_list_screen']));
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

      test('should handle screen name with underscores with separate flag', () {
        final parser = command.argParser;
        final args = parser.parse(['user_profile_screen']);
        expect(args.rest, equals(['user_profile_screen']));
      });

      test('should handle single character screen name', () {
        final parser = command.argParser;
        final result = parser.parse(['a']);

        expect(result.rest, equals(['a']));
      });

      test('should handle single character screen name with separate flag', () {
        final parser = command.argParser;
        final args = parser.parse(['a']);
        expect(args.rest, equals(['a']));
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

        for (var i = 0; i < 100; i++) {
          expect(() => parser.parse(args), returnsNormally);
        }
      });

      test('should handle repeated parsing efficiently with different syntax', () {
        expect(
          () {
            for (var i = 0; i < 100; i++) {
              command.argParser.parse(['test_screen_$i']);
            }
          },
          returnsNormally,
        );
      });
    });
  });
}