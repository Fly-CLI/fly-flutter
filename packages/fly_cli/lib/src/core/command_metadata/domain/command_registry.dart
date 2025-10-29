import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command_foundation/domain/fly_command_type.dart';
import 'package:fly_cli/src/core/command_metadata/domain/command_definition.dart';
import 'package:fly_cli/src/core/command_metadata/infrastructure/command_wrappers.dart';
import 'package:fly_cli/src/core/command_metadata/infrastructure/metadata_extractor.dart';

/// Registration data returned to CommandRunner for command registration
class CommandRegistrationData {

  CommandRegistrationData({
    required this.topLevelCommands,
    required this.commandGroups,
  });
  /// Top-level commands to register (keyed by command type)
  final Map<FlyCommandType, Command<int>> topLevelCommands;

  /// Command groups to register (keyed by group name)
  final Map<String, Command<int>> commandGroups;
}

/// Central registry for all command metadata
class CommandMetadataRegistry {
  CommandMetadataRegistry._();

  static CommandMetadataRegistry? _instance;

  /// Get the singleton instance of CommandMetadataRegistry
  static CommandMetadataRegistry get instance {
    _instance ??= CommandMetadataRegistry._();
    return _instance!;
  }

  final Map<FlyCommandType, Command<int>> _commandInstances = {};
  final Map<String, Command<int>> _commandGroups = {};
  ArgParser? _globalOptionsParser;
  final MetadataExtractor _extractor = const MetadataExtractor();

  /// Create all commands and initialize registry
  ///
  /// This method creates all command instances from the enum, builds groups
  /// dynamically, stores them internally, and returns registration data for
  /// CommandRunner to register.
  ///
  /// [context] - CommandContext for creating command instances
  /// [globalOptionsParser] - ArgParser containing global options
  ///
  /// Returns [CommandRegistrationData] containing all commands and groups
  /// that need to be registered with CommandRunner.
  CommandRegistrationData createAndInitialize({
    required CommandContext context,
    required ArgParser globalOptionsParser,
  }) {
    // Create all command instances from enum
    final commandInstances = <FlyCommandType, Command<int>>{};
    for (final commandType in FlyCommandType.values) {
      commandInstances[commandType] = commandType.createInstance(context);
    }

    // Build command groups dynamically
    final commandGroups = _buildCommandGroups(commandInstances);

    // Store internally for metadata access
    _commandInstances.addAll(commandInstances);
    _commandGroups.addAll(commandGroups);
    _globalOptionsParser = globalOptionsParser;

    // Return top-level commands for registration
    final topLevelCommands = <FlyCommandType, Command<int>>{};
    for (final entry in commandInstances.entries) {
      final commandType = entry.key;
      if (commandType.isTopLevel) {
        topLevelCommands[commandType] = entry.value;
      }
    }

    return CommandRegistrationData(
      topLevelCommands: topLevelCommands,
      commandGroups: commandGroups,
    );
  }

  /// Build command groups dynamically from enum
  ///
  /// Groups commands by their `group` property and creates group command
  /// instances containing their respective subcommands.
  Map<String, Command<int>> _buildCommandGroups(
    Map<FlyCommandType, Command<int>> commandInstances,
  ) {
    final groups = <String, Command<int>>{};

    // Group commands by group
    final groupMap = <String, List<FlyCommandType>>{};
    for (final entry in commandInstances.entries) {
      final commandType = entry.key;
      final group = commandType.group;
      if (group != null) {
        groupMap.putIfAbsent(group.name, () => []).add(commandType);
      }
    }

    // Create GroupCommand for each group
    for (final entry in groupMap.entries) {
      final groupName = entry.key;
      final subcommandTypes = entry.value;

      // Get description from the first command in the group
      // (all commands in a group should have the same description)
      final groupDescription = subcommandTypes.isNotEmpty
          ? subcommandTypes.first.group?.description
          : null;

      final groupCommand = GroupCommand(
        groupName,
        description: groupDescription,
      );
      for (final subcommandType in subcommandTypes) {
        groupCommand.addSubcommand(commandInstances[subcommandType]!);
      }
      groups[groupName] = groupCommand;
    }

    return groups;
  }

  /// Initialize the registry from pre-created command instances
  ///
  /// This method stores command instances directly, allowing lazy metadata
  /// extraction when metadata is requested. This avoids upfront processing
  /// overhead and reduces memory usage.
  ///
  /// Useful for testing scenarios where you want to provide pre-created instances.
  ///
  /// [commandInstances] - Map of command types to their pre-created instances
  /// [commandGroups] - Map of group names to their pre-created group command instances
  /// [globalOptionsParser] - ArgParser containing global options
  void initializeFromInstances({
    required Map<FlyCommandType, Command<int>> commandInstances,
    required Map<String, Command<int>> commandGroups,
    required ArgParser globalOptionsParser,
  }) {
    _commandInstances.addAll(commandInstances);
    _commandGroups.addAll(commandGroups);
    _globalOptionsParser = globalOptionsParser;
  }

  /// Find command instance by name
  Command<int>? _findInstanceByName(String name) {
    // Check command groups first
    if (_commandGroups.containsKey(name)) {
      return _commandGroups[name];
    }

    // Search through command instances
    for (final entry in _commandInstances.entries) {
      final commandType = entry.key;
      final instance = entry.value;

      // Check if name matches command name
      if (commandType.name == name) {
        return instance;
      }

      // Check if name matches any alias
      if (commandType.aliases.contains(name)) {
        return instance;
      }
    }

    return null;
  }

  /// Extract global options on-demand from parser
  List<OptionDefinition> _extractGlobalOptions() {
    if (_globalOptionsParser == null) {
      return [];
    }
    return _extractor.extractGlobalOptions(_globalOptionsParser!);
  }

  /// Get metadata for a specific command
  CommandDefinition? getCommand(String name) {
    final instance = _findInstanceByName(name);
    if (instance == null) {
      return null;
    }

    final globalOptions = _extractGlobalOptions();
    return _extractor.extractMetadata(instance, globalOptions);
  }

  /// Get all command metadata
  Map<String, CommandDefinition> getAllCommands() {
    final result = <String, CommandDefinition>{};
    final globalOptions = _extractGlobalOptions();

    // Process all top-level command instances
    for (final entry in _commandInstances.entries) {
      final commandType = entry.key;
      final instance = entry.value;

      // Skip subcommands (they're handled via 'add' group)
      if (commandType.group != null) {
        continue;
      }

      final metadata = _extractor.extractMetadata(instance, globalOptions);
      result[commandType.name] = metadata;
    }

    // Add all command groups
    for (final entry in _commandGroups.entries) {
      final groupMetadata = _extractor.extractMetadata(
        entry.value,
        globalOptions,
      );
      result[entry.key] = groupMetadata;
    }

    return Map.unmodifiable(result);
  }

  /// Get global options
  List<OptionDefinition> getGlobalOptions() {
    return List.unmodifiable(_extractGlobalOptions());
  }

  /// Get subcommands for a command
  List<SubcommandDefinition> getSubcommands(String commandName) {
    final instance = _findInstanceByName(commandName);
    if (instance == null) {
      return [];
    }

    final globalOptions = _extractGlobalOptions();
    final metadata = _extractor.extractMetadata(instance, globalOptions);
    return metadata.subcommands;
  }

  /// Get all commands with their names
  Iterable<String> getCommandNames() {
    final names = <String>[];

    // Add all top-level command names
    for (final entry in _commandInstances.entries) {
      final commandType = entry.key;
      if (commandType.group == null) {
        names.add(commandType.name);
      }
    }

    // Add all command group names
    names.addAll(_commandGroups.keys);

    return names;
  }

  /// Check if a command exists
  bool hasCommand(String name) {
    return _findInstanceByName(name) != null;
  }

  /// Export all metadata as JSON
  Map<String, dynamic> toJson() {
    final allCommands = getAllCommands();
    final globalOptions = _extractGlobalOptions();

    return {
      'commands': allCommands.map((key, value) => MapEntry(key, value.toJson())),
      'global_options': globalOptions.map((o) => o.toJson()).toList(),
    };
  }

  /// Clear all metadata (useful for testing)
  void clear() {
    _commandInstances.clear();
    _commandGroups.clear();
    _globalOptionsParser = null;
  }

  /// Check if the registry has been initialized
  bool get isInitialized => _commandInstances.isNotEmpty || _commandGroups.isNotEmpty;
}
