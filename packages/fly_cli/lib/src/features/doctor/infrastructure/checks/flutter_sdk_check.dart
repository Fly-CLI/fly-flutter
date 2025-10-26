import 'dart:io';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

import '../../domain/system_checker.dart';

/// Check for Flutter SDK installation and configuration
class FlutterSdkCheck extends SystemCheck {
  FlutterSdkCheck({this.logger});
  
  final Logger? logger;

  @override
  String get name => 'Flutter SDK';

  @override
  String get category => 'Development Environment';

  @override
  String get description => 'Check Flutter SDK installation and version compatibility';

  @override
  Future<CheckResult> run() async {
    try {
      // Check if flutter command is available
      final flutterResult = await Process.run('flutter', ['--version'], runInShell: true);
      
      if (flutterResult.exitCode != 0) {
        return CheckResult.error(
          message: 'Flutter SDK not found in PATH',
          suggestion: 'Install Flutter SDK and add it to your PATH environment variable',
          fixCommand: 'Visit https://flutter.dev/docs/get-started/install for installation instructions',
          data: {
            'exitCode': flutterResult.exitCode,
            'stderr': flutterResult.stderr,
          },
        );
      }

      // Parse Flutter version
      final versionOutput = flutterResult.stdout as String;
      final versionMatch = RegExp(r'Flutter (\d+\.\d+\.\d+)').firstMatch(versionOutput);
      
      if (versionMatch == null) {
        return CheckResult.warning(
          message: 'Could not parse Flutter version',
          suggestion: 'Ensure Flutter is properly installed',
          data: {'versionOutput': versionOutput},
        );
      }

      final flutterVersion = versionMatch.group(1)!;
      final versionParts = flutterVersion.split('.').map(int.parse).toList();
      
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
          message: 'Flutter version $flutterVersion is too old (minimum: 3.0.0)',
          suggestion: 'Update Flutter to version 3.0.0 or later',
          fixCommand: 'flutter upgrade',
          data: {
            'currentVersion': flutterVersion,
            'minVersion': '3.0.0',
          },
        );
      }

      // Check Flutter doctor
      final doctorResult = await Process.run('flutter', ['doctor'], runInShell: true);
      final doctorOutput = doctorResult.stdout as String;
      
      // Look for critical issues
      final criticalIssues = <String>[];
      if (doctorOutput.contains('No devices available')) {
        criticalIssues.add('No devices available');
      }
      if (doctorOutput.contains('Android toolchain')) {
        criticalIssues.add('Android toolchain issues');
      }
      if (doctorOutput.contains('Xcode')) {
        criticalIssues.add('Xcode issues');
      }

      if (criticalIssues.isNotEmpty) {
        return CheckResult.warning(
          message: 'Flutter SDK installed but has configuration issues',
          suggestion: 'Run "flutter doctor" to see detailed issues and suggested fixes',
          fixCommand: 'flutter doctor',
          data: {
            'version': flutterVersion,
            'issues': criticalIssues,
            'doctorOutput': doctorOutput,
          },
        );
      }

      return CheckResult.success(
        message: 'Flutter SDK $flutterVersion is installed and compatible',
        data: {
          'version': flutterVersion,
          'path': _getFlutterPath(),
        },
      );

    } catch (e) {
      return CheckResult.error(
        message: 'Failed to check Flutter SDK: $e',
        suggestion: 'Ensure Flutter is properly installed and accessible',
        data: {'error': e.toString()},
      );
    }
  }

  /// Get the Flutter SDK path
  String? _getFlutterPath() {
    try {
      final whichResult = Process.runSync('which', ['flutter'], runInShell: true);
      if (whichResult.exitCode == 0) {
        return whichResult.stdout.toString().trim();
      }
    } catch (e) {
      // Ignore errors
    }
    return null;
  }
}
