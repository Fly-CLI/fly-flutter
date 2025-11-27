import 'package:fly_cli/src/cli/infrastructure/validation/validation_rules.dart';
import 'package:fly_cli/src/generation/domain/entities/brick.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';
import 'package:fly_cli/src/generation/utils/mason_variable_keys.dart';
import 'package:fly_cli/src/generation/variables/validation/brick_variable_validator.dart';
import 'package:fly_cli/src/generation/variables/validation/ivariable_validator.dart';

/// Validator for feature (screen) generation mode variables.
///
/// Handles validation specific to feature generation, including:
/// - Component name validation (screen name format)
/// - Feature name validation
/// - Screen type validation
class FeatureVariableValidator implements IVariableValidator {
  @override
  List<String> validateAll({
    required Brick? brick,
    required Map<String, dynamic> variables,
  }) {
    final errors = <String>[];

    // Brick-level validation (if brick is provided)
    if (brick != null) {
      errors.addAll(BrickVariableValidator.validate(brick, variables));
    }

    // Business rule validation
    errors.addAll(validateBusinessRules(variables));

    return errors;
  }

  @override
  List<String> validateBusinessRules(Map<String, dynamic> variables) {
    final errors = <String>[];
    final componentName = variables.getVar<String>(BaseVarKey.componentName);
    final feature = variables.getVar<String>(BaseVarKey.feature);
    final screenTypeStr = variables.getVar<String>(FeatureVarKey.screenType);

    if (componentName == null || componentName.isEmpty) {
      errors.add('name is required for feature generation');
    } else if (!NameValidationRule.isValidScreenName(componentName)) {
      errors.add(
        'name "$componentName" must be snake_case (e.g. profile_overview)',
      );
    }

    if (feature == null || feature.isEmpty) {
      errors.add('feature is required for feature generation');
    } else if (!NameValidationRule.isValidFeatureName(feature)) {
      errors.add(
        'feature "$feature" must be snake_case and contain only letters/numbers',
      );
    }

    if (screenTypeStr == null || screenTypeStr.isEmpty) {
      errors.add('screen_type is required for feature generation');
    } else {
      try {
        ScreenType.fromKey(screenTypeStr);
      } on FormatException catch (e) {
        errors.add(e.message);
      }
    }

    return errors;
  }
}
