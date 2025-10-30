import 'size_limits_config.dart';

/// Server configuration classes

/// Concurrency configuration
/// 
/// Controls how many operations can execute concurrently, both globally
/// and per-tool.
class ConcurrencyConfig {
  /// Creates a concurrency configuration
  /// 
  /// [maxConcurrency] - Maximum number of concurrent operations globally
  /// [perToolLimits] - Optional per-tool concurrency limits
  const ConcurrencyConfig({
    this.maxConcurrency = 10,
    this.perToolLimits,
  });

  /// Maximum number of concurrent operations globally
  final int maxConcurrency;

  /// Optional per-tool concurrency limits (tool name -> limit)
  final Map<String, int>? perToolLimits;

  ConcurrencyConfig copyWith({
    int? maxConcurrency,
    Map<String, int>? perToolLimits,
  }) {
    return ConcurrencyConfig(
      maxConcurrency: maxConcurrency ?? this.maxConcurrency,
      perToolLimits: perToolLimits ?? this.perToolLimits,
    );
  }
}

/// Timeout configuration
/// 
/// Controls timeout durations for operations, with support for
/// default timeouts and per-tool overrides.
class TimeoutConfig {
  /// Creates a timeout configuration
  /// 
  /// [defaultTimeout] - Default timeout for all operations
  /// [perToolTimeouts] - Optional per-tool timeout overrides
  const TimeoutConfig({
    this.defaultTimeout = const Duration(minutes: 5),
    this.perToolTimeouts,
  });

  /// Default timeout for all operations
  final Duration defaultTimeout;

  /// Optional per-tool timeout overrides (tool name -> timeout)
  final Map<String, Duration>? perToolTimeouts;

  TimeoutConfig copyWith({
    Duration? defaultTimeout,
    Map<String, Duration>? perToolTimeouts,
  }) {
    return TimeoutConfig(
      defaultTimeout: defaultTimeout ?? this.defaultTimeout,
      perToolTimeouts: perToolTimeouts ?? this.perToolTimeouts,
    );
  }
}

/// Size limits configuration is defined in size_limits_config.dart
/// This helps prevent resource exhaustion and DoS attacks.
/// 
/// Default limits:
/// - Parameters: 1MB
/// - Results: 10MB
/// - Resources: 50MB
/// - Messages: 2MB

/// Security configuration
class SecurityConfig {
  const SecurityConfig({
    this.allowedFileSuffixes,
    this.allowedFileNames,
    this.protectedDirectories,
  });

  final Set<String>? allowedFileSuffixes;
  final Set<String>? allowedFileNames;
  final Set<String>? protectedDirectories;

  SecurityConfig copyWith({
    Set<String>? allowedFileSuffixes,
    Set<String>? allowedFileNames,
    Set<String>? protectedDirectories,
  }) {
    return SecurityConfig(
      allowedFileSuffixes: allowedFileSuffixes ?? this.allowedFileSuffixes,
      allowedFileNames: allowedFileNames ?? this.allowedFileNames,
      protectedDirectories:
          protectedDirectories ?? this.protectedDirectories,
    );
  }
}

/// Logging configuration
class LoggingConfig {
  const LoggingConfig({
    this.enabled = true,
    this.level = LogLevel.info,
    this.includeCorrelationIds = true,
  });

  final bool enabled;
  final LogLevel level;
  final bool includeCorrelationIds;

  LoggingConfig copyWith({
    bool? enabled,
    LogLevel? level,
    bool? includeCorrelationIds,
  }) {
    return LoggingConfig(
      enabled: enabled ?? this.enabled,
      level: level ?? this.level,
      includeCorrelationIds:
          includeCorrelationIds ?? this.includeCorrelationIds,
    );
  }
}

/// Log levels
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Complete server configuration
/// 
/// Contains all configuration settings for the MCP server including
/// timeouts, concurrency, security, and logging settings.
/// 
/// Example:
/// ```dart
/// final config = ServerConfig(
///   defaultTimeout: Duration(minutes: 5),
///   concurrency: ConcurrencyConfig(maxConcurrency: 10),
///   timeouts: TimeoutConfig(defaultTimeout: Duration(minutes: 5)),
/// );
/// config.validate();
/// ```
class ServerConfig {
  /// Creates a server configuration
  /// 
  /// [defaultTimeout] - Default timeout for operations
  /// [concurrency] - Concurrency configuration
  /// [timeouts] - Timeout configuration
  /// [security] - Optional security configuration
  /// [logging] - Optional logging configuration
  /// [sizeLimits] - Optional size limits configuration
  const ServerConfig({
    required this.defaultTimeout,
    required this.concurrency,
    required this.timeouts,
    this.security,
    this.logging,
    this.sizeLimits,
  });

  /// Default timeout for operations
  final Duration defaultTimeout;

  /// Concurrency configuration
  final ConcurrencyConfig concurrency;

  /// Timeout configuration
  final TimeoutConfig timeouts;

  /// Optional security configuration
  final SecurityConfig? security;

  /// Optional logging configuration
  final LoggingConfig? logging;

  /// Optional size limits configuration
  final SizeLimitsConfig? sizeLimits;

  /// Creates a default server configuration
  /// 
  /// Returns a configuration with sensible defaults:
  /// - Default timeout: 5 minutes
  /// - Max concurrency: 10
  /// - Standard security, logging, and size limits settings
  factory ServerConfig.defaultConfig() {
    return const ServerConfig(
      defaultTimeout: Duration(minutes: 5),
      concurrency: ConcurrencyConfig(),
      timeouts: TimeoutConfig(),
      security: SecurityConfig(),
      logging: LoggingConfig(),
      sizeLimits: SizeLimitsConfig(),
    );
  }

  ServerConfig copyWith({
    Duration? defaultTimeout,
    ConcurrencyConfig? concurrency,
    TimeoutConfig? timeouts,
    SecurityConfig? security,
    LoggingConfig? logging,
    SizeLimitsConfig? sizeLimits,
  }) {
    return ServerConfig(
      defaultTimeout: defaultTimeout ?? this.defaultTimeout,
      concurrency: concurrency ?? this.concurrency,
      timeouts: timeouts ?? this.timeouts,
      security: security ?? this.security,
      logging: logging ?? this.logging,
      sizeLimits: sizeLimits ?? this.sizeLimits,
    );
  }

  /// Validates the configuration
  /// 
  /// Checks that all configuration values are valid and within acceptable
  /// ranges. Throws [ArgumentError] if any validation fails.
  /// 
  /// Throws [ArgumentError] if:
  /// - defaultTimeout is not positive
  /// - maxConcurrency is not positive
  /// - timeouts.defaultTimeout is not positive
  void validate() {
    if (defaultTimeout.isNegative || defaultTimeout.inSeconds <= 0) {
      throw ArgumentError(
        'defaultTimeout must be positive',
        'defaultTimeout',
      );
    }

    if (concurrency.maxConcurrency <= 0) {
      throw ArgumentError(
        'maxConcurrency must be positive',
        'maxConcurrency',
      );
    }

    if (timeouts.defaultTimeout.isNegative ||
        timeouts.defaultTimeout.inSeconds <= 0) {
      throw ArgumentError(
        'timeouts.defaultTimeout must be positive',
        'timeouts.defaultTimeout',
      );
    }

    // Validate size limits if provided
    sizeLimits?.validate();
  }
}

