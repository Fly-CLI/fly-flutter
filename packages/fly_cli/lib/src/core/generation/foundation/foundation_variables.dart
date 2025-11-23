import 'package:fly_cli/src/core/generation/foundation/foundation_enums.dart';
import 'package:fly_cli/src/core/generation/utils/mason_variable_keys.dart';

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
    final name = vars.getVar<String>(MasonVarKey.name) ?? 'unnamed';
    final organization =
        vars.getVar<String>(MasonVarKey.organization) ?? 'com.example';
    final generationModeStr = vars.getVar<String>(MasonVarKey.generationMode);
    final generationMode = generationModeStr != null
        ? GenerationMode.fromKey(generationModeStr)
        : GenerationMode.project;
    final platformsRaw =
        vars.getVar<List>(MasonVarKey.platforms) ?? ['ios', 'android'];
    final platforms = <PlatformType>[];
    for (final key in platformsRaw) {
      if (key == null) continue;
      final keyStr = key.toString().toLowerCase().trim();
      if (keyStr.isEmpty) continue;
      try {
        platforms.add(PlatformType.fromKey(keyStr));
      } catch (_) {
        // Skip invalid platforms
      }
    }
    final finalPlatforms = platforms.isEmpty
        ? [PlatformType.ios, PlatformType.android]
        : platforms;

    return BaseTemplateVariables(
      name: name,
      organization: organization,
      generationMode: generationMode,
      platforms: finalPlatforms,
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
      flyPackages: vars.getVar<List>(MasonVarKey.flyPackages)?.cast<String>() ??
          defaultFlyPackages,
      serviceRetry: vars.getVar<bool>(MasonVarKey.withRetryLogic) ?? false,
      serviceCaching: vars.getVar<bool>(MasonVarKey.withCaching) ?? false,
      serviceInterceptors:
          vars.getVar<bool>(MasonVarKey.withInterceptors) ?? false,
      serviceMocks: vars.getVar<bool>(MasonVarKey.withMocks) ?? false,
      featureViewModel: vars.getVar<bool>(MasonVarKey.withViewModel) ?? true,
      featureValidation: vars.getVar<bool>(MasonVarKey.withValidation) ?? false,
      featureNavigation: vars.getVar<bool>(MasonVarKey.withNavigation) ?? false,
      stateManagement: StateManagement.tryFromKey(
        vars.getVar<String>(MasonVarKey.stateMgmt),
      ),
      screenType:
          ScreenType.tryFromKey(vars.getVar<String>(MasonVarKey.screenType)),
      serviceType: ServiceType.tryFromKey(
        vars.getVar<String>(MasonVarKey.serviceType),
        defaultValue: ServiceType.api,
      ),
      apiBaseUrl: vars.getVar<String>(MasonVarKey.apiBaseUrl),
      preset: vars.getVar<String>(MasonVarKey.preset),
    );
  }

  /// Converts to a Mason variables map.
  ///
  /// Emits all fields using the canonical string keys expected by Mason templates.
  Map<String, dynamic> toMasonVars() {
    return {
      MasonVarKey.name.key: name,
      MasonVarKey.organization.key: organization,
      MasonVarKey.generationMode.key: generationMode.key,
      MasonVarKey.platforms.key: platforms.map((p) => p.key).toList(),
      MasonVarKey.description.key: description,
      MasonVarKey.templateVariant.key: templateVariant,
      MasonVarKey.minFlutterSdk.key: minFlutterSdk,
      MasonVarKey.minDartSdk.key: minDartSdk,
      MasonVarKey.withTests.key: withTests,
      MasonVarKey.withDocs.key: withDocs,
      MasonVarKey.withMcp.key: withMcp,
      MasonVarKey.codeGeneration.key: codeGeneration,
      MasonVarKey.aiIntegration.key: aiIntegration,
      MasonVarKey.flyPackages.key: flyPackages,
      MasonVarKey.withRetryLogic.key: serviceRetry,
      MasonVarKey.withCaching.key: serviceCaching,
      MasonVarKey.withInterceptors.key: serviceInterceptors,
      MasonVarKey.withMocks.key: serviceMocks,
      MasonVarKey.withViewModel.key: featureViewModel,
      MasonVarKey.withValidation.key: featureValidation,
      MasonVarKey.withNavigation.key: featureNavigation,
      MasonVarKey.stateMgmt.key: stateManagement.key,
      if (screenType != null) MasonVarKey.screenType.key: screenType!.key,
      if (serviceType != null) MasonVarKey.serviceType.key: serviceType!.key,
      if (apiBaseUrl != null) MasonVarKey.apiBaseUrl.key: apiBaseUrl,
      if (preset != null) MasonVarKey.preset.key: preset,
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
    result[MasonVarKey.isProject.key] = isProject;
    result[MasonVarKey.isFeature.key] = isFeature;
    result[MasonVarKey.isService.key] = isService;
    if (activeMode != null) {
      result[MasonVarKey.activeMode.key] = activeMode!.key;
    }

    // Platform flags
    result[MasonVarKey.supportsIos.key] = supportsIos;
    result[MasonVarKey.supportsAndroid.key] = supportsAndroid;
    result[MasonVarKey.supportsWeb.key] = supportsWeb;
    result[MasonVarKey.supportsMacos.key] = supportsMacos;
    result[MasonVarKey.supportsWindows.key] = supportsWindows;
    result[MasonVarKey.supportsLinux.key] = supportsLinux;
    result[MasonVarKey.supportsDesktop.key] = supportsDesktop;

    // Feature flags
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

    // Service flags
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

    // Naming-derived values
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

    // Template metadata
    if (templateVariant != null) {
      result[MasonVarKey.templateVariant.key] = templateVariant;
    }
    if (minFlutterSdk != null)
      result[MasonVarKey.minFlutterSdk.key] = minFlutterSdk;
    if (minDartSdk != null) result[MasonVarKey.minDartSdk.key] = minDartSdk;
    if (flyPackages != null) result[MasonVarKey.flyPackages.key] = flyPackages;

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
