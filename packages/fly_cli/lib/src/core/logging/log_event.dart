import 'log_level.dart';
import 'logging_context.dart';

typedef JsonMap = Map<String, Object?>;

class LogEvent {
  LogEvent({
    required this.timestamp,
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
    JsonMap? fields,
    this.context,
    this.loggerName,
  }) : fields = fields ?? <String, Object?>{};

  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;
  final JsonMap fields;
  final LoggingContext? context;
  final String? loggerName;

  JsonMap toJson() {
    return <String, Object?>{
      'ts': timestamp.toIso8601String(),
      'level': level.toString(),
      'msg': message,
      if (loggerName != null) 'logger': loggerName,
      if (fields.isNotEmpty) 'fields': fields,
      if (context != null) ...context!.toJson(),
      if (error != null) 'err': error.toString(),
      if (stackTrace != null) 'stack': stackTrace.toString(),
    };
  }
}


