/// Structured validation error with context and hints
///
/// Represents a validation error with structured information including:
/// - Field path (where the error occurred)
/// - Error type (what kind of validation failed)
/// - Expected vs actual values
/// - Human-readable message
/// - Helpful hints for fixing the error
///
/// This is the unified error type used across all validation layers
/// (protocol validation, business validation, etc.).
class ValidationError {
  const ValidationError({
    required this.path,
    required this.type,
    required this.expected,
    this.actual,
    required this.message,
    this.hint,
  });

  /// The path to the field with the error
  ///
  /// Examples:
  /// - "screenName" (root level field)
  /// - "variables.projectName" (nested field)
  /// - "items[0].name" (array item field)
  final String path;

  /// The type of validation error
  final ValidationErrorType type;

  /// Description of what was expected
  ///
  /// Examples:
  /// - "required field"
  /// - "string"
  /// - "one of: list, detail, form"
  final String expected;

  /// The actual value (if available)
  ///
  /// This can be used to provide context about what was received
  /// versus what was expected.
  final Object? actual;

  /// Human-readable error message
  ///
  /// This should be a clear, actionable message that explains
  /// what went wrong and how to fix it.
  ///
  /// Examples:
  /// - "Missing Required parameter: screenName"
  /// - "Expected string for 'screenName', got integer"
  /// - "Invalid enum value 'invalid' for 'screenType'. Allowed values: list, detail, form"
  final String message;

  /// Hint or suggestion for fixing the error
  ///
  /// Provides actionable guidance for resolving the validation error.
  ///
  /// Examples:
  /// - "Provide screenName parameter"
  /// - "Convert number to string: \"123\""
  /// - "Use one of: list, detail, form"
  final String? hint;

  /// Convert to simple string (for backward compatibility)
  ///
  /// Returns just the error message without additional context.
  @override
  String toString() => message;

  /// Convert to Map for serialization
  Map<String, Object?> toMap() {
    return {
      'path': path,
      'type': type.name,
      'expected': expected,
      if (actual != null) 'actual': actual.toString(),
      'message': message,
      if (hint != null) 'hint': hint,
    };
  }

  /// Create from Map
  factory ValidationError.fromMap(Map<String, Object?> map) {
    return ValidationError(
      path: map['path'] as String,
      type: ValidationErrorType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ValidationErrorType.other,
      ),
      expected: map['expected'] as String,
      actual: map['actual'],
      message: map['message'] as String,
      hint: map['hint'] as String?,
    );
  }
}

/// Types of validation errors
enum ValidationErrorType {
  /// Missing required field
  missingRequired,

  /// Type mismatch (e.g., expected string, got number)
  typeMismatch,

  /// Invalid enum value
  invalidEnum,

  /// Additional property not allowed
  additionalPropertyNotAllowed,

  /// Other validation errors
  other,
}
