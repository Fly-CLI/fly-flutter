/// Error types for generation operations.
///
/// Provides structured categorization of generation errors for better
/// error handling, analytics, and user-facing messaging.
enum GenerationErrorType {
  /// Brick was not found
  brickNotFound,

  /// Variable validation failed
  variableValidation,

  /// Generation operation failed
  generationFailure,

  /// Infrastructure error (file system, Mason, etc.)
  infrastructure,

  /// Unknown or unclassified error
  unknown,
}

