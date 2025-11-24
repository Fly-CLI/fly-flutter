import 'dart:io';

/// Detects the execution environment (development vs production)
///
/// This class provides a reusable way to detect whether the CLI is running
/// in development mode (from source) or production mode (installed package).
class EnvironmentDetector {
  /// Determine if running in development mode
  ///
  /// Checks if we're running from source (development) vs installed package.
  /// This is determined by checking if the script path contains development
  /// indicators like 'packages/fly_cli' or 'bin/fly.dart'.
  static bool isDevelopmentMode() {
    final scriptPath = Platform.script.toFilePath();
    return scriptPath.contains('packages/fly_cli') ||
        scriptPath.contains('bin/fly.dart');
  }

  /// Determine if running in production mode
  ///
  /// Returns true if not in development mode.
  static bool isProductionMode() {
    return !isDevelopmentMode();
  }
}
