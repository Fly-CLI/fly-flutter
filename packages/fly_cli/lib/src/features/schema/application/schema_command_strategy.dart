import 'package:args/command_runner.dart';
import 'package:fly_cli/src/features/commands/domain/command_context.dart';
import 'package:fly_cli/src/features/commands/domain/fly_command_strategy.dart';
import 'package:fly_cli/src/features/commands/domain/categories.dart';
import 'package:fly_cli/src/features/schema/application/schema_command.dart';

/// Strategy for schema command
class SchemaCommandStrategy extends FlyCommandStrategy {
  @override
  String get name => 'schema';

  @override
  String get description => 'Export command schema for AI integration';

  @override
  List<String> get aliases => ['spec', 'export', 'api'];

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
