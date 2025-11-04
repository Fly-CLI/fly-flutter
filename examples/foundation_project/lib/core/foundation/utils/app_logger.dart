import 'dart:developer' as developer;

import 'package:logging/logging.dart';
import 'package:foundation_project/shared/firebase/crashlytics_manager.dart';

/// A reusable logger class that provides consistent logging functionality
/// across the application.
class AppLogger {
  AppLogger(String name) : _logger = Logger(name);

  final Logger _logger;

  /// Logs a message with optional error and stack trace
  /// Also reports to Crashlytics if error is provided
  void log(
    String message, {
    String? error,
    StackTrace? stackTrace,
    Map<String, String>? customKeys,
  }) {
    // Log to console
    developer.log(
      message,
      name: _logger.name,
      error: error,
      stackTrace: stackTrace,
    );

    // Log using Logger package
    if (error != null) {
      _logger.severe(message, error, stackTrace);
    } else {
      _logger.info(message);
    }

    // Report to Crashlytics if there's an error
    if (error != null) {
      CrashlyticsManager.instance.recordErrorWithCustomKeys(
        error,
        stackTrace,
        reason: message,
        customKeys: customKeys,
      );
    }
  }

  /// Logs info messages
  void info(String message) {
    _logger.info(message);
    developer.log(message, name: _logger.name);
  }

  /// Logs debug information
  void debug(String message) {
    _logger.fine(message);
    developer.log(message, name: _logger.name);
  }

  /// Logs warning messages
  void warning(String message, [Object? error]) {
    _logger.warning(message, error);
    developer.log(message, name: _logger.name, error: error);
  }

  /// Logs error messages with optional stack trace and custom keys
  void logError(
    String error, {
    StackTrace? stackTrace,
    Map<String, String>? customKeys,
  }) {
    // Log to console and Logger package
    _logger.severe(error, error, stackTrace);
    developer.log(
      error,
      name: _logger.name,
      error: error,
      stackTrace: stackTrace,
    );

    // Report to Crashlytics
    CrashlyticsManager.instance.recordErrorWithCustomKeys(
      error,
      stackTrace,
      customKeys: customKeys,
    );
  }

  /// Logs warning messages with optional stack trace and custom keys
  void logWarning(
    String warning, {
    StackTrace? stackTrace,
    Map<String, String>? customKeys,
  }) {
    // Log to console and Logger package
    _logger.warning(warning, warning, stackTrace);
    developer.log(
      warning,
      name: _logger.name,
      error: warning,
      stackTrace: stackTrace,
    );

    // Report to Crashlytics if custom keys are provided or stack trace exists
    if (customKeys != null || stackTrace != null) {
      CrashlyticsManager.instance.recordErrorWithCustomKeys(
        warning,
        stackTrace,
        reason: 'Warning: $warning',
        customKeys: customKeys,
      );
    }
  }

  /// Logs a message with the specified log level
  void logMessage(String message, LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        debug(message);
      case LogLevel.info:
        info(message);
      case LogLevel.warning:
        warning(message);
      case LogLevel.error:
        logError(message);
      case LogLevel.success:
        // Success is logged as info level
        info(message);
    }
  }

  /// Logs error messages (alias for logError)
  void error(
    String error, {
    StackTrace? stackTrace,
    Map<String, String>? customKeys,
  }) {
    logError(error, stackTrace: stackTrace, customKeys: customKeys);
  }

  /// Creates a string representation of an HTTP request for logging
  String formatRequestLog(
    String method,
    Uri url,
    Map<String, String> headers, [
    String? body,
  ]) {
    final requestLog = StringBuffer()
      ..writeln('$method Request: $url')
      ..writeln('Headers: $headers');

    if (body != null) {
      requestLog.writeln('Body: $body');
    }

    return requestLog.toString();
  }

  /// Creates a string representation of an HTTP response for logging
  String formatResponseLog(int statusCode, String body) {
    return '''
Response Status: $statusCode
Body: $body''';
  }
}

/// Log level enum
enum LogLevel {
  debug,
  info,
  warning,
  error,
  success;

  String toLogLevel() {
    switch (this) {
      case LogLevel.debug:
        return 'debug';
      case LogLevel.info:
        return 'info';
      case LogLevel.warning:
        return 'warning';
      case LogLevel.error:
        return 'error';
      case LogLevel.success:
        return 'info';
    }
  }
}
