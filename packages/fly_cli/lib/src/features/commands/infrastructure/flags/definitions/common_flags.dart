part of '../cli_flags.dart';

// ============================================================================
// Common Command Flags
// ============================================================================

/// Output file flag (-o, --output-file)
/// Industry standard: -o reserved for output files
class OutputFileFlag extends CliFlag {
  const OutputFileFlag()
    : super(
        name: 'output-file',
        abbreviation: 'o',
        // Industry standard
        description: 'Output file path (default: stdout)',
        isGlobal: false,
        category: CliFlagCategory.output,
        type: FlagType.singleValue,
      );
}

/// Output directory flag (--output-dir)
class OutputDirFlag extends CliFlag {
  const OutputDirFlag()
    : super(
        name: 'output-dir',
        description:
            'Output directory for generated files (defaults to current directory)',
        isGlobal: false,
        category: CliFlagCategory.output,
        type: FlagType.singleValue,
      );
}

/// Input file flag (--input-file)
class InputFileFlag extends CliFlag {
  const InputFileFlag()
    : super(
        name: 'input-file',
        description: 'Path to an input file',
        isGlobal: false,
        category: CliFlagCategory.inputOutput,
        type: FlagType.singleValue,
      );
}

/// Input directory flag (--input-dir)
class InputDirFlag extends CliFlag {
  const InputDirFlag()
    : super(
        name: 'input-dir',
        description: 'Path to an input directory',
        isGlobal: false,
        category: CliFlagCategory.inputOutput,
        type: FlagType.singleValue,
      );
}

/// Interactive mode flag (-i, --interactive)
class InteractiveFlag extends CliFlag {
  const InteractiveFlag()
    : super(
        name: 'interactive',
        abbreviation: 'i',
        description: 'Run in interactive mode',
        isGlobal: false,
        category: CliFlagCategory.ui,
        type: FlagType.boolean,
        isNegatable: false,
      );
}
