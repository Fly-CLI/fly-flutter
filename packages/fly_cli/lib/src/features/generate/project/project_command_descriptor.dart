import 'package:args/command_runner.dart';
import 'package:fly_cli/src/features/commands/domain/categories.dart';
import 'package:fly_cli/src/features/commands/domain/command_context.dart';
import 'package:fly_cli/src/features/commands/domain/fly_command_strategy.dart';
import 'package:fly_cli/src/features/generate/project/generate_project_command.dart';

/// Strategy for project command
class ProjectCommandDescriptor extends FlyCommandDescriptor {
  @override
  String get name => 'project';

  @override
  String get description => 'Generate a new Flutter project from templates';

  @override
  List<String> get aliases => ['new', 'init', 'scaffold', 'create'];

  @override
  CommandGroup? get group => const CommandGroup(
        name: 'generate',
        description: 'Generate new components for the current project',
      );

  @override
  CommandCategory get category => CommandCategory.generation;

  @override
  Command<int> createInstance(CommandContext context) {
    return GenerateProjectCommand.create(context);
  }
}

