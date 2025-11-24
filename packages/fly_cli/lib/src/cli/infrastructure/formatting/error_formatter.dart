import 'dart:convert';

import 'package:fly_cli/src/cli/domain/output_format.dart';
import 'package:fly_cli/src/features/commands/domain/command_result.dart';

/// Formats error output in different formats
class ErrorFormatter {
  /// Format an error result
  ///
  /// Formats the error result according to the specified output format.
  ///
  /// [result] - The error result to format
  /// [format] - The output format to use
  /// [verbose] - Whether to include verbose information (default: false)
  /// Returns the formatted output string
  static String format(
    CommandResult result,
    OutputFormat format, {
    bool verbose = false,
  }) {
    switch (format) {
      case OutputFormat.json:
        return json.encode(result.toJson());

      case OutputFormat.ai:
        return json.encode(result.toAiJson());

      case OutputFormat.human:
        return _formatHuman(result, verbose: verbose);
    }
  }

  /// Format error in human-readable format
  static String _formatHuman(CommandResult result, {bool verbose = false}) {
    final buffer = StringBuffer();

    buffer.writeln('❌ ${result.message}');

    if (result.errorCode != null) {
      buffer.writeln('Error Code: ${result.errorCode!.code}');
    }

    if (result.suggestion != null) {
      buffer
        ..writeln()
        ..writeln('💡 Suggestion: ${result.suggestion}');
    }

    if (result.errorContext != null && result.errorContext!.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Context:');
      for (final entry in result.errorContext!.entries) {
        buffer.writeln('  ${entry.key}: ${entry.value}');
      }
    }

    if (verbose && result.metadata != null && result.metadata!.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Metadata:');
      for (final entry in result.metadata!.entries) {
        buffer.writeln('  ${entry.key}: ${entry.value}');
      }
    }

    return buffer.toString();
  }
}
