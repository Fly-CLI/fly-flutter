import 'dart:io';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

import 'package:fly_cli/src/core/diagnostics/system_checker.dart';

/// Check for platform-specific development tools
class PlatformToolsCheck extends SystemCheck {
  PlatformToolsCheck({this.logger});
  
  final Logger? logger;

  @override
  String get name => 'Platform Tools';

  @override
  String get category => 'Development Environment';

  @override
  String get description => 'Check platform-specific development tools (Android SDK, Xcode, etc.)';

  @override
  Future<CheckResult> run() async {
    final issues = <String>[];
    final suggestions = <String>[];
    final data = <String, dynamic>{};

    // Check Android SDK
    final androidResult = await _checkAndroidSdk();
    if (!androidResult.healthy) {
      issues.add('Android SDK: ${androidResult.message}');
      if (androidResult.suggestion != null) {
        suggestions.add(androidResult.suggestion!);
      }
      data['android'] = androidResult.data;
    } else {
      data['android'] = androidResult.data;
    }

    // Check Xcode (macOS only)
    if (Platform.isMacOS) {
      final xcodeResult = await _checkXcode();
      if (!xcodeResult.healthy) {
        issues.add('Xcode: ${xcodeResult.message}');
        if (xcodeResult.suggestion != null) {
          suggestions.add(xcodeResult.suggestion!);
        }
        data['xcode'] = xcodeResult.data;
      } else {
        data['xcode'] = xcodeResult.data;
      }
    }

    // Check Visual Studio (Windows only)
    if (Platform.isWindows) {
      final vsResult = await _checkVisualStudio();
      if (!vsResult.healthy) {
        issues.add('Visual Studio: ${vsResult.message}');
        if (vsResult.suggestion != null) {
          suggestions.add(vsResult.suggestion!);
        }
        data['visualStudio'] = vsResult.data;
      } else {
        data['visualStudio'] = vsResult.data;
      }
    }

    if (issues.isEmpty) {
      return CheckResult.success(
        message: 'Platform tools are properly configured',
        data: data,
      );
    } else if (issues.length == 1) {
      return CheckResult.warning(
        message: 'Platform tool issue: ${issues.first}',
        suggestion: suggestions.isNotEmpty ? suggestions.first : null,
        data: data,
      );
    } else {
      return CheckResult.warning(
        message: 'Multiple platform tool issues found',
        suggestion: suggestions.join('; '),
        data: data,
      );
    }
  }

  /// Check Android SDK installation
  Future<CheckResult> _checkAndroidSdk() async {
    try {
      // Check for ANDROID_HOME environment variable
      final androidHome = Platform.environment['ANDROID_HOME'] ?? 
                         Platform.environment['ANDROID_SDK_ROOT'];
      
      if (androidHome == null) {
        return CheckResult.error(
          message: 'ANDROID_HOME environment variable not set',
          suggestion: 'Set ANDROID_HOME to your Android SDK installation directory',
          fixCommand: 'export ANDROID_HOME=/path/to/android/sdk',
          data: {'missing': 'ANDROID_HOME'},
        );
      }

      final androidHomeDir = Directory(androidHome);
      if (!await androidHomeDir.exists()) {
        return CheckResult.error(
          message: 'Android SDK directory does not exist: $androidHome',
          suggestion: 'Install Android SDK and set ANDROID_HOME correctly',
          data: {'path': androidHome, 'exists': false},
        );
      }

      // Check for key Android SDK components
      final requiredPaths = [
        'platform-tools',
        'platforms',
        'build-tools',
      ];

      final missingPaths = <String>[];
      for (final requiredPath in requiredPaths) {
        final pathDir = Directory(path.join(androidHome, requiredPath));
        if (!await pathDir.exists()) {
          missingPaths.add(requiredPath);
        }
      }

      if (missingPaths.isNotEmpty) {
        return CheckResult.warning(
          message: 'Android SDK missing components: ${missingPaths.join(', ')}',
          suggestion: 'Install missing Android SDK components using Android Studio SDK Manager',
          data: {
            'path': androidHome,
            'missing': missingPaths,
          },
        );
      }

      // Check for adb
      final adbPath = path.join(androidHome, 'platform-tools', Platform.isWindows ? 'adb.exe' : 'adb');
      final adbFile = File(adbPath);
      if (!await adbFile.exists()) {
        return CheckResult.warning(
          message: 'ADB not found in Android SDK',
          suggestion: 'Install Android SDK platform-tools',
          data: {'path': androidHome, 'adbPath': adbPath},
        );
      }

      return CheckResult.success(
        message: 'Android SDK is properly configured',
        data: {
          'path': androidHome,
          'adbPath': adbPath,
        },
      );

    } catch (e) {
      return CheckResult.error(
        message: 'Failed to check Android SDK: $e',
        suggestion: 'Check Android SDK installation',
        data: {'error': e.toString()},
      );
    }
  }

  /// Check Xcode installation (macOS only)
  Future<CheckResult> _checkXcode() async {
    try {
      // Check if xcodebuild is available with timeout
      final xcodeResult = await Process.run(
        'xcodebuild', 
        ['-version'], 
        runInShell: true,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => ProcessResult(0, 1, '', 'xcodebuild timed out after 10 seconds'),
      );
      
      if (xcodeResult.exitCode != 0) {
        return CheckResult.error(
          message: 'Xcode not found or not properly installed',
          suggestion: 'Install Xcode from the Mac App Store',
          fixCommand: 'Install Xcode from Mac App Store',
          data: {
            'exitCode': xcodeResult.exitCode,
            'stderr': xcodeResult.stderr,
          },
        );
      }

      final versionOutput = xcodeResult.stdout as String;
      final versionMatch = RegExp(r'Xcode (\d+\.\d+)').firstMatch(versionOutput);
      
      if (versionMatch == null) {
        return CheckResult.warning(
          message: 'Could not parse Xcode version',
          suggestion: 'Ensure Xcode is properly installed',
          data: {'versionOutput': versionOutput},
        );
      }

      final xcodeVersion = versionMatch.group(1)!;
      
      // Check for iOS Simulator with timeout
      final simulatorResult = await Process.run(
        'xcrun', 
        ['simctl', 'list'], 
        runInShell: true,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => ProcessResult(0, 1, '', 'xcrun simctl list timed out after 10 seconds'),
      );
      if (simulatorResult.exitCode != 0) {
        return CheckResult.warning(
          message: 'iOS Simulator not available',
          suggestion: 'Install iOS Simulator through Xcode',
          data: {
            'xcodeVersion': xcodeVersion,
            'simulatorError': simulatorResult.stderr,
          },
        );
      }

      return CheckResult.success(
        message: 'Xcode $xcodeVersion is installed and configured',
        data: {
          'version': xcodeVersion,
          'simulatorAvailable': true,
        },
      );

    } catch (e) {
      return CheckResult.error(
        message: 'Failed to check Xcode: $e',
        suggestion: 'Ensure Xcode is properly installed',
        data: {'error': e.toString()},
      );
    }
  }

  /// Check Visual Studio installation (Windows only)
  Future<CheckResult> _checkVisualStudio() async {
    try {
      // Check for Visual Studio installation
      final commonPaths = [
        r'C:\Program Files\Microsoft Visual Studio',
        r'C:\Program Files (x86)\Microsoft Visual Studio',
      ];

      var found = false;
      String? vsPath;
      
      for (final commonPath in commonPaths) {
        final vsDir = Directory(commonPath);
        if (await vsDir.exists()) {
          found = true;
          vsPath = commonPath;
          break;
        }
      }

      if (!found) {
        return CheckResult.warning(
          message: 'Visual Studio not found in common installation paths',
          suggestion: 'Install Visual Studio with C++ development tools',
          fixCommand: 'Install Visual Studio Community with C++ workload',
          data: {'searchedPaths': commonPaths},
        );
      }

      // Check for MSBuild with timeout
      final msbuildResult = await Process.run(
        'msbuild', 
        ['-version'], 
        runInShell: true,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => ProcessResult(0, 1, '', 'msbuild timed out after 10 seconds'),
      );
      if (msbuildResult.exitCode != 0) {
        return CheckResult.warning(
          message: 'MSBuild not found in PATH',
          suggestion: 'Add Visual Studio MSBuild to PATH or install Visual Studio Build Tools',
          data: {
            'vsPath': vsPath,
            'msbuildError': msbuildResult.stderr,
          },
        );
      }

      return CheckResult.success(
        message: 'Visual Studio is installed and configured',
        data: {
          'path': vsPath,
          'msbuildAvailable': true,
        },
      );

    } catch (e) {
      return CheckResult.error(
        message: 'Failed to check Visual Studio: $e',
        suggestion: 'Ensure Visual Studio is properly installed',
        data: {'error': e.toString()},
      );
    }
  }
}
