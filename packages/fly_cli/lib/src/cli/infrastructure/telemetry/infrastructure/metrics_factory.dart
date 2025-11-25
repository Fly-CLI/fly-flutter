import 'package:fly_cli/src/cli/infrastructure/telemetry/domain/metrics_collector.dart';
import 'package:fly_cli/src/cli/infrastructure/telemetry/infrastructure/exporters/in_memory_exporter.dart';
import 'package:fly_cli/src/cli/infrastructure/telemetry/infrastructure/exporters/metric_exporter.dart';
import 'package:fly_cli/src/cli/infrastructure/telemetry/infrastructure/metrics_collector_impl.dart';
import 'package:fly_cli/src/cli/infrastructure/telemetry/infrastructure/metrics_config.dart';
import 'package:fly_cli/src/cli/infrastructure/telemetry/infrastructure/storage/metric_storage.dart';

/// Factory for creating MetricsCollector instances
class MetricsFactory {
  MetricsFactory(this.config);

  final MetricsConfig config;

  /// Create a root metrics collector with default storage and exporter
  MetricsCollector create() {
    final storage = InMemoryMetricStorage(
      maxMetrics: config.maxMetricsCount,
    );

    final exporter = InMemoryExporter();

    return MetricsCollectorImpl(
      config: config,
      storage: storage,
      exporter: exporter,
    );
  }

  /// Create a metrics collector with custom storage
  MetricsCollector createWithStorage(MetricStorage storage) {
    final exporter = InMemoryExporter();

    return MetricsCollectorImpl(
      config: config,
      storage: storage,
      exporter: exporter,
    );
  }

  /// Create a metrics collector with custom exporter
  MetricsCollector createWithExporter(
    MetricStorage storage,
    MetricExporter exporter,
  ) {
    return MetricsCollectorImpl(
      config: config,
      storage: storage,
      exporter: exporter,
    );
  }
}
