import 'dart:io';
import 'package:path/path.dart' as path;

/// Cross-platform utility functions for Fly CLI
class PlatformUtils {
  static bool get isWindows => Platform.isWindows;
  static bool get isMacOS => Platform.isMacOS;
  static bool get isLinux => Platform.isLinux;

  /// Normalize path separators (always use forward slash internally)
  static String normalizePath(String filePath) {
    return filePath.replaceAll('\\', '/');
  }

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
      return Platform.environment['USERPROFILE'] ?? '';
    } else {
      return Platform.environment['HOME'] ?? '';
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
      return Platform.environment['COMSPEC'] ?? 'powershell.exe';
    } else {
      return Platform.environment['SHELL'] ?? '/bin/bash';
    }
  }

  /// Check if running in CI environment
  static bool get isCI {
    return Platform.environment.containsKey('CI') ||
        Platform.environment.containsKey('CONTINUOUS_INTEGRATION');
  }
}
