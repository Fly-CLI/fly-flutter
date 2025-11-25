import 'package:fly_cli/src/shared/logging/domain/log_level.dart';
import 'package:fly_cli/src/shared/logging/domain/logger.dart';

/// Mock logger for testing that captures log messages
class MockLogger implements Logger {
  final List<_LogEntry> _entries = [];

  /// All logged entries
  List<_LogEntry> get entries => List.unmodifiable(_entries);

  /// Info messages only
  List<String> get infoMessages => _entries
      .where((e) => e.level == LogLevel.info)
      .map((e) => e.message)
      .toList();

  /// Warning messages only
  List<String> get warningMessages => _entries
      .where((e) => e.level == LogLevel.warn)
      .map((e) => e.message)
      .toList();

  /// Error messages only
  List<String> get errorMessages => _entries
      .where((e) => e.level == LogLevel.error)
      .map((e) => e.message)
      .toList();

  /// Debug messages only
  List<String> get debugMessages => _entries
      .where((e) => e.level == LogLevel.debug)
      .map((e) => e.message)
      .toList();

  /// Clear all logged messages
  void clear() {
    _entries.clear();
  }

  /// Check if a specific message was logged
  bool hasMessage(String message, {LogLevel? level}) => _entries.any((e) {
    final messageMatch = e.message.contains(message);
    if (level != null) {
      return messageMatch && e.level == level;
    }
    return messageMatch;
  });

  @override
  String get name => 'MockLogger';

  @override
  Logger child(JsonMap contextFields) => this;

  @override
  Logger withFields(JsonMap fields) => this;

  @override
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    JsonMap? fields,
  }) {
    _entries.add(_LogEntry(level, message, error, stackTrace));
  }

  // Implement all the convenience methods from Logger interface
  @override
  void trace(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    JsonMap? fields,
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
    String message, {
    Object? error,
    StackTrace? stackTrace,
    JsonMap? fields,
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
    String message, {
    Object? error,
    StackTrace? stackTrace,
    JsonMap? fields,
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
    String message, {
    Object? error,
    StackTrace? stackTrace,
    JsonMap? fields,
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
    String message, {
    Object? error,
    StackTrace? stackTrace,
    JsonMap? fields,
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
    String message, {
    Object? error,
    StackTrace? stackTrace,
    JsonMap? fields,
  }) {
    log(
      LogLevel.fatal,
      message,
      error: error,
      stackTrace: stackTrace,
      fields: fields,
    );
  }
}

class _LogEntry {
  final LogLevel level;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  _LogEntry(this.level, this.message, this.error, this.stackTrace);
}
