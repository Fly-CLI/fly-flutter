import 'package:fly_cli/src/cli/infrastructure/telemetry/domain/metrics_collector.dart';
import 'package:fly_cli/src/cli/infrastructure/telemetry/infrastructure/metrics_config.dart';

/// Interface for metrics collector factory
///
/// This interface provides abstraction over the metrics collector creation implementation,
/// allowing for easier testing and swapping of implementations.
abstract class IMetricsCollectorFactory {
  /// Create a metrics collector
  ///
  /// [config] - Metrics configuration
  MetricsCollector create(MetricsConfig config);
}
