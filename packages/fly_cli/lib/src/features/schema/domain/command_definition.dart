/// Command metadata definitions for Fly CLI
library command_definition;

/// Complete command specification with all metadata
class CommandDefinition {
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

  /// Command-specific options
  final List<OptionDefinition> options;

  /// Nested subcommands
  final List<SubcommandDefinition> subcommands;

  /// Usage examples
  final List<CommandExample> examples;

  /// Global options available to this command
  final List<OptionDefinition> globalOptions;

  /// Whether the command is hidden from help
  final bool isHidden;

  /// Create a copy with modified fields
  CommandDefinition copyWith({
    String? name,
    String? description,
    List<ArgumentDefinition>? arguments,
    List<OptionDefinition>? options,
    List<SubcommandDefinition>? subcommands,
    List<CommandExample>? examples,
    List<OptionDefinition>? globalOptions,
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
      'arguments': arguments.map((a) => a.toJson()).toList(),
      'options': options.map((o) => o.toJson()).toList(),
      'subcommands': subcommands.map((s) => s.toJson()).toList(),
      'examples': examples.map((e) => e.toJson()).toList(),
      'global_options': globalOptions.map((o) => o.toJson()).toList(),
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
      if (!option.isValid()) return false;
    }

    // Validate all subcommands
    for (final subcommand in subcommands) {
      if (!subcommand.isValid()) return false;
    }

    return true;
  }

  @override
  String toString() => 'CommandDefinition(name: $name, description: $description)';
}

/// Positional argument metadata
class ArgumentDefinition {
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
  final List<String>? allowedValues;

  /// Default value (for optional arguments)
  final String? defaultValue;

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
      'name': name,
      'description': description,
      'required': required,
      if (allowedValues != null) 'allowed_values': allowedValues,
      if (defaultValue != null) 'default_value': defaultValue,
    };

  /// Validate metadata
  bool isValid() {
    if (name.isEmpty) return false;
    if (description.isEmpty) return false;
    return true;
  }

  @override
  String toString() => 'ArgumentDefinition(name: $name, required: $required)';
}

/// Option/flag metadata
class OptionDefinition {
  const OptionDefinition({
    required this.name,
    required this.description,
    this.short,
    this.type = OptionType.flag,
    this.defaultValue,
    this.allowedValues,
    this.isGlobal = false,
    this.isRequired = false,
  });

  /// Option name (without -- prefix)
  final String name;

  /// Human-readable description
  final String description;

  /// Short flag (e.g., 'v' for --verbose)
  final String? short;

  /// Option type (flag, string, multiple, etc.)
  final OptionType type;

  /// Default value
  final dynamic defaultValue;

  /// Allowed values (e.g., ['human', 'json'])
  final List<String>? allowedValues;

  /// Whether this is a global option
  final bool isGlobal;

  /// Whether the option is required
  final bool isRequired;

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
      'name': name,
      'description': description,
      if (short != null) 'short': short,
      'type': type.name,
      if (defaultValue != null) 'default_value': defaultValue,
      if (allowedValues != null) 'allowed_values': allowedValues,
      'is_global': isGlobal,
      'is_required': isRequired,
    };

  /// Get display name (--name or -short)
  String getDisplayName() => short != null ? '-$short/--$name' : '--$name';

  /// Validate metadata
  bool isValid() {
    if (name.isEmpty) return false;
    if (description.isEmpty) return false;
    
    // Validate type constraints
    if (type == OptionType.flag && defaultValue != null && defaultValue is bool == false) {
      return false;
    }
    
    return true;
  }

  @override
  String toString() => 'OptionDefinition(name: $name, type: ${type.name})';
}

/// Option type enumeration
enum OptionType {
  /// Boolean flag (--flag)
  flag,

  /// Single value (--option value)
  value,

  /// Multiple values (--option val1 --option val2)
  multiple,
}

/// Subcommand metadata
class SubcommandDefinition {
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
  final bool isHidden;

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
      'name': name,
      'description': description,
      'is_hidden': isHidden,
    };

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
class CommandExample {
  const CommandExample({
    required this.command,
    required this.description,
  });

  /// Example command string
  final String command;

  /// Description of what the example demonstrates
  final String description;

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
      'command': command,
      'description': description,
    };

  @override
  String toString() => 'CommandExample(command: $command)';
}
