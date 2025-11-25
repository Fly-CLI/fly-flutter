import 'package:args/command_runner.dart';
import 'package:fly_cli/src/features/commands/domain/command_context.dart';
import 'package:fly_cli/src/features/commands/domain/fly_command_strategy.dart';
import 'package:fly_cli/src/features/commands/domain/categories.dart';
import 'package:fly_cli/src/features/completion/application/completion_command.dart';

/// Strategy for completion command
class CompletionCommandDescriptor extends FlyCommandDescriptor {
  @override
  String get name => 'completion';

  @override
  String get description =>
      'Generate shell completion scripts for command line';

  @override
  List<String> get aliases => ['completions', 'complete', 'tab'];

  @override
  CommandGroup? get group => null;

  @override
  CommandCategory get category => CommandCategory.integration;

  @override
  Command<int> createInstance(CommandContext context) {
    return CompletionCommand.create(context);
  }
}
