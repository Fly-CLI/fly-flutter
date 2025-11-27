import 'package:fly_brick_composer/src/exceptions/composer_exception.dart';

/// Hook-local typedef for Mason variables map.
typedef Vars = Map<String, dynamic>;

/// Platform type enum for supported platforms.
enum PlatformType {
  ios,
  android,
  web,
  macos,
  windows,
  linux;

  /// Returns the canonical string key used in Mason variables.
  String get key {
    switch (this) {
      case PlatformType.ios:
        return 'ios';
      case PlatformType.android:
        return 'android';
      case PlatformType.web:
        return 'web';
      case PlatformType.macos:
        return 'macos';
      case PlatformType.windows:
        return 'windows';
      case PlatformType.linux:
        return 'linux';
    }
  }

  /// Parses platform from a string value.
  static PlatformType fromKey(String key) {
    final normalized = key.toLowerCase().trim();
    switch (normalized) {
      case 'ios':
        return PlatformType.ios;
      case 'android':
        return PlatformType.android;
      case 'web':
        return PlatformType.web;
      case 'macos':
        return PlatformType.macos;
      case 'windows':
        return PlatformType.windows;
      case 'linux':
        return PlatformType.linux;
      default:
        throw ComposerException(
          'Invalid platform: "$key". Must be one of: ios, android, web, macos, windows, linux.',
        );
    }
  }

  /// Parses a list of platform strings into [PlatformType] values.
  ///
  /// This method reads from a generic map. For domain-specific parsing that uses
  /// typed MasonVarKey, use domain-specific helpers (e.g., in fly_cli).
  static List<PlatformType> fromVars(Map<String, dynamic> vars) {
    final platformsRaw = vars['platforms'] as List? ?? ['ios', 'android'];
    final platforms = <PlatformType>[];
    for (final key in platformsRaw) {
      if (key == null) continue;
      final keyStr = key.toString().toLowerCase().trim();
      if (keyStr.isEmpty) continue;
      try {
        platforms.add(fromKey(keyStr));
      } on ComposerException {
        // Skip invalid platforms
      }
    }
    return platforms.isEmpty
        ? [PlatformType.ios, PlatformType.android]
        : platforms;
  }
}

