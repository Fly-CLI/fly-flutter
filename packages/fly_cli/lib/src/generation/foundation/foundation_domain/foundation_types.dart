import 'package:fly_cli/src/generation/foundation/foundation_domain/foundation_exception.dart';
import 'package:fly_cli/src/generation/utils/mason_variable_keys.dart';

/// Alias for Mason variables map (using the same typedef name as planning package).
typedef FoundationVars = Map<String, dynamic>;

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
        throw FoundationDomainException(
          'Invalid screen_type: "$key". Must be one of: list, detail, form, auth, settings.',
        );
    }
  }

  /// Parses screen_type from vars using MasonVarKey.
  static ScreenType? fromVars(FoundationVars vars) {
    final screenTypeStr = vars
        .getVar<String>(MasonVarKey.screenType)
        ?.toLowerCase();
    if (screenTypeStr == null || screenTypeStr.isEmpty) {
      return null;
    }
    return fromKey(screenTypeStr);
  }

  /// Parses screen_type from a nullable string value.
  ///
  /// Returns the corresponding enum value, or [defaultValue] if null/empty.
  /// Throws [FoundationDomainException] if the value is non-empty but invalid.
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
        throw FoundationDomainException(
          'Invalid service_type: "$key". Must be one of: api, local, cache, analytics, storage.',
        );
    }
  }

  /// Parses service_type from vars using MasonVarKey.
  static ServiceType? fromVars(FoundationVars vars) {
    final serviceTypeStr = vars
        .getVar<String>(MasonVarKey.serviceType)
        ?.toLowerCase();
    if (serviceTypeStr == null || serviceTypeStr.isEmpty) {
      return null;
    }
    return fromKey(serviceTypeStr);
  }

  /// Parses service_type from a nullable string value.
  ///
  /// Returns the corresponding enum value, or [defaultValue] if null/empty.
  /// Throws [FoundationDomainException] if the value is non-empty but invalid.
  static ServiceType? tryFromKey(String? key, {ServiceType? defaultValue}) {
    if (key == null || key.trim().isEmpty) {
      return defaultValue;
    }
    return fromKey(key);
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
        throw FoundationDomainException(
          'Invalid state_mgmt: "$key". Must be one of: riverpod, bloc, cubit.',
        );
    }
  }

  /// Parses state_mgmt from vars using MasonVarKey.
  static StateManagement fromVars(FoundationVars vars) {
    final stateMgmtStr = vars
        .getVar<String>(MasonVarKey.stateMgmt)
        ?.toLowerCase();
    if (stateMgmtStr == null || stateMgmtStr.isEmpty) {
      return StateManagement.riverpod; // Default
    }
    return fromKey(stateMgmtStr);
  }

  /// Parses state_mgmt from a nullable string value.
  ///
  /// Returns the corresponding enum value, or [defaultValue] if null/empty.
  /// Throws [FoundationDomainException] if the value is non-empty but invalid.
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

/// Model representing project name in different naming conventions.
class ProjectName {
  const ProjectName({
    required this.snake,
    required this.camel,
    required this.pascal,
  });

  /// Project name in snake_case format.
  final String snake;

  /// Project name in camelCase format.
  final String camel;

  /// Project name in PascalCase format.
  final String pascal;
}
