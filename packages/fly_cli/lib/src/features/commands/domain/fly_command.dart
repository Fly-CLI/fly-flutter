import 'package:args/command_runner.dart';
import 'package:fly_cli/src/features/commands/application/fly_command_registry.dart';
import 'package:fly_cli/src/features/commands/domain/categories.dart';
import 'package:fly_cli/src/features/commands/domain/command_context.dart';
import 'package:fly_cli/src/features/commands/domain/fly_command_strategy.dart';
import 'package:fly_cli/src/features/completion/application/completion_command_strategy.dart';
import 'package:fly_cli/src/features/context/application/context_command_strategy.dart';
import 'package:fly_cli/src/features/diagnostics/application/doctor_command_strategy.dart';
import 'package:fly_cli/src/features/generate/feature/feature_command_strategy.dart';
import 'package:fly_cli/src/features/generate/project/project_command_strategy.dart';
import 'package:fly_cli/src/features/generate/service/service_command_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/application/mcp_doctor_command_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/application/mcp_serve_command_strategy.dart';
import 'package:fly_cli/src/features/schema/application/schema_command_strategy.dart';
import 'package:fly_cli/src/features/version/version/version_command_strategy.dart';

/// Enum representing all available Fly CLI commands
///
/// Commands are organized by category for better discoverability:
/// - Generation: generateProject, generateScreen, generateService
/// - Information: version, context, schema
/// - Diagnostics: doctor
/// - Integration: completion, mcpServe, mcpDoctor
enum FlyCommand {
  // Generation commands
  generateProject,
  generateFeature,
  generateService,

  // Information commands
  version,
  context,
  schema,

  // Diagnostics
  doctor,

  // Integration
  completion,
  mcpServe,
  mcpDoctor,
}

/// Extension providing command metadata and factory methods
///
/// Delegates to strategy classes for command-specific implementation details,
/// maintaining enum exhaustiveness while leveraging the Strategy pattern
/// for flexibility and extensibility.
extension FlyCommandExtension on FlyCommand {
  /// Gets the strategy factory for this command type
  ///
  /// Uses an exhaustive switch to ensure compile-time checking.
  /// Adding a new command requires adding a case here, which will
  /// cause a compile-time error if omitted.
  ///
  /// This is the single source of truth for command-to-strategy mapping.
  FlyCommandStrategy Function() get strategyFactory => switch (this) {
    FlyCommand.generateProject => ProjectCommandStrategy.new,
    FlyCommand.doctor => DoctorCommandStrategy.new,
    FlyCommand.schema => SchemaCommandStrategy.new,
    FlyCommand.version => VersionCommandStrategy.new,
    FlyCommand.context => ContextCommandStrategy.new,
    FlyCommand.completion => CompletionCommandStrategy.new,
    FlyCommand.generateFeature => FeatureCommandStrategy.new,
    FlyCommand.generateService => ServiceCommandStrategy.new,
    FlyCommand.mcpServe => McpServeCommandStrategy.new,
    FlyCommand.mcpDoctor => McpDoctorCommandStrategy.new,
  };

  /// Gets the strategy for this command type
  FlyCommandStrategy get _strategy =>
      FlyCommandRegistry.instance.getStrategy(this);

  /// The command name as it appears in CLI
  String get name => _strategy.name;

  /// Human-readable description of the command
  String get description => _strategy.description;

  /// List of aliases for this command
  List<String> get aliases => _strategy.aliases;

  /// The command group information (null if not part of a group)
  CommandGroup? get group => _strategy.group;

  /// Whether this command is a top-level command
  bool get isTopLevel => _strategy.isTopLevel;

  /// Whether this command is a subcommand
  bool get isSubcommand => _strategy.isSubcommand;

  /// Command category for better organization
  CommandCategory get category => _strategy.category;

  /// Create a command instance using the appropriate factory method
  Command<int> createInstance(CommandContext context) {
    return _strategy.createInstance(context);
  }
}
