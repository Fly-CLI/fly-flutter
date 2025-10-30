import 'log_event.dart';
import 'log_level.dart';

typedef JsonMap = Map<String, Object?>;

abstract class Logger {
  String get name;

  Logger child(JsonMap contextFields);
  Logger withFields(JsonMap fields);

  void log(LogLevel level, String message, {Object? error, StackTrace? stackTrace, JsonMap? fields});

  void trace(String message, {Object? error, StackTrace? stackTrace, JsonMap? fields}) =>
      log(LogLevel.trace, message, error: error, stackTrace: stackTrace, fields: fields);

  void debug(String message, {Object? error, StackTrace? stackTrace, JsonMap? fields}) =>
      log(LogLevel.debug, message, error: error, stackTrace: stackTrace, fields: fields);

  void info(String message, {Object? error, StackTrace? stackTrace, JsonMap? fields}) =>
      log(LogLevel.info, message, error: error, stackTrace: stackTrace, fields: fields);

  void warn(String message, {Object? error, StackTrace? stackTrace, JsonMap? fields}) =>
      log(LogLevel.warn, message, error: error, stackTrace: stackTrace, fields: fields);

  void error(String message, {Object? error, StackTrace? stackTrace, JsonMap? fields}) =>
      log(LogLevel.error, message, error: error, stackTrace: stackTrace, fields: fields);

  void fatal(String message, {Object? error, StackTrace? stackTrace, JsonMap? fields}) =>
      log(LogLevel.fatal, message, error: error, stackTrace: stackTrace, fields: fields);
}


