import 'package:fly_cli/src/core/templates/foundation_enums.dart';
import 'package:fly_cli/src/core/validation/validation_rules.dart';

class GenerationVariableValidator {
  static final _allowedModeKeys = GenerationMode.values.map((e) => e.key).toSet();
  static final _allowedPlatformKeys = PlatformType.values.map((e) => e.key).toSet();
  static final _allowedScreenTypeKeys = ScreenType.values.map((e) => e.key).toSet();
  static final _allowedServiceTypeKeys = ServiceType.values.map((e) => e.key).toSet();

  static final _organizationPattern = RegExp(r'^[a-z][a-z0-9_]*(\.[a-z0-9_]+)+$');

  static List<String> validate(Map<String, dynamic> variables) {
    final errors = <String>[];
    final modeStr = (variables['generation_mode'] as String? ?? 'project').toLowerCase();

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

  static List<String> _validateProjectVariables(Map<String, dynamic> variables) {
    final errors = <String>[];
    final projectName = variables['project_name'] as String?;
    final organization = variables['organization'] as String?;
    final platforms = variables['platforms'];

    if (projectName == null || projectName.isEmpty) {
      errors.add('project_name is required for project generation');
    } else if (!NameValidationRule.isValidProjectName(projectName)) {
      errors.add('project_name "$projectName" is not a valid Dart package name');
    }

    if (organization == null || organization.isEmpty) {
      errors.add('organization is required for project generation');
    } else if (!_organizationPattern.hasMatch(organization)) {
      errors.add('organization "$organization" must be reverse-domain (e.g. com.example.app)');
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
            errors.add('platform "$platform" is not supported. Valid: ${_allowedPlatformKeys.join(', ')}');
          }
        }
      }
    }

    return errors;
  }

  static List<String> _validateFeatureVariables(Map<String, dynamic> variables) {
    final errors = <String>[];
    final componentName = variables['component_name'] as String?;
    final feature = variables['feature'] as String?;
    final screenTypeStr = variables['screen_type'] as String?;

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

  static List<String> _validateServiceVariables(Map<String, dynamic> variables) {
    final errors = <String>[];
    final componentName = variables['component_name'] as String?;
    final feature = variables['feature'] as String?;
    final serviceTypeStr = variables['service_type'] as String?;

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
      final baseUrl = variables['base_url'] as String? ??
          variables['api_base_url'] as String?;
      if (baseUrl == null || baseUrl.isEmpty) {
        errors.add('api_base_url is required when service_type is "api"');
      }
    }

    return errors;
  }
}
