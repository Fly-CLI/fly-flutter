import 'package:args/command_runner.dart';
import 'package:fly_cli/src/core/command_foundation/command_context.dart';
import 'package:fly_cli/src/core/command_foundation/fly_command_strategy.dart';
import 'package:fly_cli/src/core/command_foundation/fly_command_type.dart';
import 'package:fly_cli/src/features/schema/schema_command.dart';

/// Strategy for schema command
class SchemaCommandStrategy extends FlyCommandStrategy {
  @override
  String get name => 'schema';

  @override
  String get description => 'Export command schema for AI integration';

  @override
  List<String> get aliases => ['spec', 'export', 'api'];

  @override
  FlyCommandType? get parentCommand => null;

  @override
  CommandGroup? get group => const CommandGroup(
        name: 'ai',
        description: 'AI integration commands for coding assistants',
      );

  @override
  CommandCategory get category => CommandCategory.integration;

  @override
  Command<int> createInstance(CommandContext context) {
    return SchemaCommand.create(context);
  }
}

