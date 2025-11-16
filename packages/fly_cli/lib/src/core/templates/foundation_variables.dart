import 'foundation_enums.dart';

/// Base template variables representing the core input variables for template generation.
///
/// This class encapsulates all user-provided variables with proper types, including
/// common fields and optional mode-specific fields for feature and service generation.
class BaseTemplateVariables {
  static const List<String> defaultFlyPackages = [
    'fly_core',
    'fly_mvvm',
    'fly_state',
    'fly_navigation',
    'fly_flow_guard',
    'fly_logger',
    'fly_events',
    'fly_networking',
  ];

  const BaseTemplateVariables({
    required this.name,
    required this.organization,
    required this.generationMode,
    required this.platforms,
    this.description = '',
    this.templateVariant = 'foundation',
    this.minFlutterSdk = '3.10.0',
    this.minDartSdk = '3.0.0',
    // Cross-cutting flags
    this.withTests = true,
    this.withDocs = true,
    this.withMcp = true,
    this.codeGeneration = true,
    this.aiIntegration = true,
    this.flyPackages = defaultFlyPackages,
    // Preset-related flags (can be derived from preset)
    this.serviceRetry = false,
    this.serviceCaching = false,
    this.serviceInterceptors = false,
    this.serviceMocks = false,
    this.featureViewModel = true,
    this.featureValidation = false,
    this.featureNavigation = false,
    this.stateManagement = StateManagement.riverpod,
    // Mode-specific optional fields
    this.screenType,
    this.serviceType,
    this.apiBaseUrl,
    this.preset,
  });

  /// The name provided by the user (project name, feature name, or service name).
  final String name;

  /// Organization identifier (reverse domain format).
  final String organization;

  /// Generation mode (project, feature, or service).
  final GenerationMode generationMode;

  /// List of target platforms.
  final List<PlatformType> platforms;

  /// Project description.
  final String description;

  /// Template variant identifier.
  final String templateVariant;

  /// Minimum Flutter SDK version.
  final String minFlutterSdk;

  /// Minimum Dart SDK version.
  final String minDartSdk;

  /// Whether to include tests.
  final bool withTests;

  /// Whether to include documentation.
  final bool withDocs;

  /// Whether to include MCP integration.
  final bool withMcp;

  /// Whether to enable code generation.
  final bool codeGeneration;

  /// Whether to enable AI integration.
  final bool aiIntegration;

  /// List of Fly packages to include.
  final List<String> flyPackages;

  /// Service-related flags (from preset or explicit).
  final bool serviceRetry;
  final bool serviceCaching;
  final bool serviceInterceptors;
  final bool serviceMocks;

  /// Feature-related flags (from preset or explicit).
  final bool featureViewModel;
  final bool featureValidation;
  final bool featureNavigation;

  /// State management approach.
  final StateManagement stateManagement;

  /// Screen type (for feature mode).
  final ScreenType? screenType;

  /// Service type (for service mode).
  final ServiceType? serviceType;

  /// API base URL (for API service type).
  final String? apiBaseUrl;

  /// Preset identifier (if used).
  final String? preset;

  /// Creates [BaseTemplateVariables] from a Mason variables map.
  ///
  /// Parses all fields from the map, using enum parsers for categorical values
  /// and providing sensible defaults for missing values.
  factory BaseTemplateVariables.fromMasonVars(Map<String, dynamic> vars) {
    final name = (vars['name'] as String?) ?? 'unnamed';
    final organization =
        (vars['organization'] as String?) ?? 'com.example';
    final generationMode = GenerationMode.tryFromKey(
      vars['generation_mode'] as String?,
    );
    final platformsRaw = (vars['platforms'] as List?) ?? ['ios', 'android'];
    final platforms = PlatformType.fromKeys(platformsRaw);

    return BaseTemplateVariables(
      name: name,
      organization: organization,
      generationMode: generationMode,
      platforms: platforms,
      description: (vars['description'] as String?) ??
          'A new Fly foundation project',
      templateVariant: (vars['template_variant'] as String?) ?? 'foundation',
      minFlutterSdk: (vars['min_flutter_sdk'] as String?) ?? '3.10.0',
      minDartSdk: (vars['min_dart_sdk'] as String?) ?? '3.0.0',
      withTests: vars['with_tests'] as bool? ?? true,
      withDocs: vars['with_docs'] as bool? ?? true,
      withMcp: vars['with_mcp'] as bool? ?? true,
      codeGeneration: vars['code_generation'] as bool? ?? true,
      aiIntegration: vars['ai_integration'] as bool? ?? true,
      flyPackages: (vars['fly_packages'] as List?)?.cast<String>() ??
          defaultFlyPackages,
      serviceRetry: vars['with_retry_logic'] as bool? ?? false,
      serviceCaching: vars['with_caching'] as bool? ?? false,
      serviceInterceptors: vars['with_interceptors'] as bool? ?? false,
      serviceMocks: vars['with_mocks'] as bool? ?? false,
      featureViewModel: vars['with_viewmodel'] as bool? ?? true,
      featureValidation: vars['with_validation'] as bool? ?? false,
      featureNavigation: vars['with_navigation'] as bool? ?? false,
      stateManagement: StateManagement.tryFromKey(
        vars['state_mgmt'] as String?,
      ),
      screenType: ScreenType.tryFromKey(vars['screen_type'] as String?),
      serviceType: ServiceType.tryFromKey(
        vars['service_type'] as String?,
        defaultValue: ServiceType.api,
      ),
      apiBaseUrl: vars['api_base_url'] as String?,
      preset: vars['preset'] as String?,
    );
  }

  /// Converts to a Mason variables map.
  ///
  /// Emits all fields using the canonical string keys expected by Mason templates.
  Map<String, dynamic> toMasonVars() {
    return {
      'name': name,
      'organization': organization,
      'generation_mode': generationMode.key,
      'platforms': platforms.map((p) => p.key).toList(),
      'description': description,
      'template_variant': templateVariant,
      'min_flutter_sdk': minFlutterSdk,
      'min_dart_sdk': minDartSdk,
      'with_tests': withTests,
      'with_docs': withDocs,
      'with_mcp': withMcp,
      'code_generation': codeGeneration,
      'ai_integration': aiIntegration,
      'fly_packages': flyPackages,
      'with_retry_logic': serviceRetry,
      'with_caching': serviceCaching,
      'with_interceptors': serviceInterceptors,
      'with_mocks': serviceMocks,
      'with_viewmodel': featureViewModel,
      'with_validation': featureValidation,
      'with_navigation': featureNavigation,
      'state_mgmt': stateManagement.key,
      if (screenType != null) 'screen_type': screenType!.key,
      if (serviceType != null) 'service_type': serviceType!.key,
      if (apiBaseUrl != null) 'api_base_url': apiBaseUrl,
      if (preset != null) 'preset': preset,
    };
  }

  /// Creates a copy with updated fields.
  ///
  /// Returns a new instance with the specified fields updated, keeping others unchanged.
  BaseTemplateVariables copyWith({
    String? name,
    String? organization,
    GenerationMode? generationMode,
    List<PlatformType>? platforms,
    String? description,
    String? templateVariant,
    String? minFlutterSdk,
    String? minDartSdk,
    bool? withTests,
    bool? withDocs,
    bool? withMcp,
    bool? codeGeneration,
    bool? aiIntegration,
    List<String>? flyPackages,
    bool? serviceRetry,
    bool? serviceCaching,
    bool? serviceInterceptors,
    bool? serviceMocks,
    bool? featureViewModel,
    bool? featureValidation,
    bool? featureNavigation,
    StateManagement? stateManagement,
    ScreenType? screenType,
    ServiceType? serviceType,
    String? apiBaseUrl,
    String? preset,
  }) {
    return BaseTemplateVariables(
      name: name ?? this.name,
      organization: organization ?? this.organization,
      generationMode: generationMode ?? this.generationMode,
      platforms: platforms ?? this.platforms,
      description: description ?? this.description,
      templateVariant: templateVariant ?? this.templateVariant,
      minFlutterSdk: minFlutterSdk ?? this.minFlutterSdk,
      minDartSdk: minDartSdk ?? this.minDartSdk,
      withTests: withTests ?? this.withTests,
      withDocs: withDocs ?? this.withDocs,
      withMcp: withMcp ?? this.withMcp,
      codeGeneration: codeGeneration ?? this.codeGeneration,
      aiIntegration: aiIntegration ?? this.aiIntegration,
      flyPackages: flyPackages ?? this.flyPackages,
      serviceRetry: serviceRetry ?? this.serviceRetry,
      serviceCaching: serviceCaching ?? this.serviceCaching,
      serviceInterceptors: serviceInterceptors ?? this.serviceInterceptors,
      serviceMocks: serviceMocks ?? this.serviceMocks,
      featureViewModel: featureViewModel ?? this.featureViewModel,
      featureValidation: featureValidation ?? this.featureValidation,
      featureNavigation: featureNavigation ?? this.featureNavigation,
      stateManagement: stateManagement ?? this.stateManagement,
      screenType: screenType ?? this.screenType,
      serviceType: serviceType ?? this.serviceType,
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      preset: preset ?? this.preset,
    );
  }

  /// Helper methods for common transformations.
  BaseTemplateVariables withMode(GenerationMode mode) {
    return copyWith(generationMode: mode);
  }

  BaseTemplateVariables withScreenType(ScreenType type) {
    return copyWith(screenType: type);
  }

  BaseTemplateVariables withServiceType(ServiceType type) {
    return copyWith(serviceType: type);
  }

  /// Converts name to snake_case.
  String toSnakeCase(String input) {
    if (input.isEmpty) return input;

    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      if (char == char.toUpperCase() && i > 0) {
        buffer.write('_');
      }
      buffer.write(char.toLowerCase());
    }
    return buffer.toString();
  }

  /// Converts name to camelCase.
  String toCamelCase(String input) {
    final words =
        input.split(RegExp(r'[\s_-]')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return input.toLowerCase();

    final firstWord = words.first.toLowerCase();
    final otherWords = words.skip(1).map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    });

    return '$firstWord${otherWords.join()}';
  }

  /// Converts name to PascalCase.
  String toPascalCase(String input) {
    final words =
        input.split(RegExp(r'[\s_-]')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return input;

    return words.map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join();
  }
}

/// Derived template variables representing computed/derived flags and values.
///
/// This class holds all variables that are computed from base variables by planner
/// plugins, including mode flags, platform flags, feature-specific flags, and
/// service-specific flags.
class DerivedTemplateVariables {
  const DerivedTemplateVariables({
    // Mode flags
    this.isProject = false,
    this.isFeature = false,
    this.isService = false,
    this.activeMode,
    // Platform flags
    this.supportsIos = false,
    this.supportsAndroid = false,
    this.supportsWeb = false,
    this.supportsMacos = false,
    this.supportsWindows = false,
    this.supportsLinux = false,
    this.supportsDesktop = false,
    // Feature flags
    this.screenType,
    this.isListScreen = false,
    this.isDetailScreen = false,
    this.isFormScreen = false,
    this.requiresValidation = false,
    this.withNavigation = false,
    this.useRiverpod = false,
    this.useBloc = false,
    this.useCubit = false,
    // Service flags
    this.serviceType,
    this.isApiService = false,
    this.isLocalService = false,
    this.isCacheService = false,
    this.isAnalyticsService = false,
    this.isStorageService = false,
    this.supportsRetry = false,
    this.supportsCaching = false,
    this.supportsInterceptors = false,
    this.generateMocks = false,
    // Naming-derived values
    this.projectName,
    this.feature,
    this.componentName,
    this.projectNameSnake,
    this.projectNameCamel,
    this.projectNamePascal,
    // Template metadata
    this.templateVariant,
    this.minFlutterSdk,
    this.minDartSdk,
    this.flyPackages,
  });

  // Mode flags
  final bool isProject;
  final bool isFeature;
  final bool isService;
  final GenerationMode? activeMode;

  // Platform flags
  final bool supportsIos;
  final bool supportsAndroid;
  final bool supportsWeb;
  final bool supportsMacos;
  final bool supportsWindows;
  final bool supportsLinux;
  final bool supportsDesktop;

  // Feature flags
  final ScreenType? screenType;
  final bool isListScreen;
  final bool isDetailScreen;
  final bool isFormScreen;
  final bool requiresValidation;
  final bool withNavigation;
  final bool useRiverpod;
  final bool useBloc;
  final bool useCubit;

  // Service flags
  final ServiceType? serviceType;
  final bool isApiService;
  final bool isLocalService;
  final bool isCacheService;
  final bool isAnalyticsService;
  final bool isStorageService;
  final bool supportsRetry;
  final bool supportsCaching;
  final bool supportsInterceptors;
  final bool generateMocks;

  // Naming-derived values
  final String? projectName;
  final String? feature;
  final String? componentName;
  final String? projectNameSnake;
  final String? projectNameCamel;
  final String? projectNamePascal;

  // Template metadata
  final String? templateVariant;
  final String? minFlutterSdk;
  final String? minDartSdk;
  final List<String>? flyPackages;

  /// Creates an empty derived variables instance.
  static DerivedTemplateVariables empty() {
    return const DerivedTemplateVariables();
  }

  /// Merges this instance with another, with [other] taking precedence.
  ///
  /// Returns a new instance where non-null values from [other] override
  /// corresponding values from this instance.
  DerivedTemplateVariables merge(DerivedTemplateVariables other) {
    return DerivedTemplateVariables(
      // Mode flags
      isProject: other.isProject,
      isFeature: other.isFeature,
      isService: other.isService,
      activeMode: other.activeMode ?? activeMode,
      // Platform flags
      supportsIos: other.supportsIos,
      supportsAndroid: other.supportsAndroid,
      supportsWeb: other.supportsWeb,
      supportsMacos: other.supportsMacos,
      supportsWindows: other.supportsWindows,
      supportsLinux: other.supportsLinux,
      supportsDesktop: other.supportsDesktop,
      // Feature flags
      screenType: other.screenType ?? screenType,
      isListScreen: other.isListScreen,
      isDetailScreen: other.isDetailScreen,
      isFormScreen: other.isFormScreen,
      requiresValidation: other.requiresValidation,
      withNavigation: other.withNavigation,
      useRiverpod: other.useRiverpod,
      useBloc: other.useBloc,
      useCubit: other.useCubit,
      // Service flags
      serviceType: other.serviceType ?? serviceType,
      isApiService: other.isApiService,
      isLocalService: other.isLocalService,
      isCacheService: other.isCacheService,
      isAnalyticsService: other.isAnalyticsService,
      isStorageService: other.isStorageService,
      supportsRetry: other.supportsRetry,
      supportsCaching: other.supportsCaching,
      supportsInterceptors: other.supportsInterceptors,
      generateMocks: other.generateMocks,
      // Naming-derived values
      projectName: other.projectName ?? projectName,
      feature: other.feature ?? feature,
      componentName: other.componentName ?? componentName,
      projectNameSnake: other.projectNameSnake ?? projectNameSnake,
      projectNameCamel: other.projectNameCamel ?? projectNameCamel,
      projectNamePascal: other.projectNamePascal ?? projectNamePascal,
      // Template metadata
      templateVariant: other.templateVariant ?? templateVariant,
      minFlutterSdk: other.minFlutterSdk ?? minFlutterSdk,
      minDartSdk: other.minDartSdk ?? minDartSdk,
      flyPackages: other.flyPackages ?? flyPackages,
    );
  }

  /// Converts to a Mason variables map.
  ///
  /// Emits all derived variables using the canonical string keys expected by
  /// Mason templates, maintaining backward compatibility.
  Map<String, dynamic> toMasonVars() {
    final result = <String, dynamic>{};

    // Mode flags
    result['is_project'] = isProject;
    result['is_feature'] = isFeature;
    result['is_service'] = isService;
    if (activeMode != null) {
      result['active_mode'] = activeMode!.key;
    }

    // Platform flags
    result['supports_ios'] = supportsIos;
    result['supports_android'] = supportsAndroid;
    result['supports_web'] = supportsWeb;
    result['supports_macos'] = supportsMacos;
    result['supports_windows'] = supportsWindows;
    result['supports_linux'] = supportsLinux;
    result['supports_desktop'] = supportsDesktop;

    // Feature flags
    if (screenType != null) {
      result['screen_type'] = screenType!.key;
      result['is_list_screen'] = isListScreen;
      result['is_detail_screen'] = isDetailScreen;
      result['is_form_screen'] = isFormScreen;
    }
    result['requires_validation'] = requiresValidation;
    result['with_navigation'] = withNavigation;
    result['use_riverpod'] = useRiverpod;
    result['use_bloc'] = useBloc;
    result['use_cubit'] = useCubit;

    // Service flags
    if (serviceType != null) {
      result['service_type'] = serviceType!.key;
      result['is_api_service'] = isApiService;
      result['is_local_service'] = isLocalService;
      result['is_cache_service'] = isCacheService;
      result['is_analytics_service'] = isAnalyticsService;
      result['is_storage_service'] = isStorageService;
    }
    result['supports_retry'] = supportsRetry;
    result['supports_caching'] = supportsCaching;
    result['supports_interceptors'] = supportsInterceptors;
    result['generate_mocks'] = generateMocks;

    // Naming-derived values
    if (projectName != null) result['project_name'] = projectName;
    if (feature != null) result['feature'] = feature;
    if (componentName != null) result['component_name'] = componentName;
    if (projectNameSnake != null) {
      result['project_name_snake'] = projectNameSnake;
    }
    if (projectNameCamel != null) {
      result['project_name_camel'] = projectNameCamel;
    }
    if (projectNamePascal != null) {
      result['project_name_pascal'] = projectNamePascal;
    }

    // Template metadata
    if (templateVariant != null) {
      result['template_variant'] = templateVariant;
    }
    if (minFlutterSdk != null) result['min_flutter_sdk'] = minFlutterSdk;
    if (minDartSdk != null) result['min_dart_sdk'] = minDartSdk;
    if (flyPackages != null) result['fly_packages'] = flyPackages;

    return result;
  }

  /// Creates a copy with updated fields.
  DerivedTemplateVariables copyWith({
    bool? isProject,
    bool? isFeature,
    bool? isService,
    GenerationMode? activeMode,
    bool? supportsIos,
    bool? supportsAndroid,
    bool? supportsWeb,
    bool? supportsMacos,
    bool? supportsWindows,
    bool? supportsLinux,
    bool? supportsDesktop,
    ScreenType? screenType,
    bool? isListScreen,
    bool? isDetailScreen,
    bool? isFormScreen,
    bool? requiresValidation,
    bool? withNavigation,
    bool? useRiverpod,
    bool? useBloc,
    bool? useCubit,
    ServiceType? serviceType,
    bool? isApiService,
    bool? isLocalService,
    bool? isCacheService,
    bool? isAnalyticsService,
    bool? isStorageService,
    bool? supportsRetry,
    bool? supportsCaching,
    bool? supportsInterceptors,
    bool? generateMocks,
    String? projectName,
    String? feature,
    String? componentName,
    String? projectNameSnake,
    String? projectNameCamel,
    String? projectNamePascal,
    String? templateVariant,
    String? minFlutterSdk,
    String? minDartSdk,
    List<String>? flyPackages,
  }) {
    return DerivedTemplateVariables(
      isProject: isProject ?? this.isProject,
      isFeature: isFeature ?? this.isFeature,
      isService: isService ?? this.isService,
      activeMode: activeMode ?? this.activeMode,
      supportsIos: supportsIos ?? this.supportsIos,
      supportsAndroid: supportsAndroid ?? this.supportsAndroid,
      supportsWeb: supportsWeb ?? this.supportsWeb,
      supportsMacos: supportsMacos ?? this.supportsMacos,
      supportsWindows: supportsWindows ?? this.supportsWindows,
      supportsLinux: supportsLinux ?? this.supportsLinux,
      supportsDesktop: supportsDesktop ?? this.supportsDesktop,
      screenType: screenType ?? this.screenType,
      isListScreen: isListScreen ?? this.isListScreen,
      isDetailScreen: isDetailScreen ?? this.isDetailScreen,
      isFormScreen: isFormScreen ?? this.isFormScreen,
      requiresValidation: requiresValidation ?? this.requiresValidation,
      withNavigation: withNavigation ?? this.withNavigation,
      useRiverpod: useRiverpod ?? this.useRiverpod,
      useBloc: useBloc ?? this.useBloc,
      useCubit: useCubit ?? this.useCubit,
      serviceType: serviceType ?? this.serviceType,
      isApiService: isApiService ?? this.isApiService,
      isLocalService: isLocalService ?? this.isLocalService,
      isCacheService: isCacheService ?? this.isCacheService,
      isAnalyticsService: isAnalyticsService ?? this.isAnalyticsService,
      isStorageService: isStorageService ?? this.isStorageService,
      supportsRetry: supportsRetry ?? this.supportsRetry,
      supportsCaching: supportsCaching ?? this.supportsCaching,
      supportsInterceptors: supportsInterceptors ?? this.supportsInterceptors,
      generateMocks: generateMocks ?? this.generateMocks,
      projectName: projectName ?? this.projectName,
      feature: feature ?? this.feature,
      componentName: componentName ?? this.componentName,
      projectNameSnake: projectNameSnake ?? this.projectNameSnake,
      projectNameCamel: projectNameCamel ?? this.projectNameCamel,
      projectNamePascal: projectNamePascal ?? this.projectNamePascal,
      templateVariant: templateVariant ?? this.templateVariant,
      minFlutterSdk: minFlutterSdk ?? this.minFlutterSdk,
      minDartSdk: minDartSdk ?? this.minDartSdk,
      flyPackages: flyPackages ?? this.flyPackages,
    );
  }
}

