

/// Configuration for metrics collection
class MetricsConfig {
  const MetricsConfig({
    this.enabled = true,
    this.exportOnShutdown = false,
    this.maxMetricsCount = 10000,
    this.clearAfterCommand = false,
  });

  /// Whether metrics collection is enabled
  final bool enabled;

  /// Whether to export metrics on shutdown
  final bool exportOnShutdown;

  /// Maximum number of metrics to store in memory
  final int maxMetricsCount;

  /// Whether to clear metrics after each command execution
  final bool clearAfterCommand;

  /// Create configuration from environment variables
  ///
  /// Note: Metrics-specific environment variables are not yet defined in EnvVar enum.
  /// Currently uses sensible defaults. To add env var support, add constants to EnvVar enum.
  factory MetricsConfig.fromEnvironment({required bool isProd}) {
    // TODO: Add metrics environment variables to EnvVar enum when needed:
    // - FLY_METRICS_ENABLED
    // - FLY_METRICS_EXPORT_ON_SHUTDOWN
    // - FLY_METRICS_MAX_COUNT
    // - FLY_METRICS_CLEAR_AFTER_COMMAND

    return MetricsConfig(
      enabled: !isProd, // Disabled in production by default
      exportOnShutdown: false,
      maxMetricsCount: 10000,
      clearAfterCommand: true,
    );
  }

  /// Create a copy with updated fields
  MetricsConfig copyWith({
    bool? enabled,
    bool? exportOnShutdown,
    int? maxMetricsCount,
    bool? clearAfterCommand,
  }) => MetricsConfig(
    enabled: enabled ?? this.enabled,
    exportOnShutdown: exportOnShutdown ?? this.exportOnShutdown,
    maxMetricsCount: maxMetricsCount ?? this.maxMetricsCount,
    clearAfterCommand: clearAfterCommand ?? this.clearAfterCommand,
  );
}
