part of '../cli_flags.dart';

// ============================================================================
// POSIX/GNU Standard Flags
// ============================================================================

/// POSIX standard help flag (-h, --help)
class GlobalHelpFlag extends CliFlag {
  const GlobalHelpFlag() : super(
        name: 'help',
        abbreviation: 'h', // POSIX standard
        description: 'Display help information',
        isGlobal: true,
        category: CliFlagCategory.helpVersion,
        type: FlagType.boolean,
        isNegatable: false,
      );
}

/// Standard version flag (--version)
/// Note: No -v abbreviation to avoid conflict with --verbose
class GlobalVersionFlag extends CliFlag {
  const GlobalVersionFlag() : super(
        name: 'version',
        description: 'Show version information',
        isGlobal: true,
        category: CliFlagCategory.helpVersion,
        type: FlagType.boolean,
        isNegatable: false,
      );
}

// ============================================================================
// Verbosity Flags (Industry Standards)
// ============================================================================

/// Standard verbose flag (-v, --verbose)
class GlobalVerboseFlag extends CliFlag {
  const GlobalVerboseFlag() : super(
        name: 'verbose',
        abbreviation: 'v', // Industry standard
        description: 'Enable verbose output',
        isGlobal: true,
        category: CliFlagCategory.verbosity,
        type: FlagType.boolean,
        isNegatable: false,
      );
}

/// Standard quiet flag (-q, --quiet)
class GlobalQuietFlag extends CliFlag {
  const GlobalQuietFlag() : super(
        name: 'quiet',
        abbreviation: 'q', // Industry standard
        description: 'Suppress output',
        isGlobal: true,
        category: CliFlagCategory.verbosity,
        type: FlagType.boolean,
        isNegatable: false,
      );
}

/// Standard debug flag (-d, --debug)
class GlobalDebugFlag extends CliFlag {
  const GlobalDebugFlag() : super(
        name: 'debug',
        abbreviation: 'd', // Industry standard
        description: 'Enable debug mode with verbose error output',
        isGlobal: true,
        category: CliFlagCategory.verbosity,
        type: FlagType.boolean,
        isNegatable: false,
      );
}

/// Trace flag for extra diagnostic tracing
class GlobalTraceFlag extends CliFlag {
  const GlobalTraceFlag() : super(
        name: 'trace',
        description: 'Enable extra diagnostic tracing in logs',
        isGlobal: true,
        category: CliFlagCategory.verbosity,
        type: FlagType.boolean,
        isNegatable: false,
      );
}

// ============================================================================
// Output Flags
// ============================================================================

/// Output format flag (-f, --format)
class GlobalFormatFlag extends CliFlag {
  GlobalFormatFlag() : super(
        name: 'format',
        abbreviation: 'f',
        description: 'Output format (human, json, or ai)',
        isGlobal: true,
        category: CliFlagCategory.output,
        type: FlagType.singleValue,
        allowedValues: const ['human', 'json', 'ai'],
        defaultValue: 'human',
      );
}

// ============================================================================
// Execution Flags
// ============================================================================

/// Plan mode flag (dry-run)
class GlobalPlanFlag extends CliFlag {
  const GlobalPlanFlag() : super(
        name: 'plan',
        description: 'Run in plan mode (dry-run)',
        isGlobal: true,
        category: CliFlagCategory.execution,
        type: FlagType.boolean,
        isNegatable: false,
      );
}

// ============================================================================
// Logging Flags
// ============================================================================

/// Log level flag
class GlobalLogLevelFlag extends CliFlag {
  GlobalLogLevelFlag() : super(
        name: 'log-level',
        description: 'Logging level (trace, debug, info, warn, error, fatal)',
        isGlobal: true,
        category: CliFlagCategory.logging,
        type: FlagType.singleValue,
        allowedValues: const ['trace', 'debug', 'info', 'warn', 'error', 'fatal'],
      );
}

/// Log format flag
class GlobalLogFormatFlag extends CliFlag {
  GlobalLogFormatFlag() : super(
        name: 'log-format',
        description: 'Logging format (human or json)',
        isGlobal: true,
        category: CliFlagCategory.logging,
        type: FlagType.singleValue,
        allowedValues: const ['human', 'json'],
      );
}

/// Log file flag
class GlobalLogFileFlag extends CliFlag {
  const GlobalLogFileFlag() : super(
        name: 'log-file',
        description: 'Write logs to file (in addition to console)',
        isGlobal: true,
        category: CliFlagCategory.logging,
        type: FlagType.singleValue,
      );
}

// ============================================================================
// UI Flags (following --no- pattern)
// ============================================================================

/// No color flag (--no-color)
class GlobalNoColorFlag extends CliFlag {
  const GlobalNoColorFlag() : super(
        name: 'no-color',
        description: 'Disable color output for human logs',
        isGlobal: true,
        category: CliFlagCategory.ui,
        type: FlagType.boolean,
        isNegatable: false,
      );
}
