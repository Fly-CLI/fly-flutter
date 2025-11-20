import 'package:fly_foundation_planning/src/foundation_model.dart';
import 'package:fly_foundation_planning/src/logger.dart';
import 'package:fly_foundation_planning/src/planning_exception.dart';
import 'package:fly_foundation_planning/src/variables/generation_context.dart';
import 'package:fly_foundation_planning/src/variables/variable_bag.dart';
import 'package:fly_foundation_planning/src/variables/variable_deriver.dart';
import 'package:fly_foundation_planning/src/variables/variable_pipeline.dart';

/// Simple test deriver that sets a basic variable.
class TestBasicDeriver implements VariableDeriver {
  const TestBasicDeriver();

  @override
  String get id => 'test_basic';

  @override
  bool supports(GenerationContext ctx) => true;

  @override
  VariableBag derive(
    GenerationContext ctx,
    VariableBag current,
    PlanningLogger logger,
  ) {
    final name = ctx.rawVars['name'] as String? ?? 'test';
    return current.set('name', name);
  }
}

/// Test deriver that sets mode-specific flags.
class TestModeDeriver implements VariableDeriver {
  const TestModeDeriver();

  @override
  String get id => 'test_mode';

  @override
  bool supports(GenerationContext ctx) => true;

  @override
  VariableBag derive(
    GenerationContext ctx,
    VariableBag current,
    PlanningLogger logger,
  ) {
    switch (ctx.mode) {
      case GenerationMode.project:
        return current.set('is_project', true);
      case GenerationMode.feature:
        return current.set('is_feature', true);
      case GenerationMode.service:
        return current.set('is_service', true);
    }
  }
}

/// Test deriver that sets platform flags.
class TestPlatformDeriver implements VariableDeriver {
  const TestPlatformDeriver();

  @override
  String get id => 'test_platform';

  @override
  bool supports(GenerationContext ctx) => true;

  @override
  VariableBag derive(
    GenerationContext ctx,
    VariableBag current,
    PlanningLogger logger,
  ) {
    final platforms = ctx.rawVars['platforms'] as List? ?? ['ios', 'android'];
    var bag = current;
    for (final platform in platforms) {
      if (platform == 'ios') {
        bag = bag.set('supports_ios', true);
      } else if (platform == 'android') {
        bag = bag.set('supports_android', true);
      } else if (platform == 'macos') {
        bag = bag.set('supports_macos', true);
      } else if (platform == 'windows') {
        bag = bag.set('supports_windows', true);
      } else if (platform == 'linux') {
        bag = bag.set('supports_linux', true);
      }
    }
    return bag;
  }
}

/// Test deriver that sets preset-based configuration.
class TestPresetDeriver implements VariableDeriver {
  const TestPresetDeriver();

  @override
  String get id => 'test_preset';

  @override
  bool supports(GenerationContext ctx) => true;

  @override
  VariableBag derive(
    GenerationContext ctx,
    VariableBag current,
    PlanningLogger logger,
  ) {
    final preset = ctx.rawVars['preset'] as String? ?? 'starter';
    var bag = current.set('preset', preset);

    // Minimal preset disables some features
    if (preset == 'minimal') {
      bag = bag.set('with_tests', false);
      bag = bag.set('with_docs', false);
    } else {
      // Default to true unless explicitly set
      final withTests = ctx.rawVars['with_tests'] as bool? ?? true;
      final withDocs = ctx.rawVars['with_docs'] as bool? ?? false;
      bag = bag.set('with_tests', withTests);
      bag = bag.set('with_docs', withDocs);
    }

    // Handle code generation flag
    final codeGen = ctx.rawVars['code_generation'] as bool?;
    if (codeGen != null) {
      bag = bag.set('code_generation', codeGen);
      bag = bag.set('build_yaml', codeGen); // Simplified for tests
    }

    // Handle AI integration flag
    final aiIntegration = ctx.rawVars['ai_integration'] as bool?;
    if (aiIntegration != null) {
      bag = bag.set('ai_integration', aiIntegration);
      bag = bag.set('with_mcp', aiIntegration); // Simplified for tests
    }

    return bag;
  }
}

/// Test deriver that sets feature-mode-specific variables.
class TestFeatureModeDeriver implements VariableDeriver {
  const TestFeatureModeDeriver();

  @override
  String get id => 'test_feature_mode';

  @override
  bool supports(GenerationContext ctx) =>
      ctx.mode == GenerationMode.feature;

  @override
  VariableBag derive(
    GenerationContext ctx,
    VariableBag current,
    PlanningLogger logger,
  ) {
    final screenTypeStr = ctx.rawVars['screen_type'] as String? ?? 'list';
    var bag = current;

    // Set screen type flags
    bag = bag.set('is_list_screen', screenTypeStr == 'list');
    bag = bag.set('is_detail_screen', screenTypeStr == 'detail');
    bag = bag.set('is_form_screen', screenTypeStr == 'form');
    bag = bag.set('is_auth_screen', screenTypeStr == 'auth');
    bag = bag.set('is_settings_screen', screenTypeStr == 'settings');

    return bag;
  }
}

/// Test deriver that handles shared variables like features array.
class TestSharedDeriver implements VariableDeriver {
  const TestSharedDeriver();

  @override
  String get id => 'test_shared';

  @override
  bool supports(GenerationContext ctx) => true;

  @override
  VariableBag derive(
    GenerationContext ctx,
    VariableBag current,
    PlanningLogger logger,
  ) {
    var bag = current;

    // Handle feature array for multi-feature projects (project mode)
    final features = ctx.rawVars['features'] as List?;
    if (features != null) {
      bag = bag.set('features', features);
    }

    // Handle with_validation for feature mode
    final withValidation = ctx.rawVars['with_validation'] as bool?;
    if (withValidation != null) {
      bag = bag.set('with_validation', withValidation);
    }

    return bag;
  }
}

/// Test deriver that sets service-mode-specific variables.
class TestServiceModeDeriver implements VariableDeriver {
  const TestServiceModeDeriver();

  @override
  String get id => 'test_service_mode';

  @override
  bool supports(GenerationContext ctx) =>
      ctx.mode == GenerationMode.service;

  @override
  VariableBag derive(
    GenerationContext ctx,
    VariableBag current,
    PlanningLogger logger,
  ) {
    final serviceTypeStr = ctx.rawVars['service_type'] as String? ?? 'api';
    var bag = current;

    // Set service type flags
    bag = bag.set('is_api_service', serviceTypeStr == 'api');
    bag = bag.set('is_local_service', serviceTypeStr == 'local');
    bag = bag.set('is_cache_service', serviceTypeStr == 'cache');
    bag = bag.set('is_analytics_service', serviceTypeStr == 'analytics');
    bag = bag.set('is_storage_service', serviceTypeStr == 'storage');

    // Set feature flags based on raw vars
    final withRetry = ctx.rawVars['with_retry_logic'] as bool? ?? false;
    final withCaching = ctx.rawVars['with_caching'] as bool? ?? false;
    final withInterceptors = ctx.rawVars['with_interceptors'] as bool? ?? false;

    bag = bag.set('supports_retry', withRetry);
    bag = bag.set('supports_caching', withCaching);
    bag = bag.set('supports_interceptors', withInterceptors);

    // Validate analytics + caching not supported
    if (serviceTypeStr == 'analytics' && withCaching) {
      throw PlanningException(
        'Invalid combination: service_type=analytics does not support with_caching=true.',
      );
    }

    return bag;
  }
}

/// Creates a simple test pipeline for use in planning package tests.
///
/// This pipeline provides minimal derivation suitable for testing
/// the planning infrastructure without domain-specific logic.
VariablePipeline createTestPipeline() {
  return const VariablePipeline([
    TestBasicDeriver(),
    TestPlatformDeriver(),
    TestPresetDeriver(),
    TestSharedDeriver(),
    TestModeDeriver(),
    TestFeatureModeDeriver(),
    TestServiceModeDeriver(),
  ]);
}

