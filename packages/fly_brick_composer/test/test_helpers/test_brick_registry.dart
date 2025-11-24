import 'package:fly_brick_composer/fly_brick_composer.dart';

/// Creates a test brick registry for use in planning package tests.
///
/// Registers test bricks that mirror bricks but are domain-agnostic
/// for testing the core planning infrastructure.
BrickRegistry createTestBrickRegistry() {
  final registry = BrickRegistry()

  // Test project template brick
  ..register(BrickDefinition(
    id: 'project',
    kind: BrickKind.projectTemplate,
    dependencies: [],
    buildVars: (variables, instanceConfig) {
      return variables.toMap();
    },
  ))

  // Test feature component brick
  ..register(BrickDefinition(
    id: 'feature',
    kind: BrickKind.featureComponent,
    dependencies: ['project'],
    buildVars: (variables, instanceConfig) {
      // Create a new map to avoid modifying unmodifiable maps
      final vars = Map<String, dynamic>.from(variables.toMap());
      if (instanceConfig != null) {
        // Use generic InstanceConfig directly (domain-specific helpers are in CLI)
        vars['component_name'] = instanceConfig.name;
        vars['feature'] = instanceConfig.params['feature'] as String? ?? 'core';
        if (instanceConfig.params['screen_type'] != null) {
          vars['screen_type'] = instanceConfig.params['screen_type'];
        }
        vars['with_viewmodel'] = instanceConfig.params['with_viewmodel'] as bool? ?? true;
        vars['with_tests'] = instanceConfig.params['with_tests'] as bool? ?? true;
        vars['with_validation'] = instanceConfig.params['with_validation'] as bool? ?? false;
        vars['with_navigation'] = instanceConfig.params['with_navigation'] as bool? ?? false;
      }
      return vars;
    },
    resolveTargetDir: (variables, instanceConfig) {
      if (instanceConfig != null) {
        final featureKey = instanceConfig.params['feature'] as String? ?? 'core';
        return 'lib/features/$featureKey';
      }
      return null;
    },
  ))

  // Test service component brick
  ..register(BrickDefinition(
    id: 'service',
    kind: BrickKind.serviceComponent,
    dependencies: ['project'],
    buildVars: (variables, instanceConfig) {
      // Create a new map to avoid modifying unmodifiable maps
      final vars = Map<String, dynamic>.from(variables.toMap());
      if (instanceConfig != null) {
        // Use generic InstanceConfig directly (domain-specific helpers are in CLI)
        vars['component_name'] = instanceConfig.name;
        vars['feature'] = instanceConfig.params['feature'] as String? ?? 'core';
        vars['service_type'] = instanceConfig.params['service_type'] as String? ?? 'api';
        vars['with_tests'] = instanceConfig.params['with_tests'] as bool? ?? true;
        vars['with_mocks'] = instanceConfig.params['with_mocks'] as bool? ?? false;
        vars['with_interceptors'] = instanceConfig.params['with_interceptors'] as bool? ?? false;
        vars['with_retry_logic'] = instanceConfig.params['with_retry_logic'] as bool? ?? false;
        vars['with_caching'] = instanceConfig.params['with_caching'] as bool? ?? false;
        if (instanceConfig.params['api_base_url'] != null) {
          vars['api_base_url'] = instanceConfig.params['api_base_url'];
        }
      }
      return vars;
    },
    resolveTargetDir: (variables, instanceConfig) {
      if (instanceConfig != null) {
        final featureKey = instanceConfig.params['feature'] as String? ?? 'core';
        return 'lib/services/$featureKey';
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

