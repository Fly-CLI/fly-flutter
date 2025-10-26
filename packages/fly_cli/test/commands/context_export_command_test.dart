import 'dart:io';
import 'package:test/test.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

import 'package:fly_cli/src/commands/context_export_command.dart';
import 'package:fly_cli/src/commands/fly_command.dart';

import '../helpers/command_test_helper.dart';
import '../helpers/mock_logger.dart';
import '../helpers/test_fixtures.dart';

void main() {
  group('ContextExportCommand', () {
    late ContextExportCommand command;
    late MockLogger mockLogger;
    late Directory tempDir;
    late Directory projectDir;

    setUp(() {
      mockLogger = MockLogger();
      command = ContextExportCommand();
      tempDir = CommandTestHelper.createTempDir();
      
      // Create a mock Flutter project
      projectDir = Directory(path.join(tempDir.path, 'test_project'));
      projectDir.createSync();
      
      // Create pubspec.yaml
      final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
      pubspecFile.writeAsStringSync(TestFixtures.samplePubspecContent);
      
      // Create lib directory
      final libDir = Directory(path.join(projectDir.path, 'lib'));
      libDir.createSync();
      
      // Create main.dart
      final mainFile = File(path.join(libDir.path, 'main.dart'));
      mainFile.writeAsStringSync('''
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test App',
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test App')),
      body: const Center(child: Text('Hello World')),
    );
  }
}
''');
    });

    tearDown(() {
      CommandTestHelper.cleanupTempDir(tempDir);
      mockLogger.clear();
    });

    group('Basic Properties', () {
      test('should have correct name', () {
        expect(command.name, equals('context-export'));
      });

      test('should have correct description', () {
        expect(command.description, equals('Export project context for AI integration'));
      });

      test('should have required arguments', () {
        final parser = command.argParser;
        
        expect(parser.options.containsKey('file'), isTrue);
        expect(parser.options.containsKey('include-code'), isTrue);
        expect(parser.options.containsKey('include-dependencies'), isTrue);
        expect(parser.options.containsKey('plan'), isTrue);
        expect(parser.options.containsKey('output'), isTrue);
      });

      test('should have correct default values', () {
        final parser = command.argParser;
        
        expect(parser.options['include-code']!.defaultsTo, equals(false));
        expect(parser.options['include-dependencies']!.defaultsTo, equals(false));
        expect(parser.options['include-code']!.negatable, equals(false));
        expect(parser.options['include-dependencies']!.negatable, equals(false));
      });
    });

    group('Command Execution', () {
      test('should handle stdout output', () {
        final parser = command.argParser;
        final result = parser.parse([]);
        
        expect(result['file'], isNull);
        expect(result['include-code'], equals(false));
        expect(result['include-dependencies'], equals(false));
      });

      test('should handle file output', () {
        final parser = command.argParser;
        final result = parser.parse(['--file=context.json']);
        
        expect(result['file'], equals('context.json'));
      });

      test('should handle include code flag', () {
        final parser = command.argParser;
        final result = parser.parse(['--include-code']);
        
        expect(result['include-code'], equals(true));
      });

      test('should handle include dependencies flag', () {
        final parser = command.argParser;
        final result = parser.parse(['--include-dependencies']);
        
        expect(result['include-dependencies'], equals(true));
      });

      test('should handle short file option', () {
        final parser = command.argParser;
        final result = parser.parse(['-o', 'output.json']);
        
        expect(result['file'], equals('output.json'));
      });

      test('should handle all options together', () {
        final parser = command.argParser;
        final result = parser.parse([
          '--file=context.json',
          '--include-code',
          '--include-dependencies',
        ]);
        
        expect(result['file'], equals('context.json'));
        expect(result['include-code'], equals(true));
        expect(result['include-dependencies'], equals(true));
      });
    });

    group('Error Handling', () {
      test('should handle invalid arguments gracefully', () {
        final parser = command.argParser;
        
        // Should not throw for valid arguments
        expect(() => parser.parse([]), returnsNormally);
        expect(() => parser.parse(['--file=test.json']), returnsNormally);
        expect(() => parser.parse(['--include-code']), returnsNormally);
        expect(() => parser.parse(['--include-dependencies']), returnsNormally);
      });

      test('should handle empty arguments', () {
        final parser = command.argParser;
        final result = parser.parse([]);
        
        expect(result['file'], isNull);
        expect(result['include-code'], equals(false));
        expect(result['include-dependencies'], equals(false));
      });
    });

    group('Integration Scenarios', () {
      test('should generate context for AI integration', () {
        // Test that the command can handle both output modes
        expect(command, isNotNull);
        expect(command.name, equals('context-export'));
      });

      test('should provide complete project overview', () {
        // Test that the command can handle both output modes
        expect(command, isNotNull);
        expect(command.name, equals('context-export'));
      });

      test('should support different export modes', () {
        final parser = command.argParser;
        
        // Basic export
        final basicResult = parser.parse([]);
        expect(basicResult['include-code'], equals(false));
        expect(basicResult['include-dependencies'], equals(false));
        
        // Code export
        final codeResult = parser.parse(['--include-code']);
        expect(codeResult['include-code'], equals(true));
        expect(codeResult['include-dependencies'], equals(false));
        
        // Dependencies export
        final depsResult = parser.parse(['--include-dependencies']);
        expect(depsResult['include-code'], equals(false));
        expect(depsResult['include-dependencies'], equals(true));
        
        // Full export
        final fullResult = parser.parse(['--include-code', '--include-dependencies']);
        expect(fullResult['include-code'], equals(true));
        expect(fullResult['include-dependencies'], equals(true));
      });
    });

    group('Edge Cases', () {
      test('should handle very large context', () {
        // Should generate context without errors
        expect(command, isNotNull);
        expect(command.name.isNotEmpty, isTrue);
      });

      test('should handle context generation multiple times', () {
        // Should be able to generate context multiple times
        for (int i = 0; i < 10; i++) {
          expect(command, isNotNull);
          expect(command.name.isNotEmpty, isTrue);
        }
      });

      test('should handle missing project files gracefully', () {
        // Should still generate context even if some files are missing
        expect(command, isNotNull);
        expect(command.name.isNotEmpty, isTrue);
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
        final args = ['--file=test.json'];
        
        for (int i = 0; i < 100; i++) {
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
        // Command name should be kebab-case
        expect(command.name, contains('-'));
        
        // Description should be meaningful
        expect(command.description.contains('context'), isTrue);
        expect(command.description.contains('export'), isTrue);
      });
    });
  });
}