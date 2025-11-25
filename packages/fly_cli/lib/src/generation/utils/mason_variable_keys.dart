/// Centralized type-safe constants for all Mason variable keys.
///
/// This module provides specialized enums for different generation modes,
/// following SOLID principles by separating concerns:
///
/// - **BaseVarKey**: Shared variables used across all generation modes
/// - **ProjectVarKey**: Project-specific variables
/// - **FeatureVarKey**: Feature-specific variables
/// - **ServiceVarKey**: Service-specific variables
///
/// Using these enums instead of hardcoded string literals ensures:
///
/// - **Type Safety**: Compile-time validation prevents typos and incorrect key usage
/// - **Maintainability**: Key name changes require updates in only one place
/// - **IDE Support**: Autocomplete and refactoring support for all keys
/// - **Consistency**: Guaranteed consistency across all variable access points
/// - **Separation of Concerns**: Each enum contains only relevant variables
///
/// ## Usage
///
/// ### In `toMasonVars()` methods:
/// ```dart
/// Map<String, dynamic> toMasonVars() {
///   return {
///     BaseVarKey.projectName.key: projectName,
///     BaseVarKey.organization.key: organization,
///     // ...
///   };
/// }
/// ```
///
/// ### In `fromMasonVars()` / `fromVars()` methods:
/// ```dart
/// factory MyClass.fromMasonVars(Map<String, dynamic> vars) {
///   final name = vars[BaseVarKey.name.key] as String?;
///   // or using the helper extension:
///   final name = vars.getVar<String>(BaseVarKey.name);
/// }
/// ```
///
/// ### Direct map access:
/// ```dart
/// final value = vars[BaseVarKey.projectName.key];
/// // or using the helper extension:
/// final value = vars.getVar<String>(BaseVarKey.projectName);
/// ```
///
/// ## Adding New Keys
///
/// When adding a new Mason variable key:
/// 1. Add it to the appropriate enum (BaseVarKey, ProjectVarKey, FeatureVarKey, or ServiceVarKey)
/// 2. Use the exact string value that Mason templates expect
/// 3. Add documentation explaining the key's purpose
/// 4. Update all usages to use the enum instead of string literals
library;

// ============================================================================
// Base Variables - Shared across all generation modes
// ============================================================================

/// Base variable keys used across all generation modes (project, feature, service).
///
/// Contains shared variables that are used regardless of the generation mode,
/// including basic project information, platform flags, mode flags, and
/// cross-cutting feature flags.
enum BaseVarKey {
  // ============================================================================
  // Basic Variables
  // ============================================================================

  /// Project/component name provided by the user.
  name('name'),

  /// Organization identifier in reverse domain format (e.g., 'com.example.app').
  organization('organization'),

  /// Generation mode: 'project', 'feature', or 'service'.
  generationMode('generation_mode'),

  /// List of target platforms (e.g., ['ios', 'android']).
  platforms('platforms'),

  /// Project description.
  description('description'),

  /// Template variant identifier (e.g., 'foundation').
  templateVariant('template_variant'),

  /// Minimum Flutter SDK version required.
  minFlutterSdk('min_flutter_sdk'),

  /// Minimum Dart SDK version required.
  minDartSdk('min_dart_sdk'),

  // ============================================================================
  // Feature Flags (Cross-cutting)
  // ============================================================================

  /// Whether to include tests.
  withTests('with_tests'),

  /// Whether to include documentation.
  withDocs('with_docs'),

  /// Whether to include MCP integration.
  withMcp('with_mcp'),

  /// Whether to enable code generation.
  codeGeneration('code_generation'),

  /// Whether to enable AI integration.
  aiIntegration('ai_integration'),

  /// List of Fly packages to include.
  flyPackages('fly_packages'),

  // ============================================================================
  // State Management
  // ============================================================================

  /// State management approach: 'riverpod', 'bloc', or 'cubit'.
  stateMgmt('state_mgmt'),

  // ============================================================================
  // Derived Naming Variables
  // ============================================================================

  /// Project name (may be derived from component name in feature/service mode).
  projectName('project_name'),

  /// Project name in snake_case format.
  projectNameSnake('project_name_snake'),

  /// Project name in camelCase format.
  projectNameCamel('project_name_camel'),

  /// Project name in PascalCase format.
  projectNamePascal('project_name_pascal'),

  // ============================================================================
  // Mode Flags
  // ============================================================================

  /// Whether the generation mode is 'service'.
  isService('is_service'),

  /// Active generation mode key (derived from generation_mode).
  activeMode('active_mode'),

  // ============================================================================
  // Platform Flags
  // ============================================================================

  /// Whether iOS platform is supported.
  supportsIos('supports_ios'),

  /// Whether Android platform is supported.
  supportsAndroid('supports_android'),

  /// Whether Web platform is supported.
  supportsWeb('supports_web'),

  /// Whether macOS platform is supported.
  supportsMacos('supports_macos'),

  /// Whether Windows platform is supported.
  supportsWindows('supports_windows'),

  /// Whether Linux platform is supported.
  supportsLinux('supports_linux'),

  /// Whether desktop platforms (macOS, Windows, Linux) are supported.
  supportsDesktop('supports_desktop'),

  // ============================================================================
  // Component Naming
  // ============================================================================

  /// Feature name (for feature/service generation).
  feature('feature'),

  /// Component name (screen name or service name).
  componentName('component_name'),

  /// List of features (for project generation with multiple features).
  features('features');

  /// The string key used in Mason variable maps.
  final String key;

  const BaseVarKey(this.key);
}

// ============================================================================
// Project Variables - Project-specific
// ============================================================================

/// Project-specific variable keys used only in project generation mode.
enum ProjectVarKey {
  /// Preset identifier (e.g., 'starter', 'batteries_included', 'minimal').
  preset('preset');

  /// The string key used in Mason variable maps.
  final String key;

  const ProjectVarKey(this.key);
}

// ============================================================================
// Feature Variables - Feature-specific
// ============================================================================

/// Feature-specific variable keys used only in feature generation mode.
enum FeatureVarKey {
  // ============================================================================
  // Feature-Specific Flags
  // ============================================================================

  /// Whether to include view model for features.
  withViewModel('with_viewmodel'),

  /// Whether to include validation for features.
  withValidation('with_validation'),

  /// Whether to include navigation for features.
  withNavigation('with_navigation'),

  // ============================================================================
  // Mode-Specific Variables
  // ============================================================================

  /// Screen type for feature generation: 'list', 'detail', 'form', 'auth', or 'settings'.
  screenType('screen_type'),

  // ============================================================================
  // Feature Screen Flags
  // ============================================================================

  /// Whether the screen type is 'list'.
  isListScreen('is_list_screen'),

  /// Whether the screen type is 'detail'.
  isDetailScreen('is_detail_screen'),

  /// Whether the screen type is 'form'.
  isFormScreen('is_form_screen'),

  /// Whether validation is required for the feature.
  requiresValidation('requires_validation'),

  /// Whether Riverpod state management is used.
  useRiverpod('use_riverpod'),

  /// Whether BLoC state management is used.
  useBloc('use_bloc'),

  /// Whether Cubit state management is used.
  useCubit('use_cubit'),

  // ============================================================================
  // Legacy Flags
  // ============================================================================

  /// Whether screen type is 'list' (legacy flag).
  screenTypeList('screen_type_list'),

  /// Whether screen type is 'detail' (legacy flag).
  screenTypeDetail('screen_type_detail'),

  /// Whether screen type is 'form' (legacy flag).
  screenTypeForm('screen_type_form'),

  /// Whether screen type is 'auth' (legacy flag).
  screenTypeAuth('screen_type_auth'),

  /// Whether screen type is 'settings' (legacy flag).
  screenTypeSettings('screen_type_settings');

  /// The string key used in Mason variable maps.
  final String key;

  const FeatureVarKey(this.key);
}

// ============================================================================
// Service Variables - Service-specific
// ============================================================================

/// Service-specific variable keys used only in service generation mode.
enum ServiceVarKey {
  // ============================================================================
  // Service Flags
  // ============================================================================

  /// Whether to include retry logic for services.
  withRetryLogic('with_retry_logic'),

  /// Whether to include caching for services.
  withCaching('with_caching'),

  /// Whether to include interceptors for services.
  withInterceptors('with_interceptors'),

  /// Whether to include mocks for services.
  withMocks('with_mocks'),

  // ============================================================================
  // Mode-Specific Variables
  // ============================================================================

  /// Service type for service generation: 'api', 'local', 'cache', 'analytics', or 'storage'.
  serviceType('service_type'),

  /// API base URL for API service type.
  apiBaseUrl('api_base_url'),

  /// Alternative key for API base URL (legacy support).
  baseUrl('base_url'),

  // ============================================================================
  // Service Type Flags
  // ============================================================================

  /// Whether the service type is 'api'.
  isApiService('is_api_service'),

  /// Whether the service type is 'local'.
  isLocalService('is_local_service'),

  /// Whether the service type is 'cache'.
  isCacheService('is_cache_service'),

  /// Whether the service type is 'analytics'.
  isAnalyticsService('is_analytics_service'),

  /// Whether the service type is 'storage'.
  isStorageService('is_storage_service'),

  /// Whether retry logic is supported (derived flag).
  supportsRetry('supports_retry'),

  /// Whether caching is supported (derived flag).
  supportsCaching('supports_caching'),

  /// Whether interceptors are supported (derived flag).
  supportsInterceptors('supports_interceptors'),

  /// Whether mocks should be generated (derived flag).
  generateMocks('generate_mocks'),

  // ============================================================================
  // Legacy Flags
  // ============================================================================

  /// Whether service type is 'api' (legacy flag).
  serviceTypeApi('service_type_api'),

  /// Whether service type is 'local' (legacy flag).
  serviceTypeLocal('service_type_local'),

  /// Whether service type is 'cache' (legacy flag).
  serviceTypeCache('service_type_cache'),

  /// Whether service type is 'analytics' (legacy flag).
  serviceTypeAnalytics('service_type_analytics'),

  /// Whether service type is 'storage' (legacy flag).
  serviceTypeStorage('service_type_storage');

  /// The string key used in Mason variable maps.
  final String key;

  const ServiceVarKey(this.key);
}

// ============================================================================
// Unified Type System
// ============================================================================

/// Sealed class providing a unified type for all variable key enums.
///
/// This allows extension methods and type-safe operations to work with
/// any of the specialized enum types (BaseVarKey, ProjectVarKey, FeatureVarKey, ServiceVarKey).
sealed class MasonVarKey {
  /// The string key used in Mason variable maps.
  String get key;

  const MasonVarKey();

  /// Creates a MasonVarKey from a BaseVarKey.
  const factory MasonVarKey.base(BaseVarKey key) = _BaseVarKeyWrapper;

  /// Creates a MasonVarKey from a ProjectVarKey.
  const factory MasonVarKey.project(ProjectVarKey key) = _ProjectVarKeyWrapper;

  /// Creates a MasonVarKey from a FeatureVarKey.
  const factory MasonVarKey.feature(FeatureVarKey key) = _FeatureVarKeyWrapper;

  /// Creates a MasonVarKey from a ServiceVarKey.
  const factory MasonVarKey.service(ServiceVarKey key) = _ServiceVarKeyWrapper;
}

/// Internal wrapper for BaseVarKey.
final class _BaseVarKeyWrapper extends MasonVarKey {
  final BaseVarKey _key;

  const _BaseVarKeyWrapper(this._key);

  @override
  String get key => _key.key;
}

/// Internal wrapper for ProjectVarKey.
final class _ProjectVarKeyWrapper extends MasonVarKey {
  final ProjectVarKey _key;

  const _ProjectVarKeyWrapper(this._key);

  @override
  String get key => _key.key;
}

/// Internal wrapper for FeatureVarKey.
final class _FeatureVarKeyWrapper extends MasonVarKey {
  final FeatureVarKey _key;

  const _FeatureVarKeyWrapper(this._key);

  @override
  String get key => _key.key;
}

/// Internal wrapper for ServiceVarKey.
final class _ServiceVarKeyWrapper extends MasonVarKey {
  final ServiceVarKey _key;

  const _ServiceVarKeyWrapper(this._key);

  @override
  String get key => _key.key;
}

// ============================================================================
// Extension Methods
// ============================================================================

/// Extension on variable key types for convenient access to the key string.
///
/// Works with BaseVarKey, ProjectVarKey, FeatureVarKey, ServiceVarKey, and MasonVarKey.
extension MasonVarKeyExtension on Object {
  /// Returns the string key value.
  ///
  /// This is a convenience getter that provides a shorter syntax:
  /// ```dart
  /// vars[BaseVarKey.projectName.key]  // Standard
  /// vars[BaseVarKey.projectName.s]    // Shorter
  /// ```
  String get s {
    if (this is BaseVarKey) {
      return (this as BaseVarKey).key;
    } else if (this is ProjectVarKey) {
      return (this as ProjectVarKey).key;
    } else if (this is FeatureVarKey) {
      return (this as FeatureVarKey).key;
    } else if (this is ServiceVarKey) {
      return (this as ServiceVarKey).key;
    } else if (this is MasonVarKey) {
      return (this as MasonVarKey).key;
    }
    throw ArgumentError('Invalid variable key type: ${this.runtimeType}');
  }
}

/// Extension on [Map<String, dynamic>] for type-safe variable access.
///
/// Provides a convenient way to access Mason variables with type safety:
/// ```dart
/// final name = vars.getVar<String>(BaseVarKey.projectName);
/// final count = vars.getVar<int>(BaseVarKey.someCount) ?? 0;
/// ```
extension MasonVarsExtension on Map<String, dynamic> {
  /// Gets a variable value by key with type casting.
  ///
  /// Returns `null` if the key doesn't exist or if the value cannot be cast
  /// to the requested type.
  ///
  /// Works with BaseVarKey, ProjectVarKey, FeatureVarKey, ServiceVarKey, and MasonVarKey.
  ///
  /// Example:
  /// ```dart
  /// final name = vars.getVar<String>(BaseVarKey.projectName);
  /// final platforms = vars.getVar<List>(BaseVarKey.platforms);
  /// ```
  T? getVar<T>(Object key) {
    String keyString;
    if (key is BaseVarKey) {
      keyString = key.key;
    } else if (key is ProjectVarKey) {
      keyString = key.key;
    } else if (key is FeatureVarKey) {
      keyString = key.key;
    } else if (key is ServiceVarKey) {
      keyString = key.key;
    } else if (key is MasonVarKey) {
      keyString = key.key;
    } else {
      throw ArgumentError('Invalid variable key type: ${key.runtimeType}');
    }

    final value = this[keyString];
    if (value == null) return null;
    try {
      return value as T;
    } catch (_) {
      return null;
    }
  }
}
