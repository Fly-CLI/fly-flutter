import 'package:fly_cli/src/core/validation/validation_rules.dart';

class GenerationVariableValidator {
  static const _allowedModes = {'project', 'screen', 'service', 'provider'};
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
      default:
        errors.add('generation_mode "$mode" is not yet implemented in fly_foundation');
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
}
