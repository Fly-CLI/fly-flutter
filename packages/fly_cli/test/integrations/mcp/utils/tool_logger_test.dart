import 'package:fly_cli/src/core/logging/log_level.dart';
import 'package:fly_cli/src/core/logging/logger.dart' as flylog;
import 'package:fly_cli/src/core/logging/logger_impl.dart' as flylog_impl;
import 'package:fly_cli/src/integrations/mcp/utils/tool_logger.dart';
import 'package:test/test.dart';

void main() {
  group('ToolLogger', () {
    late flylog.Logger baseLogger;

    setUp(() {
      // Create a simple logger for testing
      baseLogger = flylog_impl.LoggerImpl(
        appenders: [],
        minLevel: LogLevel.debug,
      );
    });

    test('should generate correlation ID', () {
      final id1 = ToolLogger.generateCorrelationId();
      final id2 = ToolLogger.generateCorrelationId();

      expect(id1, isNotEmpty);
      expect(id2, isNotEmpty);
      expect(id1, isNot(equals(id2)));
      expect(id1, startsWith('tool_'));
    });

    test('should create tool logger with correlation ID', () {
      final logger = ToolLogger(
        logger: baseLogger,
        toolName: 'test.tool',
        correlationId: 'test-123',
      );

      expect(logger.toolName, 'test.tool');
      expect(logger.correlationId, 'test-123');
    });

    test('should log start event', () {
      var loggedMessage = '';
      var loggedFields = <String, Object?>{};

      final testLogger = TestLogger(
        onLog: (level, message, {error, stackTrace, fields}) {
          loggedMessage = message;
          loggedFields = fields ?? {};
        },
      );

      final toolLogger = ToolLogger(
        logger: testLogger,
        toolName: 'test.tool',
        correlationId: 'test-123',
      );

      toolLogger.logStart(params: {'param1': 'value1'});

      expect(loggedMessage, contains('test.tool'));
      expect(loggedMessage, contains('started'));
      expect(loggedFields['operation'], 'start');
      expect(loggedFields['params'], isNotNull);
    });

    test('should log complete event with duration', () {
      var loggedMessage = '';
      var loggedFields = <String, Object?>{};

      final testLogger = TestLogger(
        onLog: (level, message, {error, stackTrace, fields}) {
          loggedMessage = message;
          loggedFields = fields ?? {};
        },
      );

      final toolLogger = ToolLogger(
        logger: testLogger,
        toolName: 'test.tool',
        correlationId: 'test-123',
      );

      toolLogger.logComplete(
        success: true,
        result: {'success': true},
        durationMs: 1000,
      );

      expect(loggedMessage, contains('test.tool'));
      expect(loggedMessage, contains('completed'));
      expect(loggedFields['operation'], 'complete');
      expect(loggedFields['success'], true);
      expect(loggedFields['duration_ms'], 1000);
    });

    test('should log error event', () {
      var loggedMessage = '';
      var loggedError = '';
      var loggedFields = <String, Object?>{};

      final testLogger = TestLogger(
        onLog: (level, message, {error, stackTrace, fields}) {
          loggedMessage = message;
          loggedError = error?.toString() ?? '';
          loggedFields = fields ?? {};
        },
      );

      final toolLogger = ToolLogger(
        logger: testLogger,
        toolName: 'test.tool',
        correlationId: 'test-123',
      );

      final testError = StateError('Test error');
      toolLogger.logError(
        message: 'Operation failed',
        error: testError,
        context: {'error_code': 'test_error'},
      );

      expect(loggedMessage, contains('test.tool'));
      expect(loggedMessage, contains('failed'));
      expect(loggedFields['operation'], 'error');
      expect(loggedFields['error_code'], 'test_error');
    });

    test('should log progress event', () {
      var loggedMessage = '';
      var loggedFields = <String, Object?>{};

      final testLogger = TestLogger(
        onLog: (level, message, {error, stackTrace, fields}) {
          loggedMessage = message;
          loggedFields = fields ?? {};
        },
      );

      final toolLogger = ToolLogger(
        logger: testLogger,
        toolName: 'test.tool',
        correlationId: 'test-123',
      );

      toolLogger.logProgress(
        stage: 'processing',
        percent: 50,
        details: {'step': 2},
      );

      expect(loggedMessage, contains('test.tool'));
      expect(loggedMessage, contains('processing'));
      expect(loggedFields['operation'], 'progress');
      expect(loggedFields['stage'], 'processing');
      expect(loggedFields['percent'], 50);
    });

    test('should log metric event', () {
      var loggedMessage = '';
      var loggedFields = <String, Object?>{};

      final testLogger = TestLogger(
        onLog: (level, message, {error, stackTrace, fields}) {
          loggedMessage = message;
          loggedFields = fields ?? {};
        },
      );

      final toolLogger = ToolLogger(
        logger: testLogger,
        toolName: 'test.tool',
        correlationId: 'test-123',
      );

      toolLogger.logMetric(
        metricName: 'execution_time',
        value: 1000,
        unit: 'ms',
        tags: {'operation': 'test'},
      );

      expect(loggedMessage, contains('test.tool'));
      expect(loggedMessage, contains('execution_time'));
      expect(loggedFields['operation'], 'metric');
      expect(loggedFields['metric_name'], 'execution_time');
      expect(loggedFields['metric_value'], 1000);
      expect(loggedFields['metric_unit'], 'ms');
    });

    test('should get performance metrics', () {
      final toolLogger = ToolLogger(
        logger: baseLogger,
        toolName: 'test.tool',
        correlationId: 'test-123',
      );

      // Wait a bit for time difference
      Future.delayed(const Duration(milliseconds: 10), () {
        final metrics = toolLogger.getMetrics();

        expect(metrics['correlation_id'], 'test-123');
        expect(metrics['tool_name'], 'test.tool');
        expect(metrics['duration_ms'], isA<int>());
        expect(metrics['start_time'], isNotNull);
      });
    });

    test('should create child logger', () {
      final parentLogger = ToolLogger(
        logger: baseLogger,
        toolName: 'parent.tool',
        correlationId: 'parent-123',
      );

      final childLogger = parentLogger.child(
        subOperation: 'sub',
        additionalFields: {'extra': 'field'},
      );

      expect(childLogger.toolName, 'parent.tool.sub');
      expect(childLogger.correlationId, 'parent-123');
    });
  });

  group('ToolPerformanceMetrics', () {
    test('should track timer operations', () {
      var metricLogged = false;
      var metricName = '';
      var metricValue = 0;

      final testLogger = TestLogger(
        onLog: (level, message, {error, stackTrace, fields}) {
          if (fields?['operation'] == 'metric') {
            metricLogged = true;
            metricName = fields?['metric_name'] as String? ?? '';
            metricValue = fields?['metric_value'] as int? ?? 0;
          }
        },
      );

      final toolLogger = ToolLogger(
        logger: testLogger,
        toolName: 'test.tool',
        correlationId: 'test-123',
      );

      final metrics = ToolPerformanceMetrics(
        logger: toolLogger,
        toolName: 'test.tool',
      );

      metrics.startTimer('test_timer');
      Future.delayed(const Duration(milliseconds: 50), () {
        metrics.stopTimer('test_timer');

        expect(metricLogged, true);
        expect(metricName, contains('test_timer'));
        expect(metricValue, greaterThan(0));
      });
    });

    test('should record custom metrics', () {
      var metricLogged = false;
      var metricName = '';
      var metricValue = '';

      final testLogger = TestLogger(
        onLog: (level, message, {error, stackTrace, fields}) {
          if (fields?['operation'] == 'metric') {
            metricLogged = true;
            metricName = fields?['metric_name'] as String? ?? '';
            metricValue = fields?['metric_value']?.toString() ?? '';
          }
        },
      );

      final toolLogger = ToolLogger(
        logger: testLogger,
        toolName: 'test.tool',
        correlationId: 'test-123',
      );

      final metrics = ToolPerformanceMetrics(
        logger: toolLogger,
        toolName: 'test.tool',
      );

      metrics.recordMetric('custom_metric', 42, unit: 'count');

      expect(metricLogged, true);
      expect(metricName, 'custom_metric');
      expect(metricValue, '42');
    });

    test('should increment counter', () {
      var lastValue = 0;

      final testLogger = TestLogger(
        onLog: (level, message, {error, stackTrace, fields}) {
          if (fields?['operation'] == 'metric') {
            lastValue = fields?['metric_value'] as int? ?? 0;
          }
        },
      );

      final toolLogger = ToolLogger(
        logger: testLogger,
        toolName: 'test.tool',
        correlationId: 'test-123',
      );

      final metrics = ToolPerformanceMetrics(
        logger: toolLogger,
        toolName: 'test.tool',
      );

      metrics.incrementCounter('test_counter');
      metrics.incrementCounter('test_counter', amount: 5);

      expect(lastValue, 6);
    });

    test('should get all metrics', () {
      final testLogger =
          TestLogger(onLog: (level, message, {error, stackTrace, fields}) {});

      final toolLogger = ToolLogger(
        logger: testLogger,
        toolName: 'test.tool',
        correlationId: 'test-123',
      );

      final metrics = ToolPerformanceMetrics(
        logger: toolLogger,
        toolName: 'test.tool',
      );

      metrics.recordMetric('metric1', 10);
      metrics.recordMetric('metric2', 'value');
      metrics.incrementCounter('counter1');

      final allMetrics = metrics.getMetrics();

      expect(allMetrics['metric1'], 10);
      expect(allMetrics['metric2'], 'value');
      expect(allMetrics['counter1'], 1);
    });
  });
}

/// Test logger implementation
class TestLogger implements flylog.Logger {
  TestLogger({
    required this.onLog,
  });

  final void Function(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? fields,
  }) onLog;

  @override
  String get name => 'test';

  @override
  flylog.Logger child(Map<String, Object?> contextFields) => this;

  @override
  flylog.Logger withFields(Map<String, Object?> fields) => this;

  @override
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? fields,
  }) {
    onLog(level, message, error: error, stackTrace: stackTrace, fields: fields);
  }

  @override
  void trace(String message,
      {Object? error, StackTrace? stackTrace, Map<String, Object?>? fields}) {
    log(LogLevel.trace, message,
        error: error, stackTrace: stackTrace, fields: fields);
  }

  @override
  void debug(String message,
      {Object? error, StackTrace? stackTrace, Map<String, Object?>? fields}) {
    log(LogLevel.debug, message,
        error: error, stackTrace: stackTrace, fields: fields);
  }

  @override
  void info(String message,
      {Object? error, StackTrace? stackTrace, Map<String, Object?>? fields}) {
    log(LogLevel.info, message,
        error: error, stackTrace: stackTrace, fields: fields);
  }

  @override
  void warn(String message,
      {Object? error, StackTrace? stackTrace, Map<String, Object?>? fields}) {
    log(LogLevel.warn, message,
        error: error, stackTrace: stackTrace, fields: fields);
  }

  @override
  void error(String message,
      {Object? error, StackTrace? stackTrace, Map<String, Object?>? fields}) {
    log(LogLevel.error, message,
        error: error, stackTrace: stackTrace, fields: fields);
  }

  @override
  void fatal(String message,
      {Object? error, StackTrace? stackTrace, Map<String, Object?>? fields}) {
    log(LogLevel.fatal, message,
        error: error, stackTrace: stackTrace, fields: fields);
  }
}
