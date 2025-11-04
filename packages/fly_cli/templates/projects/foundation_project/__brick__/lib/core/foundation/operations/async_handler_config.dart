import 'package:{{project_name_snake}}/core/foundation/operations/retry_config.dart';
import 'package:{{project_name_snake}}/core/foundation/utils/app_logger.dart';

/// Central configuration for AsyncHandler default values
/// 
/// This class serves as the single source of truth for all default
/// timeout values, retry configurations, and behavior settings used
/// throughout the async operation handling system.
/// 
/// Modify these values to change defaults globally across the application.
class AsyncHandlerConfig {
  // Prevent instantiation - this is a configuration class
  AsyncHandlerConfig._();

  /// Logger instance for configuration-related logging
  static final AppLogger _logger = AppLogger('AsyncHandlerConfig');

  // ==========================================================================
  // TIMEOUT CONFIGURATION
  // ==========================================================================

  /// Default timeout for standard operations
  /// 
  /// Used for most CRUD operations (create, read, update, delete)
  /// that should complete quickly under normal network conditions.
  static const Duration standardTimeout = Duration(seconds: 100 * 60);

  /// Default timeout for quick operations
  /// 
  /// Used for fast operations like validations, checks, and lookups
  /// that should complete almost immediately.
  static const Duration quickTimeout = Duration(seconds: 10);

  /// Default timeout for long operations
  /// 
  /// Used for complex queries, large data fetches, and operations
  /// that are expected to take longer.
  static const Duration longTimeout = Duration(seconds: 60);

  /// Default timeout for very long operations
  /// 
  /// Used for file uploads, large report generation, and other
  /// operations that can legitimately take several minutes.
  static const Duration veryLongTimeout = Duration(seconds: 120);

  /// Default timeout for background operations
  /// 
  /// Used for non-critical background tasks that can afford to take time
  /// Legacy compatibility: 100 minutes (to match old implementation)
  static const Duration backgroundTimeout = Duration(seconds: 100 * 60);

  // ==========================================================================
  // RETRY CONFIGURATION
  // ==========================================================================

  /// Default retry configuration
  /// 
  /// Used when no specific retry config is provided.
  /// Null means no retry by default - operations must explicitly opt-in.
  static RetryConfig? get defaultRetryConfig => null;

  /// Retry configuration for critical operations
  /// 
  /// Use for operations that must eventually succeed (payments, orders, etc.)
  static RetryConfig get criticalRetryConfig => RetryConfig.aggressive();

  /// Retry configuration for standard operations
  /// 
  /// Use for most CRUD operations that can safely retry
  static RetryConfig get standardRetryConfig => RetryConfig.standard();

  /// Retry configuration for destructive operations
  /// 
  /// Use for delete operations and other destructive actions
  static RetryConfig get destructiveRetryConfig => RetryConfig.conservative();

  // ==========================================================================
  // CONNECTIVITY CONFIGURATION
  // ==========================================================================

  /// Whether to check connectivity by default
  /// 
  /// If true, all operations will check for internet connection before executing.
  /// If false, connectivity checks must be explicitly enabled per operation.
  static const bool checkConnectivityByDefault = false;

  /// Whether to queue operations offline by default
  /// 
  /// If true, failed operations will be queued when offline.
  /// If false, operations fail immediately when offline.
  static const bool queueIfOfflineByDefault = false;

  // ==========================================================================
  // OFFLINE QUEUE CONFIGURATION
  // ==========================================================================

  /// Maximum number of operations that can be queued
  /// 
  /// When queue reaches this size, new operations will be rejected.
  static const int maxQueueSize = 100;

  /// Default priority for queued operations
  /// 
  /// Used when no specific priority is provided.
  static const int defaultQueuePriority = 1; // QueuePriority.normal.value

  /// Default expiry time for queued operations
  /// 
  /// Operations older than this will be automatically removed from queue.
  static const Duration defaultQueueExpiry = Duration(hours: 24);

  /// Maximum retry attempts for queued operations
  /// 
  /// After this many failures, queued operations will be removed.
  static const int maxQueuedOperationRetries = 3;

  // ==========================================================================
  // TIMEOUT CONFIGURATION BY OPERATION TYPE
  // ==========================================================================

  /// Get appropriate timeout for operation type
  /// 
  /// Provides intelligent timeout selection based on operation category.
  /// 
  /// [operationType] - Type of operation (e.g., 'create', 'read', 'upload')
  static Duration getTimeoutForOperation(String operationType) {
    final type = operationType.toLowerCase();

    // File operations
    if (type.contains('upload') || type.contains('download')) {
      return veryLongTimeout;
    }

    // Report generation
    if (type.contains('report') || type.contains('export')) {
      return longTimeout;
    }

    // Validation operations
    if (type.contains('validate') || type.contains('check')) {
      return quickTimeout;
    }

    // Background operations
    if (type.contains('background') || type.contains('sync')) {
      return backgroundTimeout;
    }

    // Default: standard timeout
    return standardTimeout;
  }

  /// Get appropriate retry config for operation type
  /// 
  /// Provides intelligent retry strategy based on operation category.
  /// 
  /// [operationType] - Type of operation (e.g., 'create', 'delete', 'payment')
  static RetryConfig? getRetryConfigForOperation(String operationType) {
    final type = operationType.toLowerCase();

    // Critical operations
    if (type.contains('payment') || 
        type.contains('order') || 
        type.contains('transaction')) {
      return criticalRetryConfig;
    }

    // Destructive operations
    if (type.contains('delete') || type.contains('remove')) {
      return destructiveRetryConfig;
    }

    // Read operations (safe to retry)
    if (type.contains('fetch') || 
        type.contains('get') || 
        type.contains('read') ||
        type.contains('load')) {
      return standardRetryConfig;
    }

    // Write operations (retry if idempotent)
    if (type.contains('create') || 
        type.contains('update') || 
        type.contains('save')) {
      return standardRetryConfig;
    }

    // Validation operations (no retry needed)
    if (type.contains('validate') || type.contains('check')) {
      return RetryConfig.noRetry();
    }

    // Default: no retry (must opt-in)
    return defaultRetryConfig;
  }

  // ==========================================================================
  // CONNECTIVITY CONFIGURATION BY OPERATION TYPE
  // ==========================================================================

  /// Whether connectivity should be checked for this operation type
  /// 
  /// [operationType] - Type of operation
  static bool shouldCheckConnectivity(String operationType) {
    final type = operationType.toLowerCase();

    // Always check for network operations
    if (type.contains('fetch') || 
        type.contains('upload') ||
        type.contains('download') ||
        type.contains('sync')) {
      return true;
    }

    // Check for critical operations
    if (type.contains('payment') || 
        type.contains('order')) {
      return true;
    }

    // Default: no check (faster for local operations)
    return checkConnectivityByDefault;
  }

  /// Whether operation should be queued if offline
  /// 
  /// [operationType] - Type of operation
  static bool shouldQueueIfOffline(String operationType) {
    final type = operationType.toLowerCase();

    // Queue critical business operations
    if (type.contains('payment') || 
        type.contains('order') || 
        type.contains('transaction')) {
      return true;
    }

    // Queue data modifications
    if (type.contains('create') || 
        type.contains('update') || 
        type.contains('save')) {
      return true;
    }

    // Don't queue read operations (can re-fetch)
    if (type.contains('fetch') || 
        type.contains('get') || 
        type.contains('read') ||
        type.contains('load')) {
      return false;
    }

    // Default
    return queueIfOfflineByDefault;
  }

  // ==========================================================================
  // FILE SIZE-BASED TIMEOUT CALCULATION
  // ==========================================================================

  /// Calculate timeout based on file size
  /// 
  /// Provides appropriate timeout for file upload/download operations
  /// based on estimated transfer time.
  /// 
  /// [fileSizeInBytes] - Size of file in bytes
  /// [speedInBytesPerSecond] - Estimated transfer speed (default: 1MB/s)
  /// [minimumTimeout] - Minimum timeout to enforce (default: 60s)
  /// [bufferMultiplier] - Safety buffer (default: 2x)
  static Duration calculateFileTransferTimeout({
    required int fileSizeInBytes,
    int speedInBytesPerSecond = 1024 * 1024, // 1 MB/s default
    Duration minimumTimeout = const Duration(seconds: 60),
    double bufferMultiplier = 2.0,
  }) {
    // Calculate estimated transfer time
    final estimatedSeconds = fileSizeInBytes / speedInBytesPerSecond;

    // Apply buffer multiplier for safety
    final bufferedSeconds = (estimatedSeconds * bufferMultiplier).ceil();

    // Create timeout duration
    final calculatedTimeout = Duration(seconds: bufferedSeconds);

    // Enforce minimum timeout
    if (calculatedTimeout < minimumTimeout) {
      return minimumTimeout;
    }

    return calculatedTimeout;
  }

  // ==========================================================================
  // LOGGING CONFIGURATION
  // ==========================================================================

  /// Whether to log retry attempts
  static const bool logRetryAttempts = true;

  /// Whether to log connectivity checks
  static const bool logConnectivityChecks = true;

  /// Whether to log queue operations
  static const bool logQueueOperations = true;

  /// Whether to log operation durations
  static const bool logOperationDurations = true;

  // ==========================================================================
  // UTILITY METHODS
  // ==========================================================================

  /// Get a summary of current configuration
  /// 
  /// Useful for debugging and verification
  static Map<String, dynamic> getConfigSummary() {
    return {
      'timeouts': {
        'standard': '${standardTimeout.inSeconds}s',
        'quick': '${quickTimeout.inSeconds}s',
        'long': '${longTimeout.inSeconds}s',
        'veryLong': '${veryLongTimeout.inSeconds}s',
        'background': '${backgroundTimeout.inSeconds}s',
      },
      'retry': {
        'defaultConfig': defaultRetryConfig?.toString() ?? 'null',
        'critical': criticalRetryConfig.toString(),
        'standard': standardRetryConfig.toString(),
        'destructive': destructiveRetryConfig.toString(),
      },
      'connectivity': {
        'checkByDefault': checkConnectivityByDefault,
        'queueIfOfflineByDefault': queueIfOfflineByDefault,
      },
      'queue': {
        'maxSize': maxQueueSize,
        'defaultPriority': defaultQueuePriority,
        'defaultExpiry': '${defaultQueueExpiry.inHours}h',
        'maxRetries': maxQueuedOperationRetries,
      },
      'logging': {
        'retryAttempts': logRetryAttempts,
        'connectivityChecks': logConnectivityChecks,
        'queueOperations': logQueueOperations,
        'operationDurations': logOperationDurations,
      },
    };
  }

  /// Print configuration summary to console
  /// 
  /// Useful for debugging and verification
  static void printConfigSummary() {
    final summary = getConfigSummary();
    final buffer = StringBuffer();
    
    buffer.writeln('AsyncHandlerConfig Summary:');
    buffer.writeln('================================');
    summary.forEach((category, values) {
      buffer.writeln('$category:');
      if (values is Map) {
        values.forEach((key, value) {
          buffer.writeln('  $key: $value');
        });
      } else {
        buffer.writeln('  $values');
      }
    });
    buffer.writeln('================================');
    
    _logger.info(buffer.toString());
  }
}

