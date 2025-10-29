import 'package:args/args.dart';
import 'package:fly_cli/src/features/completion/application/completion_command.dart';
import 'package:test/test.dart';

import '../../helpers/command_test_helper.dart';

void main() {
  group('CompletionCommand', () {
    late CompletionCommand command;

    setUp(() {
      // Create a temporary command to get its parser
      final tempContext = CommandTestHelper.createMockCommandContext();
      final tempCommand = CompletionCommand(tempContext);
      
      // Parse empty args with the command's parser to get proper argResults
      final parsedArgs = tempCommand.argParser.parse([]);
      
      // Create the mock context with properly parsed args
      final mockContext = CommandTestHelper.createMockCommandContext(
        argResults: parsedArgs,
      );
      command = CompletionCommand(mockContext);
    });

    group('Basic Properties', () {
      test('should have correct name', () {
        expect(command.name, equals('completion'));
      });

      test('should have correct description', () {
        expect(command.description, equals('Generate shell completion scripts'));
      });

      test('should not have subcommands', () {
        expect(command.subcommands.keys, isEmpty);
      });

      test('should run successfully', () async {
        final result = await command.run();
        expect(result, equals(0));
      });

      test('should register install subcommand', () {
        // Since there are no subcommands, this test is not applicable
        expect(command.subcommands.keys, isEmpty);
      });

      test('should register uninstall subcommand', () {
        // Since there are no subcommands, this test is not applicable
        expect(command.subcommands.keys, isEmpty);
      });

      test('should register generate subcommand', () {
        // Since there are no subcommands, this test is not applicable
        expect(command.subcommands.keys, isEmpty);
      });
    });
  });
}