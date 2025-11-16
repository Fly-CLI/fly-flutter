import 'package:mason/mason.dart';

/// Hook-local typedef for Mason variables map.
typedef Vars = Map<String, dynamic>;

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
        throw HookException(
          'Invalid generation_mode: "$key". Must be one of: project, feature, service.',
        );
    }
  }

  /// Parses generation_mode from vars and returns the corresponding enum.
  static GenerationMode fromVars(Vars vars) {
    final modeStr = (vars['generation_mode'] as String?)?.toLowerCase();
    if (modeStr == null || modeStr.isEmpty) {
      return GenerationMode.project; // Default
    }
    return fromKey(modeStr);
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
        throw HookException(
          'Invalid screen_type: "$key". Must be one of: list, detail, form, auth, settings.',
        );
    }
  }

  /// Parses screen_type from vars.
  static ScreenType? fromVars(Vars vars) {
    final screenTypeStr = (vars['screen_type'] as String?)?.toLowerCase();
    if (screenTypeStr == null || screenTypeStr.isEmpty) {
      return null;
    }
    return fromKey(screenTypeStr);
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
        throw HookException(
          'Invalid service_type: "$key". Must be one of: api, local, cache, analytics, storage.',
        );
    }
  }

  /// Parses service_type from vars.
  static ServiceType? fromVars(Vars vars) {
    final serviceTypeStr = (vars['service_type'] as String?)?.toLowerCase();
    if (serviceTypeStr == null || serviceTypeStr.isEmpty) {
      return null;
    }
    return fromKey(serviceTypeStr);
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
        throw HookException(
          'Invalid platform: "$key". Must be one of: ios, android, web, macos, windows, linux.',
        );
    }
  }

  /// Parses a list of platform strings into [PlatformType] values.
  static List<PlatformType> fromVars(Vars vars) {
    final platformsRaw = (vars['platforms'] as List?) ?? ['ios', 'android'];
    final platforms = <PlatformType>[];
    for (final key in platformsRaw) {
      if (key == null) continue;
      final keyStr = key.toString().toLowerCase().trim();
      if (keyStr.isEmpty) continue;
      try {
        platforms.add(fromKey(keyStr));
      } on HookException {
        // Skip invalid platforms
      }
    }
    return platforms.isEmpty ? [PlatformType.ios, PlatformType.android] : platforms;
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
        throw HookException(
          'Invalid state_mgmt: "$key". Must be one of: riverpod, bloc, cubit.',
        );
    }
  }

  /// Parses state_mgmt from vars.
  static StateManagement fromVars(Vars vars) {
    final stateMgmtStr = (vars['state_mgmt'] as String?)?.toLowerCase();
    if (stateMgmtStr == null || stateMgmtStr.isEmpty) {
      return StateManagement.riverpod; // Default
    }
    return fromKey(stateMgmtStr);
  }
}

/// Base template variables representing the core input variables.
///
/// This is a simplified version for hook context that works with Vars maps.
class BaseTemplateVariables {
  const BaseTemplateVariables({
    required this.name,
    required this.organization,
    required this.generationMode,
    required this.platforms,
    this.description = '',
    this.templateVariant = 'foundation',
    this.minFlutterSdk = '3.10.0',
    this.minDartSdk = '3.0.0',
    this.withTests = true,
    this.withDocs = true,
    this.withMcp = true,
    this.codeGeneration = true,
    this.aiIntegration = true,
    this.serviceRetry = false,
    this.serviceCaching = false,
    this.serviceInterceptors = false,
    this.serviceMocks = false,
    this.featureViewModel = true,
    this.featureValidation = false,
    this.featureNavigation = false,
    this.stateManagement = StateManagement.riverpod,
    this.screenType,
    this.serviceType,
    this.apiBaseUrl,
    this.preset,
  });

  final String name;
  final String organization;
  final GenerationMode generationMode;
  final List<PlatformType> platforms;
  final String description;
  final String templateVariant;
  final String minFlutterSdk;
  final String minDartSdk;
  final bool withTests;
  final bool withDocs;
  final bool withMcp;
  final bool codeGeneration;
  final bool aiIntegration;
  final bool serviceRetry;
  final bool serviceCaching;
  final bool serviceInterceptors;
  final bool serviceMocks;
  final bool featureViewModel;
  final bool featureValidation;
  final bool featureNavigation;
  final StateManagement stateManagement;
  final ScreenType? screenType;
  final ServiceType? serviceType;
  final String? apiBaseUrl;
  final String? preset;

  /// Creates [BaseTemplateVariables] from a Mason variables map.
  factory BaseTemplateVariables.fromVars(Vars vars) {
    final name = (vars['name'] as String?) ?? 'unnamed';
    final organization = (vars['organization'] as String?) ?? 'com.example';
    final generationMode = GenerationMode.fromVars(vars);
    final platforms = PlatformType.fromVars(vars);

    return BaseTemplateVariables(
      name: name,
      organization: organization,
      generationMode: generationMode,
      platforms: platforms,
      description: (vars['description'] as String?) ?? 'A new Fly foundation project',
      templateVariant: (vars['template_variant'] as String?) ?? 'foundation',
      minFlutterSdk: (vars['min_flutter_sdk'] as String?) ?? '3.10.0',
      minDartSdk: (vars['min_dart_sdk'] as String?) ?? '3.0.0',
      withTests: vars['with_tests'] as bool? ?? true,
      withDocs: vars['with_docs'] as bool? ?? true,
      withMcp: vars['with_mcp'] as bool? ?? true,
      codeGeneration: vars['code_generation'] as bool? ?? true,
      aiIntegration: vars['ai_integration'] as bool? ?? true,
      serviceRetry: vars['with_retry_logic'] as bool? ?? false,
      serviceCaching: vars['with_caching'] as bool? ?? false,
      serviceInterceptors: vars['with_interceptors'] as bool? ?? false,
      serviceMocks: vars['with_mocks'] as bool? ?? false,
      featureViewModel: vars['with_viewmodel'] as bool? ?? true,
      featureValidation: vars['with_validation'] as bool? ?? false,
      featureNavigation: vars['with_navigation'] as bool? ?? false,
      stateManagement: StateManagement.fromVars(vars),
      screenType: ScreenType.fromVars(vars),
      serviceType: ServiceType.fromVars(vars),
      apiBaseUrl: vars['api_base_url'] as String?,
      preset: vars['preset'] as String?,
    );
  }
}

/// Derived template variables representing computed/derived flags and values.
class DerivedTemplateVariables {
  const DerivedTemplateVariables({
    this.isProject = false,
    this.isFeature = false,
    this.isService = false,
    this.activeMode,
    this.supportsIos = false,
    this.supportsAndroid = false,
    this.supportsWeb = false,
    this.supportsMacos = false,
    this.supportsWindows = false,
    this.supportsLinux = false,
    this.supportsDesktop = false,
    this.screenType,
    this.isListScreen = false,
    this.isDetailScreen = false,
    this.isFormScreen = false,
    this.requiresValidation = false,
    this.withNavigation = false,
    this.useRiverpod = false,
    this.useBloc = false,
    this.useCubit = false,
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
    this.projectName,
    this.feature,
    this.componentName,
    this.projectNameSnake,
    this.projectNameCamel,
    this.projectNamePascal,
    this.templateVariant,
    this.minFlutterSdk,
    this.minDartSdk,
    this.flyPackages,
  });

  final bool isProject;
  final bool isFeature;
  final bool isService;
  final GenerationMode? activeMode;
  final bool supportsIos;
  final bool supportsAndroid;
  final bool supportsWeb;
  final bool supportsMacos;
  final bool supportsWindows;
  final bool supportsLinux;
  final bool supportsDesktop;
  final ScreenType? screenType;
  final bool isListScreen;
  final bool isDetailScreen;
  final bool isFormScreen;
  final bool requiresValidation;
  final bool withNavigation;
  final bool useRiverpod;
  final bool useBloc;
  final bool useCubit;
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
  final String? projectName;
  final String? feature;
  final String? componentName;
  final String? projectNameSnake;
  final String? projectNameCamel;
  final String? projectNamePascal;
  final String? templateVariant;
  final String? minFlutterSdk;
  final String? minDartSdk;
  final List<String>? flyPackages;

  static DerivedTemplateVariables empty() {
    return const DerivedTemplateVariables();
  }

  DerivedTemplateVariables merge(DerivedTemplateVariables other) {
    return DerivedTemplateVariables(
      isProject: other.isProject,
      isFeature: other.isFeature,
      isService: other.isService,
      activeMode: other.activeMode ?? activeMode,
      supportsIos: other.supportsIos,
      supportsAndroid: other.supportsAndroid,
      supportsWeb: other.supportsWeb,
      supportsMacos: other.supportsMacos,
      supportsWindows: other.supportsWindows,
      supportsLinux: other.supportsLinux,
      supportsDesktop: other.supportsDesktop,
      screenType: other.screenType ?? screenType,
      isListScreen: other.isListScreen,
      isDetailScreen: other.isDetailScreen,
      isFormScreen: other.isFormScreen,
      requiresValidation: other.requiresValidation,
      withNavigation: other.withNavigation,
      useRiverpod: other.useRiverpod,
      useBloc: other.useBloc,
      useCubit: other.useCubit,
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
      projectName: other.projectName ?? projectName,
      feature: other.feature ?? feature,
      componentName: other.componentName ?? componentName,
      projectNameSnake: other.projectNameSnake ?? projectNameSnake,
      projectNameCamel: other.projectNameCamel ?? projectNameCamel,
      projectNamePascal: other.projectNamePascal ?? projectNamePascal,
      templateVariant: other.templateVariant ?? templateVariant,
      minFlutterSdk: other.minFlutterSdk ?? minFlutterSdk,
      minDartSdk: other.minDartSdk ?? minDartSdk,
      flyPackages: other.flyPackages ?? flyPackages,
    );
  }

  Vars toMasonVars() {
    final result = <String, dynamic>{};

    result['is_project'] = isProject;
    result['is_feature'] = isFeature;
    result['is_service'] = isService;
    if (activeMode != null) {
      result['active_mode'] = activeMode!.key;
    }

    result['supports_ios'] = supportsIos;
    result['supports_android'] = supportsAndroid;
    result['supports_web'] = supportsWeb;
    result['supports_macos'] = supportsMacos;
    result['supports_windows'] = supportsWindows;
    result['supports_linux'] = supportsLinux;
    result['supports_desktop'] = supportsDesktop;

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

    if (templateVariant != null) {
      result['template_variant'] = templateVariant;
    }
    if (minFlutterSdk != null) result['min_flutter_sdk'] = minFlutterSdk;
    if (minDartSdk != null) result['min_dart_sdk'] = minDartSdk;
    if (flyPackages != null) result['fly_packages'] = flyPackages;

    return result;
  }

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

