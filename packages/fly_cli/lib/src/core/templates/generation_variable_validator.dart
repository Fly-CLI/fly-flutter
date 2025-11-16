import 'package:fly_cli/src/core/validation/validation_rules.dart';

class GenerationVariableValidator {
  static const _allowedModes = {'project', 'feature', 'service'};
  static const _allowedPlatforms = {
    'ios',
    'android',
    'web',
    'macos',
    'windows',
    'linux',
  };

  static final _organizationPattern = RegExp(r'^[a-z][a-z0-9_]*(\.[a-z0-9_]+)+$');

  static List<String> validate(Map<String, dynamic> variables) {
    final errors = <String>[];
    final mode = (variables['generation_mode'] as String? ?? 'project').toLowerCase();

    if (!_allowedModes.contains(mode)) {
      errors.add('generation_mode "$mode" is not supported');
      return errors;
    }

    switch (mode) {
      case 'project':
        errors.addAll(_validateProjectVariables(variables));
        break;
      case 'feature':
        errors.addAll(_validateFeatureVariables(variables));
        break;
      case 'service':
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
        if (platform is! String || !_allowedPlatforms.contains(platform)) {
          errors.add('platform "$platform" is not supported. Valid: ${_allowedPlatforms.join(', ')}');
        }
      }
    }

    return errors;
  }

  static List<String> _validateFeatureVariables(Map<String, dynamic> variables) {
    final errors = <String>[];
    final componentName = variables['component_name'] as String?;
    final feature = variables['feature'] as String?;
    final screenType = variables['screen_type'] as String?;
    const screenTypes = {'list', 'detail', 'form', 'auth', 'settings'};

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

    if (screenType == null || screenType.isEmpty) {
      errors.add('screen_type is required for feature generation');
    } else if (!screenTypes.contains(screenType)) {
      errors.add(
        'screen_type "$screenType" is not supported. Valid: ${screenTypes.join(', ')}',
      );
    }

    return errors;
  }

  static List<String> _validateServiceVariables(Map<String, dynamic> variables) {
    final errors = <String>[];
    final componentName = variables['component_name'] as String?;
    final feature = variables['feature'] as String?;
    final serviceType = variables['service_type'] as String?;
    const serviceTypes = {'api', 'local', 'cache', 'analytics', 'storage'};

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

    if (serviceType == null || serviceType.isEmpty) {
      errors.add('service_type is required for service generation');
    } else if (!serviceTypes.contains(serviceType)) {
      errors.add(
        'service_type "$serviceType" is not supported. Valid: ${serviceTypes.join(', ')}',
      );
    }

    if (serviceType == 'api') {
      final baseUrl = variables['base_url'] as String? ??
          variables['api_base_url'] as String?;
      if (baseUrl == null || baseUrl.isEmpty) {
        errors.add('api_base_url is required when service_type is "api"');
      }
    }

    return errors;
  }
}
