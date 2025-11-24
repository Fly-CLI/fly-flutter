import 'package:fly_cli/src/cli/infrastructure/telemetry/domain/metric.dart';
import 'package:fly_cli/src/cli/infrastructure/telemetry/domain/metric_type.dart';
import 'package:fly_cli/src/cli/infrastructure/telemetry/domain/metrics_collector.dart';
import 'package:fly_cli/src/cli/infrastructure/telemetry/infrastructure/exporters/in_memory_exporter.dart';
import 'package:fly_cli/src/cli/infrastructure/telemetry/infrastructure/exporters/metric_exporter.dart';
import 'package:fly_cli/src/cli/infrastructure/telemetry/infrastructure/metrics_config.dart';
import 'package:fly_cli/src/cli/infrastructure/telemetry/infrastructure/storage/metric_storage.dart';

/// Implementation of MetricsCollector
class MetricsCollectorImpl implements MetricsCollector {
  MetricsCollectorImpl({
    required MetricsConfig config,
    required MetricStorage storage,
    MetricExporter? exporter,
  })  : _config = config,
        _storage = storage,
        _exporter = exporter ?? InMemoryExporter();

  final MetricsConfig _config;
  final MetricStorage _storage;
  final MetricExporter _exporter;

  @override
  void recordDuration(
    String operation,
    int milliseconds, {
    Map<String, String>? tags,
  }) {
    if (!_config.enabled) return;

    final metric = Metric(
      name: '$operation.duration',
      type: MetricType.histogram,
      value: milliseconds,
      timestamp: DateTime.now(),
      unit: 'ms',
      tags: {
        'operation': operation,
        if (tags != null) ...tags,
      },
    );

    _storage.store(metric);
  }

  @override
  void recordError(
    String operation,
    String error, {
    Map<String, String>? tags,
  }) {
    if (!_config.enabled) return;

    // Increment error counter
    final errorMetric = Metric(
      name: '$operation.errors',
      type: MetricType.counter,
      value: 1,
      timestamp: DateTime.now(),
      unit: 'count',
      tags: {
        'operation': operation,
        'error': error,
        if (tags != null) ...tags,
      },
    );

    _storage.store(errorMetric);
  }

  @override
  void incrementCounter(
    String name, {
    int amount = 1,
    Map<String, String>? tags,
  }) {
    if (!_config.enabled) return;

    final metric = Metric(
      name: name,
      type: MetricType.counter,
      value: amount,
      timestamp: DateTime.now(),
      unit: 'count',
      tags: tags ?? {},
    );

    _storage.store(metric);
  }

  @override
  void recordGauge(
    String name,
    num value, {
    String? unit,
    Map<String, String>? tags,
  }) {
    if (!_config.enabled) return;

    final metric = Metric(
      name: name,
      type: MetricType.gauge,
      value: value,
      timestamp: DateTime.now(),
      unit: unit,
      tags: tags ?? {},
    );

    _storage.store(metric);
  }

  @override
  void startTimer(String name) {
    if (!_config.enabled) return;

    if (_storage is InMemoryMetricStorage) {
      (_storage as InMemoryMetricStorage).startTimer(name);
    }
  }

  @override
  void stopTimer(
    String name, {
    Map<String, String>? tags,
  }) {
    if (!_config.enabled) return;

    if (_storage is InMemoryMetricStorage) {
      final durationMs = (_storage as InMemoryMetricStorage).stopTimer(name);
      if (durationMs != null) {
        recordDuration(
          name,
          durationMs,
          tags: tags,
        );
      }
    }
  }

  @override
  MetricSnapshot? getMetric(String name) {
    final metrics = _storage.getMetricsByName(name);
    if (metrics.isEmpty) return null;

    return _aggregateMetrics(metrics);
  }

  @override
  Map<String, MetricSnapshot> getAllMetrics() {
    final allMetrics = _storage.getAllMetrics();
    final grouped = <String, List<Metric>>{};

    for (final metric in allMetrics) {
      grouped.putIfAbsent(metric.name, () => []).add(metric);
    }

    return grouped.map((name, metrics) => MapEntry(name, _aggregateMetrics(metrics)));
  }

  @override
  Map<String, MetricSnapshot> getMetricsByOperation(String operation) {
    final operationMetrics = _storage.getMetricsByOperation(operation);
    final grouped = <String, List<Metric>>{};

    for (final metric in operationMetrics) {
      grouped.putIfAbsent(metric.name, () => []).add(metric);
    }

    return grouped.map((name, metrics) => MapEntry(name, _aggregateMetrics(metrics)));
  }

  @override
  double getAverageExecutionTime(String operation) {
    final metrics = _storage.getMetricsByOperation(operation);
    final durationMetrics = metrics.where((m) => m.name.endsWith('.duration'));

    if (durationMetrics.isEmpty) return 0.0;

    final sum = durationMetrics.map((m) => m.value).fold(0.0, (a, b) => a + b.toDouble());
    return sum / durationMetrics.length;
  }

  @override
  int getExecutionCount(String operation) {
    final metrics = _storage.getMetricsByOperation(operation);
    final counterMetrics = metrics.where((m) => m.type == MetricType.counter && !m.name.endsWith('.errors'));

    return counterMetrics.fold(0, (sum, m) => sum + m.value.toInt());
  }

  @override
  int getErrorCount(String operation) {
    final metrics = _storage.getMetricsByOperation(operation);
    final errorMetrics = metrics.where((m) => m.name.endsWith('.errors'));

    return errorMetrics.fold(0, (sum, m) => sum + m.value.toInt());
  }

  @override
  double getSuccessRate(String operation) {
    final total = getExecutionCount(operation);
    final errors = getErrorCount(operation);

    if (total == 0) return 1.0;
    return (total - errors) / total;
  }

  @override
  void clear() {
    _storage.clear();
  }

  @override
  void clearByOperation(String operation) {
    _storage.clearByOperation(operation);
  }

  @override
  Future<void> export() async {
    final allMetrics = _storage.getAllMetrics();
    await _exporter.export(allMetrics);
  }

  /// Aggregate multiple metrics into a snapshot
  MetricSnapshot _aggregateMetrics(List<Metric> metrics) {
    if (metrics.isEmpty) {
      throw ArgumentError('Cannot aggregate empty metrics list');
    }

    final first = metrics.first;
    final values = metrics.map((m) => m.value.toDouble()).toList();
    final sum = values.fold(0.0, (a, b) => a + b);

    return MetricSnapshot(
      name: first.name,
      type: first.type,
      value: first.type == MetricType.gauge ? first.value : null,
      count: metrics.length,
      sum: sum,
      min: values.reduce((a, b) => a < b ? a : b),
      max: values.reduce((a, b) => a > b ? a : b),
      average: sum / metrics.length,
      tags: first.tags,
    );
  }
}

