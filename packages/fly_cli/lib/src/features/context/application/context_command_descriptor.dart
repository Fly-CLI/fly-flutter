import 'package:args/command_runner.dart';
import 'package:fly_cli/src/features/commands/domain/command_context.dart';
import 'package:fly_cli/src/features/commands/domain/fly_command_strategy.dart';
import 'package:fly_cli/src/features/commands/domain/categories.dart';
import 'package:fly_cli/src/features/context/application/context_command.dart';

/// Strategy for context command
class ContextCommandDescriptor extends FlyCommandDescriptor {
  @override
  String get name => 'context';

  @override
  String get description => 'Analyze project context and generate insights';

  @override
  List<String> get aliases => ['analyze', 'insights', 'project'];

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
