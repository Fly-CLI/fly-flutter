import 'package:args/command_runner.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/features/completion/application/completion_command.dart';
import 'package:fly_cli/src/features/context/application/context_command.dart';
import 'package:fly_cli/src/features/create/application/create_command.dart';
import 'package:fly_cli/src/features/doctor/application/doctor_command.dart';
import 'package:fly_cli/src/features/schema/application/schema_command.dart';
import 'package:fly_cli/src/features/screen/application/add_screen_command.dart';
import 'package:fly_cli/src/features/service/application/add_service_command.dart';
import 'package:fly_cli/src/features/version/application/version_command.dart';

/// Command categories for better organization
enum CommandCategory {
  projectSetup, // create
  codeGeneration, // screen, service
  diagnostics, // doctor
  information, // version, context
  integration, // schema, completion
}

/// Represents a command group with name and description
class CommandGroup {
  const CommandGroup({
    required this.name,
    required this.description,
  });

  /// The name of the command group
  final String name;

  /// The description of the command group
  final String description;
}

/// Enum representing all available Fly CLI commands
enum FlyCommandType {
  create,
  doctor,
  schema,
  version,
  context,
  completion,
  screen, 
  service, 
}

/// Extension providing command metadata and factory methods
extension FlyCommandTypeExtension on FlyCommandType {
  /// The command name as it appears in CLI
  String get name {
    switch (this) {
      case FlyCommandType.create:
        return 'create';
      case FlyCommandType.doctor:
        return 'doctor';
      case FlyCommandType.schema:
        return 'schema';
      case FlyCommandType.version:
        return 'version';
      case FlyCommandType.context:
        return 'context';
      case FlyCommandType.completion:
        return 'completion';
      case FlyCommandType.screen:
        return 'screen';
      case FlyCommandType.service:
        return 'service';
    }
  }

  /// Human-readable description of the command
  String get description {
    switch (this) {
      case FlyCommandType.create:
        return 'Create a new Flutter project from templates';
      case FlyCommandType.doctor:
        return 'Check Flutter environment and diagnose issues';
      case FlyCommandType.schema:
        return 'Export command schema for AI integration';
      case FlyCommandType.version:
        return 'Show version information and check for updates';
      case FlyCommandType.context:
        return 'Analyze project context and generate insights';
      case FlyCommandType.completion:
        return 'Generate shell completion scripts for command line';
      case FlyCommandType.screen:
        return 'Add a new screen component to the current project';
      case FlyCommandType.service:
        return 'Add a new service component to the current project';
    }
  }

  /// List of aliases for this command
  List<String> get aliases {
    switch (this) {
      case FlyCommandType.create:
        return ['new', 'init', 'scaffold', 'generate'];
      case FlyCommandType.doctor:
        return ['check', 'diagnose', 'health'];
      case FlyCommandType.schema:
        return ['spec', 'export', 'api'];
      case FlyCommandType.version:
        return ['--version', '-v', 'info'];
      case FlyCommandType.context:
        return ['analyze', 'insights', 'project'];
      case FlyCommandType.completion:
        return ['completions', 'complete', 'tab'];
      case FlyCommandType.screen:
        return [
          'add-screen',
          'generate-screen',
          'new-screen',
          'make-screen',
          'addScreen'
        ];
      case FlyCommandType.service:
        return [
          'add-service',
          'generate-service',
          'new-service',
          'make-service',
          'addService'
        ];
    }
  }

  /// Parent command for subcommands, null for top-level commands
  FlyCommandType? get parentCommand {
    switch (this) {
      case FlyCommandType.screen:
      case FlyCommandType.service:
        return null; // These will be grouped under 'add' command
      case FlyCommandType.create:
      case FlyCommandType.doctor:
      case FlyCommandType.schema:
      case FlyCommandType.version:
      case FlyCommandType.context:
      case FlyCommandType.completion:
        return null;
    }
  }

  /// The command group information (null if not part of a group)
  CommandGroup? get group {
    switch (this) {
      case FlyCommandType.screen:
      case FlyCommandType.service:
        return const CommandGroup(
          name: 'add',
          description: 'Add new components to the current project',
        );
      case FlyCommandType.schema:
      case FlyCommandType.context:
        return const CommandGroup(
          name: 'ai',
          description: 'AI integration commands for coding assistants',
        );
      case FlyCommandType.create:
      case FlyCommandType.doctor:
      case FlyCommandType.version:
      case FlyCommandType.completion:
        return null;
    }
  }

  /// Whether this command is a top-level command
  bool get isTopLevel => parentCommand == null;

  /// Whether this command is a subcommand
  bool get isSubcommand => parentCommand != null;

  /// Command category for better organization
  CommandCategory get category {
    switch (this) {
      case FlyCommandType.create:
        return CommandCategory.projectSetup;
      case FlyCommandType.screen:
      case FlyCommandType.service:
        return CommandCategory.codeGeneration;
      case FlyCommandType.doctor:
        return CommandCategory.diagnostics;
      case FlyCommandType.version:
      case FlyCommandType.context:
        return CommandCategory.information;
      case FlyCommandType.schema:
      case FlyCommandType.completion:
        return CommandCategory.integration;
    }
  }

  /// Create a command instance using the appropriate factory method
  Command<int> createInstance(CommandContext context) {
    switch (this) {
      case FlyCommandType.create:
        return CreateCommand.create(context);
      case FlyCommandType.doctor:
        return DoctorCommand.create(context);
      case FlyCommandType.schema:
        return SchemaCommand.create(context);
      case FlyCommandType.version:
        return VersionCommand.create(context);
      case FlyCommandType.context:
        return ContextCommand.create(context);
      case FlyCommandType.completion:
        return CompletionCommand.create(context);
      case FlyCommandType.screen:
        return AddScreenCommand.create(context);
      case FlyCommandType.service:
        return AddServiceCommand.create(context);
    }
  }
}
