import 'dart:io';

import 'package:fly_core/src/environment/env_var.dart';
import 'package:fly_core/src/environment/environment_manager.dart';
import 'package:path/path.dart' as path;

/// Cross-platform utility functions for applications
class PlatformUtils {
  /// Platform detection
  static bool get isWindows => Platform.isWindows;

  static bool get isMacOS => Platform.isMacOS;

  static bool get isLinux => Platform.isLinux;

  /// Normalize path separators (always use forward slash internally)
  static String normalizePath(String filePath) =>
      filePath.replaceAll(r'\', '/');

  /// Make file executable (Unix only)
  static Future<void> makeExecutable(String filePath) async {
    if (isWindows) return;
    await Process.run('chmod', ['+x', filePath]);
  }

  /// Get appropriate line ending for platform
  static String get lineEnding => isWindows ? '\r\n' : '\n';

  /// Get user home directory
  static Future<String> getUserHome() async {
    if (isWindows) {
      return const EnvironmentManager().getString(EnvVar.userProfile) ?? '';
    } else {
      return const EnvironmentManager().getString(EnvVar.home) ?? '';
    }
  }

  /// Get config directory based on platform conventions
  ///
  /// [appName] - Application name (defaults to 'fly_cli' for backward compatibility)
  static Future<String> getConfigDirectory({String appName = 'fly_cli'}) async {
    final home = await getUserHome();
    if (isWindows) {
      return path.join(home, 'AppData', 'Local', appName);
    } else if (isMacOS) {
      return path.join(home, 'Library', 'Application Support', appName);
    } else {
      // Linux and other Unix-like systems
      return path.join(home, '.config', appName);
    }
  }

  /// Get cache directory
  ///
  /// [appName] - Application name (defaults to 'fly_cli' for backward compatibility)
  static Future<String> getCacheDirectory({String appName = 'fly_cli'}) async {
    final configDir = await getConfigDirectory(appName: appName);
    return path.join(configDir, 'cache');
  }

  /// Get default cache directory synchronously (for constructor)
  ///
  /// [appName] - Application name (defaults to 'fly_cli' for backward compatibility)
  static String getDefaultCacheDirectory({String appName = 'fly_cli'}) {
    const env = EnvironmentManager();
    final home =
        env.getString(EnvVar.home) ?? env.getString(EnvVar.userProfile) ?? '';
    if (isWindows) {
      return path.join(home, 'AppData', 'Local', appName, 'cache');
    } else if (isMacOS) {
      return path.join(
          home, 'Library', 'Application Support', appName, 'cache');
    } else {
      // Linux and other Unix-like systems
      return path.join(home, '.config', appName, 'cache');
    }
  }

  /// Get templates directory
  ///
  /// [appName] - Application name (defaults to 'fly_cli' for backward compatibility)
  static Future<String> getTemplatesDirectory({String appName = 'fly_cli'}) async {
    final configDir = await getConfigDirectory(appName: appName);
    return path.join(configDir, 'templates');
  }

  /// Ensure config directory exists
  ///
  /// [appName] - Application name (defaults to 'fly_cli' for backward compatibility)
  static Future<String> ensureConfigDirectory({String appName = 'fly_cli'}) async {
    final configDir = await getConfigDirectory(appName: appName);
    await Directory(configDir).create(recursive: true);
    return configDir;
  }

  /// Get shell for current platform
  static String getShell() {
    if (isWindows) {
      final env = const EnvironmentManager();
      return env.getString(EnvVar.comspec) ??
          env.getString(EnvVar.comSpec) ??
          'powershell.exe';
    } else {
      return const EnvironmentManager().getString(EnvVar.shell) ?? '/bin/bash';
    }
  }

  /// Detect the current shell type
  static String detectShell() {
    final env = const EnvironmentManager();
    final shell = env.getString(EnvVar.shell) ?? env.getString(EnvVar.comSpec);
    if (shell == null) {
      return 'unknown';
    }

    if (shell.contains('bash')) return 'bash';
    if (shell.contains('zsh')) return 'zsh';
    if (shell.contains('fish')) return 'fish';
    if (shell.contains('powershell') || shell.contains('pwsh'))
      return 'powershell';
    if (shell.contains('cmd')) return 'cmd';

    return 'unknown';
  }

  /// Check if running in CI environment
  static bool get isCI =>
      Platform.environment.containsKey('CI') ||
      Platform.environment.containsKey('CONTINUOUS_INTEGRATION');
}

