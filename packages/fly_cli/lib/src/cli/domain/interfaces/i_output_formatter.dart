import 'package:fly_cli/src/cli/domain/output_format.dart';
import 'package:fly_cli/src/features/commands/domain/command_result.dart';

/// Interface for output formatter
///
/// This interface provides abstraction over the output formatting implementation,
/// allowing for easier testing and swapping of implementations.
abstract class IOutputFormatter {
  /// Format a command result
  ///
  /// [result] - The command result to format
  /// [format] - The output format to use
  /// Returns the formatted output as a string
  String formatResult(CommandResult result, OutputFormat format);

  /// Format an error result
  ///
  /// [result] - The error result to format
  /// [format] - The output format to use
  /// Returns the formatted output as a string
  String formatError(CommandResult result, OutputFormat format);

  /// Format version information
  ///
  /// [versionInfo] - The version information map
  /// [format] - The output format to use
  /// Returns the formatted output as a string
  String formatVersion(Map<String, dynamic> versionInfo, OutputFormat format);
}
