import 'package:fly_cli/src/core/templates/foundation_enums.dart';
import 'package:fly_cli/src/core/templates/mason_variable_keys.dart';
import 'package:fly_cli/src/core/validation/validation_rules.dart';

class GenerationVariableValidator {
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

  static List<String> validate(Map<String, dynamic> variables) {
    final errors = <String>[];
    final modeStr =
        (variables.getVar<String>(MasonVarKey.generationMode) ?? 'project')
            .toLowerCase();

    GenerationMode? mode;
    try {
      mode = GenerationMode.fromKey(modeStr);
    } on FormatException catch (e) {
      errors.add(e.message);
      return errors;
    }

    switch (mode) {
      case GenerationMode.project:
        errors.addAll(_validateProjectVariables(variables));
        break;
      case GenerationMode.feature:
        errors.addAll(_validateFeatureVariables(variables));
        break;
      case GenerationMode.service:
        errors.addAll(_validateServiceVariables(variables));
        break;
    }

    return errors;
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
