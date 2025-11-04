import 'dart:io';

import 'package:flutter/material.dart';
import 'package:foundation_project/core/foundation/foundation.dart';
import 'package:foundation_project/l10n/app_localizations.dart';
import 'package:foundation_project/shared/localization/localizations.dart' as fallback;

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
  /// - [context]: BuildContext for localization (optional - uses fallback if null)
  /// - [logError]: Whether to log the technical error (default: true)
  ///
  /// Returns a localized, user-friendly error message
  static String format(Object error, {BuildContext? context, bool logError = true}) {
    // Log technical error for debugging
    if (logError) {
      _logger.logError('Formatting error for user display: $error');
    }

    // Use AppLocalizations if context is available, otherwise use fallback
    final l10n = context != null 
        ? AppLocalizations.of(context).asLocalizationInterface
        : _FallbackLocalizations();

    // Handle custom app exceptions first
    if (error is AppException) {
      return _formatAppException(error, l10n);
    }

    // Handle common system exceptions
    if (error is SocketException) {
      return _formatNetworkError(error, l10n);
    }

    if (error is TimeoutException) {
      return l10n.networkErrorTimeoutRecovery;
    }

    if (error is FileSystemException) {
      return l10n.databaseErrorPleaseTryAgain;
    }

    if (error is FormatException) {
      return l10n.unexpectedErrorOccurred;
    }

    // Check error string for common patterns
    return _formatByErrorString(error, l10n);
  }

  /// Formats custom AppException types
  static String _formatAppException(AppException exception, _LocalizationInterface l10n) {
    if (exception is NetworkException) {
      return l10n.networkErrorConnectionRecovery;
    }

    if (exception is DatabaseException) {
      return l10n.databaseErrorPleaseTryAgain;
    }

    if (exception is ValidationException) {
      // Validation exceptions usually have good messages already
      return exception.message;
    }

    if (exception is AuthenticationException) {
      return l10n.networkErrorAuthRecovery;
    }

    if (exception is PermissionException) {
      return l10n.permissionDenied;
    }

    if (exception is TimeoutException) {
      return l10n.networkErrorTimeoutRecovery;
    }

    // Generic AppException - use its message if meaningful
    if (exception.message.isNotEmpty &&
        !exception.message.contains('Exception') &&
        !exception.message.contains('Error:')) {
      return exception.message;
    }

    return l10n.unexpectedErrorOccurred;
  }

  /// Formats network-related errors
  static String _formatNetworkError(SocketException exception, _LocalizationInterface l10n) {
    final message = exception.message.toLowerCase();

    if (message.contains('failed host lookup') ||
        message.contains('no address associated')) {
      return l10n.networkErrorDnsRecovery;
    }

    if (message.contains('connection refused') ||
        message.contains('connection failed')) {
      return l10n.networkErrorConnectionRecovery;
    }

    if (message.contains('network is unreachable')) {
      return l10n.networkErrorNoInternetRecovery;
    }

    // Generic network error
    return l10n.networkErrorConnectionRecovery;
  }

  /// Formats errors by analyzing the error string
  static String _formatByErrorString(Object error, _LocalizationInterface l10n) {
    final errorString = error.toString().toLowerCase();

    // Network-related errors
    if (errorString.contains('socketexception') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('network')) {
      return l10n.networkErrorConnectionRecovery;
    }

    // Database-related errors
    if (errorString.contains('sqliteexception') ||
        errorString.contains('database') ||
        errorString.contains('sql')) {
      return l10n.databaseErrorPleaseTryAgain;
    }

    // Timeout errors
    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return l10n.networkErrorTimeoutRecovery;
    }

    // Permission errors
    if (errorString.contains('permission') ||
        errorString.contains('denied') ||
        errorString.contains('access denied')) {
      return l10n.permissionDenied;
    }

    // Authentication errors
    if (errorString.contains('authentication') ||
        errorString.contains('unauthorized') ||
        errorString.contains('401')) {
      return l10n.networkErrorAuthRecovery;
    }

    // Not found errors
    if (errorString.contains('not found') || errorString.contains('404')) {
      return l10n.networkErrorNotFoundRecovery;
    }

    // Rate limit errors
    if (errorString.contains('rate limit') ||
        errorString.contains('too many requests') ||
        errorString.contains('429')) {
      return l10n.networkErrorRateLimitRecovery;
    }

    // Server errors
    if (errorString.contains('500') ||
        errorString.contains('503') ||
        errorString.contains('server error')) {
      return l10n.networkErrorServerRecovery;
    }

    // Certificate/SSL errors
    if (errorString.contains('certificate') ||
        errorString.contains('ssl') ||
        errorString.contains('handshake')) {
      return l10n.networkErrorCertificateRecovery;
    }

    // Generic fallback
    _logger.logWarning('Unknown error type, using generic message: $error');
    return l10n.networkErrorUnknownRecovery;
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

/// Interface for localization methods used by ErrorMessageFormatter
abstract class _LocalizationInterface {
  String get networkErrorConnectionRecovery;
  String get networkErrorTimeoutRecovery;
  String get networkErrorDnsRecovery;
  String get networkErrorNoInternetRecovery;
  String get networkErrorAuthRecovery;
  String get networkErrorNotFoundRecovery;
  String get networkErrorRateLimitRecovery;
  String get networkErrorServerRecovery;
  String get networkErrorCertificateRecovery;
  String get networkErrorUnknownRecovery;
  String get databaseErrorPleaseTryAgain;
  String get permissionDenied;
  String get unexpectedErrorOccurred;
}

/// Extension to make AppLocalizations conform to _LocalizationInterface
extension _AppLocalizationsExtension on AppLocalizations {
  _LocalizationInterface get asLocalizationInterface => _AppLocalizationsAdapter(this);
}

class _AppLocalizationsAdapter implements _LocalizationInterface {
  final AppLocalizations _l10n;
  
  _AppLocalizationsAdapter(this._l10n);
  
  @override
  String get networkErrorConnectionRecovery => _l10n.networkErrorConnectionRecovery;
  
  @override
  String get networkErrorTimeoutRecovery => _l10n.networkErrorTimeoutRecovery;
  
  @override
  String get networkErrorDnsRecovery => _l10n.networkErrorDnsRecovery;
  
  @override
  String get networkErrorNoInternetRecovery => _l10n.networkErrorNoInternetRecovery;
  
  @override
  String get networkErrorAuthRecovery => _l10n.networkErrorAuthRecovery;
  
  @override
  String get networkErrorNotFoundRecovery => _l10n.networkErrorNotFoundRecovery;
  
  @override
  String get networkErrorRateLimitRecovery => _l10n.networkErrorRateLimitRecovery;
  
  @override
  String get networkErrorServerRecovery => _l10n.networkErrorServerRecovery;
  
  @override
  String get networkErrorCertificateRecovery => _l10n.networkErrorCertificateRecovery;
  
  @override
  String get networkErrorUnknownRecovery => _l10n.networkErrorUnknownRecovery;
  
  @override
  String get databaseErrorPleaseTryAgain => _l10n.databaseErrorPleaseTryAgain;
  
  @override
  String get permissionDenied => _l10n.permissionDenied;
  
  @override
  String get unexpectedErrorOccurred => _l10n.unexpectedErrorOccurred;
}

/// Fallback localizations adapter for when BuildContext is not available
class _FallbackLocalizations implements _LocalizationInterface {
  @override
  String get networkErrorConnectionRecovery => fallback.localizations.networkErrorConnectionRecovery;
  
  @override
  String get networkErrorTimeoutRecovery => fallback.localizations.networkErrorTimeoutRecovery;
  
  @override
  String get networkErrorDnsRecovery => fallback.localizations.networkErrorDnsRecovery;
  
  @override
  String get networkErrorNoInternetRecovery => fallback.localizations.networkErrorNoInternetRecovery;
  
  @override
  String get networkErrorAuthRecovery => fallback.localizations.networkErrorAuthRecovery;
  
  @override
  String get networkErrorNotFoundRecovery => fallback.localizations.networkErrorNotFoundRecovery;
  
  @override
  String get networkErrorRateLimitRecovery => fallback.localizations.networkErrorRateLimitRecovery;
  
  @override
  String get networkErrorServerRecovery => fallback.localizations.networkErrorServerRecovery;
  
  @override
  String get networkErrorCertificateRecovery => fallback.localizations.networkErrorCertificateRecovery;
  
  @override
  String get networkErrorUnknownRecovery => fallback.localizations.networkErrorUnknownRecovery;
  
  @override
  String get databaseErrorPleaseTryAgain => fallback.localizations.databaseErrorPleaseTryAgain;
  
  @override
  String get permissionDenied => fallback.localizations.permissionDenied;
  
  @override
  String get unexpectedErrorOccurred => fallback.localizations.unexpectedErrorOccurred;
}

