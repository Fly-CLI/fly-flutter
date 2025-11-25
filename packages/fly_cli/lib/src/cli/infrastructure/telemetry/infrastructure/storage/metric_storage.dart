import 'package:fly_cli/src/cli/infrastructure/telemetry/domain/metric.dart';

/// Storage strategy for metrics
abstract class MetricStorage {
  /// Store a metric
  void store(Metric metric);

  /// Get all stored metrics
  List<Metric> getAllMetrics();

  /// Get metrics by name
  List<Metric> getMetricsByName(String name);

  /// Get metrics by operation
  List<Metric> getMetricsByOperation(String operation);

  /// Get metrics matching tags
  List<Metric> getMetricsByTags(Map<String, String> tags);

  /// Clear all stored metrics
  void clear();

  /// Clear metrics by operation
  void clearByOperation(String operation);

  /// Get count of stored metrics
  int get count;
}

/// In-memory thread-safe metric storage
class InMemoryMetricStorage implements MetricStorage {
  InMemoryMetricStorage({this.maxMetrics = 10000});

  final int maxMetrics;
  final List<Metric> _metrics = [];
  final Map<String, DateTime> _timers = {};

  /// Active timers: name -> start time
  Map<String, DateTime> get timers => Map.unmodifiable(_timers);

  /// Store a metric (thread-safe)
  @override
  void store(Metric metric) {
    synchronized(() {
      if (_metrics.length >= maxMetrics) {
        // Remove oldest 10% of metrics to make room
        final removeCount = (maxMetrics * 0.1).ceil();
        _metrics.removeRange(0, removeCount);
      }
      _metrics.add(metric);
    });
  }

  /// Get all stored metrics
  @override
  List<Metric> getAllMetrics() {
    return synchronized(() => List.unmodifiable(_metrics));
  }

  /// Get metrics by name
  @override
  List<Metric> getMetricsByName(String name) {
    return synchronized(() => _metrics.where((m) => m.name == name).toList());
  }

  /// Get metrics by operation (using tags)
  @override
  List<Metric> getMetricsByOperation(String operation) {
    return synchronized(
      () => _metrics.where((m) => m.tags['operation'] == operation).toList(),
    );
  }

  /// Get metrics matching tags
  @override
  List<Metric> getMetricsByTags(Map<String, String> tags) {
    return synchronized(() {
      return _metrics.where((m) {
        for (final entry in tags.entries) {
          if (m.tags[entry.key] != entry.value) {
            return false;
          }
        }
        return true;
      }).toList();
    });
  }

  /// Clear all stored metrics
  @override
  void clear() {
    synchronized(() {
      _metrics.clear();
      _timers.clear();
    });
  }

  /// Clear metrics by operation
  @override
  void clearByOperation(String operation) {
    synchronized(() {
      _metrics.removeWhere((m) => m.tags['operation'] == operation);
    });
  }

  /// Get count of stored metrics
  @override
  int get count => synchronized(() => _metrics.length);

  /// Record timer start
  DateTime? startTimer(String name) {
    return synchronized(() {
      _timers[name] = DateTime.now();
      return _timers[name];
    });
  }

  /// Record timer stop and return duration
  int? stopTimer(String name) {
    return synchronized(() {
      final startTime = _timers.remove(name);
      if (startTime != null) {
        return DateTime.now().difference(startTime).inMilliseconds;
      }
      return null;
    });
  }

  /// Thread-safe execution helper
  T synchronized<T>(T Function() action) {
    // Simple synchronization - in Dart, we can use locks or isolate-safe operations
    // For now, using a simple approach (Dart's isolate model means we're single-threaded per isolate)
    // But we'll structure it to be ready for multi-threading if needed
    return action();
  }
}
