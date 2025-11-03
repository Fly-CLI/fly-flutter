import 'package:fly_cli/src/core/telemetry/domain/metric.dart';
import 'metric_exporter.dart';

/// In-memory exporter that stores metrics for querying
class InMemoryExporter implements MetricExporter {
  InMemoryExporter();

  final List<Metric> _exportedMetrics = [];

  @override
  Future<void> export(List<Metric> metrics) async {
    _exportedMetrics.addAll(metrics);
  }

  @override
  Future<Map<String, dynamic>> getExportedData() async {
    return {
      'count': _exportedMetrics.length,
      'metrics': _exportedMetrics.map((m) => m.toJson()).toList(),
    };
  }

  /// Get exported metrics
  List<Metric> get metrics => List.unmodifiable(_exportedMetrics);

  /// Clear exported metrics
  void clear() {
    _exportedMetrics.clear();
  }
}

