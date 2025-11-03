import 'package:args/command_runner.dart';
import 'package:fly_cli/src/core/command/foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command/foundation/domain/fly_command_strategy.dart';
import 'package:fly_cli/src/core/definitions/categories.dart';
import 'package:fly_cli/src/features/create/create_command.dart';

/// Strategy for create command
class CreateCommandStrategy extends FlyCommandStrategy {
  @override
  String get name => 'create';

  @override
  String get description => 'Create a new Flutter project from templates';

  @override
  List<String> get aliases => ['new', 'init', 'scaffold', 'generate'];

  @override
  CommandGroup? get group => null;

  @override
  CommandCategory get category => CommandCategory.project;

  @override
  Command<int> createInstance(CommandContext context) {
    return CreateCommand.create(context);
  }
}
