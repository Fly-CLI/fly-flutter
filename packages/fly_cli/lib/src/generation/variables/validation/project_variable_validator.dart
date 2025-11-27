import 'package:fly_cli/src/cli/infrastructure/validation/validation_rules.dart';
import 'package:fly_cli/src/generation/domain/entities/brick.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';
import 'package:fly_cli/src/generation/utils/mason_variable_keys.dart';
import 'package:fly_cli/src/generation/variables/validation/brick_variable_validator.dart';
import 'package:fly_cli/src/generation/variables/validation/ivariable_validator.dart';

/// Validator for project generation mode variables.
///
/// Handles validation specific to project generation, including:
/// - Project name validation (Dart package name format)
/// - Organization validation (reverse-domain format)
/// - Platform validation (at least one platform, valid platform types)
class ProjectVariableValidator implements IVariableValidator {
  static final Set<String> _allowedPlatformKeys = PlatformType.values
      .map((e) => e.key)
      .toSet();

  static final _organizationPattern = RegExp(
    r'^[a-z][a-z0-9_]*(\.[a-z0-9_]+)+$',
  );

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
    final projectName = variables.getVar<String>(ProjectVarKey.projectName);
    final organization = variables.getVar<String>(BaseVarKey.organization);
    final platforms = variables.getVar(BaseVarKey.platforms);

    if (projectName == null || projectName.isEmpty) {
      errors.add('project_name is required for project generation');
    } else if (!NameValidationRule.isValidProjectName(projectName)) {
      errors.add(
        'project_name "$projectName" is not a valid Dart package name',
      );
    }

    if (organization == null || organization.isEmpty) {
      errors.add('organization is required for project generation');
    } else if (!_organizationPattern.hasMatch(organization)) {
      errors.add(
        'organization "$organization" must be reverse-domain (e.g. com.example.app)',
      );
    }

    if (platforms is! List || platforms.isEmpty) {
      errors.add('platforms must include at least one target platform');
    } else {
      for (final platform in platforms) {
        if (platform is! String) {
          errors.add('platform "$platform" must be a string');
        } else {
          final platformKey = platform.toLowerCase().trim();
          if (!_allowedPlatformKeys.contains(platformKey)) {
            errors.add(
              'platform "$platform" is not supported. Valid: ${_allowedPlatformKeys.join(', ')}',
            );
          }
        }
      }
    }

    return errors;
  }
}
