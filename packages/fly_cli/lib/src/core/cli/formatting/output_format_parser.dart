import 'package:args/args.dart';
import 'package:fly_cli/src/core/cli/output_format.dart';
import 'package:fly_cli/src/core/command/foundation/flags/cli_flags.dart';
import 'package:fly_cli/src/core/command/foundation/flags/flag_accessor.dart';

/// Utility class for parsing output format from various sources
///
/// Provides centralized parsing logic for output format to ensure consistency
/// across the codebase.
class OutputFormatParser {
  /// Parse output format from ArgResults
  ///
  /// Extracts the format from the parsed arguments using the GlobalFormatFlag.
  /// Returns the default format (human) if not specified.
  ///
  /// [args] - Parsed command arguments
  static OutputFormat parseFromArgResults(ArgResults? args) {
    if (args == null) {
      return getDefault();
    }

    final formatString = FlagAccessor.getString(args, GlobalFormatFlag());
    return OutputFormat.parse(formatString);
  }

  /// Parse output format from raw command line arguments
  ///
  /// Useful for error handling when ArgResults might not be available.
  /// Looks for --format=value or -f value patterns in the arguments.
  ///
  /// [args] - Raw command line arguments
  static OutputFormat parseFromArgs(Iterable<String> args) {
    final argsList = args.toList();

    // Check for --format=value pattern
    for (final arg in argsList) {
      if (arg.startsWith('--format=')) {
        final value = arg.substring('--format='.length);
        return OutputFormat.parse(value);
      }
    }

    // Check for -f value pattern
    final index = argsList.indexOf('-f');
    if (index >= 0 && index < argsList.length - 1) {
      return OutputFormat.parse(argsList[index + 1]);
    }

    // Check for --format value pattern
    final formatIndex = argsList.indexOf('--format');
    if (formatIndex >= 0 && formatIndex < argsList.length - 1) {
      return OutputFormat.parse(argsList[formatIndex + 1]);
    }

    return getDefault();
  }

  /// Get the default output format
  ///
  /// Returns [OutputFormat.human] as the default format.
  static OutputFormat getDefault() {
    return OutputFormat.human;
  }
}
