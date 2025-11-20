import 'package:fly_foundation_planning/fly_foundation_planning.dart';

/// Creates a test brick registry for use in planning package tests.
///
/// Registers test bricks that mirror foundation bricks but are domain-agnostic
/// for testing the core planning infrastructure.
BrickRegistry createTestBrickRegistry() {
  final registry = BrickRegistry()

  // Test project template brick
  ..register(BrickDefinition(
    id: 'fly_foundation_project',
    kind: BrickKind.projectTemplate,
    dependencies: [],
    buildVars: (variables, instanceConfig) {
      return variables.toMap();
    },
  ))

  // Test feature component brick
  ..register(BrickDefinition(
    id: 'fly_foundation_feature',
    kind: BrickKind.featureComponent,
    dependencies: ['fly_foundation_project'],
    buildVars: (variables, instanceConfig) {
      // Create a new map to avoid modifying unmodifiable maps
      final vars = Map<String, dynamic>.from(variables.toMap());
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
  ))

  // Test service component brick
  ..register(BrickDefinition(
    id: 'fly_foundation_service',
    kind: BrickKind.serviceComponent,
    dependencies: ['fly_foundation_project'],
    buildVars: (variables, instanceConfig) {
      // Create a new map to avoid modifying unmodifiable maps
      final vars = Map<String, dynamic>.from(variables.toMap());
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
  ))

  // Test brick for workflow tests
  ..register(BrickDefinition(
    id: 'test_brick',
    kind: BrickKind.utility,
    dependencies: [],
    buildVars: (variables, instanceConfig) {
      return variables.toMap();
    },
  ));

  return registry;
}

