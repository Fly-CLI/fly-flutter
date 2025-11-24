/// Type of metric measurement
enum MetricType {
  /// Counter: monotonically increasing value (e.g., execution count, error count)
  counter,

  /// Gauge: single value that can go up or down (e.g., current execution time, success rate)
  gauge,

  /// Histogram: distribution of values (e.g., execution time distribution)
  histogram,
}

