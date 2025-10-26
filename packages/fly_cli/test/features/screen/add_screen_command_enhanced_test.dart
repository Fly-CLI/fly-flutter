import 'package:fly_cli/src/features/screen/application/add_screen_command.dart';
import 'package:test/test.dart';

import '../../helpers/command_test_helper.dart';


void main() {
  group('AddScreenCommand', () {
    late AddScreenCommand command;

    setUp(() {
      final mockContext = CommandTestHelper.createMockCommandContext();
      command = AddScreenCommand(mockContext);
    });

    group('Basic Properties', () {
      test('should have correct name', () {
        expect(command.name, equals('screen'));
      });

      test('should have correct description', () {
        expect(command.description, equals('Add a screen to your project'));
      });

      test('should have required arguments', () {
        expect(command.argParser.options.containsKey('feature'), isTrue);
        expect(command.argParser.options.containsKey('type'), isTrue);
        expect(command.argParser.options.containsKey('with-viewmodel'), isTrue);
        expect(command.argParser.options.containsKey('with-tests'), isTrue);
        expect(command.argParser.options.containsKey('interactive'), isTrue);
        expect(command.argParser.options.containsKey('with-validation'), isTrue);
        expect(command.argParser.options.containsKey('with-navigation'), isTrue);
      });

      test('should have correct default values', () {
        final args = command.argParser.parse([]);
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
        expect(command.isValidName('home'), isTrue);
        expect(command.isValidName('user_profile'), isTrue);
        expect(command.isValidName('settings_screen'), isTrue);
        expect(command.isValidName('screen123'), isTrue);
      });

      test('should reject invalid screen names', () {
        expect(command.isValidName(''), isFalse);
        expect(command.isValidName('Home'), isFalse); // uppercase
        expect(command.isValidName('user-profile'), isFalse); // hyphen
        expect(command.isValidName('user.profile'), isFalse); // dot
        expect(command.isValidName('123screen'), isFalse); // starts with number
        expect(command.isValidName('a'), isFalse); // too short
        expect(command.isValidName('a' * 51), isFalse); // too long
      });
    });

    group('Screen Type Validation', () {
      test('should accept valid screen types', () {
        final args = command.argParser.parse(['--type', 'list']);
        expect(args['type'], equals('list'));

        final args2 = command.argParser.parse(['--type', 'detail']);
        expect(args2['type'], equals('detail'));

        final args3 = command.argParser.parse(['--type', 'form']);
        expect(args3['type'], equals('form'));

        final args4 = command.argParser.parse(['--type', 'auth']);
        expect(args4['type'], equals('auth'));

        final args5 = command.argParser.parse(['--type', 'settings']);
        expect(args5['type'], equals('settings'));
      });

      test('should reject invalid screen types', () {
        expect(
          () => command.argParser.parse(['--type', 'invalid']),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('Feature Organization', () {
      test('should default to home feature', () {
        final args = command.argParser.parse([]);
        expect(args['feature'], equals('home'));
      });

      test('should accept custom feature name', () {
        final args = command.argParser.parse(['--feature', 'user_management']);
        expect(args['feature'], equals('user_management'));
      });
    });

    group('ViewModel Generation', () {
      test('should have with-viewmodel flag', () {
        expect(command.argParser.options.containsKey('with-viewmodel'), isTrue);
      });

      test('should default to false for with-viewmodel', () {
        final args = command.argParser.parse([]);
        expect(args['with-viewmodel'], equals(false));
      });

      test('should accept with-viewmodel flag', () {
        final args = command.argParser.parse(['--with-viewmodel']);
        expect(args['with-viewmodel'], equals(true));
      });
    });

    group('Test Generation', () {
      test('should have with-tests flag', () {
        expect(command.argParser.options.containsKey('with-tests'), isTrue);
      });

      test('should default to false for with-tests', () {
        final args = command.argParser.parse([]);
        expect(args['with-tests'], equals(false));
      });

      test('should accept with-tests flag', () {
        final args = command.argParser.parse(['--with-tests']);
        expect(args['with-tests'], equals(true));
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

    group('Additional Options', () {
      test('should have with-validation flag', () {
        expect(command.argParser.options.containsKey('with-validation'), isTrue);
      });

      test('should have with-navigation flag', () {
        expect(command.argParser.options.containsKey('with-navigation'), isTrue);
      });

      test('should default to true for with-navigation', () {
        final args = command.argParser.parse([]);
        expect(args['with-navigation'], equals(true));
      });
    });

    group('Command Execution Scenarios', () {
      test('should handle basic screen creation', () {
        final args = command.argParser.parse(['home_screen']);
        expect(args.rest, equals(['home_screen']));
      });

      test('should handle screen with custom feature', () {
        final args = command.argParser.parse(['--feature', 'auth', 'login_screen']);
        expect(args['feature'], equals('auth'));
        expect(args.rest, equals(['login_screen']));
      });

      test('should handle screen with viewmodel', () {
        final args = command.argParser.parse(['--with-viewmodel', 'profile_screen']);
        expect(args['with-viewmodel'], equals(true));
        expect(args.rest, equals(['profile_screen']));
      });

      test('should handle screen with tests', () {
        final args = command.argParser.parse(['--with-tests', 'settings_screen']);
        expect(args['with-tests'], equals(true));
        expect(args.rest, equals(['settings_screen']));
      });

      test('should handle screen with all options', () {
        final args = command.argParser.parse([
          '--feature', 'user',
          '--type', 'form',
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
        final args = command.argParser.parse([]);
        expect(args.rest, isEmpty);
      });

      test('should handle empty screen name', () {
        final args = command.argParser.parse(['']);
        expect(args.rest, equals(['']));
      });

      test('should handle invalid screen name', () {
        final args = command.argParser.parse(['Invalid-Name']);
        expect(args.rest, equals(['Invalid-Name']));
      });
    });

    group('Integration Scenarios', () {
      test('should handle authentication screens', () {
        final args = command.argParser.parse([
          '--feature', 'auth',
          '--type', 'auth',
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
        final args = command.argParser.parse([
          '--feature', 'user',
          '--type', 'list',
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
      test('should handle screen name with underscores', () {
        final args = command.argParser.parse(['user_profile_screen']);
        expect(args.rest, equals(['user_profile_screen']));
      });

      test('should handle single character screen name', () {
        final args = command.argParser.parse(['a']);
        expect(args.rest, equals(['a']));
      });
    });

    group('Command Result Structure', () {
      test('should have proper command result structure', () {
        // This would be tested in integration tests
        expect(command.name, equals('screen'));
        expect(command.description, isNotEmpty);
      });
    });

    group('Performance Considerations', () {
      test('should handle repeated parsing efficiently', () {
        expect(() {
          for (var i = 0; i < 100; i++) {
            command.argParser.parse(['test_screen_$i']);
          }
        }, returnsNormally,);
      });
    });
  });
}
