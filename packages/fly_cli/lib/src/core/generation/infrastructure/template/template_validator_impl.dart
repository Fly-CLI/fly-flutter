import 'dart:io';

import 'package:fly_cli/src/core/generation/domain/repositories/itemplate_validator.dart';
import 'package:fly_cli/src/core/generation/template/template_info.dart';
import 'package:fly_cli/src/core/generation/versioning/compatibility_checker.dart';
import 'package:fly_cli/src/core/generation/versioning/compatibility_result.dart';
import 'package:fly_cli/src/core/generation/versioning/version_parser.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// Implementation of ITemplateValidator.
///
/// Validates template structure, required fields, and compatibility.
class TemplateValidatorImpl implements ITemplateValidator {
  TemplateValidatorImpl({
    required CompatibilityChecker compatibilityChecker,
    Logger? logger,
  })
      : _compatibilityChecker = compatibilityChecker,
        _logger = logger ?? Logger();

  final CompatibilityChecker _compatibilityChecker;
  final Logger _logger;

  @override
  Future<TemplateValidationResult> validateTemplate(
      TemplateInfo template,) async {
    final issues = <String>[];

    // Basic structure validation
    if (template.name.isEmpty) {
      issues.add('Template name is required');
    }

    if (template.path.isEmpty) {
      issues.add('Template path is required');
    }

    if (template.description.isEmpty) {
      issues.add('Template description is required');
    }

    if (template.version.isEmpty) {
      issues.add('Template version is required');
    } else {
      // Validate version format
      final parsedVersion = VersionParser.parseTemplateVersion(
          template.version);
      if (parsedVersion == null) {
        issues.add(
          'Invalid version format: "${template.version}". '
              'Expected SemVer format (MAJOR.MINOR.PATCH)',
        );
      }
    }

    // Check template.yaml file exists and is valid
    final brickPath = template.path;
    final templatePath = path.dirname(brickPath);
    var templateYamlPath = path.join(templatePath, 'template.yaml');
    var templateYamlFile = File(templateYamlPath);

    // If not found, try in brick path (for backward compatibility)
    if (!await templateYamlFile.exists()) {
      templateYamlPath = path.join(brickPath, 'template.yaml');
      templateYamlFile = File(templateYamlPath);
    }

    if (await templateYamlFile.exists()) {
      try {
        final yamlContent = await templateYamlFile.readAsString();
        final yaml = loadYaml(yamlContent) as Map<dynamic, dynamic>;

        // Check if description is missing or empty in original YAML
        final description = yaml['description'] as String?;
        if (description == null || description
            .trim()
            .isEmpty) {
          issues.add('Missing template description in template.yaml');
        }

        // Check if version is missing or empty in original YAML
        final version = yaml['version'] as String?;
        if (version == null || version
            .trim()
            .isEmpty) {
          issues.add('Missing template version in template.yaml');
        }
      } catch (e) {
        issues.add('Invalid template.yaml format: $e');
      }
    } else {
      issues.add('template.yaml file not found');
    }

    // Check compatibility
    final compatibilityResult = await checkCompatibility(template);
    if (compatibilityResult.isIncompatible) {
      issues.addAll(compatibilityResult.errors);
    }

    // Log warnings (non-blocking)
    for (final warning in compatibilityResult.warnings) {
      _logger.warn('Template compatibility warning: $warning');
    }

    return TemplateValidationResult(
      isValid: issues.isEmpty,
      issues: issues,
      template: template,
    );
  }

  @override
  Future<CompatibilityResult> checkCompatibility(TemplateInfo template,) async {
    return _compatibilityChecker.checkTemplateCompatibility(template);
  }
}

