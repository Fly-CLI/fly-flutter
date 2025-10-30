import 'dart:convert';
import 'dart:io';

import 'package:fly_mcp_server/src/config/server_config.dart';

/// Logger for MCP server that respects LoggingConfig
class Logger {
  /// Creates a logger with the specified configuration
  /// 
  /// [config] - Logging configuration (optional, defaults to enabled with info level)
  /// [output] - Output stream for logs (defaults to stderr)
  Logger({
    LoggingConfig? config,
    IOSink? output,
  })  : _config = config ?? const LoggingConfig(),
        _output = output ?? stderr;

  final LoggingConfig _config;
  final IOSink _output;

  /// Check if logging is enabled
  bool get enabled => _config.enabled;

  /// Check if a log level should be logged
  bool _shouldLog(LogLevel level) {
    if (!enabled) return false;

    // Map log levels to numeric values for comparison
    final levelValue = _levelValue(level);
    final configLevelValue = _levelValue(_config.level);
    return levelValue >= configLevelValue;
  }

  /// Get numeric value for log level
  int _levelValue(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 0;
      case LogLevel.info:
        return 1;
      case LogLevel.warning:
        return 2;
      case LogLevel.error:
        return 3;
    }
  }

  /// Get string representation of log level
  String _levelString(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 'debug';
      case LogLevel.info:
        return 'info';
      case LogLevel.warning:
        return 'warning';
      case LogLevel.error:
        return 'error';
    }
  }

  /// Log a debug message
  void debug(String message, {Map<String, Object?>? context}) {
    _log(LogLevel.debug, message, context: context);
  }

  /// Log an info message
  void info(String message, {Map<String, Object?>? context}) {
    _log(LogLevel.info, message, context: context);
  }

  /// Log a warning message
  void warning(String message, {Map<String, Object?>? context}) {
    _log(LogLevel.warning, message, context: context);
  }

  /// Log an error message
  void error(String message, {Object? error, Map<String, Object?>? context}) {
    final errorContext = <String, Object?>{
      if (context != null) ...context,
      if (error != null) 'error': error.toString(),
    };
    _log(LogLevel.error, message, context: errorContext);
  }

  /// Internal logging method
  void _log(
    LogLevel level,
    String message, {
    Map<String, Object?>? context,
  }) {
    if (!_shouldLog(level)) return;

    final logEntry = <String, Object?>{
      'component': 'fly_mcp_server',
      'level': _levelString(level),
      'message': message,
      'ts': DateTime.now().toIso8601String(),
    };

    if (_config.includeCorrelationIds && context != null) {
      if (context.containsKey('correlation_id')) {
        logEntry['correlation_id'] = context['correlation_id'];
      }
    }

    if (context != null) {
      for (final entry in context.entries) {
        if (entry.key != 'correlation_id' ||
            _config.includeCorrelationIds) {
          logEntry[entry.key] = entry.value;
        }
      }
    }

    try {
      _output.writeln(jsonEncode(logEntry));
    } catch (e) {
      // If JSON encoding fails, fall back to simple string output
      _output.writeln('[$level] $message');
    }
  }
}

