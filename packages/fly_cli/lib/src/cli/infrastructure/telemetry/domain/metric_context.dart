/// Context information for metrics
class MetricContext {
  const MetricContext({
    this.operation,
    this.tags = const {},
  });

  /// Name of the operation being measured
  final String? operation;

  /// Additional tags/labels for filtering and grouping
  final Map<String, String> tags;

  /// Create a copy with updated fields
  MetricContext copyWith({
    String? operation,
    Map<String, String>? tags,
  }) => MetricContext(
    operation: operation ?? this.operation,
    tags: tags != null ? {...this.tags, ...tags} : this.tags,
  );

  /// Merge with another context
  MetricContext merge(MetricContext other) => copyWith(
    operation: other.operation ?? operation,
    tags: other.tags,
  );
}
