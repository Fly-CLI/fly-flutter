part of '../cli_flags.dart';

// ============================================================================
// Schema Command Flags
// ============================================================================

/// Schema export format flag
class SchemaFormatFlag extends CliFlag {
  const SchemaFormatFlag() : super(
        name: 'format',
        description: 'Export format',
        isGlobal: false,
        category: CliFlagCategory.output,
        type: FlagType.singleValue,
        allowedValues: const ['json-schema', 'openapi', 'cli-spec'],
        defaultValue: 'json-schema',
      );
}

/// Schema command filter flag (-c, --command)
class SchemaCommandFilterFlag extends CliFlag {
  const SchemaCommandFilterFlag() : super(
        name: 'command',
        abbreviation: 'c',
        description: 'Export schema for specific command only',
        isGlobal: false,
        category: CliFlagCategory.output,
        type: FlagType.singleValue,
      );
}

/// Schema include examples flag
class SchemaIncludeExamplesFlag extends CliFlag {
  const SchemaIncludeExamplesFlag() : super(
        name: 'include-examples',
        description: 'Include command examples in schema',
        isGlobal: false,
        category: CliFlagCategory.output,
        type: FlagType.boolean,
        isNegatable: false,
        defaultValue: true,
      );
}

/// Schema include validation flag
class SchemaIncludeValidationFlag extends CliFlag {
  const SchemaIncludeValidationFlag() : super(
        name: 'include-validation',
        description: 'Include validation rules in schema',
        isGlobal: false,
        category: CliFlagCategory.output,
        type: FlagType.boolean,
        isNegatable: false,
        defaultValue: true,
      );
}

/// Schema include global options flag
class SchemaIncludeGlobalOptionsFlag extends CliFlag {
  const SchemaIncludeGlobalOptionsFlag() : super(
        name: 'include-global-options',
        description: 'Include global options in schema',
        isGlobal: false,
        category: CliFlagCategory.output,
        type: FlagType.boolean,
        isNegatable: false,
        defaultValue: true,
      );
}

/// Schema pretty print flag
class SchemaPrettyPrintFlag extends CliFlag {
  const SchemaPrettyPrintFlag() : super(
        name: 'pretty-print',
        description: 'Pretty print the output',
        isGlobal: false,
        category: CliFlagCategory.output,
        type: FlagType.boolean,
        isNegatable: false,
        defaultValue: true,
      );
}
