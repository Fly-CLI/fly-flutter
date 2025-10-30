import 'package:args/command_runner.dart';
import 'package:fly_cli/src/core/command_foundation/command_context.dart';
import 'package:fly_cli/src/core/command_foundation/fly_command_strategy.dart';
import 'package:fly_cli/src/core/command_foundation/fly_command_strategy_registry.dart';

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
  mcpServe,
  mcpDoctor,
}

/// Extension providing command metadata and factory methods
/// 
/// Delegates to strategy classes for command-specific implementation details,
/// maintaining enum exhaustiveness while leveraging the Strategy pattern
/// for flexibility and extensibility.
extension FlyCommandTypeExtension on FlyCommandType {
  /// Gets the strategy for this command type
  FlyCommandStrategy get _strategy => flyCommandStrategyRegistry.getStrategy(this);

  /// The command name as it appears in CLI
  String get name => _strategy.name;

  /// Human-readable description of the command
  String get description => _strategy.description;

  /// List of aliases for this command
  List<String> get aliases => _strategy.aliases;

  /// Parent command for subcommands, null for top-level commands
  FlyCommandType? get parentCommand => _strategy.parentCommand;

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
