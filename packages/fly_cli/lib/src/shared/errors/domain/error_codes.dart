/// Error code taxonomy for Fly CLI
///
/// Provides structured error codes with semantic categories for programmatic
/// error handling and consistent error reporting across all commands.
enum ErrorCode {
  // User Errors (E1xxx) - Invalid input, missing dependencies, user mistakes
  invalidProjectName(
    'E1001',
    ErrorCategory.user,
    ErrorSeverity.error,
    'Invalid project name',
    'Project names must be lowercase, start with a letter, and contain only letters, numbers, and underscores',
  ),
  invalidTemplateName(
    'E1002',
    ErrorCategory.user,
    ErrorSeverity.error,
    'Invalid template name',
    'Template name must be one of: minimal, riverpod',
  ),
  missingRequiredArgument(
    'E1003',
    ErrorCategory.user,
    ErrorSeverity.error,
    'Missing required argument',
    'Please provide all required arguments',
  ),
  invalidArgumentValue(
    'E1004',
    ErrorCategory.user,
    ErrorSeverity.error,
    'Invalid argument value',
    'Check argument values and try again',
  ),
  projectAlreadyExists(
    'E1005',
    ErrorCategory.user,
    ErrorSeverity.error,
    'Project already exists',
    'Choose a different project name or remove the existing project',
  ),
  invalidOrganizationId(
    'E1006',
    ErrorCategory.user,
    ErrorSeverity.error,
    'Invalid organization identifier',
    'Organization ID must follow reverse domain notation (e.g., com.example)',
  ),
  invalidPlatformList(
    'E1007',
    ErrorCategory.user,
    ErrorSeverity.error,
    'Invalid platform list',
    'Platforms must be one or more of: ios, android, web, macos, windows, linux',
  ),
  invalidFeatureName(
    'E1008',
    ErrorCategory.user,
    ErrorSeverity.error,
    'Invalid feature name',
    'Feature names must be lowercase and contain only letters, numbers, and underscores',
  ),
  invalidServiceName(
    'E1009',
    ErrorCategory.user,
    ErrorSeverity.error,
    'Invalid service name',
    'Service names must be lowercase and contain only letters, numbers, and underscores',
  ),
  invalidScreenName(
    'E1010',
    ErrorCategory.user,
    ErrorSeverity.error,
    'Invalid screen name',
    'Screen names must be lowercase and contain only letters, numbers, and underscores',
  ),

  // System Errors (E2xxx) - Permission, disk space, network, OS issues
  permissionDenied(
    'E2001',
    ErrorCategory.system,
    ErrorSeverity.error,
    'Permission denied',
    'Check file permissions or run with elevated privileges',
  ),
  networkError(
    'E2002',
    ErrorCategory.system,
    ErrorSeverity.error,
    'Network connection error',
    'Check your internet connection and try again',
  ),
  diskSpaceError(
    'E2003',
    ErrorCategory.system,
    ErrorSeverity.error,
    'Insufficient disk space',
    'Free up disk space and try again',
  ),
  fileSystemError(
    'E2004',
    ErrorCategory.system,
    ErrorSeverity.error,
    'File system error',
    'Check file system integrity and permissions',
  ),
  timeoutError(
    'E2005',
    ErrorCategory.system,
    ErrorSeverity.error,
    'Operation timed out',
    'The operation took too long to complete',
  ),
  resourceUnavailable(
    'E2006',
    ErrorCategory.system,
    ErrorSeverity.error,
    'Resource unavailable',
    'Required system resource is not available',
  ),
  processError(
    'E2007',
    ErrorCategory.system,
    ErrorSeverity.error,
    'Process execution error',
    'Failed to execute external process',
  ),
  environmentError(
    'E2008',
    ErrorCategory.system,
    ErrorSeverity.error,
    'Environment configuration error',
    'Check your system environment configuration',
  ),

  // Integration Errors (E3xxx) - Flutter SDK, template engine, external tools
  flutterSdkNotFound(
    'E3001',
    ErrorCategory.integration,
    ErrorSeverity.error,
    'Flutter SDK not found',
    'Install Flutter SDK and ensure it\'s in your PATH',
  ),
  dartSdkNotFound(
    'E3002',
    ErrorCategory.integration,
    ErrorSeverity.error,
    'Dart SDK not found',
    'Install Dart SDK and ensure it\'s in your PATH',
  ),
  templateNotFound(
    'E3003',
    ErrorCategory.integration,
    ErrorSeverity.error,
    'Template not found',
    'Check available templates with "fly template list"',
  ),
  templateValidationFailed(
    'E3004',
    ErrorCategory.integration,
    ErrorSeverity.error,
    'Template validation failed',
    'Template may be corrupted or incompatible',
  ),
  templateGenerationFailed(
    'E3005',
    ErrorCategory.integration,
    ErrorSeverity.error,
    'Template generation failed',
    'Check template variables and try again',
  ),
  masonError(
    'E3006',
    ErrorCategory.integration,
    ErrorSeverity.error,
    'Mason template engine error',
    'Mason template engine encountered an error',
  ),
  pubCacheError(
    'E3007',
    ErrorCategory.integration,
    ErrorSeverity.error,
    'Pub cache error',
    'Clear pub cache with "flutter pub cache clean"',
  ),
  platformToolsError(
    'E3008',
    ErrorCategory.integration,
    ErrorSeverity.error,
    'Platform tools error',
    'Install required platform tools (Android SDK, Xcode, etc.)',
  ),

  // Internal Errors (E4xxx) - Bugs, unexpected states, implementation issues
  internalError(
    'E4001',
    ErrorCategory.internal,
    ErrorSeverity.error,
    'Internal error',
    'An unexpected error occurred. Please report this issue',
  ),
  stateError(
    'E4002',
    ErrorCategory.internal,
    ErrorSeverity.error,
    'Invalid state',
    'The application is in an unexpected state',
  ),
  configurationError(
    'E4003',
    ErrorCategory.internal,
    ErrorSeverity.error,
    'Configuration error',
    'Internal configuration is invalid',
  ),
  dependencyInjectionError(
    'E4004',
    ErrorCategory.internal,
    ErrorSeverity.error,
    'Dependency injection error',
    'Failed to resolve required dependencies',
  ),
  middlewareError(
    'E4005',
    ErrorCategory.internal,
    ErrorSeverity.error,
    'Middleware error',
    'Command middleware encountered an error',
  ),
  validationError(
    'E4006',
    ErrorCategory.internal,
    ErrorSeverity.error,
    'Validation error',
    'Command validation failed',
  ),
  lifecycleError(
    'E4007',
    ErrorCategory.internal,
    ErrorSeverity.error,
    'Lifecycle error',
    'Command lifecycle hook failed',
  ),
  unknownError(
    'E4999',
    ErrorCategory.internal,
    ErrorSeverity.error,
    'Unknown error',
    'An unknown error occurred',
  );

  const ErrorCode(
    this.code,
    this.category,
    this.severity,
    this.defaultMessage,
    this.defaultSuggestion,
  );

  /// The error code string (e.g., 'E1001')
  final String code;

  /// The category this error belongs to
  final ErrorCategory category;

  /// The severity level of this error
  final ErrorSeverity severity;

  /// Default human-readable message for this error
  final String defaultMessage;

  /// Default suggestion for resolving this error
  final String defaultSuggestion;

  /// Documentation URL for this error code (if available)
  String? get documentationUrl {
    switch (category) {
      case ErrorCategory.user:
        return 'https://fly-cli.dev/docs/errors/user-errors';
      case ErrorCategory.system:
        return 'https://fly-cli.dev/docs/errors/system-errors';
      case ErrorCategory.integration:
        return 'https://fly-cli.dev/docs/errors/integration-errors';
      case ErrorCategory.internal:
        return 'https://fly-cli.dev/docs/errors/internal-errors';
    }
  }

  /// Whether this error is typically recoverable
  bool get isRecoverable {
    switch (this) {
      case ErrorCode.networkError:
      case ErrorCode.timeoutError:
      case ErrorCode.templateNotFound:
      case ErrorCode.templateValidationFailed:
      case ErrorCode.pubCacheError:
        return true;
      case ErrorCode.permissionDenied:
      case ErrorCode.diskSpaceError:
      case ErrorCode.flutterSdkNotFound:
      case ErrorCode.dartSdkNotFound:
        return true; // Can be fixed by user
      default:
        return false;
    }
  }

  /// Whether this error should trigger automatic retry
  bool get isRetryable {
    switch (this) {
      case ErrorCode.networkError:
      case ErrorCode.timeoutError:
      case ErrorCode.resourceUnavailable:
        return true;
      default:
        return false;
    }
  }

  /// Get error code by string code
  static ErrorCode? fromCode(String code) {
    for (final errorCode in ErrorCode.values) {
      if (errorCode.code == code) {
        return errorCode;
      }
    }
    return null;
  }

  /// Get all error codes for a specific category
  static List<ErrorCode> getByCategory(ErrorCategory category) {
    return ErrorCode.values.where((code) => code.category == category).toList();
  }

  /// Get all error codes with a specific severity
  static List<ErrorCode> getBySeverity(ErrorSeverity severity) {
    return ErrorCode.values.where((code) => code.severity == severity).toList();
  }
}

/// Error categories for organizing error codes
enum ErrorCategory {
  /// User errors - caused by invalid input or user mistakes
  user,

  /// System errors - caused by OS, permissions, or system resources
  system,

  /// Integration errors - caused by external tools or dependencies
  integration,

  /// Internal errors - caused by bugs or unexpected states
  internal,
}

/// Error severity levels
enum ErrorSeverity {
  /// Informational message
  info,

  /// Warning - operation may have issues but can continue
  warning,

  /// Error - operation failed but may be recoverable
  error,

  /// Critical error - operation failed and cannot continue
  critical,
}

/// Extension methods for ErrorSeverity
extension ErrorSeverityExtension on ErrorSeverity {
  /// Whether this severity indicates failure
  bool get isFailure =>
      this == ErrorSeverity.error || this == ErrorSeverity.critical;

  /// Whether this severity indicates success
  bool get isSuccess => this == ErrorSeverity.info;

  /// Whether this severity indicates a warning
  bool get isWarning => this == ErrorSeverity.warning;

  /// Get the exit code for this severity
  int get exitCode {
    switch (this) {
      case ErrorSeverity.info:
        return 0;
      case ErrorSeverity.warning:
        return 0; // Warnings don't fail the command
      case ErrorSeverity.error:
        return 1;
      case ErrorSeverity.critical:
        return 2;
    }
  }
}
