import 'dart:io';

import 'package:{{project_name_snake}}/core/foundation/foundation.dart';
import 'package:{{project_name_snake}}/shared/localization/localizations.dart';

/// Formats technical errors into user-friendly localized messages
///
/// This utility converts exceptions and errors into messages suitable
/// for display to end users, while logging technical details for debugging.
///
/// Usage:
/// ```dart
/// try {
///   await someOperation();
/// } catch (e) {
///   final userMessage = ErrorMessageFormatter.format(e);
///   ScaffoldMessenger.of(context).showSnackBar(
///     SnackBar(content: Text(userMessage)),
///   );
/// }
/// ```
class ErrorMessageFormatter {
  static final AppLogger _logger = AppLogger('ErrorMessageFormatter');

  /// Formats an error into a user-friendly localized message
  ///
  /// Converts technical exception details into localized messages
  /// appropriate for displaying to users. Technical details are
  /// logged for debugging purposes.
  ///
  /// Parameters:
  /// - [error]: The error or exception to format
  /// - [logError]: Whether to log the technical error (default: true)
  ///
  /// Returns a localized, user-friendly error message
  static String format(Object error, {bool logError = true}) {
    // Log technical error for debugging
    if (logError) {
      _logger.logError('Formatting error for user display: $error');
    }

    // Handle custom app exceptions first
    if (error is AppException) {
      return _formatAppException(error);
    }

    // Handle common system exceptions
    if (error is SocketException) {
      return _formatNetworkError(error);
    }

    if (error is TimeoutException) {
      return localizations.networkErrorTimeoutRecovery;
    }

    if (error is FileSystemException) {
      return localizations.databaseErrorPleaseTryAgain;
    }

    if (error is FormatException) {
      return localizations.unexpectedErrorOccurred;
    }

    // Check error string for common patterns
    return _formatByErrorString(error);
  }

  /// Formats custom AppException types
  static String _formatAppException(AppException exception) {
    if (exception is NetworkException) {
      return localizations.networkErrorConnectionRecovery;
    }

    if (exception is DatabaseException) {
      return localizations.databaseErrorPleaseTryAgain;
    }

    if (exception is ValidationException) {
      // Validation exceptions usually have good messages already
      return exception.message;
    }

    if (exception is AuthenticationException) {
      return localizations.networkErrorAuthRecovery;
    }

    if (exception is PermissionException) {
      return localizations.permissionDenied;
    }

    if (exception is TimeoutException) {
      return localizations.networkErrorTimeoutRecovery;
    }

    // Generic AppException - use its message if meaningful
    if (exception.message.isNotEmpty &&
        !exception.message.contains('Exception') &&
        !exception.message.contains('Error:')) {
      return exception.message;
    }

    return localizations.unexpectedErrorOccurred;
  }

  /// Formats network-related errors
  static String _formatNetworkError(SocketException exception) {
    final message = exception.message.toLowerCase();

    if (message.contains('failed host lookup') ||
        message.contains('no address associated')) {
      return localizations.networkErrorDnsRecovery;
    }

    if (message.contains('connection refused') ||
        message.contains('connection failed')) {
      return localizations.networkErrorConnectionRecovery;
    }

    if (message.contains('network is unreachable')) {
      return localizations.networkErrorNoInternetRecovery;
    }

    // Generic network error
    return localizations.networkErrorConnectionRecovery;
  }

  /// Formats errors by analyzing the error string
  static String _formatByErrorString(Object error) {
    final errorString = error.toString().toLowerCase();

    // Network-related errors
    if (errorString.contains('socketexception') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('network')) {
      return localizations.networkErrorConnectionRecovery;
    }

    // Database-related errors
    if (errorString.contains('sqliteexception') ||
        errorString.contains('database') ||
        errorString.contains('sql')) {
      return localizations.databaseErrorPleaseTryAgain;
    }

    // Timeout errors
    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return localizations.networkErrorTimeoutRecovery;
    }

    // Permission errors
    if (errorString.contains('permission') ||
        errorString.contains('denied') ||
        errorString.contains('access denied')) {
      return localizations.permissionDenied;
    }

    // Authentication errors
    if (errorString.contains('authentication') ||
        errorString.contains('unauthorized') ||
        errorString.contains('401')) {
      return localizations.networkErrorAuthRecovery;
    }

    // Not found errors
    if (errorString.contains('not found') || errorString.contains('404')) {
      return localizations.networkErrorNotFoundRecovery;
    }

    // Rate limit errors
    if (errorString.contains('rate limit') ||
        errorString.contains('too many requests') ||
        errorString.contains('429')) {
      return localizations.networkErrorRateLimitRecovery;
    }

    // Server errors
    if (errorString.contains('500') ||
        errorString.contains('503') ||
        errorString.contains('server error')) {
      return localizations.networkErrorServerRecovery;
    }

    // Certificate/SSL errors
    if (errorString.contains('certificate') ||
        errorString.contains('ssl') ||
        errorString.contains('handshake')) {
      return localizations.networkErrorCertificateRecovery;
    }

    // Generic fallback
    _logger.logWarning('Unknown error type, using generic message: $error');
    return localizations.networkErrorUnknownRecovery;
  }

  /// Checks if an error is network-related
  static bool isNetworkError(Object error) {
    if (error is SocketException || error is NetworkException) {
      return true;
    }

    final errorString = error.toString().toLowerCase();
    return errorString.contains('socketexception') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('network');
  }

  /// Checks if an error is database-related
  static bool isDatabaseError(Object error) {
    if (error is DatabaseException) {
      return true;
    }

    final errorString = error.toString().toLowerCase();
    return errorString.contains('sqliteexception') ||
        errorString.contains('database') ||
        errorString.contains('sql');
  }

  /// Checks if an error is timeout-related
  static bool isTimeoutError(Object error) {
    if (error is TimeoutException) {
      return true;
    }

    final errorString = error.toString().toLowerCase();
    return errorString.contains('timeout') || errorString.contains('timed out');
  }
}

