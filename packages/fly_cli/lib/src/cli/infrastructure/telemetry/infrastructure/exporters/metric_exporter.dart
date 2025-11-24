import 'package:fly_cli/src/cli/infrastructure/telemetry/domain/metric.dart';

/// Abstract interface for exporting metrics
abstract class MetricExporter {
  /// Export a list of metrics
  Future<void> export(List<Metric> metrics);

  /// Get exported metrics in a serializable format
  Future<Map<String, dynamic>> getExportedData();
}

