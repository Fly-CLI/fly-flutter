import 'package:args/command_runner.dart';

import 'command_definition.dart';
import 'package:fly_cli/src/features/schema/infrastructure/metadata_extractor.dart';

/// Central registry for all command metadata
class CommandMetadataRegistry {
  CommandMetadataRegistry._();

  static CommandMetadataRegistry? _instance;
  
  static CommandMetadataRegistry get instance {
    _instance ??= CommandMetadataRegistry._();
    return _instance!;
  }

  final Map<String, CommandDefinition> _commands = {};
  final List<OptionDefinition> _globalOptions = [];
  final MetadataExtractor _extractor = const MetadataExtractor();
  
  bool _initialized = false;

  /// Initialize the registry by discovering commands from CommandRunner
  void initialize(CommandRunner<int> runner) {
    if (_initialized) {
      return;
    }

    // Extract global options
    _globalOptions.addAll(_extractor.extractGlobalOptions(runner));

    // Extract metadata from all commands
    for (final entry in runner.commands.entries) {
      final command = entry.value;
      final metadata = _extractor.extractMetadata(command, _globalOptions);
      _commands[entry.key] = metadata;
    }

    _initialized = true;
  }

  /// Get metadata for a specific command
  CommandDefinition? getCommand(String name) => _commands[name];

  /// Get all command metadata
  Map<String, CommandDefinition> getAllCommands() => Map.unmodifiable(_commands);

  /// Get global options
  List<OptionDefinition> getGlobalOptions() => List.unmodifiable(_globalOptions);

  /// Get subcommands for a command
  List<SubcommandDefinition> getSubcommands(String commandName) {
    final command = _commands[commandName];
    return command?.subcommands ?? [];
  }

  /// Get all commands with their names
  Iterable<String> getCommandNames() => _commands.keys;

  /// Check if a command exists
  bool hasCommand(String name) => _commands.containsKey(name);

  /// Export all metadata as JSON
  Map<String, dynamic> toJson() => {
      'commands': _commands.map((key, value) => MapEntry(key, value.toJson())),
      'global_options': _globalOptions.map((o) => o.toJson()).toList(),
    };

  /// Clear all metadata (useful for testing)
  void clear() {
    _commands.clear();
    _globalOptions.clear();
    _initialized = false;
  }

  /// Check if the registry has been initialized
  bool get isInitialized => _initialized;
}
