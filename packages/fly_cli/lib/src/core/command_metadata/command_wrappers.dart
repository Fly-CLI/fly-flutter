import 'package:args/command_runner.dart';

/// Command class for grouping subcommands
///
/// This wrapper allows multiple subcommands to be grouped under a single
/// top-level command name. Useful for organizing related commands.
class GroupCommand extends Command<int> {
  /// Creates a new group command
  ///
  /// [groupName] - The name of the command group
  /// [description] - Optional description for the group (defaults to generic description)
  GroupCommand(this.groupName, {String? description})
      : _description = description ?? 'Group of related commands',
        super();

  /// The name of the command group
  final String groupName;

  final String _description;

  @override
  String get name => groupName;

  @override
  String get description => _description;

  @override
  Future<int> run() async {
    // This is handled by subcommands
    return 0;
  }

  /// Add a subcommand to this group
  void addSubcommand(Command<int> subcommand) {
    super.addSubcommand(subcommand);
  }
}

/// Command class for creating command aliases
///
/// This wrapper allows creating alternative names for existing commands,
/// delegating all execution to the target command.
class AliasCommand extends Command<int> {
  /// Creates a new alias command
  ///
  /// [aliasName] - The alias name for the command
  /// [targetCommand] - The command instance to delegate to
  AliasCommand(String aliasName, this._targetCommand)
      : _aliasName = aliasName,
        super();

  /// The command instance to delegate execution to
  final Command<int> _targetCommand;

  /// The alias name
  final String _aliasName;

  @override
  String get name => _aliasName;

  @override
  String get description => _targetCommand.description;

  @override
  Future<int> run() async {
    final result = await _targetCommand.run();
    return result is int ? result : 1;
  }
}

