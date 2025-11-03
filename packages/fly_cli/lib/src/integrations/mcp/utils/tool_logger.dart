import 'package:fly_cli/src/core/command/foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/logging/logger.dart' as flylog;
import 'package:fly_cli/src/core/logging/logger_factory.dart' as flylog_factory;
import 'package:fly_cli/src/core/logging/logging_config.dart' as flylog_cfg;
import 'package:fly_cli/src/core/logging/logging_context.dart' as flylog_ctx;
import 'package:fly_cli/src/core/telemetry/domain/metrics_collector.dart';

/// Structured logger for MCP tool execution
///
/// Provides correlation IDs, performance metrics, and structured logging
/// for all MCP tool operations.
class ToolLogger {
  ToolLogger({
    required this.logger,
    required this.toolName,
    required this.correlationId,
    String? spanId,
    Map<String, Object?>? initialFields,
  })  : _spanId = spanId ?? _generateSpanId(),
        _startTime = DateTime.now(),
        _initialFields = Map<String, Object?>.from(initialFields ?? {}) {
    _toolLogger = logger.child({
      'tool': toolName,
      'correlation_id': correlationId,
      'span_id': _spanId,
      ..._initialFields,
    });
  }

  final flylog.Logger logger;
  final String toolName;
  final String correlationId;
  final String _spanId;
  final DateTime _startTime;
  final Map<String, Object?> _initialFields;
  late final flylog.Logger _toolLogger;

  /// Generate a correlation ID for tool execution
  static String generateCorrelationId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final random = DateTime.now().millisecondsSinceEpoch % 10000;
    return 'tool_${timestamp}_$random';
  }

  /// Generate a span ID
  static String _generateSpanId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final random = DateTime.now().millisecondsSinceEpoch % 1000;
    return 'span_${timestamp}_$random';
  }

  /// Log tool start with parameters
  void logStart({Map<String, Object?>? params}) {
    _toolLogger.info(
      'Tool execution started: $toolName',
      fields: {
        if (params != null) 'params': params,
        'operation': 'start',
      },
    );
  }

  /// Log tool completion with results
  void logComplete({
    required bool success,
    Map<String, Object?>? result,
    int? durationMs,
  }) {
    final endTime = DateTime.now();
    final actualDurationMs =
        durationMs ?? endTime.difference(_startTime).inMilliseconds;

    _toolLogger.info(
      'Tool execution completed: $toolName',
      fields: {
        'operation': 'complete',
        'success': success,
        'duration_ms': actualDurationMs,
        if (result != null) 'result': result,
      },
    );
  }

  /// Log tool error
  void logError({
    required String message,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? context,
  }) {
    final endTime = DateTime.now();
    final durationMs = endTime.difference(_startTime).inMilliseconds;

    _toolLogger.error(
      'Tool execution failed: $toolName - $message',
      error: error,
      stackTrace: stackTrace,
      fields: {
        'operation': 'error',
        'duration_ms': durationMs,
        if (context != null) ...context,
      },
    );
  }

  /// Log progress stage
  void logProgress({
    required String stage,
    int? percent,
    Map<String, Object?>? details,
  }) {
    _toolLogger.debug(
      'Tool progress: $toolName - $stage',
      fields: {
        'operation': 'progress',
        'stage': stage,
        if (percent != null) 'percent': percent,
        if (details != null) ...details,
      },
    );
  }

  /// Log performance metric
  void logMetric({
    required String metricName,
    required Object value,
    String? unit,
    Map<String, Object?>? tags,
  }) {
    _toolLogger.debug(
      'Tool metric: $toolName - $metricName',
      fields: {
        'operation': 'metric',
        'metric_name': metricName,
        'metric_value': value,
        if (unit != null) 'metric_unit': unit,
        if (tags != null) ...tags,
      },
    );
  }

  /// Log validation result
  void logValidation({
    required bool passed,
    List<String>? errors,
    Map<String, Object?>? details,
  }) {
    _toolLogger.debug(
      'Tool validation: $toolName',
      fields: {
        'operation': 'validation',
        'validation_passed': passed,
        if (errors != null) 'validation_errors': errors,
        if (details != null) ...details,
      },
    );
  }

  /// Log cancellation
  void logCancellation() {
    final endTime = DateTime.now();
    final durationMs = endTime.difference(_startTime).inMilliseconds;

    _toolLogger.warn(
      'Tool execution cancelled: $toolName',
      fields: {
        'operation': 'cancelled',
        'duration_ms': durationMs,
      },
    );
  }

  /// Log timeout
  void logTimeout({required Duration timeout}) {
    final endTime = DateTime.now();
    final durationMs = endTime.difference(_startTime).inMilliseconds;

    _toolLogger.warn(
      'Tool execution timed out: $toolName',
      fields: {
        'operation': 'timeout',
        'timeout_duration_ms': timeout.inMilliseconds,
        'duration_ms': durationMs,
      },
    );
  }

  /// Get performance metrics
  Map<String, Object?> getMetrics() {
    final endTime = DateTime.now();
    final durationMs = endTime.difference(_startTime).inMilliseconds;

    return {
      'correlation_id': correlationId,
      'span_id': _spanId,
      'tool_name': toolName,
      'duration_ms': durationMs,
      'start_time': _startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
    };
  }

  /// Create a child logger with additional context
  ToolLogger child({
    required String subOperation,
    Map<String, Object?>? additionalFields,
  }) {
    return ToolLogger(
      logger: logger,
      toolName: '$toolName.$subOperation',
      correlationId: correlationId,
      spanId: _generateSpanId(),
      // New span for sub-operation
      initialFields: {
        ..._initialFields,
        'parent_span_id': _spanId,
        if (additionalFields != null) ...additionalFields,
      },
    );
  }

  /// Log an info message
  void info(String message, {Map<String, Object?>? fields}) {
    _toolLogger.info(message, fields: fields);
  }

  /// Log a debug message
  void debug(String message, {Map<String, Object?>? fields}) {
    _toolLogger.debug(message, fields: fields);
  }

  /// Log a warning message
  void warn(String message, {Map<String, Object?>? fields}) {
    _toolLogger.warn(message, fields: fields);
  }

  /// Log an error message
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? fields,
  }) {
    _toolLogger.error(
      message,
      error: error,
      stackTrace: stackTrace,
      fields: fields,
    );
  }
}

/// Helper to create a tool logger from CommandContext
extension ToolLoggerFromContext on CommandContext {
  /// Create a tool logger from context
  ///
  /// If a structured logger is available in context data, uses it.
  /// Otherwise creates a new structured logger instance.
  ToolLogger createToolLogger({
    required String toolName,
    String? correlationId,
    Map<String, Object?>? initialFields,
  }) {
    // Try to get structured logger from context data
    final structuredLogger = getData('structured_logger') as flylog.Logger?;

    final logger = structuredLogger ?? _getOrCreateStructuredLogger();

    return ToolLogger(
      logger: logger,
      toolName: toolName,
      correlationId: correlationId ?? ToolLogger.generateCorrelationId(),
      initialFields: {
        'command': argResults.command?.name ?? 'mcp',
        if (initialFields != null) ...initialFields,
      },
    );
  }

  /// Get or create a structured logger
  flylog.Logger _getOrCreateStructuredLogger() {
    // Check if logger already exists in context
    final existing = getData('structured_logger') as flylog.Logger?;
    if (existing != null) {
      return existing;
    }

    // Create a new structured logger
    // For now, treat all environments as development
    // In production, this would be determined by environment variables or config
    final isProd = false;
    final config = flylog_cfg.LoggingConfig.fromEnvironment(isProd: isProd);
    final baseCtx = flylog_ctx.LoggingContext(
      environment: isProd ? 'production' : 'development',
      command: argResults.command?.name ?? 'mcp',
    );

    final logger = flylog_factory.LoggerFactory(
      config,
      baseContext: baseCtx,
      name: 'fly.mcp',
    ).createRoot();

    // Store in context for reuse
    setData('structured_logger', logger);

    return logger;
  }
}

/// Performance metrics tracker for tool operations
/// 
/// @deprecated Use MetricsCollector directly for new code.
/// This class is maintained for backward compatibility.
class ToolPerformanceMetrics {
  ToolPerformanceMetrics({
    required this.logger,
    required this.toolName,
    MetricsCollector? metricsCollector,
  }) : _metricsCollector = metricsCollector;

  final ToolLogger logger;
  final String toolName;
  final MetricsCollector? _metricsCollector;
  final Map<String, Object?> _metrics = {};
  final Map<String, DateTime> _timers = {};

  /// Start timing an operation
  void startTimer(String timerName) {
    _timers[timerName] = DateTime.now();
    _metricsCollector?.startTimer(timerName);
  }

  /// Stop timing an operation and record metric
  void stopTimer(String timerName) {
    final startTime = _timers.remove(timerName);
    if (startTime != null) {
      final durationMs = DateTime.now().difference(startTime).inMilliseconds;
      
      // Record using MetricsCollector if available
      _metricsCollector?.stopTimer(
        timerName,
        tags: {'tool': toolName},
      );
      
      // Also record locally for backward compatibility
      recordMetric('${timerName}_duration_ms', durationMs, unit: 'ms');
    }
  }

  /// Record a performance metric
  void recordMetric(String metricName, Object value, {String? unit}) {
    _metrics[metricName] = value;
    
    // Record using MetricsCollector if available
    if (_metricsCollector != null && value is num) {
      _metricsCollector.recordGauge(
        metricName,
        value,
        unit: unit,
        tags: {'tool': toolName},
      );
    }
    
    // Also log to logger for backward compatibility
    logger.logMetric(
      metricName: metricName,
      value: value,
      unit: unit,
    );
  }

  /// Record a counter metric
  void incrementCounter(String counterName, {int amount = 1}) {
    final current = (_metrics[counterName] as int?) ?? 0;
    final newValue = current + amount;
    _metrics[counterName] = newValue;
    
    // Record using MetricsCollector if available
    _metricsCollector?.incrementCounter(
      counterName,
      amount: amount,
      tags: {'tool': toolName},
    );
    
    // Also log to logger for backward compatibility
    logger.logMetric(
      metricName: counterName,
      value: newValue,
      unit: 'count',
    );
  }

  /// Get all recorded metrics
  Map<String, Object?> getMetrics() {
    if (_metricsCollector != null) {
      // Get metrics from MetricsCollector and merge with local metrics
      final collectorMetrics = _metricsCollector!
          .getMetricsByOperation(toolName)
          .map((key, value) => MapEntry(key, value.value));
      return {..._metrics, ...collectorMetrics};
    }
    return Map<String, Object?>.from(_metrics);
  }

  /// Clear all metrics
  void clear() {
    _metrics.clear();
    _timers.clear();
    _metricsCollector?.clearByOperation(toolName);
  }
}
