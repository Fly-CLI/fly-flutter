import 'dart:convert';

import 'package:fly_cli/src/cli/domain/output_format.dart';
import 'package:fly_cli/src/features/commands/domain/command_result.dart';

/// Formats version information in different formats
class VersionFormatter {
  /// Format version information
  ///
  /// Formats the version information according to the specified output format.
  ///
  /// [versionInfo] - The version information map
  /// [format] - The output format to use
  /// Returns the formatted output string
  static String format(Map<String, dynamic> versionInfo, OutputFormat format) {
    // Create a command result for version info
    final result = CommandResult.success(
      command: 'version',
      message: 'Version information retrieved',
      data: versionInfo,
      metadata: {
        'cli_version': versionInfo['version'] ?? 'unknown',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    switch (format) {
      case OutputFormat.json:
        return json.encode(result.toJson());

      case OutputFormat.ai:
        return json.encode(result.toAiJson());

      case OutputFormat.human:
        return _formatHuman(versionInfo);
    }
  }

  /// Format version in human-readable format
  static String _formatHuman(Map<String, dynamic> versionInfo) {
    final buffer = StringBuffer();

    buffer.writeln('Fly CLI Version Information');
    buffer.writeln('─' * 40);

    if (versionInfo.containsKey('version')) {
      buffer.writeln('Version: ${versionInfo['version']}');
    }

    if (versionInfo.containsKey('build_number')) {
      buffer.writeln('Build: ${versionInfo['build_number']}');
    }

    if (versionInfo.containsKey('git_commit')) {
      buffer.writeln('Git Commit: ${versionInfo['git_commit']}');
    }

    if (versionInfo.containsKey('git_branch')) {
      buffer.writeln('Git Branch: ${versionInfo['git_branch']}');
    }

    if (versionInfo.containsKey('dart_version')) {
      buffer.writeln('Dart: ${versionInfo['dart_version']}');
    }

    if (versionInfo.containsKey('flutter_version')) {
      buffer.writeln('Flutter: ${versionInfo['flutter_version']}');
    }

    if (versionInfo.containsKey('environment')) {
      buffer.writeln('Environment: ${versionInfo['environment']}');
    }

    buffer.writeln('─' * 40);

    return buffer.toString();
  }
}
