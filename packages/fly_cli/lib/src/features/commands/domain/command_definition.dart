/// Command metadata definitions for Fly CLI
library;

import 'package:fly_cli/src/features/commands/infrastructure/flags/cli_flags.dart';
import 'package:json_annotation/json_annotation.dart';

part 'command_definition.g.dart';

/// Complete command specification with all metadata
class CommandDefinition {
  /// Create CommandDefinition from JSON metadata
  factory CommandDefinition.fromJson(Map<String, dynamic> json) {
    List<T> _readList<T>(
      List<dynamic>? source,
      T Function(Map<String, dynamic> map) convert,
    ) {
      if (source == null) return const [];
      return source
          .map((e) => convert(e as Map<String, dynamic>))
          .toList(growable: false);
    }

    return CommandDefinition(
      name: json['name'] as String,
      description: json['description'] as String,
      arguments: _readList(
        json['arguments'] as List<dynamic>?,
        ArgumentDefinition.fromJson,
      ),
      options: _readList(
        json['options'] as List<dynamic>?,
        CliFlag.fromJson,
      ),
      subcommands: _readList(
        json['subcommands'] as List<dynamic>?,
        SubcommandDefinition.fromJson,
      ),
      examples: _readList(
        json['examples'] as List<dynamic>?,
        CommandExample.fromJson,
      ),
      globalOptions: _readList(
        json['global_options'] as List<dynamic>?,
        CliFlag.fromJson,
      ),
      isHidden: json['is_hidden'] as bool? ?? false,
    );
  }

  const CommandDefinition({
    required this.name,
    required this.description,
    this.arguments = const [],
    this.options = const [],
    this.subcommands = const [],
    this.examples = const [],
    this.globalOptions = const [],
    this.isHidden = false,
  });

  /// Command name (e.g., 'create')
  final String name;

  /// Human-readable description
  final String description;

  /// Positional arguments
  final List<ArgumentDefinition> arguments;

  /// Command-specific options/flags
  final List<CliFlag> options;

  /// Nested subcommands
  final List<SubcommandDefinition> subcommands;

  /// Usage examples
  final List<CommandExample> examples;

  /// Global options available to this command
  @JsonKey(name: 'global_options')
  final List<CliFlag> globalOptions;

  /// Whether the command is hidden from help
  @JsonKey(name: 'is_hidden')
  final bool isHidden;

  /// Create a copy with modified fields
  CommandDefinition copyWith({
    String? name,
    String? description,
    List<ArgumentDefinition>? arguments,
    List<CliFlag>? options,
    List<SubcommandDefinition>? subcommands,
    List<CommandExample>? examples,
    List<CliFlag>? globalOptions,
    bool? isHidden,
  }) => CommandDefinition(
    name: name ?? this.name,
    description: description ?? this.description,
    arguments: arguments ?? this.arguments,
    options: options ?? this.options,
    subcommands: subcommands ?? this.subcommands,
    examples: examples ?? this.examples,
    globalOptions: globalOptions ?? this.globalOptions,
    isHidden: isHidden ?? this.isHidden,
  );

  /// Convert to JSON for schema export
  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'arguments': arguments.map((e) => e.toJson()).toList(),
    'options': options.map((flag) => flag.toJson()).toList(),
    'subcommands': subcommands.map((e) => e.toJson()).toList(),
    'examples': examples.map((e) => e.toJson()).toList(),
    'global_options': globalOptions
        .map((flag) => flag.toJson(isGlobalOverride: true))
        .toList(),
    'is_hidden': isHidden,
  };

  /// Validate metadata integrity
  bool isValid() {
    if (name.isEmpty) return false;
    if (description.isEmpty) return false;

    // Validate all arguments
    for (final arg in arguments) {
      if (!arg.isValid()) return false;
    }

    // Validate all options
    for (final option in options) {
      if (option.name.isEmpty) return false;
      if (option.description.isEmpty) return false;
    }

    // Validate all subcommands
    for (final subcommand in subcommands) {
      if (!subcommand.isValid()) return false;
    }

    return true;
  }

  @override
  String toString() =>
      'CommandDefinition(name: $name, description: $description)';
}

/// Positional argument metadata
@JsonSerializable(explicitToJson: true, includeIfNull: false)
class ArgumentDefinition {
  /// Create ArgumentDefinition from JSON
  factory ArgumentDefinition.fromJson(Map<String, dynamic> json) =>
      _$ArgumentDefinitionFromJson(json);

  const ArgumentDefinition({
    required this.name,
    required this.description,
    this.required = true,
    this.allowedValues,
    this.defaultValue,
  });

  /// Argument name
  final String name;

  /// Human-readable description
  final String description;

  /// Whether the argument is required
  final bool required;

  /// Allowed values (if restricted)
  @JsonKey(name: 'allowed_values')
  final List<String>? allowedValues;

  /// Default value (for optional arguments)
  @JsonKey(name: 'default_value')
  final String? defaultValue;

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$ArgumentDefinitionToJson(this);

  /// Validate metadata
  bool isValid() {
    if (name.isEmpty) return false;
    if (description.isEmpty) return false;
    return true;
  }

  @override
  String toString() => 'ArgumentDefinition(name: $name, required: $required)';
}

/// Subcommand metadata
@JsonSerializable(explicitToJson: true, includeIfNull: false)
class SubcommandDefinition {
  /// Create SubcommandDefinition from JSON
  factory SubcommandDefinition.fromJson(Map<String, dynamic> json) =>
      _$SubcommandDefinitionFromJson(json);

  const SubcommandDefinition({
    required this.name,
    required this.description,
    this.isHidden = false,
  });

  /// Subcommand name
  final String name;

  /// Human-readable description
  final String description;

  /// Whether the subcommand is hidden
  @JsonKey(name: 'is_hidden')
  final bool isHidden;

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$SubcommandDefinitionToJson(this);

  /// Validate metadata
  bool isValid() {
    if (name.isEmpty) return false;
    if (description.isEmpty) return false;
    return true;
  }

  @override
  String toString() => 'SubcommandDefinition(name: $name)';
}

/// Command usage example
@JsonSerializable(explicitToJson: true, includeIfNull: false)
class CommandExample {
  /// Create CommandExample from JSON
  factory CommandExample.fromJson(Map<String, dynamic> json) =>
      _$CommandExampleFromJson(json);

  const CommandExample({
    required this.command,
    required this.description,
  });

  /// Example command string
  final String command;

  /// Description of what the example demonstrates
  final String description;

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$CommandExampleToJson(this);

  @override
  String toString() => 'CommandExample(command: $command)';
}
