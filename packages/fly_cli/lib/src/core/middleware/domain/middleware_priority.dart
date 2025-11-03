/// Priority constants for middleware execution.
///
/// Middleware are executed in priority order (lower numbers execute first).
/// Use these constants to ensure consistent ordering across middleware.
class MiddlewarePriority {
  const MiddlewarePriority._();

  /// Dry-run middleware - runs first to short-circuit execution in plan mode
  static const int dryRun = -100;

  /// Validation middleware - runs early to validate inputs
  static const int validation = 0;

  /// Rate limiting middleware - enforces rate limits
  static const int rateLimiting = 10;

  /// Logging middleware - logs command execution
  static const int logging = 20;

  /// Metrics middleware - collects performance metrics
  static const int metrics = 30;

  /// Caching middleware - caches command results
  static const int caching = 40;

  /// Default priority for custom middleware
  static const int defaultPriority = 50;
}
