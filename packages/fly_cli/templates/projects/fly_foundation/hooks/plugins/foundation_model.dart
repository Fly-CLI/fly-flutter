import 'package:mason/mason.dart';
import 'mason_variable_keys.dart';
import 'hook_exception.dart';

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
    final modeStr =
        vars.getVar<String>(MasonVarKey.generationMode)?.toLowerCase();
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
    final screenTypeStr =
        vars.getVar<String>(MasonVarKey.screenType)?.toLowerCase();
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
    final serviceTypeStr =
        vars.getVar<String>(MasonVarKey.serviceType)?.toLowerCase();
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
    final platformsRaw =
        vars.getVar<List>(MasonVarKey.platforms) ?? ['ios', 'android'];
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
    return platforms.isEmpty
        ? [PlatformType.ios, PlatformType.android]
        : platforms;
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
    final stateMgmtStr =
        vars.getVar<String>(MasonVarKey.stateMgmt)?.toLowerCase();
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
    final name = vars.getVar<String>(MasonVarKey.name) ?? 'unnamed';
    final organization =
        vars.getVar<String>(MasonVarKey.organization) ?? 'com.example';
    final generationMode = GenerationMode.fromVars(vars);
    final platforms = PlatformType.fromVars(vars);

    return BaseTemplateVariables(
      name: name,
      organization: organization,
      generationMode: generationMode,
      platforms: platforms,
      description: vars.getVar<String>(MasonVarKey.description) ??
          'A new Fly foundation project',
      templateVariant:
          vars.getVar<String>(MasonVarKey.templateVariant) ?? 'foundation',
      minFlutterSdk: vars.getVar<String>(MasonVarKey.minFlutterSdk) ?? '3.10.0',
      minDartSdk: vars.getVar<String>(MasonVarKey.minDartSdk) ?? '3.0.0',
      withTests: vars.getVar<bool>(MasonVarKey.withTests) ?? true,
      withDocs: vars.getVar<bool>(MasonVarKey.withDocs) ?? true,
      withMcp: vars.getVar<bool>(MasonVarKey.withMcp) ?? true,
      codeGeneration: vars.getVar<bool>(MasonVarKey.codeGeneration) ?? true,
      aiIntegration: vars.getVar<bool>(MasonVarKey.aiIntegration) ?? true,
      serviceRetry: vars.getVar<bool>(MasonVarKey.withRetryLogic) ?? false,
      serviceCaching: vars.getVar<bool>(MasonVarKey.withCaching) ?? false,
      serviceInterceptors:
          vars.getVar<bool>(MasonVarKey.withInterceptors) ?? false,
      serviceMocks: vars.getVar<bool>(MasonVarKey.withMocks) ?? false,
      featureViewModel: vars.getVar<bool>(MasonVarKey.withViewModel) ?? true,
      featureValidation: vars.getVar<bool>(MasonVarKey.withValidation) ?? false,
      featureNavigation: vars.getVar<bool>(MasonVarKey.withNavigation) ?? false,
      stateManagement: StateManagement.fromVars(vars),
      screenType: ScreenType.fromVars(vars),
      serviceType: ServiceType.fromVars(vars),
      apiBaseUrl: vars.getVar<String>(MasonVarKey.apiBaseUrl),
      preset: vars.getVar<String>(MasonVarKey.preset),
    );
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

    result[MasonVarKey.isProject.key] = isProject;
    result[MasonVarKey.isFeature.key] = isFeature;
    result[MasonVarKey.isService.key] = isService;
    if (activeMode != null) {
      result[MasonVarKey.activeMode.key] = activeMode!.key;
    }

    result[MasonVarKey.supportsIos.key] = supportsIos;
    result[MasonVarKey.supportsAndroid.key] = supportsAndroid;
    result[MasonVarKey.supportsWeb.key] = supportsWeb;
    result[MasonVarKey.supportsMacos.key] = supportsMacos;
    result[MasonVarKey.supportsWindows.key] = supportsWindows;
    result[MasonVarKey.supportsLinux.key] = supportsLinux;
    result[MasonVarKey.supportsDesktop.key] = supportsDesktop;

    if (screenType != null) {
      result[MasonVarKey.screenType.key] = screenType!.key;
      result[MasonVarKey.isListScreen.key] = isListScreen;
      result[MasonVarKey.isDetailScreen.key] = isDetailScreen;
      result[MasonVarKey.isFormScreen.key] = isFormScreen;
    }
    result[MasonVarKey.requiresValidation.key] = requiresValidation;
    result[MasonVarKey.withNavigation.key] = withNavigation;
    result[MasonVarKey.useRiverpod.key] = useRiverpod;
    result[MasonVarKey.useBloc.key] = useBloc;
    result[MasonVarKey.useCubit.key] = useCubit;

    if (serviceType != null) {
      result[MasonVarKey.serviceType.key] = serviceType!.key;
      result[MasonVarKey.isApiService.key] = isApiService;
      result[MasonVarKey.isLocalService.key] = isLocalService;
      result[MasonVarKey.isCacheService.key] = isCacheService;
      result[MasonVarKey.isAnalyticsService.key] = isAnalyticsService;
      result[MasonVarKey.isStorageService.key] = isStorageService;
    }
    result[MasonVarKey.supportsRetry.key] = supportsRetry;
    result[MasonVarKey.supportsCaching.key] = supportsCaching;
    result[MasonVarKey.supportsInterceptors.key] = supportsInterceptors;
    result[MasonVarKey.generateMocks.key] = generateMocks;

    if (projectName != null) result[MasonVarKey.projectName.key] = projectName;
    if (feature != null) result[MasonVarKey.feature.key] = feature;
    if (componentName != null)
      result[MasonVarKey.componentName.key] = componentName;
    if (projectNameSnake != null) {
      result[MasonVarKey.projectNameSnake.key] = projectNameSnake;
    }
    if (projectNameCamel != null) {
      result[MasonVarKey.projectNameCamel.key] = projectNameCamel;
    }
    if (projectNamePascal != null) {
      result[MasonVarKey.projectNamePascal.key] = projectNamePascal;
    }

    if (templateVariant != null) {
      result[MasonVarKey.templateVariant.key] = templateVariant;
    }
    if (minFlutterSdk != null)
      result[MasonVarKey.minFlutterSdk.key] = minFlutterSdk;
    if (minDartSdk != null) result[MasonVarKey.minDartSdk.key] = minDartSdk;
    if (flyPackages != null) result[MasonVarKey.flyPackages.key] = flyPackages;

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
