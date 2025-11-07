import 'dart:io';

import 'package:foundation_project/foundation/foundation.dart';

/// Formats technical errors into user-friendly localized messages
///
/// This utility provides a centralized, type-safe system for converting exceptions
/// into messages suitable for display to end users. It uses an explicit registry
/// pattern to ensure only known exception types are formatted, preventing accidental
/// exposure of sensitive data.
///
/// ## Architecture
///
/// The formatter uses a three-tier approach:
/// 1. **Registry-based formatting**: Known AppException types are looked up in a
///    type-safe registry and formatted using registered handlers
/// 2. **System exception handling**: Common system exceptions (SocketException,
///    FileSystemException, etc.) receive appropriate user-friendly messages
/// 3. **Fallback processing**: Unknown errors are cleaned of technical prefixes
///    and passed through, or replaced with generic messages if unusable
///
/// ## Usage
///
/// Basic error formatting:
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
///
/// ## Adding New Exception Types
///
/// To add support for a new exception type:
///
/// 1. **Create a custom exception class** extending `AppException`:
/// ```dart
/// class MyCustomException extends AppException {
///   MyCustomException(String message) : super(message);
/// }
/// ```
///
/// 2. **Register the exception** in `_exceptionFormatters`:
/// ```dart
/// static final Map<Type, String Function(AppException)> _exceptionFormatters = {
///   // ... existing entries ...
///   MyCustomException: (e) => e.message,
/// };
/// ```
///
/// 3. **Add tests** to verify formatting behavior:
/// ```dart
/// test('should format MyCustomException', () {
///   final error = MyCustomException('Custom error');
///   final formatted = ErrorMessageFormatter.format(error);
///   expect(formatted, equals('Custom error'));
/// });
/// ```
///
/// ## Design Principles
///
/// - **Type Safety**: Use explicit exception types instead of string matching
/// - **Security**: Only registered exception types are formatted to prevent data leaks
/// - **Maintainability**: Clear registry makes it easy to see all handled exceptions
/// - **Localization**: All formatted messages use localized strings
/// - **Logging**: Technical details are logged for debugging while users see friendly messages
///
/// ## Error Handling Strategy
///
/// - **Validation errors**: Pass through the exception message (usually already user-friendly)
/// - **Network errors**: Provide recovery suggestions based on error type
/// - **Database errors**: Generic message to avoid exposing database structure
/// - **Business rule violations**: Show detailed, actionable information to users
/// - **Unknown errors**: Clean technical prefixes or use generic fallback
///
/// See also:
/// - [AppException] - Base class for custom exceptions
class ErrorMessageFormatter {
  static final FlyLoggerImpl _logger = FlyLoggerImpl('ErrorMessageFormatter');

  /// Registry of known AppException types and their formatters
  /// 
  /// This explicit mapping provides type-safe exception handling and prevents
  /// accidental exposure of sensitive data through unhandled exception types.
  /// 
  /// To add a new exception type:
  /// 1. Add the exception type to this map with its formatter function
  /// 2. Ensure the formatter returns a user-friendly, localized message
  /// 3. Add tests to verify the formatting behavior
  static Map<Type, String Function(AppException, FoundationLocalizationProvider)> _exceptionFormatters(
    FoundationLocalizationProvider localizations,
  ) {
    return {
      ValidationException: (e, _) => e.message,
      NetworkException: (e, loc) => loc.networkErrorConnectionRecovery,
      DatabaseException: (e, loc) => loc.databaseErrorPleaseTryAgain,
      AuthenticationException: (e, loc) => loc.networkErrorAuthRecovery,
      PermissionException: (e, loc) => loc.permissionDenied,
      TimeoutException: (e, loc) => loc.networkErrorTimeoutRecovery,
  };
  }

  /// Formats an error into a user-friendly localized message
  ///
  /// Converts technical exception details into localized messages
  /// appropriate for displaying to users. Technical details are
  /// logged for debugging purposes.
  ///
  /// Parameters:
  /// - [error]: The error or exception to format
  /// - [localizations]: Localization provider (defaults to DefaultFoundationLocalizationProvider)
  /// - [logError]: Whether to log the technical error (default: true)
  ///
  /// Returns a localized, user-friendly error message
  static String format(
    Object error, {
    FoundationLocalizationProvider? localizations,
    bool logError = true,
  }) {
    final loc = localizations ?? DefaultFoundationLocalizationProvider();
    // Log technical error for debugging
    if (logError) {
      _logger.error('Formatting error for user display: $error');
    }

    // Handle custom app exceptions first
    if (error is AppException) {
      return _formatAppException(error, loc);
    }

    // Handle common system exceptions
    if (error is SocketException) {
      return _formatNetworkError(error, loc);
    }

    if (error is TimeoutException) {
      return loc.networkErrorTimeoutRecovery;
    }

    if (error is FileSystemException) {
      return loc.databaseErrorPleaseTryAgain;
    }

    if (error is FormatException) {
      return loc.unexpectedErrorOccurred;
    }

    // Check error string for common patterns
    return _formatByErrorString(error, loc);
  }

  /// Formats custom AppException types using the registry
  /// 
  /// This method looks up the exception type in the registry and applies
  /// the registered formatter. For unregistered exception types, it attempts
  /// to use the exception's message if meaningful, otherwise returns a generic error.
  static String _formatAppException(
    AppException exception,
    FoundationLocalizationProvider localizations,
  ) {
    // Look up formatter in registry
    final formatters = _exceptionFormatters(localizations);
    final formatter = formatters[exception.runtimeType];
    if (formatter != null) {
      return formatter(exception, localizations);
    }
    
    // Fallback for unregistered AppException types
    // Use the exception's message if it's meaningful (not just technical noise)
    if (exception.message.isNotEmpty &&
        !exception.message.contains('Exception') &&
        !exception.message.contains('Error:')) {
      return exception.message;
    }

    // Last resort: generic error message
    _logger.warn(
      'Unregistered AppException type: ${exception.runtimeType}. '
      'Consider adding it to _exceptionFormatters registry.',
    );
    return localizations.unexpectedErrorOccurred;
  }

  /// Formats network-related errors
  static String _formatNetworkError(
    SocketException exception,
    FoundationLocalizationProvider localizations,
  ) {
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

  /// Extracts the meaningful message from an error string
  /// 
  /// This method cleans up error strings by:
  /// - Removing technical prefixes like "Exception: "
  /// - Detecting and handling empty or purely technical messages
  /// - Providing a fallback for unusable error messages
  /// 
  /// Returns a user-friendly message or a generic fallback if the message
  /// contains no useful information.
  static String _extractMessage(
    String errorString,
    FoundationLocalizationProvider localizations,
  ) {
    String message = errorString.trim();
    
    // Remove technical prefixes (handle multiple occurrences)
    while (message.startsWith('Exception: ')) {
      message = message.substring('Exception: '.length).trim();
    }
    
    // Check if message is empty or just technical noise
    if (message.isEmpty) {
      _logger.warn('Empty error message encountered');
      return localizations.unexpectedErrorOccurred;
    }
    
    // Check for technical noise patterns that aren't useful to users
    final messageLower = message.toLowerCase();
    if (messageLower.startsWith('instance of ') ||
        messageLower == 'null' ||
        messageLower == 'exception' ||
        messageLower == 'exception:' ||  // Handle empty exception toString
        messageLower == 'error') {
      _logger.warn('Technical error message encountered: $message');
      return localizations.unexpectedErrorOccurred;
    }
    
    return message;
  }

  /// Formats errors by analyzing the error string (fallback for non-typed exceptions)
  /// 
  /// This method is a last resort for errors that are not properly typed exceptions.
  /// Most errors should be handled through the type-based registry system instead.
  /// 
  /// IMPORTANT: String pattern matching is fragile and should be avoided.
  /// Always create custom exception types for business rules instead of relying
  /// on string patterns.
  /// 
  /// This method simply cleans the error message and passes it through, allowing
  /// meaningful error messages to reach users while removing technical prefixes.
  /// If the error is truly unknown/technical, the user will get a fallback message
  /// from _extractMessage.
  static String _formatByErrorString(
    Object error,
    FoundationLocalizationProvider localizations,
  ) {
    final errorString = error.toString();
    
    // Clean the message and pass through - no string pattern matching
    // All business rules should be handled by typed exceptions in the registry
    return _extractMessage(errorString, localizations);
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
