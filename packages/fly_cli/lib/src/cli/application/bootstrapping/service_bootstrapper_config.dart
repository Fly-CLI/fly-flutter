/// Configuration for service bootstrapper
///
/// This class holds configuration options for service initialization,
/// allowing for different configurations in production, development, and testing.
class ServiceBootstrapperConfig {
  /// Create a new configuration
  ///
  /// [isDevelopment] - Whether running in development mode
  /// [loggerName] - Logger name (defaults to 'fly')
  /// [enableMetrics] - Whether to enable metrics collection (defaults to true)
  /// [templatesDirectory] - Override templates directory (optional)
  ServiceBootstrapperConfig({
    required this.isDevelopment,
    this.loggerName = 'fly',
    this.enableMetrics = true,
    this.templatesDirectory,
  });

  /// Whether running in development mode
  final bool isDevelopment;

  /// Logger name
  final String loggerName;

  /// Whether to enable metrics collection
  final bool enableMetrics;

  /// Override templates directory (optional)
  /// If null, the default will be resolved by PathResolver
  final String? templatesDirectory;

  /// Create a configuration for production mode
  factory ServiceBootstrapperConfig.production() {
    return ServiceBootstrapperConfig(
      isDevelopment: false,
      loggerName: 'fly',
      enableMetrics: true,
    );
  }

  /// Create a configuration for development mode
  factory ServiceBootstrapperConfig.development() {
    return ServiceBootstrapperConfig(
      isDevelopment: true,
      loggerName: 'fly',
      enableMetrics: true,
    );
  }

  /// Create a configuration for testing
  factory ServiceBootstrapperConfig.test({
    String loggerName = 'fly_test',
    bool enableMetrics = false,
  }) {
    return ServiceBootstrapperConfig(
      isDevelopment: true,
      loggerName: loggerName,
      enableMetrics: enableMetrics,
    );
  }
}
