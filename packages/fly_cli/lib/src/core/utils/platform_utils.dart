import 'dart:io';

import 'package:fly_core/src/environment/environment_manager.dart';
import 'package:fly_core/src/environment/env_var.dart';
import 'package:path/path.dart' as path;

/// Cross-platform utility functions for Fly CLI
class PlatformUtils {
  static bool get isWindows => Platform.isWindows;
  static bool get isMacOS => Platform.isMacOS;
  static bool get isLinux => Platform.isLinux;

  /// Normalize path separators (always use forward slash internally)
  static String normalizePath(String filePath) => filePath.replaceAll(r'\', '/');

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

  /// Get CLI config directory based on platform conventions
  static Future<String> getConfigDirectory() async {
    final home = await getUserHome();
    if (isWindows) {
      return path.join(home, 'AppData', 'Local', 'fly_cli');
    } else if (isMacOS) {
      return path.join(home, 'Library', 'Application Support', 'fly_cli');
    } else {
      // Linux and other Unix-like systems
      return path.join(home, '.config', 'fly_cli');
    }
  }

  /// Get cache directory
  static Future<String> getCacheDirectory() async {
    final configDir = await getConfigDirectory();
    return path.join(configDir, 'cache');
  }

  /// Get default cache directory synchronously (for constructor)
  static String getDefaultCacheDirectory() {
    const env = EnvironmentManager();
    final home = env.getString(EnvVar.home) ?? env.getString(EnvVar.userProfile) ?? '';
    if (isWindows) {
      return path.join(home, 'AppData', 'Local', 'fly_cli', 'cache');
    } else if (isMacOS) {
      return path.join(home, 'Library', 'Application Support', 'fly_cli', 'cache');
    } else {
      // Linux and other Unix-like systems
      return path.join(home, '.config', 'fly_cli', 'cache');
    }
  }

  /// Get templates directory
  static Future<String> getTemplatesDirectory() async {
    final configDir = await getConfigDirectory();
    return path.join(configDir, 'templates');
  }

  /// Ensure config directory exists
  static Future<String> ensureConfigDirectory() async {
    final configDir = await getConfigDirectory();
    await Directory(configDir).create(recursive: true);
    return configDir;
  }

  /// Get shell for current platform
  static String getShell() {
    if (isWindows) {
      final env = const EnvironmentManager();
      return env.getString(EnvVar.comspec) 
          ?? env.getString(EnvVar.comSpec) 
          ?? 'powershell.exe';
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
    if (shell.contains('powershell') || shell.contains('pwsh')) return 'powershell';
    if (shell.contains('cmd')) return 'cmd';
    
    return 'unknown';
  }

  /// Check if running in CI environment
  static bool get isCI => Platform.environment.containsKey('CI') ||
        Platform.environment.containsKey('CONTINUOUS_INTEGRATION');
}
