import 'package:args/command_runner.dart';
import 'package:fly_cli/src/core/command/foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/definitions/categories.dart';

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

  /// The command group information (null if not part of a group)
  CommandGroup? get group;

  /// Command category for better organization
  CommandCategory get category;

  /// Whether this command is a top-level command
  ///
  /// Determined by the presence of a group - commands in a group are considered subcommands
  bool get isTopLevel => group == null;

  /// Whether this command is a subcommand
  ///
  /// Determined by the presence of a group - commands in a group are subcommands
  bool get isSubcommand => group != null;

  /// Create a command instance using the appropriate factory method
  Command<int> createInstance(CommandContext context);
}
