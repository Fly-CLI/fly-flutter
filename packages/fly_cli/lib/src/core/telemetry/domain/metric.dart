import 'metric_type.dart';

/// A single metric measurement
class Metric {
  const Metric({
    required this.name,
    required this.type,
    required this.value,
    required this.timestamp,
    this.unit,
    this.tags = const {},
  });

  /// Name of the metric
  final String name;

  /// Type of metric
  final MetricType type;

  /// Value of the metric
  final num value;

  /// When this metric was recorded
  final DateTime timestamp;

  /// Unit of measurement (e.g., 'ms', 'count', 'bytes')
  final String? unit;

  /// Tags/labels for filtering and grouping
  final Map<String, String> tags;

  /// Create a copy with updated fields
  Metric copyWith({
    String? name,
    MetricType? type,
    num? value,
    DateTime? timestamp,
    String? unit,
    Map<String, String>? tags,
  }) =>
      Metric(
        name: name ?? this.name,
        type: type ?? this.type,
        value: value ?? this.value,
        timestamp: timestamp ?? this.timestamp,
        unit: unit ?? this.unit,
        tags: tags ?? this.tags,
      );

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type.name,
        'value': value,
        'timestamp': timestamp.toIso8601String(),
        if (unit != null) 'unit': unit,
        'tags': tags,
      };
}

/// Snapshot of aggregated metric data
class MetricSnapshot {
  const MetricSnapshot({
    required this.name,
    required this.type,
    this.value,
    this.count = 0,
    this.sum = 0.0,
    this.min,
    this.max,
    this.average,
    this.tags = const {},
  });

  /// Name of the metric
  final String name;

  /// Type of metric
  final MetricType type;

  /// Single value (for gauge)
  final num? value;

  /// Number of measurements
  final int count;

  /// Sum of all values
  final double sum;

  /// Minimum value
  final num? min;

  /// Maximum value
  final num? max;

  /// Average value
  final double? average;

  /// Tags/labels
  final Map<String, String> tags;

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type.name,
        'count': count,
        'sum': sum,
        if (value != null) 'value': value,
        if (min != null) 'min': min,
        if (max != null) 'max': max,
        if (average != null) 'average': average,
        'tags': tags,
      };
}

