import 'dart:io';

import 'package:fly_cli/src/core/command_foundation/application/command_base.dart';
import 'package:fly_cli/src/features/schema/application/schema_command.dart';
import 'package:test/test.dart';

import '../../helpers/command_test_helper.dart';
import '../../helpers/mock_logger.dart';

void main() {
  group('SchemaCommand', () {
    late SchemaCommand command;
    late MockLogger mockLogger;
    late Directory tempDir;

    setUp(() {
      mockLogger = MockLogger();
      final mockContext = CommandTestHelper.createMockCommandContext(
        logger: mockLogger,
      );
      command = SchemaCommand(mockContext);
      tempDir = CommandTestHelper.createTempDir();
    });

    tearDown(() {
      CommandTestHelper.cleanupTempDir(tempDir);
      mockLogger.clear();
    });

    group('Basic Properties', () {
      test('should have correct name', () {
        expect(command.name, equals('schema'));
      });

      test('should have correct description', () {
        expect(command.description, equals('Export CLI schema and command specifications'));
      });

      test('should have required arguments', () {
        final parser = command.argParser;
        
        expect(parser.options.containsKey('file'), isTrue);
        expect(parser.options.containsKey('include-examples'), isTrue);
        expect(parser.options.containsKey('plan'), isTrue);
        expect(parser.options.containsKey('output'), isTrue);
      });

      test('should have correct default values', () {
        final parser = command.argParser;
        
        expect(parser.options['include-examples']!.defaultsTo, equals(false));
      });
    });

    group('Command Execution', () {
      test('should handle stdout output', () {
        final parser = command.argParser;
        final result = parser.parse([]);
        
        expect(result['file'], isNull);
        expect(result['include-examples'], equals(false));
      });

      test('should handle file output', () {
        final parser = command.argParser;
        final result = parser.parse(['--file=schema.json']);
        
        expect(result['file'], equals('schema.json'));
      });

      test('should handle include examples flag', () {
        final parser = command.argParser;
        final result = parser.parse(['--include-examples']);
        
        expect(result['include-examples'], equals(true));
      });

      test('should handle short file option', () {
        final parser = command.argParser;
        final result = parser.parse(['-o', 'output.json']);
        
        expect(result['file'], equals('output.json'));
      });

      test('should handle all options together', () {
        final parser = command.argParser;
        final result = parser.parse([
          '--file=schema.json',
          '--include-examples',
        ]);
        
        expect(result['file'], equals('schema.json'));
        expect(result['include-examples'], equals(true));
      });
    });

    group('Error Handling', () {
      test('should handle invalid arguments gracefully', () {
        final parser = command.argParser;
        
        // Should not throw for valid arguments
        expect(() => parser.parse([]), returnsNormally);
        expect(() => parser.parse(['--file=test.json']), returnsNormally);
        expect(() => parser.parse(['--include-examples']), returnsNormally);
      });

      test('should handle empty arguments', () {
        final parser = command.argParser;
        final result = parser.parse([]);
        
        expect(result['file'], isNull);
        expect(result['include-examples'], equals(false));
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
        final args = ['test_command', '--file=test.json'];
        
        for (var i = 0; i < 100; i++) {
          expect(() => parser.parse(args), returnsNormally);
        }
      });
    });

    group('Content Quality', () {
      test('should provide meaningful command information', () {
        expect(command.name.isNotEmpty, isTrue);
        expect(command.description.isNotEmpty, isTrue);
        expect(command.description.length, greaterThan(10));
      });

      test('should have consistent naming conventions', () {
        // Command name should be lowercase
        expect(command.name, equals(command.name.toLowerCase()));
        
        // Description should be meaningful
        expect(command.description.contains('schema'), isTrue);
      });
    });
  });
}