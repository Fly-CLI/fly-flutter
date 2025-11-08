import 'dart:async';
import 'dart:io';

import 'package:fly_connectivity/fly_connectivity.dart';
import 'package:fly_errors/fly_errors.dart';
import 'package:fly_events/fly_events.dart';
import 'package:fly_localization/fly_localization.dart';
import 'package:fly_logger/fly_logger.dart';
import 'package:fly_operations/src/async_operation_config.dart';
import 'package:fly_operations/src/offline_queue.dart';
import 'package:fly_operations/src/result.dart';
import 'package:fly_operations/src/retry_config.dart';
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
/// - Event emission for observability
class AsyncOperationHandler with EventEmitterMixin {
  final FlyLogger _logger;
  final ConnectivityService? _connectivityService;
  final OfflineQueue? _offlineQueue;
  final FoundationLocalizationProvider _localizations;
  final ErrorMessageFormatter _errorMessageFormatter;
  final Uuid _uuid = const Uuid();

  static const String _defaultOperationName = 'execute';

  AsyncOperationHandler({
    required FlyLogger logger,
    ConnectivityService? connectivityService,
    ConnectivityChecker? connectivityChecker,
    OfflineQueue? offlineQueue,
    FoundationLocalizationProvider? localizations,
    ErrorMessageFormatter? errorMessageFormatter,
  })  : _logger = logger,
        _connectivityService = connectivityService ??
            (connectivityChecker != null
                ? ConnectivityService(checker: connectivityChecker, logger: logger)
                : null),
        _offlineQueue = offlineQueue,
        _localizations = localizations ?? DefaultFoundationLocalizationProvider(),
        _errorMessageFormatter = errorMessageFormatter ??
            ErrorMessageFormatter(
              logger: logger,
              defaultLocalizations: localizations ?? DefaultFoundationLocalizationProvider(),
            );

  /// Execute an operation with basic error handling and timeout
  /// 
  /// [operation] - The async operation to execute
  /// [errorMessage] - Custom error message for failures
  /// [timeout] - Maximum time to wait for operation (defaults to AsyncHandlerConfig.standardTimeout)
  /// [checkConnectivity] - Whether to verify internet connection first
  /// [queueIfOffline] - Whether to queue operation if offline
  /// [operationName] - Optional name for the operation (for events, defaults to 'execute')
  Future<AppResult<T>> execute<T>(
    Future<T> Function() operation, {
    String? errorMessage,
    Duration? timeout,
    bool? checkConnectivity,
    bool? queueIfOffline,
    String? operationName,
  }) async {
    final options = _buildExecuteOptions(
      timeout: timeout,
      checkConnectivity: checkConnectivity,
      queueIfOffline: queueIfOffline,
      errorMessage: errorMessage,
      operationName: operationName,
    );
    final startTime = DateTime.now();
    final operationId = _uuid.v4();

    _emitStartEvent(operationId, options);

    try {
      final connectivityFailure = await _ensureConnectivityIfNeeded<T>(
        operation: operation,
        operationId: operationId,
        options: options,
        startTime: startTime,
      );
      if (connectivityFailure != null) {
        return connectivityFailure;
      }

      final result = await operation().timeout(options.timeout);
      final duration = DateTime.now().difference(startTime);

      _logger.debug('Operation completed in ${duration.inMilliseconds}ms');
      _emitCompletionEvent(operationId, options, duration);

      return Success(result);
    } on TimeoutException {
      return _handleTimeoutFailure<T>(
        startTime: startTime,
        options: options,
        operationId: operationId,
      );
    } on SocketException catch (e, stackTrace) {
      return _handleSocketFailure<T>(
        startTime: startTime,
        socketException: e,
        stackTrace: stackTrace,
        options: options,
        operationId: operationId,
      );
    } catch (e, stackTrace) {
      return _handleGenericFailure<T>(
        error: e,
        stackTrace: stackTrace,
        startTime: startTime,
        options: options,
        operationId: operationId,
      );
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
        AsyncOperationConfig.defaultRetryConfig ??
        RetryConfig.noRetry();
    final startTime = DateTime.now();
    Object? lastError;
    final delays = <Duration>[];

    _logger.debug('Starting operation with retry config: $config');

    for (var attempt = 0; attempt <= config.maxAttempts; attempt++) {
      final isRetryAttempt = attempt > 0;

      if (isRetryAttempt) {
        final delay = config.calculateDelay(attempt - 1);
        delays.add(delay);
        _logger.debug(
          'Retry attempt $attempt/${config.maxAttempts} after ${delay.inMilliseconds}ms delay',
        );
        await Future<void>.delayed(delay);
      } else {
        _logger.debug('Initial attempt');
      }

      final result = await execute(
        operation,
        errorMessage: errorMessage,
        timeout: timeout,
        checkConnectivity: (checkConnectivity ?? true) && !isRetryAttempt,
        queueIfOffline: false,
      );

      if (result.isSuccess) {
        final totalDuration = DateTime.now().difference(startTime);
        _logger.info(
          'Operation succeeded on attempt ${attempt + 1} (total time: ${totalDuration.inMilliseconds}ms)',
        );
        return result;
      }

      if (result is Failure<T>) {
        lastError = result.originalError;
      }

      if (lastError != null && !config.isRetryable(lastError)) {
        _logger.warn('Error is not retryable: ${lastError.runtimeType}');
        break;
      }

      if (attempt == config.maxAttempts) {
        _logger.warn('Max retry attempts reached');
        break;
      }
    }

    final totalDuration = DateTime.now().difference(startTime);
    _logger.error(
      'Operation failed after ${config.maxAttempts + 1} attempts '
      '(total time: ${totalDuration.inSeconds}s)',
    );

    // Format error message for user display
    final formattedError = errorMessage ?? 
        (lastError != null 
            ? _errorMessageFormatter.format(
                lastError,
                localizations: _localizations,
              )
            : _localizations.networkOperationFailedAfterRetries);

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
    final connectivityService = _connectivityService;
    if (connectivityService != null) {
      final hasConnection = await connectivityService.hasInternetConnection();
      if (!hasConnection) {
        _logger.warn('No internet connection for network operation');

        // Queue operation if requested and queue available
        if (effectiveQueueIfOffline && _offlineQueue != null) {
          await _queueOperation(operation, errorMessage);
          return Failure(
            errorMessage ?? _localizations.noInternetConnectionQueuedLong,
            NoInternetError(localizations: _localizations),
          );
        }

        return Failure(
          errorMessage ?? _localizations.networkNoInternet,
          NoInternetError(localizations: _localizations),
        );
      }
    } else {
      _logger.warn(
        'Connectivity service not configured; running network operation without connectivity checks',
      );
    }

    // Execute with retry
    return executeWithRetry(
      operation,
      retryConfig: retryConfig ?? AsyncOperationConfig.defaultRetryConfig,
      errorMessage: errorMessage,
      timeout: timeout,
      checkConnectivity: false, // Already checked above when available
    );
  }

  /// Execute operation with progress callbacks (for ViewModel integration)
  /// 
  /// Provides network-aware async operation execution with progress tracking
  Future<AppResult<T>> runAsyncOperation<T>(
    Future<T> Function() operation, {
    String? errorMessage,
    Duration? timeout,
    RetryConfig? retryConfig,
    void Function({required bool isLoading})? onLoadingChanged,
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
    onLoadingChanged?.call(isLoading: true);
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
        onLoadingChanged?.call(isLoading: false);
        onErrorChanged?.call(null);
        if (notifyChange) onNotify?.call();
        return result;
      } else {
        final errorMessage = result.error ?? _localizations.networkUnknownError;
        _handleError(
          errorMessage,
          onLoadingChanged,
          onErrorChanged,
          onNotify,
          notifyChange,
        );
        return result;
      }
    } catch (e, stackTrace) {
      _logger.error('Operation failed: $e', stackTrace: stackTrace);
      
      final formattedError = errorMessage ?? _errorMessageFormatter.format(
        e,
        localizations: _localizations,
      );
      
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
    void Function({bool isLoading}) onProgress, {
    String? errorMessage,
    Duration? timeout,
  }) async {
    onProgress(isLoading: true);
    try {
      final result = await execute(
        operation,
        errorMessage: errorMessage,
        timeout: timeout,
      );
      onProgress(isLoading: false);
      return result;
    } catch (e, stackTrace) {
      onProgress(isLoading: false);
      _logger.error('Operation failed: $e', stackTrace: stackTrace);
      
      final formattedError = errorMessage ?? _errorMessageFormatter.format(
        e,
        localizations: _localizations,
      );
      
      return Failure(formattedError, e);
    }
  }

  /// Helper method to queue an operation for offline processing
  Future<void> _queueOperation<T>(
    Future<T> Function() operation,
    String? errorMessage,
  ) async {
    final queue = _offlineQueue;
    if (queue == null) {
      _logger.warn('No queue available for offline operation');
      return;
    }

    final queuedOp = QueuedOperation<T>(
      id: _uuid.v4(),
      operation: operation,
      operationType: errorMessage ?? _localizations.networkOperationDefault,
      expiresAt: DateTime.now().add(AsyncOperationConfig.defaultQueueExpiry),
    );

    final queued = await queue.enqueue(queuedOp);
    if (queued) {
      _logger.info('Operation queued: ${queuedOp.id}');
    } else {
      _logger.warn('Failed to queue operation: ${queuedOp.id}');
    }
  }

  void _handleError(
    String error,
    void Function({required bool isLoading})? onLoadingChanged,
    void Function(String? error)? onErrorChanged,
    void Function()? onNotify,
    bool notifyChange,
  ) {
    // Error is already formatted, use it directly
    onLoadingChanged?.call(isLoading: false);
    onErrorChanged?.call(error);
    if (notifyChange) {
      onNotify?.call();
    }
  }

  _ExecuteOptions _buildExecuteOptions({
    Duration? timeout,
    bool? checkConnectivity,
    bool? queueIfOffline,
    String? errorMessage,
    String? operationName,
  }) {
    return _ExecuteOptions(
      timeout: timeout ?? AsyncOperationConfig.standardTimeout,
      checkConnectivity:
          checkConnectivity ?? AsyncOperationConfig.checkConnectivityByDefault,
      queueIfOffline:
          queueIfOffline ?? AsyncOperationConfig.queueIfOfflineByDefault,
      userFacingErrorMessage: errorMessage,
      operationName: operationName ?? _defaultOperationName,
    );
  }

  Future<AppResult<T>?> _ensureConnectivityIfNeeded<T>({
    required Future<T> Function() operation,
    required String operationId,
    required _ExecuteOptions options,
    required DateTime startTime,
  }) async {
    if (!options.checkConnectivity) {
      return null;
    }

    final connectivityService = _connectivityService;
    if (connectivityService == null) {
      _logger.warn(
        'Connectivity check requested but no connectivity service available; skipping check',
      );
      return null;
    }

    final hasConnection = await connectivityService.hasInternetConnection();
    if (hasConnection) {
      return null;
    }

    _logger.warn('No internet connection detected');

    final duration = DateTime.now().difference(startTime);
    final message = options.userFacingErrorMessage ??
        (options.queueIfOffline
            ? _localizations.noInternetConnectionQueuedShort
            : _localizations.networkNoInternet);

    _emitFailureEvent(
      operationId: operationId,
      operationName: options.operationName,
      duration: duration,
      error: message,
      metadata: <String, Object?>{
        'errorType': 'NoInternetError',
        'queued': options.queueIfOffline && _offlineQueue != null,
      },
    );

    if (options.queueIfOffline && _offlineQueue != null) {
      await _queueOperation(operation, options.userFacingErrorMessage);
    }

    return Failure(
      message,
      NoInternetError(localizations: _localizations),
    );
  }

  Failure<T> _handleTimeoutFailure<T>({
    required DateTime startTime,
    required _ExecuteOptions options,
    required String operationId,
  }) {
    final duration = DateTime.now().difference(startTime);
    _logger.error('Operation timed out after ${duration.inSeconds} seconds');

    final message =
        options.userFacingErrorMessage ?? _localizations.networkTimeout;
    final timeoutError = TimeoutError(
      timeout: options.timeout,
      localizations: _localizations,
    );

    _emitFailureEvent(
      operationId: operationId,
      operationName: options.operationName,
      duration: duration,
      error: message,
      metadata: <String, Object?>{
        'errorType': 'TimeoutException',
        'timeout': options.timeout.inMilliseconds,
      },
    );

    return Failure(message, timeoutError);
  }

  Failure<T> _handleSocketFailure<T>({
    required DateTime startTime,
    required SocketException socketException,
    required StackTrace stackTrace,
    required _ExecuteOptions options,
    required String operationId,
  }) {
    _logger.error(
      'Socket exception: ${socketException.message}',
      stackTrace: stackTrace,
    );

    final duration = DateTime.now().difference(startTime);
    final classifiedError = NetworkErrorClassifier.classifyError(
      socketException,
      localizations: _localizations,
    );
    final message = options.userFacingErrorMessage ??
        (classifiedError.message);

    _emitFailureEvent(
      operationId: operationId,
      operationName: options.operationName,
      duration: duration,
      error: message,
      metadata: <String, Object?>{
        'errorType': 'SocketException',
        'originalError': socketException.toString(),
      },
    );

    return Failure(message, classifiedError);
  }

  Failure<T> _handleGenericFailure<T>({
    required Object error,
    required StackTrace stackTrace,
    required DateTime startTime,
    required _ExecuteOptions options,
    required String operationId,
  }) {
    _logger.error('Operation failed: $error', stackTrace: stackTrace);

    final classifiedError = NetworkErrorClassifier.classifyError(
      error,
      timeout: options.timeout,
      localizations: _localizations,
    );
    final message = options.userFacingErrorMessage ??
        _errorMessageFormatter.format(
          error,
          localizations: _localizations,
        );
    final duration = DateTime.now().difference(startTime);

    _emitFailureEvent(
      operationId: operationId,
      operationName: options.operationName,
      duration: duration,
      error: message,
      metadata: <String, Object?>{
        'errorType': error.runtimeType.toString(),
        'originalError': error.toString(),
      },
    );

    return Failure(message, classifiedError);
  }

  void _emitStartEvent(String operationId, _ExecuteOptions options) {
    emit(
      AsyncOperationStartedEvent(
        operationId: operationId,
        operationName: options.operationName,
        metadata: <String, Object?>{
          'timeout': options.timeout.inMilliseconds,
          'checkConnectivity': options.checkConnectivity,
          'queueIfOffline': options.queueIfOffline,
        },
      ),
    );
  }

  void _emitCompletionEvent(
    String operationId,
    _ExecuteOptions options,
    Duration duration,
  ) {
    emit(
      AsyncOperationCompletedEvent(
        operationId: operationId,
        operationName: options.operationName,
        success: true,
        duration: duration,
        metadata: <String, Object?>{
          'timeout': options.timeout.inMilliseconds,
        },
      ),
    );
  }

  void _emitFailureEvent({
    required String operationId,
    required String operationName,
    required Duration duration,
    required String error,
    required Map<String, Object?> metadata,
  }) {
    emit(
      AsyncOperationFailedEvent(
        operationId: operationId,
        operationName: operationName,
        error: error,
        duration: duration,
        metadata: metadata,
      ),
    );
  }
}

class _ExecuteOptions {
  _ExecuteOptions({
    required this.timeout,
    required this.checkConnectivity,
    required this.queueIfOffline,
    required this.userFacingErrorMessage,
    required this.operationName,
  });

  final Duration timeout;
  final bool checkConnectivity;
  final bool queueIfOffline;
  final String? userFacingErrorMessage;
  final String operationName;
}

