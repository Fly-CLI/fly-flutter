import 'package:fly_cli/src/core/logging/domain/log_level.dart';
import 'package:fly_cli/src/core/logging/domain/logger.dart' as flylog;
import 'package:mason_logger/mason_logger.dart' as mason;

class LoggerAdapter {
  LoggerAdapter({required this.masonLogger, required this.flyLogger});

  final mason.Logger masonLogger;
  final flylog.Logger flyLogger;

  void info(String message, {Map<String, Object?>? fields}) {
    masonLogger.info(message);
    flyLogger.info(message, fields: fields);
  }

  void warn(String message, {Map<String, Object?>? fields}) {
    masonLogger.warn(message);
    flyLogger.warn(message, fields: fields);
  }

  void err(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? fields,
  }) {
    masonLogger.err(message);
    flyLogger.error(
      message,
      error: error,
      stackTrace: stackTrace,
      fields: fields,
    );
  }

  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? fields,
  }) {
    switch (level) {
      case LogLevel.trace:
      case LogLevel.debug:
      case LogLevel.info:
        info(message, fields: fields);
        break;
      case LogLevel.warn:
        warn(message, fields: fields);
        break;
      case LogLevel.error:
      case LogLevel.fatal:
        err(message, error: error, stackTrace: stackTrace, fields: fields);
        break;
    }
  }
}
