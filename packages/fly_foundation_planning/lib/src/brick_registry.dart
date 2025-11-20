import 'package:fly_foundation_planning/src/foundation_model.dart';
import 'package:fly_foundation_planning/src/planning_exception.dart';
import 'package:fly_foundation_planning/src/variables/variable_bag.dart';

/// Kind/category of a brick.
enum BrickKind {
  /// Project template brick (e.g., fly_foundation_project).
  projectTemplate,

  /// Feature component brick (e.g., fly_foundation_feature).
  featureComponent,

  /// Service component brick (e.g., fly_foundation_service).
  serviceComponent,

  /// Utility brick (e.g., tooling, scripts).
  utility,

  /// Custom/unknown brick type.
  custom;
}

/// Generic instance configuration for a brick invocation.
///
/// This is a flexible model that can represent any per-instance configuration
/// needed by a brick, with type-specific helpers for common patterns.
class InstanceConfig {
  const InstanceConfig({
    required this.type,
    required this.name,
    this.params = const {},
  });

  /// Type identifier (e.g., 'feature', 'service').
  final String type;

  /// Instance name (e.g., 'home', 'api').
  final String name;

  /// Additional parameters specific to this instance.
  final Map<String, dynamic> params;

  /// Creates from a generic map (e.g., from manifest or CLI).
  factory InstanceConfig.fromMap(Map<String, dynamic> map) {
    return InstanceConfig(
      type: map['type'] as String? ?? '',
      name: map['name'] as String? ?? '',
      params: Map<String, dynamic>.from(map['params'] as Map? ?? {}),
    );
  }

  /// Converts to a map representation.
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'name': name,
      'params': params,
    };
  }
}

/// Helper for feature instance configurations.
class FeatureInstanceConfig {
  const FeatureInstanceConfig({
    required this.name,
    required this.featureKey,
    this.screenType,
    this.withViewModel = true,
    this.withTests = true,
    this.withValidation = false,
    this.withNavigation = false,
  });

  final String name;
  final String featureKey;
  final ScreenType? screenType;
  final bool withViewModel;
  final bool withTests;
  final bool withValidation;
  final bool withNavigation;

  /// Creates from a generic InstanceConfig.
  factory FeatureInstanceConfig.fromInstanceConfig(InstanceConfig config) {
    final params = config.params;
    return FeatureInstanceConfig(
      name: config.name,
      featureKey: params['feature'] as String? ?? 'core',
      screenType: params['screen_type'] != null
          ? ScreenType.fromKey(params['screen_type'] as String)
          : null,
      withViewModel: params['with_viewmodel'] as bool? ?? true,
      withTests: params['with_tests'] as bool? ?? true,
      withValidation: params['with_validation'] as bool? ?? false,
      withNavigation: params['with_navigation'] as bool? ?? false,
    );
  }

  /// Converts to InstanceConfig.
  InstanceConfig toInstanceConfig() {
    return InstanceConfig(
      type: 'feature',
      name: name,
      params: {
        'feature': featureKey,
        if (screenType != null) 'screen_type': screenType!.key,
        'with_viewmodel': withViewModel,
        'with_tests': withTests,
        'with_validation': withValidation,
        'with_navigation': withNavigation,
      },
    );
  }
}

/// Helper for service instance configurations.
class ServiceInstanceConfig {
  const ServiceInstanceConfig({
    required this.name,
    required this.featureKey,
    required this.serviceType,
    this.withTests = true,
    this.withMocks = false,
    this.withInterceptors = false,
    this.withRetryLogic = false,
    this.withCaching = false,
    this.baseUrl,
  });

  final String name;
  final String featureKey;
  final ServiceType serviceType;
  final bool withTests;
  final bool withMocks;
  final bool withInterceptors;
  final bool withRetryLogic;
  final bool withCaching;
  final String? baseUrl;

  /// Creates from a generic InstanceConfig.
  factory ServiceInstanceConfig.fromInstanceConfig(InstanceConfig config) {
    final params = config.params;
    return ServiceInstanceConfig(
      name: config.name,
      featureKey: params['feature'] as String? ?? 'core',
      serviceType: params['service_type'] != null
          ? ServiceType.fromKey(params['service_type'] as String)
          : ServiceType.api,
      withTests: params['with_tests'] as bool? ?? true,
      withMocks: params['with_mocks'] as bool? ?? false,
      withInterceptors: params['with_interceptors'] as bool? ?? false,
      withRetryLogic: params['with_retry_logic'] as bool? ?? false,
      withCaching: params['with_caching'] as bool? ?? false,
      baseUrl:
          params['base_url'] as String? ?? params['api_base_url'] as String?,
    );
  }

  /// Converts to InstanceConfig.
  InstanceConfig toInstanceConfig() {
    return InstanceConfig(
      type: 'service',
      name: name,
      params: {
        'feature': featureKey,
        'service_type': serviceType.key,
        'with_tests': withTests,
        'with_mocks': withMocks,
        'with_interceptors': withInterceptors,
        'with_retry_logic': withRetryLogic,
        'with_caching': withCaching,
        if (baseUrl != null) 'api_base_url': baseUrl,
      },
    );
  }
}

/// Global variables available to all bricks during planning.
///
/// This is a wrapper around VariableBag that provides convenient access
/// to derived variables and base template variables.
class GlobalVars {
  const GlobalVars({
    required this.variables,
    required this.base,
  });

  /// Derived variables from the variable pipeline.
  final VariableBag variables;

  /// Base template variables.
  final BaseTemplateVariables base;

  /// Converts to a Mason variables map.
  Map<String, dynamic> toMasonVars() {
    final result = variables.toMap();
    // Ensure base variables are included (they may already be in variables)
    result['name'] = base.name;
    result['organization'] = base.organization;
    result['description'] = base.description;
    result['generation_mode'] = base.generationMode.key;
    return result;
  }
}

/// Definition of a brick, including its metadata and behavior.
class BrickDefinition {
  const BrickDefinition({
    required this.id,
    required this.kind,
    this.requiredCapabilities = const [],
    this.dependencies = const [],
    required this.buildVars,
    this.resolveTargetDir,
  });

  /// Unique brick identifier (e.g., 'fly_foundation_project').
  final String id;

  /// Kind/category of this brick.
  final BrickKind kind;

  /// List of capabilities this brick requires from other bricks.
  final List<String> requiredCapabilities;

  /// List of brick IDs this brick depends on.
  final List<String> dependencies;

  /// Function to build Mason variables for this brick from variable bag and instance config.
  final Map<String, dynamic> Function(VariableBag variables, InstanceConfig?) buildVars;

  /// Optional function to resolve the target directory for this brick.
  ///
  /// If null, the brick will use the root output directory.
  final String? Function(VariableBag variables, InstanceConfig?)? resolveTargetDir;
}

/// Registry of all known bricks.
///
/// This registry holds all BrickDefinitions and provides lookup methods.
/// Bricks are registered in code for now; in the future, this could be data-driven.
class BrickRegistry {
  final Map<String, BrickDefinition> _bricks = {};
  final Map<BrickKind, List<BrickDefinition>> _byKind = {};

  /// Creates an empty registry.
  BrickRegistry();

  /// Creates a registry with default foundation bricks registered.
  factory BrickRegistry.defaultRegistry() {
    final registry = BrickRegistry();
    registry._registerFoundationBricks();
    return registry;
  }

  /// Registers a brick definition.
  void register(BrickDefinition definition) {
    _bricks[definition.id] = definition;
    _byKind.putIfAbsent(definition.kind, () => []).add(definition);
  }

  /// Gets a brick by its ID.
  BrickDefinition? getById(String id) => _bricks[id];

  /// Gets all bricks of a specific kind.
  List<BrickDefinition> getByKind(BrickKind kind) => _byKind[kind] ?? const [];

  /// Gets all registered bricks.
  List<BrickDefinition> get all => _bricks.values.toList();

  /// Validates that a brick ID exists.
  void validateBrickId(String brickId) {
    if (!_bricks.containsKey(brickId)) {
      throw PlanningException(
        'Unknown brick ID: "$brickId". '
        'Available bricks: ${_bricks.keys.join(", ")}.',
      );
    }
  }

  /// Registers the default foundation bricks.
  void _registerFoundationBricks() {
    // Project template brick
    register(BrickDefinition(
      id: 'fly_foundation_project',
      kind: BrickKind.projectTemplate,
      dependencies: [],
      buildVars: (variables, instanceConfig) {
        return variables.toMap();
      },
    ));

    // Feature component brick
    register(BrickDefinition(
      id: 'fly_foundation_feature',
      kind: BrickKind.featureComponent,
      dependencies: ['fly_foundation_project'],
      buildVars: (variables, instanceConfig) {
        final vars = variables.toMap();
        if (instanceConfig != null) {
          final featureConfig = FeatureInstanceConfig.fromInstanceConfig(
            instanceConfig,
          );
          vars['component_name'] = featureConfig.name;
          vars['feature'] = featureConfig.featureKey;
          if (featureConfig.screenType != null) {
            vars['screen_type'] = featureConfig.screenType!.key;
          }
          vars['with_viewmodel'] = featureConfig.withViewModel;
          vars['with_tests'] = featureConfig.withTests;
          vars['with_validation'] = featureConfig.withValidation;
          vars['with_navigation'] = featureConfig.withNavigation;
        }
        return vars;
      },
      resolveTargetDir: (variables, instanceConfig) {
        if (instanceConfig != null) {
          final featureConfig = FeatureInstanceConfig.fromInstanceConfig(
            instanceConfig,
          );
          return 'lib/features/${featureConfig.featureKey}';
        }
        return null;
      },
    ));

    // Service component brick
    register(BrickDefinition(
      id: 'fly_foundation_service',
      kind: BrickKind.serviceComponent,
      dependencies: ['fly_foundation_project'],
      buildVars: (variables, instanceConfig) {
        final vars = variables.toMap();
        if (instanceConfig != null) {
          final serviceConfig = ServiceInstanceConfig.fromInstanceConfig(
            instanceConfig,
          );
          vars['component_name'] = serviceConfig.name;
          vars['feature'] = serviceConfig.featureKey;
          vars['service_type'] = serviceConfig.serviceType.key;
          vars['with_tests'] = serviceConfig.withTests;
          vars['with_mocks'] = serviceConfig.withMocks;
          vars['with_interceptors'] = serviceConfig.withInterceptors;
          vars['with_retry_logic'] = serviceConfig.withRetryLogic;
          vars['with_caching'] = serviceConfig.withCaching;
          if (serviceConfig.baseUrl != null) {
            vars['api_base_url'] = serviceConfig.baseUrl;
          }
        }
        return vars;
      },
      resolveTargetDir: (variables, instanceConfig) {
        if (instanceConfig != null) {
          final serviceConfig = ServiceInstanceConfig.fromInstanceConfig(
            instanceConfig,
          );
          return 'lib/services/${serviceConfig.featureKey}';
        }
        return null;
      },
    ),);
  }
}
