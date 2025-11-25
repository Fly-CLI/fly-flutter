import 'package:args/command_runner.dart';
import 'package:fly_cli/src/features/commands/domain/categories.dart';
import 'package:fly_cli/src/features/commands/domain/command_context.dart';
import 'package:fly_cli/src/features/commands/domain/fly_command_strategy.dart';
import 'package:fly_cli/src/features/generate/service/generate_service_command.dart';

/// Strategy for service command
class ServiceCommandDescriptor extends FlyCommandDescriptor {
  @override
  String get name => 'service';

  @override
  String get description =>
      'Generate a new service component to the current project';

  @override
  List<String> get aliases => [
    'generate-service',
    'add-service',
    'new-service',
    'make-service',
    'generateService',
  ];

  @override
  CommandGroup? get group => const CommandGroup(
    name: 'generate',
    description: 'Generate new components for the current project',
  );

  @override
  CommandCategory get category => CommandCategory.generation;

  @override
  Command<int> createInstance(CommandContext context) {
    return GenerateServiceCommand.create(context);
  }
}
