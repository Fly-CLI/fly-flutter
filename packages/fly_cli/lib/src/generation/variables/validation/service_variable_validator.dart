import 'package:fly_cli/src/cli/infrastructure/validation/validation_rules.dart';
import 'package:fly_cli/src/generation/domain/entities/brick.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';
import 'package:fly_cli/src/generation/utils/mason_variable_keys.dart';
import 'package:fly_cli/src/generation/variables/validation/brick_variable_validator.dart';
import 'package:fly_cli/src/generation/variables/validation/ivariable_validator.dart';

/// Validator for service generation mode variables.
///
/// Handles validation specific to service generation, including:
/// - Component name validation (service name format)
/// - Feature name validation
/// - Service type validation
/// - API base URL validation (when service type is API)
class ServiceVariableValidator implements IVariableValidator {
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
    final serviceTypeStr = variables.getVar<String>(ServiceVarKey.serviceType);

    if (componentName == null || componentName.isEmpty) {
      errors.add('name is required for service generation');
    } else if (!NameValidationRule.isValidServiceName(componentName)) {
      errors.add(
        'name "$componentName" must be snake_case (e.g. auth_service)',
      );
    }

    if (feature == null || feature.isEmpty) {
      errors.add('feature is required for service generation');
    } else if (!NameValidationRule.isValidFeatureName(feature)) {
      errors.add(
        'feature "$feature" must be snake_case and contain only letters/numbers',
      );
    }

    ServiceType? serviceType;
    if (serviceTypeStr == null || serviceTypeStr.isEmpty) {
      errors.add('service_type is required for service generation');
    } else {
      try {
        serviceType = ServiceType.fromKey(serviceTypeStr);
      } on FormatException catch (e) {
        errors.add(e.message);
      }
    }

    if (serviceType == ServiceType.api) {
      final baseUrl =
          variables.getVar<String>(ServiceVarKey.baseUrl) ??
          variables.getVar<String>(ServiceVarKey.apiBaseUrl);
      if (baseUrl == null || baseUrl.isEmpty) {
        errors.add('api_base_url is required when service_type is "api"');
      }
    }

    return errors;
  }
}

