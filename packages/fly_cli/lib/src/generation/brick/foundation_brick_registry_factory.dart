import 'package:fly_brick_composer/fly_brick_composer.dart';
import 'package:fly_cli/src/generation/foundation/foundation_domain/foundation_instance_configs.dart';

/// Factory for creating a BrickRegistry configured with Fly foundation bricks.
class FoundationBrickRegistryFactory {
  /// Creates a BrickRegistry with all foundation bricks registered.
  ///
  /// Registers:
  /// - project (project template brick)
  /// - feature (feature component brick)
  /// - service (service component brick)
  static BrickRegistry create() {
    final registry = BrickRegistry()

    // Project template brick
    ..register(
      BrickDefinition(
        id: 'project',
        kind: BrickKind.projectTemplate,
        dependencies: [],
        buildVars: (variables, instanceConfig) {
          // Create a new map to avoid modifying unmodifiable maps
          return Map<String, dynamic>.from(variables.toMap());
        },
      ),
    )

    // Feature component brick
    ..register(
      BrickDefinition(
        id: 'feature',
        kind: BrickKind.featureComponent,
        dependencies: ['project'],
        buildVars: (variables, instanceConfig) {
          // Create a new map to avoid modifying unmodifiable maps
          final vars = Map<String, dynamic>.from(variables.toMap());
          if (instanceConfig != null) {
            final featureConfig = FeatureInstanceConfig.fromInstanceConfig(
              instanceConfig,
            );
            vars['name'] = featureConfig.name;
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
      ),
    )

    // Service component brick
    ..register(
      BrickDefinition(
        id: 'service',
        kind: BrickKind.serviceComponent,
        dependencies: ['project'],
        buildVars: (variables, instanceConfig) {
          // Create a new map to avoid modifying unmodifiable maps
          final vars = Map<String, dynamic>.from(variables.toMap());
          if (instanceConfig != null) {
            final serviceConfig = ServiceInstanceConfig.fromInstanceConfig(
              instanceConfig,
            );
            vars['name'] = serviceConfig.name;
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
      ),
    );

    return registry;
  }
}
