import 'package:args/command_runner.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command_foundation/domain/fly_command_type.dart';

/// Abstract base class for Fly command strategies
/// 
/// Each command implements a concrete strategy that encapsulates all command-specific
/// metadata, aliases, grouping, and factory methods.
abstract class FlyCommandStrategy {
  /// The command name as it appears in CLI (e.g., 'create')
  String get name;

  /// Human-readable description of the command
  String get description;

  /// List of aliases for this command
  List<String> get aliases;

  /// Parent command for subcommands, null for top-level commands
  FlyCommandType? get parentCommand;

  /// The command group information (null if not part of a group)
  CommandGroup? get group;

  /// Command category for better organization
  CommandCategory get category;

  /// Whether this command is a top-level command
  bool get isTopLevel => parentCommand == null;

  /// Whether this command is a subcommand
  bool get isSubcommand => parentCommand != null;

  /// Create a command instance using the appropriate factory method
  Command<int> createInstance(CommandContext context);
}

