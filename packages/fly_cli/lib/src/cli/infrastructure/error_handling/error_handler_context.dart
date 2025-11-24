

/// Context for error handling
///
/// This class encapsulates all information needed for error handling,
/// making it easier to pass error context through the error handling pipeline.
class ErrorHandlerContext {
  /// Create error handler context
  ///
  /// [error] - The error object
  /// [outputFormat] - The output format for error formatting
  /// [stackTrace] - The stack trace (optional)
  /// [args] - The command arguments that caused the error (optional)
  /// [commandName] - The command name (optional)
  /// [isVerbose] - Whether verbose output is enabled
  ErrorHandlerContext({
    required this.error,
    required this.outputFormat,
    this.stackTrace,
    this.args,
    this.commandName,
    this.isVerbose = false,
  });

  /// The error object
  final Object error;

  /// The stack trace (optional)
  final StackTrace? stackTrace;

  /// The command arguments that caused the error (optional)
  final Iterable<String>? args;

  /// The output format for error formatting
  final String outputFormat;

  /// The command name (optional)
  final String? commandName;

  /// Whether verbose output is enabled
  final bool isVerbose;
}
