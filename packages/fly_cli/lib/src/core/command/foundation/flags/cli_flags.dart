/// CLI flag definitions following industry standards (POSIX/GNU conventions)
library;

// Part files
part 'definitions/global_flags.dart';
part 'definitions/common_flags.dart';
part 'definitions/schema_flags.dart';
part 'definitions/context_flags.dart';
part 'definitions/completion_flags.dart';
part 'definitions/create_flags.dart';
part '../../../command/foundation/flags/definitions/generate_flags.dart';
part 'definitions/doctor_flags.dart';
part 'definitions/version_flags.dart';
part 'definitions/mcp_flags.dart';

/// Flag categories following industry standards
enum CliFlagCategory {
  /// Help & Version flags (POSIX standards)
  helpVersion,

  /// Verbosity flags (industry standards)
  verbosity,

  /// Output format and file flags
  output,

  /// Execution control flags
  execution,

  /// Logging infrastructure flags
  logging,

  /// Input/Output file operations
  inputOutput,

  /// User interface flags
  ui,
}

/// Flag types for ArgParser
enum FlagType {
  /// Boolean flag (--flag)
  boolean,

  /// Single value flag (--option value)
  singleValue,

  /// Multiple values flag (--option val1 val2)
  multiValue,
}

/// Base sealed class for all CLI flags following industry standards
abstract class CliFlag {
  final String name;
  final String? abbreviation;
  final String description;
  final bool isGlobal;
  final CliFlagCategory category;
  final FlagType type;
  final bool isNegatable;
  final List<String>? allowedValues;
  final dynamic defaultValue;

  const CliFlag({
    required this.name,
    this.abbreviation,
    required this.description,
    required this.isGlobal,
    required this.category,
    required this.type,
    this.isNegatable = false,
    this.allowedValues,
    this.defaultValue,
  });

  /// Serialize the flag into the option metadata schema used by CommandDefinition.
  Map<String, dynamic> toJson({bool? isGlobalOverride}) {
    final map = <String, dynamic>{
      'name': name,
      'description': description,
      'type': _flagTypeToJsonType(type),
      'is_global': isGlobalOverride ?? isGlobal,
      'is_required': false,
    };

    if (abbreviation != null) {
      map['short'] = abbreviation;
    }

    if (defaultValue != null) {
      map['default_value'] = defaultValue;
    }

    if (allowedValues != null) {
      map['allowed_values'] = allowedValues;
    }

    return map;
  }
}

String _flagTypeToJsonType(FlagType type) => switch (type) {
      FlagType.boolean => 'flag',
      FlagType.singleValue => 'value',
      FlagType.multiValue => 'multiple',
    };
