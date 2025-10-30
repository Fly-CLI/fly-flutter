/// Standardized validation result
/// 
/// Provides a consistent way to represent validation results
/// across all packages in the Fly CLI ecosystem.
class ValidationResult {
  const ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  /// Whether validation passed
  final bool isValid;

  /// List of validation errors
  final List<String> errors;

  /// List of validation warnings
  final List<String> warnings;

  /// Create a successful validation result
  factory ValidationResult.success() => const ValidationResult(isValid: true);

  /// Create a failed validation result with errors
  factory ValidationResult.failure(List<String> errors) => ValidationResult(
    isValid: false,
    errors: errors,
  );

  /// Create a validation result with warnings
  factory ValidationResult.withWarnings(List<String> warnings) => ValidationResult(
    isValid: true,
    warnings: warnings,
  );

  /// Combine multiple validation results
  factory ValidationResult.combine(List<ValidationResult> results) {
    final allErrors = <String>[];
    final allWarnings = <String>[];

    for (final result in results) {
      allErrors.addAll(result.errors);
      allWarnings.addAll(result.warnings);
    }

    return ValidationResult(
      isValid: allErrors.isEmpty,
      errors: allErrors,
      warnings: allWarnings,
    );
  }

  /// Get all messages (errors and warnings)
  List<String> get allMessages => [...errors, ...warnings];

  /// Get the first error message
  String? get firstError => errors.isNotEmpty ? errors.first : null;

  /// Get the first warning message
  String? get firstWarning => warnings.isNotEmpty ? warnings.first : null;

  /// Convert to map for serialization
  Map<String, dynamic> toMap() {
    return {
      'is_valid': isValid,
      'errors': errors,
      'warnings': warnings,
    };
  }

  /// Create from map
  factory ValidationResult.fromMap(Map<String, dynamic> map) {
    return ValidationResult(
      isValid: map['is_valid'] as bool,
      errors: List<String>.from(map['errors'] as List? ?? []),
      warnings: List<String>.from(map['warnings'] as List? ?? []),
    );
  }

  @override
  String toString() {
    if (isValid) {
      if (warnings.isNotEmpty) {
        return 'ValidationResult(valid, warnings: ${warnings.length})';
      }
      return 'ValidationResult(valid)';
    }
    return 'ValidationResult(invalid, errors: ${errors.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ValidationResult &&
        other.isValid == isValid &&
        other.errors.length == errors.length &&
        other.warnings.length == warnings.length;
  }

  @override
  int get hashCode {
    return Object.hash(isValid, errors.length, warnings.length);
  }
}

