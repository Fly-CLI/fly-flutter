import 'package:fly_foundation_planning/src/foundation_model.dart';
import 'package:fly_foundation_planning/src/logger.dart';
import 'package:fly_foundation_planning/src/mason_variable_keys.dart';
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
    return current.set(MasonVarKey.name.key, name);
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
      }
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
    TestModeDeriver(),
  ]);
}

