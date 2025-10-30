import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import '../helpers/test_temp_dir.dart';

void main() {
  final temp = TestTempDir();

  setUpAll(temp.initSuite);
  setUp(temp.beforeEach);
  tearDown(temp.afterEach);
  tearDownAll(temp.cleanupSuite);

  group('Unified Output Format Tests', () {
    group('Human Output Mode', () {
      test('version command outputs human-readable format', () async {
        final result = await Process.run(
          'dart',
          ['run', 'bin/fly.dart', '--version', '--output=human'],
          workingDirectory: temp.currentTestDir.path,
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout, contains('Fly CLI'));
        expect(result.stdout, contains('✅'));
        expect(result.stdout, isNot(contains('{')));
      });

      test('doctor command outputs human-readable format', () async {
        final result = await Process.run(
          'dart',
          ['run', 'bin/fly.dart', 'doctor', '--output=human'],
          workingDirectory: temp.currentTestDir.path,
        );

        expect(result.exitCode, anyOf(equals(0), equals(1)));
        expect(result.stdout, anyOf(
          contains('✅'),
          contains('❌'),
          contains('🔧'),
        ));
        expect(result.stdout, isNot(contains('{')));
      });

      test('context command outputs human-readable format', () async {
        final result = await Process.run(
          'dart',
          ['run', 'bin/fly.dart', 'context', '--output=human'],
          workingDirectory: temp.currentTestDir.path,
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout, contains('📋'));
        expect(result.stdout, isNot(contains('{')));
      });

      test('schema command outputs human-readable format', () async {
        final result = await Process.run(
          'dart',
          ['run', 'bin/fly.dart', 'schema', '--output=human'],
          workingDirectory: temp.currentTestDir.path,
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout, contains('📋'));
        expect(result.stdout, isNot(contains('{')));
      });

      test('completion command outputs human-readable format', () async {
        final result = await Process.run(
          'dart',
          ['run', 'bin/fly.dart', 'completion', '--output=human'],
          workingDirectory: temp.currentTestDir.path,
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout, contains('🔧'));
        expect(result.stdout, isNot(contains('{')));
      });
    });

    group('JSON Output Mode', () {
      test('version command outputs valid JSON', () async {
        final result = await Process.run(
          'dart',
          ['run', 'bin/fly.dart', '--version', '--output=json'],
          workingDirectory: temp.currentTestDir.path,
        );

        expect(result.exitCode, equals(0));
        
        // ignore: argument_type_not_assignable
        final jsonOutput = json.decode(result.stdout) as Map<String, dynamic>;
        expect(jsonOutput, containsPair('success', true));
        expect(jsonOutput, containsPair('command', 'version'));
        expect(jsonOutput.keys, contains('message'));
        expect(jsonOutput.keys, contains('data'));
        expect(jsonOutput.keys, contains('metadata'));
        
        // ignore: argument_type_not_assignable
        final metadata = jsonOutput['metadata'] as Map<String, dynamic>;
        expect(metadata.keys, contains('cli_version'));
        expect(metadata.keys, contains('timestamp'));
      });

      test('doctor command outputs valid JSON', () async {
        final result = await Process.run(
          'dart',
          ['run', 'bin/fly.dart', 'doctor', '--output=json'],
          workingDirectory: temp.currentTestDir.path,
        );

        expect(result.exitCode, anyOf(equals(0), equals(1)));
        
        // ignore: argument_type_not_assignable
        final jsonOutput = json.decode(result.stdout) as Map<String, dynamic>;
        expect(jsonOutput.keys, contains('success'));
        expect(jsonOutput, containsPair('command', 'doctor'));
        expect(jsonOutput.keys, contains('message'));
        expect(jsonOutput.keys, contains('data'));
        expect(jsonOutput.keys, contains('metadata'));
        
        if (jsonOutput['success'] == true) {
          // ignore: argument_type_not_assignable
          final data = jsonOutput['data'] as Map<String, dynamic>;
          expect(data.keys, contains('total_checks'));
          expect(data.keys, contains('healthy_checks'));
          expect(data.keys, contains('overall_status'));
        } else {
          expect(jsonOutput.keys, contains('suggestion'));
          // ignore: argument_type_not_assignable
          final data = jsonOutput['data'] as Map<String, dynamic>;
          expect(data.keys, contains('issues_found'));
        }
      });

      test('context command outputs valid JSON', () async {
        final result = await Process.run(
          'dart',
          ['run', 'bin/fly.dart', 'context', '--output=json'],
          workingDirectory: temp.currentTestDir.path,
        );

        expect(result.exitCode, equals(0));
        
        // ignore: argument_type_not_assignable
        final jsonOutput = json.decode(result.stdout) as Map<String, dynamic>;
        expect(jsonOutput, containsPair('success', true));
        expect(jsonOutput, containsPair('command', 'context'));
        expect(jsonOutput.keys, contains('message'));
        expect(jsonOutput.keys, contains('data'));
        expect(jsonOutput.keys, contains('metadata'));
        
        // ignore: argument_type_not_assignable
        final data = jsonOutput['data'] as Map<String, dynamic>;
        expect(data.keys, contains('export_config'));
        expect(data.keys, contains('export_metadata'));
      });

      test('schema command outputs valid JSON', () async {
        final result = await Process.run(
          'dart',
          ['run', 'bin/fly.dart', 'schema', '--output=json'],
          workingDirectory: temp.currentTestDir.path,
        );

        expect(result.exitCode, equals(0));
        
        // ignore: argument_type_not_assignable
        final jsonOutput = json.decode(result.stdout) as Map<String, dynamic>;
        expect(jsonOutput, containsPair('success', true));
        expect(jsonOutput, containsPair('command', 'schema'));
        expect(jsonOutput.keys, contains('message'));
        expect(jsonOutput.keys, contains('data'));
        expect(jsonOutput.keys, contains('metadata'));
        
        final data = jsonOutput['data'] as Map<String, dynamic>?;
        expect(data, isNotNull);
        expect(data!.keys, contains('schema'));
        expect(data.keys, contains('export_config'));
        expect(data.keys, contains('export_metadata'));
      });

      test('completion command outputs valid JSON', () async {
        final result = await Process.run(
          'dart',
          ['run', 'bin/fly.dart', 'completion', '--output=json'],
          workingDirectory: temp.currentTestDir.path,
        );

        expect(result.exitCode, equals(0));
        
        // ignore: argument_type_not_assignable
        final jsonOutput = json.decode(result.stdout) as Map<String, dynamic>;
        expect(jsonOutput, containsPair('success', true));
        expect(jsonOutput, containsPair('command', 'completion'));
        expect(jsonOutput.keys, contains('message'));
        expect(jsonOutput.keys, contains('data'));
        expect(jsonOutput.keys, contains('metadata'));
        
        final data = jsonOutput['data'] as Map<String, dynamic>?;
        expect(data, isNotNull);
        expect(data!.keys, contains('script'));
        expect(data.keys, contains('shell'));
        expect(data.keys, contains('export_config'));
        expect(data.keys, contains('export_metadata'));
      });
    });

    group('AI Output Mode', () {
      test('version command outputs AI-optimized JSON', () async {
        final result = await Process.run(
          'dart',
          ['run', 'bin/fly.dart', '--version', '--output=ai'],
          workingDirectory: temp.currentTestDir.path,
        );

        expect(result.exitCode, equals(0));
        
        // ignore: argument_type_not_assignable
        final jsonOutput = json.decode(result.stdout) as Map<String, dynamic>;
        expect(jsonOutput, containsPair('status', 'success'));
        expect(jsonOutput, containsPair('command', 'version'));
        expect(jsonOutput.keys, contains('summary'));
        expect(jsonOutput.keys, contains('details'));
        expect(jsonOutput.keys, contains('context'));
        
        // ignore: argument_type_not_assignable
        final context = jsonOutput['context'] as Map<String, dynamic>;
        expect(context, containsPair('tool', 'fly_cli'));
        expect(context, containsPair('format', 'ai_optimized'));
        expect(context.keys, contains('version'));
        expect(context.keys, contains('timestamp'));
      });

      test('doctor command outputs AI-optimized JSON', () async {
        final result = await Process.run(
          'dart',
          ['run', 'bin/fly.dart', 'doctor', '--output=ai'],
          workingDirectory: temp.currentTestDir.path,
        );

        expect(result.exitCode, anyOf(equals(0), equals(1)));
        
        // ignore: argument_type_not_assignable
        final jsonOutput = json.decode(result.stdout) as Map<String, dynamic>;
        expect(jsonOutput.keys, contains('status'));
        expect(jsonOutput, containsPair('command', 'doctor'));
        expect(jsonOutput.keys, contains('summary'));
        expect(jsonOutput.keys, contains('details'));
        expect(jsonOutput.keys, contains('context'));
        
        // ignore: argument_type_not_assignable
        final context = jsonOutput['context'] as Map<String, dynamic>;
        expect(context, containsPair('tool', 'fly_cli'));
        expect(context, containsPair('format', 'ai_optimized'));
        
        if (jsonOutput['status'] == 'error') {
          expect(jsonOutput.keys, contains('recommendation'));
        }
      });

      test('context command outputs AI-optimized JSON', () async {
        final result = await Process.run(
          'dart',
          ['run', 'bin/fly.dart', 'context', '--output=ai'],
          workingDirectory: temp.currentTestDir.path,
        );

        expect(result.exitCode, equals(0));
        
        // ignore: argument_type_not_assignable
        final jsonOutput = json.decode(result.stdout) as Map<String, dynamic>;
        expect(jsonOutput, containsPair('status', 'success'));
        expect(jsonOutput, containsPair('command', 'context'));
        expect(jsonOutput.keys, contains('summary'));
        expect(jsonOutput.keys, contains('details'));
        expect(jsonOutput.keys, contains('context'));
        
        // ignore: argument_type_not_assignable
        final context = jsonOutput['context'] as Map<String, dynamic>;
        expect(context, containsPair('tool', 'fly_cli'));
        expect(context, containsPair('format', 'ai_optimized'));
      });

      test('schema command outputs AI-optimized JSON', () async {
        final result = await Process.run(
          'dart',
          ['run', 'bin/fly.dart', 'schema', '--output=ai'],
          workingDirectory: temp.currentTestDir.path,
        );

        expect(result.exitCode, equals(0));
        
        // ignore: argument_type_not_assignable
        final jsonOutput = json.decode(result.stdout) as Map<String, dynamic>;
        expect(jsonOutput, containsPair('status', 'success'));
        expect(jsonOutput, containsPair('command', 'schema'));
        expect(jsonOutput.keys, contains('summary'));
        expect(jsonOutput.keys, contains('details'));
        expect(jsonOutput.keys, contains('context'));
        
        // ignore: argument_type_not_assignable
        final context = jsonOutput['context'] as Map<String, dynamic>;
        expect(context, containsPair('tool', 'fly_cli'));
        expect(context, containsPair('format', 'ai_optimized'));
      });

      test('completion command outputs AI-optimized JSON', () async {
        final result = await Process.run(
          'dart',
          ['run', 'bin/fly.dart', 'completion', '--output=ai'],
          workingDirectory: temp.currentTestDir.path,
        );

        expect(result.exitCode, equals(0));
        
        // ignore: argument_type_not_assignable
        final jsonOutput = json.decode(result.stdout) as Map<String, dynamic>;
        expect(jsonOutput, containsPair('status', 'success'));
        expect(jsonOutput, containsPair('command', 'completion'));
        expect(jsonOutput.keys, contains('summary'));
        expect(jsonOutput.keys, contains('details'));
        expect(jsonOutput.keys, contains('context'));
        
        // ignore: argument_type_not_assignable
        final context = jsonOutput['context'] as Map<String, dynamic>;
        expect(context, containsPair('tool', 'fly_cli'));
        expect(context, containsPair('format', 'ai_optimized'));
      });
    });

    group('Error Handling', () {
      test('invalid command outputs consistent error format', () async {
        final result = await Process.run(
          'dart',
          ['run', 'bin/fly.dart', 'invalid-command', '--output=json'],
          workingDirectory: temp.currentTestDir.path,
        );

        expect(result.exitCode, equals(1));
        
        // ignore: argument_type_not_assignable
        final jsonOutput = json.decode(result.stdout) as Map<String, dynamic>;
        expect(jsonOutput, containsPair('success', false));
        expect(jsonOutput, containsPair('command', 'error'));
        expect(jsonOutput.keys, contains('message'));
        expect(jsonOutput.keys, contains('suggestion'));
        expect(jsonOutput.keys, contains('metadata'));
      });

      test('invalid command outputs AI-optimized error format', () async {
        final result = await Process.run(
          'dart',
          ['run', 'bin/fly.dart', 'invalid-command', '--output=ai'],
          workingDirectory: temp.currentTestDir.path,
        );

        expect(result.exitCode, equals(1));
        
        // ignore: argument_type_not_assignable
        final jsonOutput = json.decode(result.stdout) as Map<String, dynamic>;
        expect(jsonOutput, containsPair('status', 'error'));
        expect(jsonOutput, containsPair('command', 'error'));
        expect(jsonOutput.keys, contains('summary'));
        expect(jsonOutput.keys, contains('recommendation'));
        expect(jsonOutput.keys, contains('context'));
        
        // ignore: argument_type_not_assignable
        final context = jsonOutput['context'] as Map<String, dynamic>;
        expect(context, containsPair('tool', 'fly_cli'));
        expect(context, containsPair('format', 'ai_optimized'));
      });
    });

    group('Next Steps', () {
      test('successful commands include next steps', () async {
        final result = await Process.run(
          'dart',
          ['run', 'bin/fly.dart', 'version', '--output=json'],
          workingDirectory: temp.currentTestDir.path,
        );

        expect(result.exitCode, equals(0));
        
        // ignore: argument_type_not_assignable
        final jsonOutput = json.decode(result.stdout) as Map<String, dynamic>;
        expect(jsonOutput.keys, contains('next_steps'));
        
        final nextSteps = jsonOutput['next_steps'] as List<dynamic>?;
        if (nextSteps != null) {
          for (final step in nextSteps) {
            final stepMap = step as Map<String, dynamic>;
            expect(stepMap.keys, contains('command'));
            expect(stepMap.keys, contains('description'));
          }
        }
      });

      test('AI mode includes actions instead of next_steps', () async {
        final result = await Process.run(
          'dart',
          ['run', 'bin/fly.dart', 'version', '--output=ai'],
          workingDirectory: temp.currentTestDir.path,
        );

        expect(result.exitCode, equals(0));
        
        // ignore: argument_type_not_assignable
        final jsonOutput = json.decode(result.stdout) as Map<String, dynamic>;
        expect(jsonOutput.keys, contains('actions'));
        
        final actions = jsonOutput['actions'] as List<dynamic>?;
        if (actions != null) {
          for (final action in actions) {
            final actionMap = action as Map<String, dynamic>;
            expect(actionMap.keys, contains('command'));
            expect(actionMap.keys, contains('description'));
            expect(actionMap.keys, contains('type'));
            expect(actionMap['type'], equals('terminal_command'));
          }
        }
      });
    });

    group('Metadata Consistency', () {
      test('all commands include required metadata fields', () async {
        final commands = [
          'version',
          'doctor',
          'context',
          'schema',
          'completion'
        ];
        
        for (final command in commands) {
          final result = await Process.run(
            'dart',
            ['run', 'bin/fly.dart', command, '--output=json'],
            workingDirectory: temp.currentTestDir.path,
          );

          expect(result.exitCode, anyOf(equals(0), equals(1)));
          
          // ignore: argument_type_not_assignable
        final jsonOutput = json.decode(result.stdout) as Map<String, dynamic>;
          expect(jsonOutput.keys, contains('metadata'));
          
          // ignore: argument_type_not_assignable
          final metadata = jsonOutput['metadata'] as Map<String, dynamic>;
          expect(metadata.keys, contains('cli_version'));
          expect(metadata.keys, contains('timestamp'));
          // ignore: argument_type_not_assignable
          expect(metadata['cli_version'], equals('0.1.0'));
        }
      });

      test('AI mode includes proper context fields', () async {
        final commands = [
          'version',
          'doctor',
          'context',
          'schema',
          'completion'
        ];
        
        for (final command in commands) {
          final result = await Process.run(
            'dart',
            ['run', 'bin/fly.dart', command, '--output=ai'],
            workingDirectory: temp.currentTestDir.path,
          );

          expect(result.exitCode, anyOf(equals(0), equals(1)));
          
          // ignore: argument_type_not_assignable
        final jsonOutput = json.decode(result.stdout) as Map<String, dynamic>;
          expect(jsonOutput.keys, contains('context'));
          
        // ignore: argument_type_not_assignable
        final context = jsonOutput['context'] as Map<String, dynamic>;
        expect(context, containsPair('tool', 'fly_cli'));
        expect(context, containsPair('format', 'ai_optimized'));
          expect(context.keys, contains('version'));
          expect(context.keys, contains('timestamp'));
        }
      });
    });
  });
}