import 'package:fly_cli/src/core/logging/appender.dart';
import 'package:fly_cli/src/core/logging/log_event.dart';
import 'package:fly_cli/src/core/logging/log_level.dart';
import 'package:fly_cli/src/core/logging/logger.dart';
import 'package:fly_cli/src/core/logging/logging_context.dart';
import 'package:fly_cli/src/core/logging/redaction_policy.dart';

typedef JsonMap = Map<String, Object?>;

class LoggerImpl implements Logger {
  LoggerImpl({
    required List<Appender> appenders,
    required LogLevel minLevel,
    LoggingContext? context,
    String? name,
    JsonMap? fields,
    RedactionPolicy? redaction,
    SamplingThrottlingOptions sampling = const SamplingThrottlingOptions(),
  }) : _appenders = List<Appender>.unmodifiable(appenders),
       _minLevel = minLevel,
       _context = context,
       _name = name,
       _fields = fields == null
           ? const <String, Object?>{}
           : Map<String, Object?>.unmodifiable(fields),
       _redaction = redaction ?? RedactionPolicy(),
       _sampling = sampling;

  final List<Appender> _appenders;
  final LogLevel _minLevel;
  final LoggingContext? _context;
  final String? _name;
  final JsonMap _fields;
  final RedactionPolicy _redaction;
  final SamplingThrottlingOptions _sampling;
  static final Map<String, DateTime> _lastSeen = <String, DateTime>{};

  @override
  String get name => _name ?? 'root';

  @override
  Logger child(JsonMap contextFields) {
    final childCtx = (_context ?? LoggingContext()).copyWith(
      extra: {...(_context?.extra ?? {}), ...contextFields},
    );
    return LoggerImpl(
      appenders: _appenders,
      minLevel: _minLevel,
      context: childCtx,
      name: _name,
      fields: _fields,
    );
  }

  @override
  Logger withFields(JsonMap fields) {
    return LoggerImpl(
      appenders: _appenders,
      minLevel: _minLevel,
      context: _context,
      name: _name,
      fields: {..._fields, ...fields},
    );
  }

  @override
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    JsonMap? fields,
  }) {
    if (level.severity < _minLevel.severity) return;
    if (!_shouldSample(level)) return;
    final mergedFields = _redaction.scrub({
      ..._fields,
      if (fields != null) ...fields,
    });
    if (_isDuplicate(level, message, mergedFields)) return;
    final event = LogEvent(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      error: error,
      stackTrace: stackTrace,
      fields: mergedFields,
      context: _context,
      loggerName: name,
    );
    for (final appender in _appenders) {
      // Fire-and-forget to avoid blocking caller; errors are ignored by design.
      // ignore: discarded_futures
      appender.append(event);
    }
  }

  bool _shouldSample(LogLevel level) {
    final rate = _sampling.levelSampling[level] ?? 1.0;
    if (rate >= 1.0) return true;
    return (DateTime.now().microsecondsSinceEpoch % 1000) / 1000.0 < rate;
  }

  bool _isDuplicate(LogLevel level, String message, JsonMap fields) {
    final window = _sampling.duplicateSuppressionWindow;
    if (window.inMilliseconds <= 0) return false;
    final key = '${level.name}|$message|${fields.hashCode}';
    final now = DateTime.now();
    final last = _lastSeen[key];
    if (last != null && now.difference(last) < window) {
      return true;
    }
    _lastSeen[key] = now;
    return false;
  }

  @override
  void trace(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    JsonMap? fields,
  }) => log(
    LogLevel.trace,
    message,
    error: error,
    stackTrace: stackTrace,
    fields: fields,
  );

  @override
  void debug(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    JsonMap? fields,
  }) => log(
    LogLevel.debug,
    message,
    error: error,
    stackTrace: stackTrace,
    fields: fields,
  );

  @override
  void info(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    JsonMap? fields,
  }) => log(
    LogLevel.info,
    message,
    error: error,
    stackTrace: stackTrace,
    fields: fields,
  );

  @override
  void warn(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    JsonMap? fields,
  }) => log(
    LogLevel.warn,
    message,
    error: error,
    stackTrace: stackTrace,
    fields: fields,
  );

  @override
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    JsonMap? fields,
  }) => log(
    LogLevel.error,
    message,
    error: error,
    stackTrace: stackTrace,
    fields: fields,
  );

  @override
  void fatal(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    JsonMap? fields,
  }) => log(
    LogLevel.fatal,
    message,
    error: error,
    stackTrace: stackTrace,
    fields: fields,
  );
}

class SamplingThrottlingOptions {
  const SamplingThrottlingOptions({
    this.levelSampling = const {},
    this.duplicateSuppressionWindow = const Duration(seconds: 0),
  });

  final Map<LogLevel, double> levelSampling; // 0.0..1.0
  final Duration duplicateSuppressionWindow;
}
