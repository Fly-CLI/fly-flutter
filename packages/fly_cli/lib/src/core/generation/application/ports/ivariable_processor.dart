import 'package:fly_cli/src/core/generation/domain/entities/brick.dart';
import 'package:fly_cli/src/core/generation/foundation/foundation_enums.dart';

/// Result of variable processing.
class ProcessedVariables {
  const ProcessedVariables({
    required this.values,
    required this.validationResult,
  });

  /// Processed variable values.
  final Map<String, dynamic> values;

  /// Validation result.
  final VariableValidationResult validationResult;
}

/// Result of variable validation.
class VariableValidationResult {
  const VariableValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  /// Whether validation passed.
  final bool isValid;

  /// Validation errors.
  final List<String> errors;

  /// Validation warnings.
  final List<String> warnings;

  factory VariableValidationResult.success() =>
      const VariableValidationResult(isValid: true);

  factory VariableValidationResult.failure(List<String> errors) =>
      VariableValidationResult(isValid: false, errors: errors);
}

/// Interface for variable processing pipeline.
///
/// Handles variable derivation, transformation, and validation.
abstract class IVariableProcessor {
  /// Process variables through the pipeline.
  ///
  /// [rawVars] are the input variables.
  /// [mode] is the generation mode (project, feature, service).
  /// [brick] is the brick being used for generation.
  ///
  /// Returns processed variables with validation result.
  Future<ProcessedVariables> process({
    required Map<String, dynamic> rawVars,
    required GenerationMode mode,
    required Brick brick,
  });
}

