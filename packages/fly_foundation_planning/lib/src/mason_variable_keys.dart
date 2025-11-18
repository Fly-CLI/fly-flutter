/// Centralized type-safe constants for all Mason variable keys.
///
/// This enum provides a single source of truth for all variable keys used
/// throughout the Fly CLI codebase and Mason templates.
enum MasonVarKey {
  // ============================================================================
  // Base Variables
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
  // Feature-Specific Flags
  // ============================================================================

  /// Whether to include view model for features.
  withViewModel('with_viewmodel'),

  /// Whether to include validation for features.
  withValidation('with_validation'),

  /// Whether to include navigation for features.
  withNavigation('with_navigation'),

  // ============================================================================
  // State Management
  // ============================================================================

  /// State management approach: 'riverpod', 'bloc', or 'cubit'.
  stateMgmt('state_mgmt'),

  // ============================================================================
  // Mode-Specific Variables
  // ============================================================================

  /// Screen type for feature generation: 'list', 'detail', 'form', 'auth', or 'settings'.
  screenType('screen_type'),

  /// Service type for service generation: 'api', 'local', 'cache', 'analytics', or 'storage'.
  serviceType('service_type'),

  /// API base URL for API service type.
  apiBaseUrl('api_base_url'),

  /// Alternative key for API base URL (legacy support).
  baseUrl('base_url'),

  /// Preset identifier (e.g., 'starter', 'batteries_included', 'minimal').
  preset('preset'),

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

  /// Whether the generation mode is 'project'.
  isProject('is_project'),

  /// Whether the generation mode is 'feature'.
  isFeature('is_feature'),

  /// Whether the generation mode is 'service'.
  isService('is_service'),

  /// Active generation mode key (derived from generation_mode).
  activeMode('active_mode'),

  /// Whether the component is a screen (legacy flag).
  isScreen('is_screen'),

  /// Whether the component is a provider (legacy flag).
  isProvider('is_provider'),

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

  /// Whether screen type is 'list' (legacy flag).
  screenTypeList('screen_type_list'),

  /// Whether screen type is 'detail' (legacy flag).
  screenTypeDetail('screen_type_detail'),

  /// Whether screen type is 'form' (legacy flag).
  screenTypeForm('screen_type_form'),

  /// Whether screen type is 'auth' (legacy flag).
  screenTypeAuth('screen_type_auth'),

  /// Whether screen type is 'settings' (legacy flag).
  screenTypeSettings('screen_type_settings'),

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

  /// Whether service type is 'api' (legacy flag).
  serviceTypeApi('service_type_api'),

  /// Whether service type is 'local' (legacy flag).
  serviceTypeLocal('service_type_local'),

  /// Whether service type is 'cache' (legacy flag).
  serviceTypeCache('service_type_cache'),

  /// Whether service type is 'analytics' (legacy flag).
  serviceTypeAnalytics('service_type_analytics'),

  /// Whether service type is 'storage' (legacy flag).
  serviceTypeStorage('service_type_storage'),

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

  const MasonVarKey(this.key);
}

/// Extension on [Map<String, dynamic>] for type-safe variable access.
extension MasonVarsExtension on Map<String, dynamic> {
  /// Gets a variable value by key with type casting.
  T? getVar<T>(MasonVarKey key) {
    final value = this[key.key];
    if (value == null) return null;
    try {
      return value as T;
    } catch (_) {
      return null;
    }
  }
}

