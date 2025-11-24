import 'package:fly_cli/src/generation/template/template_info.dart';
import 'package:fly_cli/src/generation/versioning/compatibility_result.dart';

/// Result of template validation
class TemplateValidationResult {
  const TemplateValidationResult({
    required this.isValid,
    required this.issues,
    this.template,
  });

  factory TemplateValidationResult.failure(String error) =>
      TemplateValidationResult(
        isValid: false,
        issues: [error],
      );

  factory TemplateValidationResult.success({TemplateInfo? template}) =>
      TemplateValidationResult(
        isValid: true,
        issues: const [],
        template: template,
      );

  final bool isValid;
  final List<String> issues;
  final TemplateInfo? template;
}

/// Interface for template validation.
///
/// Provides abstraction over template validation logic, allowing
/// different implementations and easier testing.
abstract class ITemplateValidator {
  /// Validate a template.
  ///
  /// [template] is the template to validate.
  ///
  /// Returns a [TemplateValidationResult] with validation status and issues.
  Future<TemplateValidationResult> validateTemplate(TemplateInfo template);

  /// Check template compatibility.
  ///
  /// [template] is the template to check.
  ///
  /// Returns a [CompatibilityResult] with compatibility status.
  Future<CompatibilityResult> checkCompatibility(TemplateInfo template);
}

