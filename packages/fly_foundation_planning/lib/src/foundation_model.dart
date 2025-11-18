import 'package:fly_foundation_planning/src/mason_variable_keys.dart';
import 'package:fly_foundation_planning/src/planning_exception.dart';

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
        throw PlanningException(
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
        throw PlanningException(
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
        throw PlanningException(
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
        throw PlanningException(
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
      } on PlanningException {
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
        throw PlanningException(
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

