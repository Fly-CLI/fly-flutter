import 'dart:convert';

import 'package:fly_cli/src/core/cli/output_format.dart';
import 'package:fly_cli/src/core/cli/formatting/error_formatter.dart';
import 'package:fly_cli/src/core/cli/formatting/version_formatter.dart';
import 'package:fly_cli/src/core/cli/interfaces/i_output_formatter.dart';
import 'package:fly_cli/src/core/command/foundation/domain/command_result.dart';

/// Unified output formatter for all output types
///
/// This class provides a single point for formatting all CLI output,
/// supporting multiple output formats (human, JSON, AI).
class OutputFormatter implements IOutputFormatter {
  /// Create an output formatter
  ///
  /// [debugMode] - Whether debug mode is enabled (default: false)
  OutputFormatter({this.debugMode = false});

  final bool debugMode;

  @override
  String formatResult(CommandResult result, OutputFormat format) {
    switch (format) {
      case OutputFormat.json:
        return json.encode(result.toJson());

      case OutputFormat.ai:
        return json.encode(result.toAiJson());

      case OutputFormat.human:
        if (debugMode) {
          return 'DEBUG: ${json.encode(result.toJson())}';
        }
        result.displayHuman();
        return ''; // displayHuman() prints directly, so return empty

      default:
        result.displayHuman();
        return '';
    }
  }

  @override
  String formatError(CommandResult result, OutputFormat format) {
    return ErrorFormatter.format(result, format, verbose: debugMode);
  }

  @override
  String formatVersion(Map<String, dynamic> versionInfo, OutputFormat format) {
    return VersionFormatter.format(versionInfo, format);
  }
}
