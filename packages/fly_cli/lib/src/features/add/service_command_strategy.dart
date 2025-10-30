import 'package:args/command_runner.dart';
import 'package:fly_cli/src/core/command_foundation/command_context.dart';
import 'package:fly_cli/src/core/command_foundation/fly_command_strategy.dart';
import 'package:fly_cli/src/core/command_foundation/fly_command_type.dart';
import 'package:fly_cli/src/features/add/add_service_command.dart';

/// Strategy for service command
class ServiceCommandStrategy extends FlyCommandStrategy {
  @override
  String get name => 'service';

  @override
  String get description => 'Add a new service component to the current project';

  @override
  List<String> get aliases => [
        'add-service',
        'generate-service',
        'new-service',
        'make-service',
        'addService',
      ];

  @override
  FlyCommandType? get parentCommand => null;

  @override
  CommandGroup? get group => const CommandGroup(
        name: 'add',
        description: 'Add new components to the current project',
      );

  @override
  CommandCategory get category => CommandCategory.codeGeneration;

  @override
  Command<int> createInstance(CommandContext context) {
    return AddServiceCommand.create(context);
  }
}

