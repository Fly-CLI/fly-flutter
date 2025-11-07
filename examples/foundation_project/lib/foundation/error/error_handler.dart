import 'package:flutter/foundation.dart';
import 'package:foundation_project/foundation/foundation.dart';
import 'package:foundation_project/core/di/global_container.dart';
import 'package:foundation_project/core/providers/logger_provider.dart';

/// Centralized error handling system for the application
class ErrorHandler {
  static Logger get _logger =>
      GlobalContainer.instance.read(loggerProvider('ErrorHandler'));

  /// Handles errors with proper logging and user-friendly messages
  static void handleError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
    Map<String, dynamic>? additionalData,
  }) {
    // Log error with context
    _logger.error(
      'Error in $context: $error',
      stackTrace: stackTrace,
      fields: additionalData?.map(
        (key, value) => MapEntry(key, value),
      ),
    );

    // Report to crashlytics if available
    if (kDebugMode) {
      print('Error: $error');
      print('Stack trace: $stackTrace');
      if (additionalData != null) {
        print('Additional data: $additionalData');
      }
    }
  }

  /// Converts technical errors to user-friendly messages
  static String getUserFriendlyMessage(
    dynamic error, {
    FoundationLocalizationProvider? localizations,
  }) {
    final loc = localizations ?? DefaultFoundationLocalizationProvider();
    if (error is NetworkException) {
      return loc.networkErrorConnectionRecovery;
    }

    if (error is ValidationException) {
      return error.message;
    }

    if (error is DatabaseException) {
      return loc.databaseErrorPleaseTryAgain;
    }

    if (error is AuthenticationException) {
      return loc.networkErrorAuthRecovery;
    }

    if (error is PermissionException) {
      return loc.permissionDenied;
    }

    if (error is TimeoutException) {
      return loc.networkErrorTimeoutRecovery;
    }

    if (error is AppException) {
      return error.message;
    }

    // Generic error message
    return loc.unexpectedErrorOccurred;
  }

  /// Handles async operations with error catching
  static Future<T> handleAsync<T>(
    Future<T> Function() operation, {
    String? context,
    T? defaultValue,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      handleError(error, stackTrace, context: context);

      if (defaultValue != null) {
        return defaultValue;
      }

      rethrow;
    }
  }

  /// Handles sync operations with error catching
  static T handleSync<T>(
    T Function() operation, {
    String? context,
    T? defaultValue,
  }) {
    try {
      return operation();
    } catch (error, stackTrace) {
      handleError(error, stackTrace, context: context);

      if (defaultValue != null) {
        return defaultValue;
      }

      rethrow;
    }
  }
}

/// Network-related exceptions
class NetworkException extends AppException {
  NetworkException(super.message, {super.code, super.details});
}

/// Validation-related exceptions
class ValidationException extends AppException {
  ValidationException(super.message, {super.code, super.details});
}

/// Database-related exceptions
class DatabaseException extends AppException {
  DatabaseException(super.message, {super.code, super.details});
}

/// Authentication-related exceptions
class AuthenticationException extends AppException {
  AuthenticationException(super.message, {super.code, super.details});
}

/// Permission-related exceptions
class PermissionException extends AppException {
  PermissionException(super.message, {super.code, super.details});
}

/// Timeout-related exceptions
class TimeoutException extends AppException {
  TimeoutException(super.message, {super.code, super.details});
}
