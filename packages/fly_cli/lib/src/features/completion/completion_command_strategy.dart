import 'package:args/command_runner.dart';
import 'package:fly_cli/src/core/command/foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command/foundation/domain/fly_command_strategy.dart';
import 'package:fly_cli/src/core/definitions/categories.dart';
import 'package:fly_cli/src/features/completion/completion_command.dart';

/// Strategy for completion command
class CompletionCommandStrategy extends FlyCommandStrategy {
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
