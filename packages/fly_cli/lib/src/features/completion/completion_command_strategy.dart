import 'package:args/command_runner.dart';
import 'package:fly_cli/src/core/command_foundation/command_context.dart';
import 'package:fly_cli/src/core/command_foundation/fly_command_strategy.dart';
import 'package:fly_cli/src/core/command_foundation/fly_command_type.dart';
import 'package:fly_cli/src/features/completion/completion_command.dart';

/// Strategy for completion command
class CompletionCommandStrategy extends FlyCommandStrategy {
  @override
  String get name => 'completion';

  @override
  String get description => 'Generate shell completion scripts for command line';

  @override
  List<String> get aliases => ['completions', 'complete', 'tab'];

  @override
  FlyCommandType? get parentCommand => null;

  @override
  CommandGroup? get group => null;

  @override
  CommandCategory get category => CommandCategory.integration;

  @override
  Command<int> createInstance(CommandContext context) {
    return CompletionCommand.create(context);
  }
}

