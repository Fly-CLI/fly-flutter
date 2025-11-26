import 'package:fly_cli/src/generation/domain/entities/brick.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';

/// Result of variable processing.
class ProcessedVariables {
  /// Creates a new instance of [ProcessedVariables].
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
  /// Creates a new instance of [VariableValidationResult].
  const VariableValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  /// Creates a successful validation result.
  factory VariableValidationResult.success() =>
      const VariableValidationResult(isValid: true);

  /// Creates a failed validation result.
  factory VariableValidationResult.failure(List<String> errors) =>
      VariableValidationResult(isValid: false, errors: errors);

  /// Whether validation passed.
  final bool isValid;

  /// Validation errors.
  final List<String> errors;

  /// Validation warnings.
  final List<String> warnings;
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
