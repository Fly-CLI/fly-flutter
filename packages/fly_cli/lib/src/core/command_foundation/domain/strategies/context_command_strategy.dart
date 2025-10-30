import 'package:args/command_runner.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command_foundation/domain/fly_command_strategy.dart';
import 'package:fly_cli/src/core/command_foundation/domain/fly_command_type.dart';
import 'package:fly_cli/src/features/context/application/context_command.dart';

/// Strategy for context command
class ContextCommandStrategy extends FlyCommandStrategy {
  @override
  String get name => 'context';

  @override
  String get description => 'Analyze project context and generate insights';

  @override
  List<String> get aliases => ['analyze', 'insights', 'project'];

  @override
  FlyCommandType? get parentCommand => null;

  @override
  CommandGroup? get group => const CommandGroup(
        name: 'ai',
        description: 'AI integration commands for coding assistants',
      );

  @override
  CommandCategory get category => CommandCategory.information;

  @override
  Command<int> createInstance(CommandContext context) {
    return ContextCommand.create(context);
  }
}

