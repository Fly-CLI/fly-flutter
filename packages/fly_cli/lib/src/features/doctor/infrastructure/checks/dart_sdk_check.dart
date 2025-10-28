import 'dart:io';
import 'package:mason_logger/mason_logger.dart';

import 'package:fly_cli/src/core/diagnostics/system_checker.dart';

/// Check for Dart SDK installation and configuration
class DartSdkCheck extends SystemCheck {
  DartSdkCheck({this.logger});
  
  final Logger? logger;

  @override
  String get name => 'Dart SDK';

  @override
  String get category => 'Development Environment';

  @override
  String get description => 'Check Dart SDK installation and version compatibility';

  @override
  Future<CheckResult> run() async {
    try {
      // Check if dart command is available
      final dartResult = await Process.run('dart', ['--version'], runInShell: true);
      
      if (dartResult.exitCode != 0) {
        return CheckResult.error(
          message: 'Dart SDK not found in PATH',
          suggestion: 'Dart SDK is usually included with Flutter SDK. Ensure Flutter is properly installed.',
          fixCommand: 'Install Flutter SDK which includes Dart SDK',
          data: {
            'exitCode': dartResult.exitCode,
            'stderr': dartResult.stderr,
          },
        );
      }

      // Parse Dart version
      final versionOutput = dartResult.stdout as String;
      final versionMatch = RegExp(r'Dart SDK version: (\d+\.\d+\.\d+)').firstMatch(versionOutput);
      
      if (versionMatch == null) {
        return CheckResult.warning(
          message: 'Could not parse Dart version',
          suggestion: 'Ensure Dart SDK is properly installed',
          data: {'versionOutput': versionOutput},
        );
      }

      final dartVersion = versionMatch.group(1)!;
      final versionParts = dartVersion.split('.').map(int.parse).toList();
      
      // Check minimum version (3.0.0)
      final minVersion = [3, 0, 0];
      var isCompatible = true;
      
      for (var i = 0; i < minVersion.length; i++) {
        if (versionParts[i] < minVersion[i]) {
          isCompatible = false;
          break;
        } else if (versionParts[i] > minVersion[i]) {
          break;
        }
      }

      if (!isCompatible) {
        return CheckResult.error(
          message: 'Dart version $dartVersion is too old (minimum: 3.0.0)',
          suggestion: 'Update Dart SDK to version 3.0.0 or later',
          fixCommand: 'Update Flutter SDK which includes Dart SDK',
          data: {
            'currentVersion': dartVersion,
            'minVersion': '3.0.0',
          },
        );
      }

      // Check Dart analyzer
      final analyzeResult = await Process.run('dart', ['analyze', '--version'], runInShell: true);
      
      if (analyzeResult.exitCode != 0) {
        return CheckResult.warning(
          message: 'Dart analyzer not working properly',
          suggestion: 'Check Dart SDK installation',
          data: {
            'exitCode': analyzeResult.exitCode,
            'stderr': analyzeResult.stderr,
          },
        );
      }

      return CheckResult.success(
        message: 'Dart SDK $dartVersion is installed and compatible',
        data: {
          'version': dartVersion,
          'path': _getDartPath(),
        },
      );

    } catch (e) {
      return CheckResult.error(
        message: 'Failed to check Dart SDK: $e',
        suggestion: 'Ensure Dart SDK is properly installed and accessible',
        data: {'error': e.toString()},
      );
    }
  }

  /// Get the Dart SDK path
  String? _getDartPath() {
    try {
      final whichResult = Process.runSync('which', ['dart'], runInShell: true);
      if (whichResult.exitCode == 0) {
        return whichResult.stdout.toString().trim();
      }
    } catch (e) {
      // Ignore errors
    }
    return null;
  }
}
