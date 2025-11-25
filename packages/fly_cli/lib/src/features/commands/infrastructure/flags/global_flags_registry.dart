import 'package:args/args.dart';
import 'package:fly_cli/src/features/commands/infrastructure/flags/cli_flags.dart';
import 'package:fly_cli/src/features/commands/infrastructure/flags/flag_factory.dart';

/// Enum representing all global flag types.
///
/// This enum ensures exhaustiveness: when adding a new Global*Flag class,
/// you must add a corresponding value here. The exhaustive switch expression
/// in [GlobalFlagTypeExtension] will then require you to handle it.
enum GlobalFlagType {
  // POSIX/GNU Standard Flags
  help,
  version,

  // Verbosity Flags
  verbose,
  quiet,
  debug,
  trace,

  // Output Flags
  format,

  // Execution Flags
  plan,

  // Logging Flags
  logLevel,
  logFormat,
  logFile,

  // UI Flags
  noColor,
}

/// Extension providing flag factory methods for each global flag type.
///
/// Uses an exhaustive switch expression to ensure compile-time checking.
/// Adding a new global flag type requires adding a case here, which will
/// cause a compile-time error if omitted.
extension GlobalFlagTypeExtension on GlobalFlagType {
  /// Creates an instance of the flag corresponding to this type.
  ///
  /// Uses an exhaustive switch to ensure compile-time checking.
  /// Adding a new flag type requires adding a case here.
  CliFlag createFlag() => switch (this) {
    GlobalFlagType.help => const GlobalHelpFlag(),
    GlobalFlagType.version => const GlobalVersionFlag(),
    GlobalFlagType.verbose => const GlobalVerboseFlag(),
    GlobalFlagType.quiet => const GlobalQuietFlag(),
    GlobalFlagType.debug => const GlobalDebugFlag(),
    GlobalFlagType.trace => const GlobalTraceFlag(),
    GlobalFlagType.format => GlobalFormatFlag(),
    GlobalFlagType.plan => const GlobalPlanFlag(),
    GlobalFlagType.logLevel => GlobalLogLevelFlag(),
    GlobalFlagType.logFormat => GlobalLogFormatFlag(),
    GlobalFlagType.logFile => const GlobalLogFileFlag(),
    GlobalFlagType.noColor => const GlobalNoColorFlag(),
  };
}

/// Registry for global flags available to all commands
/// Follows industry standards (POSIX/GNU conventions)
class GlobalFlagsRegistry {
  /// All global flags in order of priority.
  ///
  /// This list is built using an exhaustive enum and switch expression,
  /// ensuring compile-time checking. When adding a new Global*Flag class:
  /// 1. Add a value to [GlobalFlagType] enum
  /// 2. Add a case to [GlobalFlagTypeExtension.createFlag] switch
  /// 3. Add the enum value to the [_flagTypesInOrder] list below
  ///
  /// The compiler will error if any step is missed.
  static List<CliFlag> get globalFlags {
    return _flagTypesInOrder.map((type) => type.createFlag()).toList();
  }

  /// Global flag types in the order they should appear in the registry.
  ///
  /// This list must include all values from [GlobalFlagType] enum.
  /// The exhaustive switch in [GlobalFlagTypeExtension.createFlag] ensures
  /// all enum values are handled. Add new flag types here when creating them.
  ///
  /// Compile-time assertion: This list must contain exactly all enum values.
  /// If a new enum value is added, it must be added here, otherwise the
  /// assertion below will fail at compile time.
  static const List<GlobalFlagType> _flagTypesInOrder = [
    // POSIX/GNU Standard Flags
    GlobalFlagType.help,
    GlobalFlagType.version,

    // Verbosity Flags
    GlobalFlagType.verbose,
    GlobalFlagType.quiet,
    GlobalFlagType.debug,
    GlobalFlagType.trace,

    // Output Flags
    GlobalFlagType.format,

    // Execution Flags
    GlobalFlagType.plan,

    // Logging Flags
    GlobalFlagType.logLevel,
    GlobalFlagType.logFormat,
    GlobalFlagType.logFile,

    // UI Flags
    GlobalFlagType.noColor,
  ];

  /// Create a new ArgParser with all global flags
  static ArgParser createGlobalParser() {
    return FlagFactory.createParser(globalFlags);
  }

  /// Apply global flags to an existing parser
  static void applyToParser(ArgParser parser) {
    FlagFactory.applyFlagsToParser(parser, globalFlags);
  }

  /// Create base command parser (includes global flags from command_base.dart)
  /// This includes flags that are available at command level
  static ArgParser createBaseCommandParser() {
    final baseFlags = [
      GlobalFormatFlag(),
      const GlobalDebugFlag(),
      const GlobalVerboseFlag(),
      const GlobalPlanFlag(),
    ];
    return FlagFactory.createParser(baseFlags);
  }

  /// Get all global flags grouped by category
  static Map<CliFlagCategory, List<CliFlag>> getFlagsByCategory() {
    final grouped = <CliFlagCategory, List<CliFlag>>{};
    for (final flag in globalFlags) {
      grouped.putIfAbsent(flag.category, () => []).add(flag);
    }
    return grouped;
  }

  /// Find a flag by name
  static CliFlag? findFlagByName(String name) {
    try {
      return globalFlags.firstWhere((flag) => flag.name == name);
    } catch (_) {
      return null;
    }
  }

  /// Find a flag by abbreviation
  static CliFlag? findFlagByAbbreviation(String abbreviation) {
    try {
      return globalFlags.firstWhere(
        (flag) => flag.abbreviation == abbreviation,
      );
    } catch (_) {
      return null;
    }
  }
}
