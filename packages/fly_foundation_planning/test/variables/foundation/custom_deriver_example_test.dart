import 'package:fly_foundation_planning/src/foundation_model.dart';
import 'package:fly_foundation_planning/src/logger.dart';
import 'package:fly_foundation_planning/src/mason_variable_keys.dart';
import 'package:fly_foundation_planning/src/variables/foundation/foundation_pipeline.dart';
import 'package:fly_foundation_planning/src/variables/generation_context.dart';
import 'package:fly_foundation_planning/src/variables/variable_bag.dart';
import 'package:fly_foundation_planning/src/variables/variable_deriver.dart';
import 'package:fly_foundation_planning/src/variables/variable_pipeline.dart';
import 'package:test/test.dart';

/// Example custom deriver that adds organization-specific variables.
class CustomComplianceDeriver implements VariableDeriver {
  const CustomComplianceDeriver();

  @override
  String get id => 'custom_compliance';

  @override
  bool supports(GenerationContext ctx) => true; // Always run

  @override
  VariableBag derive(
    GenerationContext ctx,
    VariableBag current,
    PlanningLogger logger,
  ) {
    final organization = ctx.rawVars['organization'] as String? ?? '';
    
    // Add compliance flags based on organization
    final requiresCompliance = organization.contains('enterprise') ||
        organization.contains('corp');

    return current.setAll({
      'requires_compliance': requiresCompliance,
      'compliance_level': requiresCompliance ? 'enterprise' : 'standard',
    });
  }
}

/// Example of creating a custom pipeline by composing existing derivers.
void main() {
  group('Custom Deriver Example', () {
    test('custom deriver adds organization-specific variables', () {
      final deriver = const CustomComplianceDeriver();
      final ctx = GenerationContext.fromVars({
        'name': 'test',
        'organization': 'com.enterprise',
      });
      final logger = const NoOpLogger();
      final current = VariableBag.empty();

      final result = deriver.derive(ctx, current, logger);

      expect(result.get<bool>('requires_compliance'), isTrue);
      expect(result.get<String>('compliance_level'), 'enterprise');
    });

    test('custom pipeline composes foundation and custom derivers', () {
      // Create a custom pipeline that includes foundation derivers
      // plus a custom compliance deriver
      final customPipeline = VariablePipeline([
        ...foundationPipeline.steps,
        const CustomComplianceDeriver(),
      ]);

      final ctx = GenerationContext.fromVars({
        'name': 'test_project',
        'organization': 'com.enterprise',
        'generation_mode': 'project',
        'platforms': ['ios', 'android'],
      });
      final logger = const NoOpLogger();

      final result = customPipeline.run(ctx, logger);

      // Foundation variables should be present
      expect(result.get<String>(MasonVarKey.projectName.key), 'test_project');
      expect(result.get<bool>(MasonVarKey.supportsIos.key), isTrue);
      
      // Custom variables should also be present
      expect(result.get<bool>('requires_compliance'), isTrue);
      expect(result.get<String>('compliance_level'), 'enterprise');
    });

    test('custom deriver can conditionally run based on context', () {
      final conditionalDeriver = ConditionalDeriver();
      
      final ctx1 = GenerationContext.fromVars({
        'name': 'test',
        'generation_mode': 'project',
      });
      final ctx2 = GenerationContext.fromVars({
        'name': 'test',
        'generation_mode': 'feature',
      });
      final logger = const NoOpLogger();

      expect(conditionalDeriver.supports(ctx1), isTrue);
      expect(conditionalDeriver.supports(ctx2), isFalse);
    });
  });
}

/// Example of a conditional deriver that only runs for specific modes.
class ConditionalDeriver implements VariableDeriver {
  const ConditionalDeriver();

  @override
  String get id => 'conditional';

  @override
  bool supports(GenerationContext ctx) =>
      ctx.mode == GenerationMode.project;

  @override
  VariableBag derive(
    GenerationContext ctx,
    VariableBag current,
    PlanningLogger logger,
  ) {
    return current.set('conditional_flag', true);
  }
}

