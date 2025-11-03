import 'package:fly_cli/src/core/cli/cli_exit_code.dart';
import 'package:fly_cli/src/core/errors/error_codes.dart';

/// Maps ErrorCode to CliExitCode following POSIX standards
///
/// This class provides a centralized mapping between application error codes
/// and POSIX-compliant exit codes for better shell script integration.
class ExitCodeMapper {
  /// Map an ErrorCode to a CliExitCode
  ///
  /// Maps error codes to appropriate POSIX exit codes based on error category:
  /// - User errors (E1xxx) -> EX_USAGE (64) or EX_DATAERR (65)
  /// - System errors (E2xxx) -> EX_OSERR (71), EX_NOPERM (77), etc.
  /// - Integration errors (E3xxx) -> EX_UNAVAILABLE (69) or EX_SOFTWARE (70)
  /// - Internal errors (E4xxx) -> EX_SOFTWARE (70)
  ///
  /// [errorCode] - The error code to map
  /// Returns the corresponding CliExitCode
  static CliExitCode mapErrorCode(ErrorCode? errorCode) {
    if (errorCode == null) {
      return CliExitCode.generalError;
    }

    // Map based on error category
    return switch (errorCode.category) {
      ErrorCategory.user => _mapUserError(errorCode),
      ErrorCategory.system => _mapSystemError(errorCode),
      ErrorCategory.integration => _mapIntegrationError(errorCode),
      ErrorCategory.internal => CliExitCode.softwareError,
    };
  }

  /// Map user errors to exit codes
  static CliExitCode _mapUserError(ErrorCode errorCode) {
    // Usage errors (missing arguments, invalid values)
    if (errorCode == ErrorCode.missingRequiredArgument ||
        errorCode == ErrorCode.invalidArgumentValue) {
      return CliExitCode.usageError;
    }

    // Data format errors (invalid names, invalid formats)
    if (errorCode == ErrorCode.invalidProjectName ||
        errorCode == ErrorCode.invalidTemplateName ||
        errorCode == ErrorCode.invalidOrganizationId ||
        errorCode == ErrorCode.invalidPlatformList ||
        errorCode == ErrorCode.invalidFeatureName ||
        errorCode == ErrorCode.invalidServiceName ||
        errorCode == ErrorCode.invalidScreenName) {
      return CliExitCode.dataError;
    }

    // Default user error
    return CliExitCode.dataError;
  }

  /// Map system errors to exit codes
  static CliExitCode _mapSystemError(ErrorCode errorCode) {
    return switch (errorCode) {
      ErrorCode.permissionDenied => CliExitCode.noPermission,
      ErrorCode.networkError => CliExitCode.unavailable,
      ErrorCode.resourceUnavailable => CliExitCode.unavailable,
      ErrorCode.timeoutError => CliExitCode.tempFailure,
      ErrorCode.fileSystemError => CliExitCode.osFile,
      ErrorCode.diskSpaceError => CliExitCode.ioError,
      ErrorCode.processError => CliExitCode.osError,
      ErrorCode.environmentError => CliExitCode.config,
      _ => CliExitCode.osError,
    };
  }

  /// Map integration errors to exit codes
  static CliExitCode _mapIntegrationError(ErrorCode errorCode) {
    // SDK not found errors
    if (errorCode == ErrorCode.flutterSdkNotFound ||
        errorCode == ErrorCode.dartSdkNotFound) {
      return CliExitCode.unavailable;
    }

    // Template/tool errors
    if (errorCode == ErrorCode.templateNotFound ||
        errorCode == ErrorCode.masonError) {
      return CliExitCode.unavailable;
    }

    // Default integration error
    return CliExitCode.unavailable;
  }

  /// Map a general error to exit code
  ///
  /// For errors without a specific ErrorCode, returns general error code.
  static CliExitCode mapGeneralError() {
    return CliExitCode.generalError;
  }
}
