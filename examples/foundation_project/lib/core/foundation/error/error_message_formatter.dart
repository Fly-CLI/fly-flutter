import 'dart:io';

import 'package:flutter/material.dart';
import 'package:foundation_project/core/foundation/foundation.dart';

/// Formats technical errors into user-friendly messages
///
/// This utility converts exceptions and errors into messages suitable
/// for display to end users, while logging technical details for debugging.
///
/// Users can provide their own formatter function for localization.
///
/// Usage:
/// ```dart
/// try {
///   await someOperation();
/// } catch (e) {
///   final userMessage = ErrorMessageFormatter.format(
///     e,
///     formatter: (error) => AppLocalizations.of(context).formatError(error),
///   );
///   ScaffoldMessenger.of(context).showSnackBar(
///     SnackBar(content: Text(userMessage)),
///   );
/// }
/// ```
class ErrorMessageFormatter {
  static final AppLogger _logger = AppLogger('ErrorMessageFormatter');

  /// Formats an error into a user-friendly message
  ///
  /// Converts technical exception details into messages appropriate for displaying
  /// to users. Technical details are logged for debugging purposes.
  ///
  /// Parameters:
  /// - [error]: The error or exception to format
  /// - [formatter]: Optional formatter function for localization. If provided, this
  ///   function will be called with the error to get a localized message.
  ///   If not provided, returns basic error message or exception.toString().
  /// - [logError]: Whether to log the technical error (default: true)
  ///
  /// Returns a user-friendly error message (localized if formatter is provided)
  static String format(
    Object error, {
    String Function(Object error)? formatter,
    bool logError = true,
  }) {
    // Log technical error for debugging
    if (logError) {
      _logger.logError('Formatting error for user display: $error');
    }

    // If user provides formatter, use it
    if (formatter != null) {
      return formatter(error);
    }

    // Otherwise, return basic error message (no localization)
    if (error is AppException && error.message.isNotEmpty) {
      return error.message;
    }

    return error.toString(); // Fallback to raw error string
  }

  /// Formats custom AppException types
  /// @deprecated Use [format] with a formatter function instead
  @Deprecated('Use format() with a formatter function for localization')
  static String _formatAppException(AppException exception, dynamic l10n) {
    // This method is kept for backward compatibility but is no longer used
    // Users should provide their own formatter function
    return exception.message.isNotEmpty ? exception.message : exception.toString();
  }

  /// Formats network-related errors
  /// @deprecated Use [format] with a formatter function instead
  @Deprecated('Use format() with a formatter function for localization')
  static String _formatNetworkError(SocketException exception, dynamic l10n) {
    // This method is kept for backward compatibility but is no longer used
    return exception.message;
  }

  /// Formats errors by analyzing the error string
  /// @deprecated Use [format] with a formatter function instead
  @Deprecated('Use format() with a formatter function for localization')
  static String _formatByErrorString(Object error, dynamic l10n) {
    final errorString = error.toString().toLowerCase();

    // Network-related errors
    if (errorString.contains('socketexception') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('network')) {
      return error.toString();
    }

    // Database-related errors
    if (errorString.contains('sqliteexception') ||
        errorString.contains('database') ||
        errorString.contains('sql')) {
      return error.toString();
    }

    // Timeout errors
    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return error.toString();
    }

    // Permission errors
    if (errorString.contains('permission') ||
        errorString.contains('denied') ||
        errorString.contains('access denied')) {
      return error.toString();
    }

    // Authentication errors
    if (errorString.contains('authentication') ||
        errorString.contains('unauthorized') ||
        errorString.contains('401')) {
      return error.toString();
    }

    // Not found errors
    if (errorString.contains('not found') || errorString.contains('404')) {
      return error.toString();
    }

    // Rate limit errors
    if (errorString.contains('rate limit') ||
        errorString.contains('too many requests') ||
        errorString.contains('429')) {
      return error.toString();
    }

    // Server errors
    if (errorString.contains('500') ||
        errorString.contains('503') ||
        errorString.contains('server error')) {
      return error.toString();
    }

    // Certificate/SSL errors
    if (errorString.contains('certificate') ||
        errorString.contains('ssl') ||
        errorString.contains('handshake')) {
      return error.toString();
    }

    // Generic fallback
    _logger.logWarning('Unknown error type, using generic message: $error');
    return error.toString();
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


