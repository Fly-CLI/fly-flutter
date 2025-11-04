import 'dart:async';
import 'dart:io';

import 'package:{{project_name_snake}}/core/foundation/error/error_message_formatter.dart';
import 'package:{{project_name_snake}}/core/foundation/foundation.dart';
import 'package:{{project_name_snake}}/shared/localization/localizations.dart';
import 'package:uuid/uuid.dart';

/// Enhanced async operation handler with network awareness
/// 
/// Features:
/// - Connectivity checking before operations
/// - Configurable retry with exponential backoff and jitter
/// - Network error classification and handling
/// - Offline queue integration for failed operations
/// - Timeout configuration per operation
/// - Progress callbacks for long operations
/// - Telemetry and logging
class AsyncHandler {
  final AppLogger _logger = AppLogger('AsyncHandler');
  final ConnectivityService _connectivityService;
  final OfflineQueueManager? _offlineQueueManager;
  final Uuid _uuid = const Uuid();

  AsyncHandler({
    ConnectivityService? connectivityService,
    OfflineQueueManager? offlineQueueManager,
  })  : _connectivityService =
            connectivityService ?? ConnectivityService(),
        _offlineQueueManager = offlineQueueManager;

  /// Execute an operation with basic error handling and timeout
  /// 
  /// [operation] - The async operation to execute
  /// [errorMessage] - Custom error message for failures
  /// [timeout] - Maximum time to wait for operation (defaults to AsyncHandlerConfig.standardTimeout)
  /// [checkConnectivity] - Whether to verify internet connection first
  /// [queueIfOffline] - Whether to queue operation if offline
  Future<AppResult<T>> execute<T>(
    Future<T> Function() operation, {
    String? errorMessage,
    Duration? timeout,
    bool? checkConnectivity,
    bool? queueIfOffline,
  }) async {
    final effectiveTimeout = timeout ?? AsyncHandlerConfig.standardTimeout;
    final effectiveCheckConnectivity = 
        checkConnectivity ?? AsyncHandlerConfig.checkConnectivityByDefault;
    final effectiveQueueIfOffline = 
        queueIfOffline ?? AsyncHandlerConfig.queueIfOfflineByDefault;
    final startTime = DateTime.now();

    try {
      // Check connectivity if requested
      if (effectiveCheckConnectivity) {
        final hasConnection =
            await _connectivityService.hasInternetConnection();
        if (!hasConnection) {
          _logger.warning('No internet connection detected');

          // Queue operation if requested
          if (effectiveQueueIfOffline && _offlineQueueManager != null) {
            await _queueOperation(operation, errorMessage);
            return Failure(
              errorMessage ?? localizations.noInternetConnectionQueuedShort,
              NoInternetError(),
            );
          }

          return Failure(
            errorMessage ?? localizations.networkNoInternet,
            NoInternetError(),
          );
        }
      }

      // Execute operation with timeout
      final result = await operation().timeout(effectiveTimeout);

      final duration = DateTime.now().difference(startTime);
      _logger.debug('Operation completed in ${duration.inMilliseconds}ms');

      return Success(result);
    } on TimeoutException {
      final duration = DateTime.now().difference(startTime);
      _logger.logError(
        'Operation timed out after ${duration.inSeconds} seconds',
      );

      final error = TimeoutError(timeout: effectiveTimeout);
      return Failure(
        errorMessage ?? localizations.networkTimeout,
        error,
      );
    } on SocketException catch (e, stackTrace) {
      _logger.logError('Socket exception: ${e.message}', stackTrace: stackTrace);

      final error = NetworkErrorClassifier.classifyError(e);
      return Failure(
        errorMessage ?? error.message,
        error,
      );
    } catch (e, stackTrace) {
      _logger.logError('Operation failed: $e', stackTrace: stackTrace);

      // Classify error as network error if applicable
      final classifiedError = NetworkErrorClassifier.classifyError(
        e,
        timeout: effectiveTimeout,
      );

      // Format error message for user display
      final formattedError = errorMessage ?? ErrorMessageFormatter.format(e);

      return Failure(formattedError, classifiedError);
    }
  }

  /// Execute an operation with retry logic and exponential backoff
  /// 
  /// [operation] - The async operation to execute
  /// [retryConfig] - Configuration for retry behavior (defaults to AsyncHandlerConfig.defaultRetryConfig)
  /// [errorMessage] - Custom error message for failures
  /// [timeout] - Maximum time to wait per attempt (defaults to AsyncHandlerConfig.standardTimeout)
  /// [checkConnectivity] - Whether to verify internet connection
  Future<AppResult<T>> executeWithRetry<T>(
    Future<T> Function() operation, {
    RetryConfig? retryConfig,
    String? errorMessage,
    Duration? timeout,
    bool? checkConnectivity,
  }) async {
    final config = retryConfig ?? 
        AsyncHandlerConfig.defaultRetryConfig ??
        RetryConfig.noRetry();
    final startTime = DateTime.now();
    var lastError;
    final delays = <Duration>[];

    _logger.debug('Starting operation with retry config: $config');

    // Initial attempt + retries
    for (int attempt = 0; attempt <= config.maxAttempts; attempt++) {
      final isRetry = attempt > 0;

      if (isRetry) {
        final delay = config.calculateDelay(attempt - 1);
        delays.add(delay);
        _logger.debug('Retry attempt $attempt/${config.maxAttempts} '
            'after ${delay.inMilliseconds}ms delay');
        await Future.delayed(delay);
      } else {
        _logger.debug('Initial attempt');
      }

      // Execute operation
      final result = await execute(
        operation,
        errorMessage: errorMessage,
        timeout: timeout,
        checkConnectivity: (checkConnectivity ?? true) && !isRetry, // Only check on first attempt
        queueIfOffline: false, // Don't queue during retries
      );

      if (result.isSuccess) {
        final totalDuration = DateTime.now().difference(startTime);
        _logger.log(
          'Operation succeeded on attempt ${attempt + 1} '
          '(total time: ${totalDuration.inMilliseconds}ms)',
        );

        return result;
      }

      // Operation failed, check if we should retry
      lastError = result.error;

      if (!config.isRetryable(lastError)) {
        _logger.warning('Error is not retryable: ${lastError.runtimeType}');
        break;
      }

      if (attempt == config.maxAttempts) {
        _logger.warning('Max retry attempts reached');
        break;
      }
    }

    // All attempts failed
    final totalDuration = DateTime.now().difference(startTime);
    _logger.logError(
      'Operation failed after ${config.maxAttempts + 1} attempts '
      '(total time: ${totalDuration.inSeconds}s)',
    );

    // Format error message for user display
    final formattedError = errorMessage ?? 
        (lastError != null 
            ? ErrorMessageFormatter.format(lastError)
            : localizations.networkOperationFailedAfterRetries);

    return Failure(formattedError, lastError);
  }

  /// Execute a network operation with full error handling
  /// 
  /// This method enforces connectivity checking and provides
  /// comprehensive network error handling with optional queuing
  /// 
  /// [operation] - The network operation to execute
  /// [retryConfig] - Configuration for retry behavior (defaults to AsyncHandlerConfig.standardRetryConfig)
  /// [errorMessage] - Custom error message for failures
  /// [timeout] - Maximum time to wait per attempt (defaults to AsyncHandlerConfig.standardTimeout)
  /// [queueIfOffline] - Whether to queue operation if offline (defaults to AsyncHandlerConfig.queueIfOfflineByDefault)
  Future<AppResult<T>> executeNetworkOperation<T>(
    Future<T> Function() operation, {
    RetryConfig? retryConfig,
    String? errorMessage,
    Duration? timeout,
    bool? queueIfOffline,
  }) async {
    final effectiveQueueIfOffline = queueIfOffline ?? true; // Network operations should queue by default
    // Check connectivity first
    final hasConnection = await _connectivityService.hasInternetConnection();
    if (!hasConnection) {
      _logger.warning('No internet connection for network operation');

      // Queue operation if requested and queue manager available
      if (effectiveQueueIfOffline && _offlineQueueManager != null) {
        await _queueOperation(operation, errorMessage);
        return Failure(
          errorMessage ?? localizations.noInternetConnectionQueuedLong,
          NoInternetError(),
        );
      }

      return Failure(
        errorMessage ?? localizations.networkNoInternet,
        NoInternetError(),
      );
    }

    // Execute with retry
    return executeWithRetry(
      operation,
      retryConfig: retryConfig ?? AsyncHandlerConfig.defaultRetryConfig,
      errorMessage: errorMessage,
      timeout: timeout,
      checkConnectivity: false, // Already checked above
    );
  }

  /// Execute operation with progress callbacks (for ViewModel integration)
  /// 
  /// This method maintains compatibility with existing ViewModel usage
  /// while adding network awareness
  Future<AppResult<T>> performAsync<T>(
    Future<T> Function() operation, {
    String? errorMessage,
    Duration? timeout,
    RetryConfig? retryConfig,
    void Function(bool isLoading)? onLoadingChanged,
    void Function(String? error)? onErrorChanged,
    void Function()? onNotify,
    bool resetError = true,
    bool notifyChange = true,
    void Function()? onFinally,
    bool? checkConnectivity,
    bool? queueIfOffline,
  }) async {
    // Handle initial state
    if (resetError) {
      onErrorChanged?.call(null);
    }
    onLoadingChanged?.call(true);
    if (notifyChange) onNotify?.call();

    try {
      AppResult<T> result;

      // Use retry if config provided, otherwise basic execution
      if (retryConfig != null) {
        result = await executeWithRetry(
          operation,
          retryConfig: retryConfig,
          errorMessage: errorMessage,
          timeout: timeout,
          checkConnectivity: checkConnectivity,
        );
      } else {
        result = await execute(
          operation,
          errorMessage: errorMessage,
          timeout: timeout,
          checkConnectivity: checkConnectivity,
          queueIfOffline: queueIfOffline,
        );
      }

      // Handle result
      if (result.isSuccess) {
        onLoadingChanged?.call(false);
        onErrorChanged?.call(null);
        if (notifyChange) onNotify?.call();
        return result;
      } else {
        _handleError(
          result.error ?? localizations.networkUnknownError,
          onLoadingChanged,
          onErrorChanged,
          onNotify,
          notifyChange,
        );
        return result;
      }
    } catch (e, stackTrace) {
      _logger.logError('Operation failed: $e', stackTrace: stackTrace);
      
      // Format error message for user display
      final formattedError = errorMessage ?? ErrorMessageFormatter.format(e);
      
      _handleError(
        formattedError,
        onLoadingChanged,
        onErrorChanged,
        onNotify,
        notifyChange,
      );
      return Failure(formattedError, e);
    } finally {
      onFinally?.call();
    }
  }

  /// Execute operation with progress callbacks (simple version without retry)
  Future<AppResult<T>> executeWithProgress<T>(
    Future<T> Function() operation,
    void Function(bool isLoading) onProgress, {
    String? errorMessage,
    Duration? timeout,
  }) async {
    onProgress(true);
    try {
      final result = await execute(
        operation,
        errorMessage: errorMessage,
        timeout: timeout,
      );
      onProgress(false);
      return result;
    } catch (e, stackTrace) {
      onProgress(false);
      _logger.logError('Operation failed: $e', stackTrace: stackTrace);
      
      // Format error message for user display
      final formattedError = errorMessage ?? ErrorMessageFormatter.format(e);
      
      return Failure(formattedError, e);
    }
  }

  /// Helper method to queue an operation for offline processing
  Future<void> _queueOperation<T>(
    Future<T> Function() operation,
    String? errorMessage,
  ) async {
    if (_offlineQueueManager == null) {
      _logger.warning('No queue manager available for offline operation');
      return;
    }

    final queuedOp = QueuedOperation<T>(
      id: _uuid.v4(),
      operation: operation,
      operationType: errorMessage ?? localizations.networkOperationDefault,
      priority: QueuePriority.normal,
      expiresAt: DateTime.now().add(AsyncHandlerConfig.defaultQueueExpiry),
      maxRetries: AsyncHandlerConfig.maxQueuedOperationRetries,
    );

    final queued = await _offlineQueueManager.enqueue(queuedOp);
    if (queued) {
      _logger.log('Operation queued: ${queuedOp.id}');
    } else {
      _logger.warning('Failed to queue operation: ${queuedOp.id}');
    }
  }

  /// Helper method to handle error states consistently
  void _handleError(
    String error,
    void Function(bool isLoading)? onLoadingChanged,
    void Function(String? error)? onErrorChanged,
    void Function()? onNotify,
    bool notifyChange,
  ) {
    // Format error message for user display
    final formattedError = ErrorMessageFormatter.format(error, logError: false);
    
    onLoadingChanged?.call(false);
    onErrorChanged?.call(formattedError);
    if (notifyChange) onNotify?.call();
  }
}
