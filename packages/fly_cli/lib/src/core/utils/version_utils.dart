import 'dart:io';

import 'package:fly_core/src/environment/environment_manager.dart';
import 'package:fly_core/src/environment/env_var.dart';
import 'package:path/path.dart' as path;
import 'package:pubspec_parse/pubspec_parse.dart';

/// Model representing CLI version information
class VersionInfo {
  const VersionInfo({
    required this.version,
    this.buildNumber,
    this.gitCommit,
    required this.buildDate,
  });

  /// Current CLI version
  final String version;

  /// Build number (if available)
  final String? buildNumber;

  /// CLI git commit hash (if available)
  final String? gitCommit;

  /// Build date
  final String buildDate;

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'build_number': buildNumber,
      'git_commit': gitCommit,
      'build_date': buildDate,
    };
  }

  /// Create from JSON map
  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    return VersionInfo(
      version: json['version'] as String,
      buildNumber: json['build_number'] as String?,
      gitCommit: json['git_commit'] as String?,
      buildDate: json['build_date'] as String,
    );
  }

  @override
  String toString() {
    return 'VersionInfo(version: $version, buildNumber: $buildNumber, gitCommit: $gitCommit, buildDate: $buildDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VersionInfo &&
        other.version == version &&
        other.buildNumber == buildNumber &&
        other.gitCommit == gitCommit &&
        other.buildDate == buildDate;
  }

  @override
  int get hashCode {
    return Object.hash(version, buildNumber, gitCommit, buildDate);
  }
}

/// Utility for getting CLI version information
class VersionUtils {
  VersionUtils._();

  static String? _cachedVersion;
  static String? _cachedBuildNumber;

  /// Get the current CLI version from pubspec.yaml
  static String getCurrentVersion() {
    if (_cachedVersion != null) {
      return _cachedVersion!;
    }

    try {
      // Try to read from the CLI package's pubspec.yaml
      final pubspecPath = _findPubspecPath();
      if (pubspecPath != null) {
        final pubspecFile = File(pubspecPath);
        if (pubspecFile.existsSync()) {
          final content = pubspecFile.readAsStringSync();
          final pubspec = Pubspec.parse(content);
          _cachedVersion = pubspec.version.toString();
          return _cachedVersion!;
        }
      }
    } catch (e) {
      // Fallback to default version
    }

    // Fallback version if we can't read pubspec.yaml
    _cachedVersion = '0.1.0';
    return _cachedVersion!;
  }

  /// Get build number (if available)
  static String? getBuildNumber() {
    if (_cachedBuildNumber != null) {
      return _cachedBuildNumber;
    }

    // Try to get from environment variable (set during build)
    _cachedBuildNumber = const EnvironmentManager().getString(EnvVar.buildNumber);
    return _cachedBuildNumber;
  }

  /// Get git commit hash for the CLI (if available)
  static String? getGitCommit() {
    try {
      // Find the CLI package directory
      final cliDir = _findCliDirectory();
      if (cliDir != null) {
        final result = Process.runSync(
          'git', 
          ['rev-parse', '--short', 'HEAD'],
          workingDirectory: cliDir,
        );
        if (result.exitCode == 0) {
          return (result.stdout as String).trim();
        }
      }
    } catch (e) {
      // Git not available or not in a git repository
    }
    return null;
  }

  /// Get build date
  static String getBuildDate() {
    // Try to get from environment variable (set during build)
    final buildDate = const EnvironmentManager().getString(EnvVar.buildDate);
    if (buildDate != null) {
      return buildDate;
    }
    
    // Fallback to current time
    return DateTime.now().toIso8601String();
  }

  /// Find the CLI package directory
  static String? _findCliDirectory() {
    // Try multiple possible locations for the CLI package directory
    final possiblePaths = [
      // Current working directory (if it's the CLI root)
      Directory.current.path,
      // Relative to current script
      path.join(path.dirname(Platform.script.toFilePath()), '..', '..'),
      // Relative to executable
      path.join(path.dirname(Platform.resolvedExecutable), '..', '..', 'packages', 'fly_cli'),
      // Development path
      path.join(Directory.current.path, 'packages', 'fly_cli'),
    ];

    for (final cliPath in possiblePaths) {
      final dir = Directory(cliPath);
      if (dir.existsSync()) {
        try {
          // Check if this directory contains the fly_cli pubspec.yaml
          final pubspecFile = File(path.join(cliPath, 'pubspec.yaml'));
          if (pubspecFile.existsSync()) {
            final content = pubspecFile.readAsStringSync();
            final pubspec = Pubspec.parse(content);
            if (pubspec.name == 'fly_cli') {
              return cliPath;
            }
          }
          
          // Also check parent directories for the Fly repository root
          final parentDir = Directory(path.dirname(cliPath));
          if (parentDir.existsSync()) {
            final parentPubspecFile = File(path.join(parentDir.path, 'pubspec.yaml'));
            if (parentPubspecFile.existsSync()) {
              final content = parentPubspecFile.readAsStringSync();
              final pubspec = Pubspec.parse(content);
              if (pubspec.name == 'fly_cli') {
                return parentDir.path;
              }
            }
          }
        } catch (e) {
          // Continue to next path
        }
      }
    }

    return null;
  }

  /// Find the pubspec.yaml file for the CLI package
  static String? _findPubspecPath() {
    // Try multiple possible locations for the CLI package's pubspec.yaml
    final possiblePaths = [
      // Current working directory
      'pubspec.yaml',
      // Relative to current script
      path.join(path.dirname(Platform.script.toFilePath()), '..', '..', 'pubspec.yaml'),
      // Relative to executable
      path.join(path.dirname(Platform.resolvedExecutable), '..', '..', 'packages', 'fly_cli', 'pubspec.yaml'),
      // Development path
      path.join(Directory.current.path, 'packages', 'fly_cli', 'pubspec.yaml'),
    ];

    for (final pubspecPath in possiblePaths) {
      final file = File(pubspecPath);
      if (file.existsSync()) {
        try {
          // Verify this is the fly_cli pubspec.yaml
          final content = file.readAsStringSync();
          final pubspec = Pubspec.parse(content);
          if (pubspec.name == 'fly_cli') {
            return pubspecPath;
          }
        } catch (e) {
          // Continue to next path
        }
      }
    }

    return null;
  }

  /// Get complete version information
  static VersionInfo getVersionInfo() {
    return VersionInfo(
      version: getCurrentVersion(),
      buildNumber: getBuildNumber(),
      gitCommit: getGitCommit(),
      buildDate: getBuildDate(),
    );
  }
}
