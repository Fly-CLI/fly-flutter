/// Shared enums and type definitions for the fly_foundation template system.
///
/// Provides strongly-typed enums for all categorical variables used in template
/// generation, with helpers for parsing from and serializing to Mason variable maps.

/// Generation mode enum representing the three main workflows.
enum GenerationMode {
  project,
  feature,
  service;

  /// Returns the canonical string key used in Mason variables.
  String get key {
    switch (this) {
      case GenerationMode.project:
        return 'project';
      case GenerationMode.feature:
        return 'feature';
      case GenerationMode.service:
        return 'service';
    }
  }

  /// Parses generation_mode from a string value.
  ///
  /// Returns the corresponding enum value, or throws [FormatException] if invalid.
  static GenerationMode fromKey(String key) {
    final normalized = key.toLowerCase().trim();
    switch (normalized) {
      case 'project':
        return GenerationMode.project;
      case 'feature':
        return GenerationMode.feature;
      case 'service':
        return GenerationMode.service;
      default:
        throw FormatException(
          'Invalid generation_mode: "$key". Must be one of: project, feature, service.',
        );
    }
  }

  /// Parses generation_mode from a nullable string value.
  ///
  /// Returns the corresponding enum value, or [defaultValue] if null/empty.
  /// Throws [FormatException] if the value is non-empty but invalid.
  static GenerationMode tryFromKey(
    String? key, {
    GenerationMode defaultValue = GenerationMode.project,
  }) {
    if (key == null || key.trim().isEmpty) {
      return defaultValue;
    }
    return fromKey(key);
  }
}

/// Screen type enum for feature generation.
enum ScreenType {
  list,
  detail,
  form,
  auth,
  settings;

  /// Returns the canonical string key used in Mason variables.
  String get key {
    switch (this) {
      case ScreenType.list:
        return 'list';
      case ScreenType.detail:
        return 'detail';
      case ScreenType.form:
        return 'form';
      case ScreenType.auth:
        return 'auth';
      case ScreenType.settings:
        return 'settings';
    }
  }

  /// Parses screen_type from a string value.
  ///
  /// Returns the corresponding enum value, or throws [FormatException] if invalid.
  static ScreenType fromKey(String key) {
    final normalized = key.toLowerCase().trim();
    switch (normalized) {
      case 'list':
        return ScreenType.list;
      case 'detail':
        return ScreenType.detail;
      case 'form':
        return ScreenType.form;
      case 'auth':
        return ScreenType.auth;
      case 'settings':
        return ScreenType.settings;
      default:
        throw FormatException(
          'Invalid screen_type: "$key". Must be one of: list, detail, form, auth, settings.',
        );
    }
  }

  /// Parses screen_type from a nullable string value.
  ///
  /// Returns the corresponding enum value, or [defaultValue] if null/empty.
  /// Throws [FormatException] if the value is non-empty but invalid.
  static ScreenType? tryFromKey(String? key, {ScreenType? defaultValue}) {
    if (key == null || key.trim().isEmpty) {
      return defaultValue;
    }
    return fromKey(key);
  }
}

/// Service type enum for service generation.
enum ServiceType {
  api,
  local,
  cache,
  analytics,
  storage;

  /// Returns the canonical string key used in Mason variables.
  String get key {
    switch (this) {
      case ServiceType.api:
        return 'api';
      case ServiceType.local:
        return 'local';
      case ServiceType.cache:
        return 'cache';
      case ServiceType.analytics:
        return 'analytics';
      case ServiceType.storage:
        return 'storage';
    }
  }

  /// Parses service_type from a string value.
  ///
  /// Returns the corresponding enum value, or throws [FormatException] if invalid.
  static ServiceType fromKey(String key) {
    final normalized = key.toLowerCase().trim();
    switch (normalized) {
      case 'api':
        return ServiceType.api;
      case 'local':
        return ServiceType.local;
      case 'cache':
        return ServiceType.cache;
      case 'analytics':
        return ServiceType.analytics;
      case 'storage':
        return ServiceType.storage;
      default:
        throw FormatException(
          'Invalid service_type: "$key". Must be one of: api, local, cache, analytics, storage.',
        );
    }
  }

  /// Parses service_type from a nullable string value.
  ///
  /// Returns the corresponding enum value, or [defaultValue] if null/empty.
  /// Throws [FormatException] if the value is non-empty but invalid.
  static ServiceType? tryFromKey(String? key, {ServiceType? defaultValue}) {
    if (key == null || key.trim().isEmpty) {
      return defaultValue;
    }
    return fromKey(key);
  }
}

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
  ///
  /// Returns the corresponding enum value, or throws [FormatException] if invalid.
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
        throw FormatException(
          'Invalid platform: "$key". Must be one of: ios, android, web, macos, windows, linux.',
        );
    }
  }

  /// Parses a list of platform strings into [PlatformType] values.
  ///
  /// Returns a list of valid platforms, filtering out invalid entries.
  /// Throws [FormatException] if any entry is invalid and [strict] is true.
  static List<PlatformType> fromKeys(
    List<dynamic> keys, {
    bool strict = false,
  }) {
    final platforms = <PlatformType>[];
    for (final key in keys) {
      if (key == null) continue;
      final keyStr = key.toString().toLowerCase().trim();
      if (keyStr.isEmpty) continue;

      try {
        platforms.add(fromKey(keyStr));
      } on FormatException {
        if (strict) {
          rethrow;
        }
        // Skip invalid platforms in non-strict mode
      }
    }
    return platforms;
  }
}

/// State management enum for feature generation.
enum StateManagement {
  riverpod,
  bloc,
  cubit;

  /// Returns the canonical string key used in Mason variables.
  String get key {
    switch (this) {
      case StateManagement.riverpod:
        return 'riverpod';
      case StateManagement.bloc:
        return 'bloc';
      case StateManagement.cubit:
        return 'cubit';
    }
  }

  /// Parses state_mgmt from a string value.
  ///
  /// Returns the corresponding enum value, or throws [FormatException] if invalid.
  static StateManagement fromKey(String key) {
    final normalized = key.toLowerCase().trim();
    switch (normalized) {
      case 'riverpod':
        return StateManagement.riverpod;
      case 'bloc':
        return StateManagement.bloc;
      case 'cubit':
        return StateManagement.cubit;
      default:
        throw FormatException(
          'Invalid state_mgmt: "$key". Must be one of: riverpod, bloc, cubit.',
        );
    }
  }

  /// Parses state_mgmt from a nullable string value.
  ///
  /// Returns the corresponding enum value, or [defaultValue] if null/empty.
  /// Throws [FormatException] if the value is non-empty but invalid.
  static StateManagement tryFromKey(
    String? key, {
    StateManagement defaultValue = StateManagement.riverpod,
  }) {
    if (key == null || key.trim().isEmpty) {
      return defaultValue;
    }
    return fromKey(key);
  }
}

