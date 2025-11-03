part of '../cli_flags.dart';

// ============================================================================
// Context Command Flags
// ============================================================================

/// Context include code flag
class ContextIncludeCodeFlag extends CliFlag {
  const ContextIncludeCodeFlag() : super(
        name: 'include-code',
        description: 'Include source code in context export',
        isGlobal: false,
        category: CliFlagCategory.output,
        type: FlagType.boolean,
        isNegatable: false,
        defaultValue: false,
      );
}

/// Context include dependencies flag
class ContextIncludeDependenciesFlag extends CliFlag {
  const ContextIncludeDependenciesFlag() : super(
        name: 'include-dependencies',
        description: 'Include dependency analysis in context export',
        isGlobal: false,
        category: CliFlagCategory.output,
        type: FlagType.boolean,
        isNegatable: false,
        defaultValue: false,
      );
}

/// Context include architecture flag
class ContextIncludeArchitectureFlag extends CliFlag {
  const ContextIncludeArchitectureFlag() : super(
        name: 'include-architecture',
        description: 'Include architecture analysis in context export',
        isGlobal: false,
        category: CliFlagCategory.output,
        type: FlagType.boolean,
        isNegatable: false,
        defaultValue: true,
      );
}

/// Context include suggestions flag
class ContextIncludeSuggestionsFlag extends CliFlag {
  const ContextIncludeSuggestionsFlag() : super(
        name: 'include-suggestions',
        description: 'Include AI suggestions in context export',
        isGlobal: false,
        category: CliFlagCategory.output,
        type: FlagType.boolean,
        isNegatable: false,
        defaultValue: true,
      );
}

/// Context max files flag
class ContextMaxFilesFlag extends CliFlag {
  const ContextMaxFilesFlag() : super(
        name: 'max-files',
        description: 'Maximum number of files to analyze',
        isGlobal: false,
        category: CliFlagCategory.output,
        type: FlagType.singleValue,
        defaultValue: '50',
      );
}

/// Context max file size flag
class ContextMaxFileSizeFlag extends CliFlag {
  const ContextMaxFileSizeFlag() : super(
        name: 'max-file-size',
        description: 'Maximum file size to include (in bytes)',
        isGlobal: false,
        category: CliFlagCategory.output,
        type: FlagType.singleValue,
        defaultValue: '10000',
      );
}
