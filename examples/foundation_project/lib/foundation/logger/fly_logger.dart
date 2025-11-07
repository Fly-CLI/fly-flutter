import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:logging/logging.dart' as logging;
import 'package:foundation_project/shared/firebase/crashlytics_manager.dart';

/// Standard log levels following industry conventions (RFC 5424).
/// 
/// Levels are ordered by severity, with higher values indicating more severe events.
enum LogLevel {
  /// Trace-level messages for very detailed diagnostic information.
  /// Typically used for internal tracing and flow control.
  trace(0, 'TRACE'),

  /// Debug-level messages for detailed diagnostic information.
  /// Typically used during development and debugging.
  debug(1, 'DEBUG'),

  /// Info-level messages for general informational events.
  /// Used to track application flow and state changes.
  info(2, 'INFO'),

  /// Warning-level messages for potentially problematic situations.
  /// Indicates situations that may cause problems but don't prevent operation.
  warn(3, 'WARN'),

  /// Error-level messages for error events.
  /// Indicates serious problems that may cause the application to fail.
  error(4, 'ERROR'),

  /// Fatal-level messages for critical events.
  /// Indicates severe errors that cause the application to abort.
  fatal(5, 'FATAL');

  /// Creates a [LogLevel] with the specified severity and label.
  const LogLevel(this.severity, this.label);

  /// Numeric severity value (higher = more severe).
  final int severity;

  /// Human-readable label for the log level.
  final String label;

  /// Returns true if this level is at least as severe as [other].
  bool isAtLeast(LogLevel other) => severity >= other.severity;

  /// Returns the log level from its string representation.
  static LogLevel? fromString(String level) {
    switch (level.toUpperCase()) {
      case 'TRACE':
        return LogLevel.trace;
      case 'DEBUG':
        return LogLevel.debug;
      case 'INFO':
        return LogLevel.info;
      case 'WARN':
      case 'WARNING':
        return LogLevel.warn;
      case 'ERROR':
        return LogLevel.error;
      case 'FATAL':
        return LogLevel.fatal;
      default:
        return null;
    }
  }
}

/// Type alias for structured log metadata.
/// 
/// Values can be any JSON-serializable type (String, num, bool, null,
/// List, Map, or nested combinations).
typedef LogFields = Map<String, Object?>;

/// Type alias for lazy message evaluation.
/// 
/// Used to defer expensive message construction until logging is actually needed.
typedef LogMessageBuilder = String Function();

/// Abstract interface for structured logging following industry standards.
/// 
/// This interface provides a comprehensive, reusable contract for logging
/// operations. It follows patterns from SLF4J, Log4j, Winston, and other
/// industry-standard logging frameworks.
/// 
/// **Key Features:**
/// - Standard log levels (TRACE, DEBUG, INFO, WARN, ERROR, FATAL)
/// - Structured logging with key-value metadata
/// - Child loggers with inherited context
/// - Lazy message evaluation for performance
/// - Automatic exception handling with stack traces
/// - Context propagation via fields
/// 
/// **Usage Example:**
/// ```dart
/// final logger = AppLogger('MyService');
/// 
/// // Simple logging
/// logger.info('User logged in');
/// 
/// // Structured logging
/// logger.info('User logged in', fields: {
///   'userId': user.id,
///   'timestamp': DateTime.now().toIso8601String(),
/// });
/// 
/// // Error logging with exception
/// try {
///   // ...
/// } catch (e, stackTrace) {
///   logger.error('Operation failed', error: e, stackTrace: stackTrace);
/// }
/// 
/// // Child logger with context
/// final requestLogger = logger.child({'requestId': requestId});
/// requestLogger.debug('Processing request');
/// ```
abstract class FlyLogger {
  /// The name/identifier of this logger instance.
  String get name;

  /// Creates a child logger with additional context fields.
  /// 
  /// Child loggers inherit all fields from the parent and add the provided
  /// fields. This is useful for request-scoped logging or operation tracking.
  /// 
  /// [fields] - Additional context fields to include in all log entries
  /// 
  /// Returns a new logger instance with the combined context
  /// 
  /// **Example:**
  /// ```dart
  /// final parent = logger.child({'service': 'api'});
  /// final child = parent.child({'requestId': '123'});
  /// // Both 'service' and 'requestId' will be included in child's logs
  /// ```
  FlyLogger child(LogFields fields);

  /// Creates a logger with additional fields for the next log call only.
  /// 
  /// Unlike [child], this returns the same logger instance but with
  /// temporary fields that apply only to the next log operation.
  /// 
  /// [fields] - Temporary fields to include in the next log entry
  /// 
  /// Returns a logger with temporary fields (may return `this`)
  FlyLogger withFields(LogFields fields);

  /// Logs a message at the specified level.
  /// 
  /// This is the core logging method. All level-specific methods delegate
  /// to this method.
  /// 
  /// [level] - The log level
  /// [message] - The log message (or builder function for lazy evaluation)
  /// [error] - Optional error object (Exception, Error, or any Object)
  /// [stackTrace] - Optional stack trace (automatically captured if error is provided and stackTrace is null)
  /// [fields] - Optional structured metadata
  /// 
  /// **Example:**
  /// ```dart
  /// logger.log(LogLevel.info, 'Processing started', fields: {'count': 42});
  /// logger.log(LogLevel.error, 'Failed', error: exception, stackTrace: stackTrace);
  /// logger.log(LogLevel.debug, () => expensiveMessageComputation());
  /// ```
  void log(
    LogLevel level,
    Object message, {
    Object? error,
    StackTrace? stackTrace,
    LogFields? fields,
  });

  /// Logs a trace-level message.
  /// 
  /// Trace messages are for very detailed diagnostic information, typically
  /// used for internal tracing and flow control.
  /// 
  /// [message] - The message or message builder
  /// [error] - Optional error object
  /// [stackTrace] - Optional stack trace
  /// [fields] - Optional structured metadata
  void trace(
    Object message, {
    Object? error,
    StackTrace? stackTrace,
    LogFields? fields,
  }) {
    log(
      LogLevel.trace,
      message,
      error: error,
      stackTrace: stackTrace,
      fields: fields,
    );
  }

  /// Logs a debug-level message.
  /// 
  /// Debug messages are for detailed diagnostic information, typically
  /// used during development and debugging.
  /// 
  /// [message] - The message or message builder
  /// [error] - Optional error object
  /// [stackTrace] - Optional stack trace
  /// [fields] - Optional structured metadata
  void debug(
    Object message, {
    Object? error,
    StackTrace? stackTrace,
    LogFields? fields,
  }) {
    log(
      LogLevel.debug,
      message,
      error: error,
      stackTrace: stackTrace,
      fields: fields,
    );
  }

  /// Logs an info-level message.
  /// 
  /// Info messages are for general informational events, used to track
  /// application flow and state changes.
  /// 
  /// [message] - The message or message builder
  /// [error] - Optional error object
  /// [stackTrace] - Optional stack trace
  /// [fields] - Optional structured metadata
  void info(
    Object message, {
    Object? error,
    StackTrace? stackTrace,
    LogFields? fields,
  }) {
    log(
      LogLevel.info,
      message,
      error: error,
      stackTrace: stackTrace,
      fields: fields,
    );
  }

  /// Logs a warning-level message.
  /// 
  /// Warning messages indicate potentially problematic situations that
  /// don't prevent the application from functioning.
  /// 
  /// [message] - The message or message builder
  /// [error] - Optional error object
  /// [stackTrace] - Optional stack trace
  /// [fields] - Optional structured metadata
  void warn(
    Object message, {
    Object? error,
    StackTrace? stackTrace,
    LogFields? fields,
  }) {
    log(
      LogLevel.warn,
      message,
      error: error,
      stackTrace: stackTrace,
      fields: fields,
    );
  }

  /// Logs an error-level message.
  /// 
  /// Error messages indicate serious problems that may cause the application
  /// to fail or behave unexpectedly.
  /// 
  /// [message] - The message or message builder
  /// [error] - Optional error object
  /// [stackTrace] - Optional stack trace
  /// [fields] - Optional structured metadata
  void error(
    Object message, {
    Object? error,
    StackTrace? stackTrace,
    LogFields? fields,
  }) {
    log(
      LogLevel.error,
      message,
      error: error,
      stackTrace: stackTrace,
      fields: fields,
    );
  }

  /// Logs a fatal-level message.
  /// 
  /// Fatal messages indicate severe errors that cause the application to abort.
  /// 
  /// [message] - The message or message builder
  /// [error] - Optional error object
  /// [stackTrace] - Optional stack trace
  /// [fields] - Optional structured metadata
  void fatal(
    Object message, {
    Object? error,
    StackTrace? stackTrace,
    LogFields? fields,
  }) {
    log(
      LogLevel.fatal,
      message,
      error: error,
      stackTrace: stackTrace,
      fields: fields,
    );
  }

  /// Checks if the specified level is enabled for this logger.
  /// 
  /// Useful for avoiding expensive operations when logging is disabled.
  /// 
  /// [level] - The log level to check
  /// 
  /// Returns true if messages at this level will be logged
  /// 
  /// **Example:**
  /// ```dart
  /// if (logger.isEnabled(LogLevel.debug)) {
  ///   final data = expensiveComputation();
  ///   logger.debug('Data: $data');
  /// }
  /// ```
  bool isEnabled(LogLevel level);
}

/// Concrete implementation of [FlyLogger] using `logging` package, `dart:developer`,
/// and Firebase Crashlytics.
/// 
/// This implementation provides:
/// - Console logging via `dart:developer`
/// - Structured logging via `logging` package
/// - Error reporting to Firebase Crashlytics
/// - Child logger support with context inheritance
/// - Lazy message evaluation
/// 
/// **Example:**
/// ```dart
/// final logger = AppLogger('MyService');
/// final childLogger = logger.child({'requestId': '123'});
/// childLogger.info('Request started');
/// ```
class FlyLoggerImpl implements FlyLogger {
  /// Creates an [FlyLoggerImpl] instance with the specified name.
  /// 
  /// [name] - The logger name (typically the class or module name)
  /// [minLevel] - Minimum log level (defaults to [LogLevel.debug] in debug mode, [LogLevel.info] in release)
  /// [contextFields] - Initial context fields to include in all log entries
  FlyLoggerImpl(
    this.name, {
    LogLevel? minLevel,
    LogFields? contextFields,
  })  : _logger = logging.Logger(name),
        _minLevel = minLevel ?? (kDebugMode ? LogLevel.debug : LogLevel.info),
        _contextFields = contextFields ?? <String, Object?>{};

  @override
  final String name;

  final logging.Logger _logger;
  final LogLevel _minLevel;
  final LogFields _contextFields;

  @override
  bool isEnabled(LogLevel level) => level.isAtLeast(_minLevel);

  @override
  FlyLogger child(LogFields fields) {
    return FlyLoggerImpl(
      name,
      minLevel: _minLevel,
      contextFields: {..._contextFields, ...fields},
    );
  }

  @override
  FlyLogger withFields(LogFields fields) {
    // For simplicity, we'll merge fields in the log method
    // A more sophisticated implementation could return a wrapper
    return _LoggerWithFields(this, fields);
  }

  @override
  void log(
    LogLevel level,
    Object message, {
    Object? error,
    StackTrace? stackTrace,
    LogFields? fields,
  }) {
    // Check if logging is enabled for this level
    if (!isEnabled(level)) {
      return;
    }

    // Resolve message (support lazy evaluation)
    final String messageStr = message is LogMessageBuilder
        ? message()
        : message.toString();

    // Merge context fields with provided fields
    final mergedFields = {..._contextFields, if (fields != null) ...fields};

    // Capture stack trace if error is provided but stack trace is not
    StackTrace? effectiveStackTrace = stackTrace;
    if (error != null && effectiveStackTrace == null) {
      try {
        effectiveStackTrace = StackTrace.current;
      } catch (_) {
        // Stack trace capture failed, continue without it
      }
    }

    // Log to dart:developer
    developer.log(
      messageStr,
      name: name,
      error: error,
      stackTrace: effectiveStackTrace,
    );

    // Log using logging package
    _logToLoggerPackage(level, messageStr, error, effectiveStackTrace);

    // Report to Crashlytics for error and fatal levels
    if (level.severity >= LogLevel.error.severity && error != null) {
      _reportToCrashlytics(
        error,
        effectiveStackTrace,
        reason: messageStr,
        fields: mergedFields,
      );
    }
  }

  @override
  void trace(
    Object message, {
    Object? error,
    StackTrace? stackTrace,
    LogFields? fields,
  }) {
    log(
      LogLevel.trace,
      message,
      error: error,
      stackTrace: stackTrace,
      fields: fields,
    );
  }

  @override
  void debug(
    Object message, {
    Object? error,
    StackTrace? stackTrace,
    LogFields? fields,
  }) {
    log(
      LogLevel.debug,
      message,
      error: error,
      stackTrace: stackTrace,
      fields: fields,
    );
  }

  @override
  void info(
    Object message, {
    Object? error,
    StackTrace? stackTrace,
    LogFields? fields,
  }) {
    log(
      LogLevel.info,
      message,
      error: error,
      stackTrace: stackTrace,
      fields: fields,
    );
  }

  @override
  void warn(
    Object message, {
    Object? error,
    StackTrace? stackTrace,
    LogFields? fields,
  }) {
    log(
      LogLevel.warn,
      message,
      error: error,
      stackTrace: stackTrace,
      fields: fields,
    );
  }

  @override
  void error(
    Object message, {
    Object? error,
    StackTrace? stackTrace,
    LogFields? fields,
  }) {
    log(
      LogLevel.error,
      message,
      error: error,
      stackTrace: stackTrace,
      fields: fields,
    );
  }

  @override
  void fatal(
    Object message, {
    Object? error,
    StackTrace? stackTrace,
    LogFields? fields,
  }) {
    log(
      LogLevel.fatal,
      message,
      error: error,
      stackTrace: stackTrace,
      fields: fields,
    );
  }

  void _logToLoggerPackage(
    LogLevel level,
    String message,
    Object? error,
    StackTrace? stackTrace,
  ) {
    switch (level) {
      case LogLevel.trace:
        _logger.finest(message, error, stackTrace);
        break;
      case LogLevel.debug:
        _logger.fine(message, error, stackTrace);
        break;
      case LogLevel.info:
        _logger.info(message, error, stackTrace);
        break;
      case LogLevel.warn:
        _logger.warning(message, error, stackTrace);
        break;
      case LogLevel.error:
        _logger.severe(message, error, stackTrace);
        break;
      case LogLevel.fatal:
        _logger.shout(message, error, stackTrace);
        break;
    }
  }

  void _reportToCrashlytics(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    LogFields? fields,
  }) {
    // Convert LogFields to Map<String, String> for Crashlytics
    final Map<String, String>? customKeys = fields?.map(
      (key, value) => MapEntry(key, value?.toString() ?? 'null'),
    );

    CrashlyticsManager.instance.recordErrorWithCustomKeys(
      error,
      stackTrace,
      reason: reason,
      customKeys: customKeys,
    );
  }
}

/// Internal wrapper logger that adds temporary fields to the next log call.
class _LoggerWithFields implements FlyLogger {
  _LoggerWithFields(this._delegate, this._tempFields);

  final FlyLogger _delegate;
  final LogFields _tempFields;

  @override
  String get name => _delegate.name;

  @override
  FlyLogger child(LogFields fields) {
    return _delegate.child({..._tempFields, ...fields});
  }

  @override
  FlyLogger withFields(LogFields fields) {
    return _LoggerWithFields(_delegate, {..._tempFields, ...fields});
  }

  @override
  void log(
    LogLevel level,
    Object message, {
    Object? error,
    StackTrace? stackTrace,
    LogFields? fields,
  }) {
    _delegate.log(
      level,
      message,
      error: error,
      stackTrace: stackTrace,
      fields: {..._tempFields, if (fields != null) ...fields},
    );
  }

  @override
  bool isEnabled(LogLevel level) => _delegate.isEnabled(level);

  @override
  void trace(
    Object message, {
    Object? error,
    StackTrace? stackTrace,
    LogFields? fields,
  }) =>
      log(
        LogLevel.trace,
        message,
        error: error,
        stackTrace: stackTrace,
        fields: fields,
      );

  @override
  void debug(
    Object message, {
    Object? error,
    StackTrace? stackTrace,
    LogFields? fields,
  }) =>
      log(
        LogLevel.debug,
        message,
        error: error,
        stackTrace: stackTrace,
        fields: fields,
      );

  @override
  void info(
    Object message, {
    Object? error,
    StackTrace? stackTrace,
    LogFields? fields,
  }) =>
      log(
        LogLevel.info,
        message,
        error: error,
        stackTrace: stackTrace,
        fields: fields,
      );

  @override
  void warn(
    Object message, {
    Object? error,
    StackTrace? stackTrace,
    LogFields? fields,
  }) =>
      log(
        LogLevel.warn,
        message,
        error: error,
        stackTrace: stackTrace,
        fields: fields,
      );

  @override
  void error(
    Object message, {
    Object? error,
    StackTrace? stackTrace,
    LogFields? fields,
  }) =>
      log(
        LogLevel.error,
        message,
        error: error,
        stackTrace: stackTrace,
        fields: fields,
      );

  @override
  void fatal(
    Object message, {
    Object? error,
    StackTrace? stackTrace,
    LogFields? fields,
  }) =>
      log(
        LogLevel.fatal,
        message,
        error: error,
        stackTrace: stackTrace,
        fields: fields,
      );
}
