import 'metric.dart';
import 'metric_context.dart';
import 'metric_type.dart';

/// Abstract interface for collecting performance metrics
///
/// Follows OpenTelemetry principles and industry standards for metrics collection.
/// Responsible for gathering, aggregating, and querying performance metrics.
abstract class MetricsCollector {
  /// Record a duration measurement (histogram/gauge)
  ///
  /// [operation] - Name of the operation being measured
  /// [milliseconds] - Duration in milliseconds
  /// [tags] - Additional tags for filtering and grouping
  void recordDuration(
    String operation,
    int milliseconds, {
    Map<String, String>? tags,
  });

  /// Record an error
  ///
  /// [operation] - Name of the operation that failed
  /// [error] - Error message or description
  /// [tags] - Additional tags for filtering and grouping
  void recordError(
    String operation,
    String error, {
    Map<String, String>? tags,
  });

  /// Increment a counter metric
  ///
  /// [name] - Name of the counter
  /// [amount] - Amount to increment (default: 1)
  /// [tags] - Additional tags for filtering and grouping
  void incrementCounter(
    String name, {
    int amount = 1,
    Map<String, String>? tags,
  });

  /// Record a gauge metric (single value)
  ///
  /// [name] - Name of the gauge
  /// [value] - Current value
  /// [unit] - Unit of measurement (e.g., 'ms', 'bytes')
  /// [tags] - Additional tags for filtering and grouping
  void recordGauge(
    String name,
    num value, {
    String? unit,
    Map<String, String>? tags,
  });

  /// Start timing an operation
  ///
  /// [name] - Name of the timer
  /// Returns a timer handle that can be used with [stopTimer]
  void startTimer(String name);

  /// Stop timing an operation and record the duration
  ///
  /// [name] - Name of the timer (must match [startTimer])
  /// [tags] - Additional tags for the recorded metric
  void stopTimer(
    String name, {
    Map<String, String>? tags,
  });

  /// Get a specific metric snapshot
  ///
  /// [name] - Name of the metric
  /// Returns null if metric doesn't exist
  MetricSnapshot? getMetric(String name);

  /// Get all recorded metrics
  Map<String, MetricSnapshot> getAllMetrics();

  /// Get metrics filtered by operation
  ///
  /// [operation] - Name of the operation
  Map<String, MetricSnapshot> getMetricsByOperation(String operation);

  /// Get average execution time for an operation
  ///
  /// [operation] - Name of the operation
  /// Returns 0.0 if no metrics exist
  double getAverageExecutionTime(String operation);

  /// Get execution count for an operation
  ///
  /// [operation] - Name of the operation
  int getExecutionCount(String operation);

  /// Get error count for an operation
  ///
  /// [operation] - Name of the operation
  int getErrorCount(String operation);

  /// Get success rate for an operation
  ///
  /// [operation] - Name of the operation
  /// Returns 1.0 if no errors, 0.0 if all errors, or calculated rate
  double getSuccessRate(String operation);

  /// Clear all metrics
  void clear();

  /// Clear metrics for a specific operation
  ///
  /// [operation] - Name of the operation to clear
  void clearByOperation(String operation);

  /// Export metrics using the configured exporter
  ///
  /// Exports all current metrics in the configured format
  Future<void> export();
}

