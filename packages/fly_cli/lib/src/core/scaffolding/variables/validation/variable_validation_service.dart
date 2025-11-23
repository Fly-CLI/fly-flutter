import 'package:fly_brick_composer/fly_brick_composer.dart';
import 'package:fly_cli/src/core/scaffolding/brick/brick_info.dart';
import 'package:fly_cli/src/core/scaffolding/foundation/foundation_enums.dart';
import 'package:fly_cli/src/core/scaffolding/utils/mason_variable_keys.dart';
import 'package:fly_cli/src/core/validation/validation_rules.dart';

/// Unified validation service for generation variables.
///
class VariableValidationService {
  static final _allowedModeKeys =
      GenerationMode.values.map((e) => e.key).toSet();
  static final _allowedPlatformKeys =
      PlatformType.values.map((e) => e.key).toSet();
  static final _allowedScreenTypeKeys =
      ScreenType.values.map((e) => e.key).toSet();
  static final _allowedServiceTypeKeys =
      ServiceType.values.map((e) => e.key).toSet();

  static final _organizationPattern =
      RegExp(r'^[a-z][a-z0-9_]*(\.[a-z0-9_]+)+$');

  /// Validate all aspects of variables: brick-level and business rules.
  ///
  /// This is the main entry point for validation. It performs both brick-level
  /// validation (required vars, types, choices) and business rule validation
  /// (naming, formats, dependencies).
  ///
  /// Returns a list of error messages. Empty list means validation passed.
  static List<String> validateAll({
    required BrickInfo? brick,
    required GenerationMode? mode,
    required Map<String, dynamic> variables,
  }) {
    final errors = <String>[];

    // Brick-level validation (if brick is provided)
    if (brick != null) {
      errors.addAll(validateBrickVariables(brick, variables));
    }

    // Business rule validation (if mode is provided)
    if (mode != null) {
      errors.addAll(validateBusinessRules(mode, variables));
    } else {
      // Try to infer mode from variables
      final modeStr =
          (variables.getVar<String>(MasonVarKey.generationMode) ?? 'project')
              .toLowerCase();
      try {
        final inferredMode = GenerationMode.fromKey(modeStr);
        errors.addAll(validateBusinessRules(inferredMode, variables));
      } on FormatException catch (e) {
        errors.add(e.message);
      }
    }

    return errors;
  }

  /// Validate variables against brick requirements.
  ///
  /// Checks:
  /// - Required variables are present
  /// - Variable types match brick expectations
  /// - Variable values are in allowed choices (if specified)
  static List<String> validateBrickVariables(
    BrickInfo brick,
    Map<String, dynamic> variables,
  ) {
    final errors = <String>[];

    // Check required variables
    for (final requiredVar in brick.requiredVariables) {
      if (!variables.containsKey(requiredVar.name)) {
        errors.add('Required variable "${requiredVar.name}" is missing');
      }
    }

    // Validate variable types and values
    for (final entry in variables.entries) {
      final variableName = entry.key;
      final value = entry.value;
      final brickVar = brick.getVariable(variableName);

      if (brickVar != null) {
        // Check if value matches expected type
        if (brickVar.type == 'list' && value is! List) {
          errors.add('Variable "$variableName" should be a list');
        } else if ((brickVar.type == 'bool' || brickVar.type == 'boolean') &&
            value is! bool) {
          errors.add('Variable "$variableName" should be a boolean');
        } else if (brickVar.type == 'string' && value is! String) {
          errors.add('Variable "$variableName" should be a string');
        }

        // Check choices if specified
        if (brickVar.choices != null && brickVar.choices!.isNotEmpty) {
          if (value is String && !brickVar.choices!.contains(value)) {
            errors.add(
                'Variable "$variableName" value "$value" is not in allowed choices: ${brickVar.choices!.join(', ')}');
          }
        }
      }
    }

    return errors;
  }

  /// Validate business rules for a specific generation mode.
  ///
  /// Checks naming conventions, format requirements, and dependencies
  /// specific to project, feature, or service generation.
  static List<String> validateBusinessRules(
    GenerationMode mode,
    Map<String, dynamic> variables,
  ) {
    switch (mode) {
      case GenerationMode.project:
        return _validateProjectVariables(variables);
      case GenerationMode.feature:
        return _validateFeatureVariables(variables);
      case GenerationMode.service:
        return _validateServiceVariables(variables);
    }
  }

  static List<String> _validateProjectVariables(
      Map<String, dynamic> variables) {
    final errors = <String>[];
    final projectName = variables.getVar<String>(MasonVarKey.projectName);
    final organization = variables.getVar<String>(MasonVarKey.organization);
    final platforms = variables.getVar(MasonVarKey.platforms);

    if (projectName == null || projectName.isEmpty) {
      errors.add('project_name is required for project generation');
    } else if (!NameValidationRule.isValidProjectName(projectName)) {
      errors
          .add('project_name "$projectName" is not a valid Dart package name');
    }

    if (organization == null || organization.isEmpty) {
      errors.add('organization is required for project generation');
    } else if (!_organizationPattern.hasMatch(organization)) {
      errors.add(
          'organization "$organization" must be reverse-domain (e.g. com.example.app)');
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
                'platform "$platform" is not supported. Valid: ${_allowedPlatformKeys.join(', ')}');
          }
        }
      }
    }

    return errors;
  }

  static List<String> _validateFeatureVariables(
      Map<String, dynamic> variables) {
    final errors = <String>[];
    final componentName = variables.getVar<String>(MasonVarKey.componentName);
    final feature = variables.getVar<String>(MasonVarKey.feature);
    final screenTypeStr = variables.getVar<String>(MasonVarKey.screenType);

    if (componentName == null || componentName.isEmpty) {
      errors.add('component_name is required for feature generation');
    } else if (!NameValidationRule.isValidScreenName(componentName)) {
      errors.add(
        'component_name "$componentName" must be snake_case (e.g. profile_overview)',
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

  static List<String> _validateServiceVariables(
      Map<String, dynamic> variables) {
    final errors = <String>[];
    final componentName = variables.getVar<String>(MasonVarKey.componentName);
    final feature = variables.getVar<String>(MasonVarKey.feature);
    final serviceTypeStr = variables.getVar<String>(MasonVarKey.serviceType);

    if (componentName == null || componentName.isEmpty) {
      errors.add('component_name is required for service generation');
    } else if (!NameValidationRule.isValidServiceName(componentName)) {
      errors.add(
        'component_name "$componentName" must be snake_case (e.g. auth_service)',
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
      final baseUrl = variables.getVar<String>(MasonVarKey.baseUrl) ??
          variables.getVar<String>(MasonVarKey.apiBaseUrl);
      if (baseUrl == null || baseUrl.isEmpty) {
        errors.add('api_base_url is required when service_type is "api"');
      }
    }

    return errors;
  }
}

