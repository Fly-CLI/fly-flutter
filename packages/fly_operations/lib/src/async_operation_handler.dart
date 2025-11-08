import 'dart:async';
import 'dart:io';

import 'package:fly_connectivity/fly_connectivity.dart';
import 'package:fly_errors/fly_errors.dart' hide TimeoutException;
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
    final operationId = _uuid.v4();

    final lifecycle = _OperationLifecycle(
      operationId: operationId,
      operationName: options.operationName,
      options: options,
      emit: emit,
    );

    final failureTranslator = _FailureTranslator(
      logger: _logger,
      localizations: _localizations,
      errorMessageFormatter: _errorMessageFormatter,
      options: options,
      lifecycle: lifecycle,
    );

    final connectivityGuard = _ConnectivityGuard(
      logger: _logger,
      connectivityService: _connectivityService,
      offlineQueue: _offlineQueue,
      localizations: _localizations,
    );

    lifecycle.start();

    try {
      final queueOperation = options.queueIfOffline && _offlineQueue != null
          ? () => _queueOperation(operation, options.userFacingErrorMessage)
          : null;

      final connectivityFailure = await connectivityGuard.ensureConnectivity<T>(
        options: options,
        queueOperation: queueOperation,
        failureTranslator: failureTranslator,
      );
      if (connectivityFailure != null) {
        return connectivityFailure;
      }

      final result = await operation().timeout(options.timeout);
      final duration = lifecycle.elapsed;

      _logger.debug('Operation completed in ${duration.inMilliseconds}ms');
      lifecycle.complete();

      return Success(result);
    } on TimeoutException {
      return failureTranslator.timeoutFailure<T>();
    } on SocketException catch (e, stackTrace) {
      return failureTranslator.socketFailure<T>(
        socketException: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      return failureTranslator.genericFailure<T>(
        error: e,
        stackTrace: stackTrace,
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
  /// [queueIfOffline] - Whether to enqueue the operation when offline (first attempt only)
  Future<AppResult<T>> executeWithRetry<T>(
    Future<T> Function() operation, {
    RetryConfig? retryConfig,
    String? errorMessage,
    Duration? timeout,
    bool? checkConnectivity,
    bool? queueIfOffline,
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
        queueIfOffline: (queueIfOffline ?? false) && !isRetryAttempt,
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
    final effectiveQueueIfOffline = queueIfOffline ?? true;
    final resolvedRetryConfig =
        retryConfig ?? AsyncOperationConfig.defaultRetryConfig;

    return executeWithRetry(
      operation,
      retryConfig: resolvedRetryConfig,
      errorMessage: errorMessage,
      timeout: timeout,
      checkConnectivity: true,
      queueIfOffline: effectiveQueueIfOffline,
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

class _ConnectivityGuard {
  _ConnectivityGuard({
    required FlyLogger logger,
    required ConnectivityService? connectivityService,
    required OfflineQueue? offlineQueue,
    required FoundationLocalizationProvider localizations,
  })  : _logger = logger,
        _connectivityService = connectivityService,
        _offlineQueue = offlineQueue,
        _localizations = localizations;

  final FlyLogger _logger;
  final ConnectivityService? _connectivityService;
  final OfflineQueue? _offlineQueue;
  final FoundationLocalizationProvider _localizations;

  Future<AppResult<T>?> ensureConnectivity<T>({
    required _ExecuteOptions options,
    required _FailureTranslator failureTranslator,
    Future<void> Function()? queueOperation,
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

    if (queueOperation != null) {
      await queueOperation();
    }

    final queued = queueOperation != null && _offlineQueue != null;

    return failureTranslator.connectivityFailure<T>(queued: queued);
  }
}

class _FailureTranslator {
  _FailureTranslator({
    required FlyLogger logger,
    required FoundationLocalizationProvider localizations,
    required ErrorMessageFormatter errorMessageFormatter,
    required _ExecuteOptions options,
    required _OperationLifecycle lifecycle,
  })  : _logger = logger,
        _localizations = localizations,
        _errorMessageFormatter = errorMessageFormatter,
        _options = options,
        _lifecycle = lifecycle;

  final FlyLogger _logger;
  final FoundationLocalizationProvider _localizations;
  final ErrorMessageFormatter _errorMessageFormatter;
  final _ExecuteOptions _options;
  final _OperationLifecycle _lifecycle;

  Failure<T> connectivityFailure<T>({required bool queued}) {
    final message = _options.userFacingErrorMessage ??
        (queued
            ? _localizations.noInternetConnectionQueuedLong
            : _localizations.networkNoInternet);

    _lifecycle.fail(
      error: message,
      metadata: <String, Object?>{
        'errorType': 'NoInternetError',
        'queued': queued,
      },
    );

    return Failure(
      message,
      NoInternetError(localizations: _localizations),
    );
  }

  Failure<T> timeoutFailure<T>() {
    final duration = _lifecycle.elapsed;
    _logger.error('Operation timed out after ${duration.inSeconds} seconds');

    final message =
        _options.userFacingErrorMessage ?? _localizations.networkTimeout;
    final timeoutError = TimeoutError(
      timeout: _options.timeout,
      localizations: _localizations,
    );

    _lifecycle.fail(
      error: message,
      metadata: <String, Object?>{
        'errorType': 'TimeoutException',
        'timeout': _options.timeout.inMilliseconds,
      },
    );

    return Failure(message, timeoutError);
  }

  Failure<T> socketFailure<T>({
    required SocketException socketException,
    required StackTrace stackTrace,
  }) {
    _logger.error(
      'Socket exception: ${socketException.message}',
      stackTrace: stackTrace,
    );

    final classifiedError = NetworkErrorClassifier.classifyError(
      socketException,
      localizations: _localizations,
    );
    final message = _options.userFacingErrorMessage ??
        (classifiedError is AppException
            ? classifiedError.message
            : socketException.message);

    _lifecycle.fail(
      error: message,
      metadata: <String, Object?>{
        'errorType': 'SocketException',
        'originalError': socketException.toString(),
      },
    );

    return Failure(message, classifiedError);
  }

  Failure<T> genericFailure<T>({
    required Object error,
    required StackTrace stackTrace,
  }) {
    _logger.error('Operation failed: $error', stackTrace: stackTrace);

    final classifiedError = NetworkErrorClassifier.classifyError(
      error,
      timeout: _options.timeout,
      localizations: _localizations,
    );
    final message = _options.userFacingErrorMessage ??
        _errorMessageFormatter.format(
          error,
          localizations: _localizations,
        );

    _lifecycle.fail(
      error: message,
      metadata: <String, Object?>{
        'errorType': error.runtimeType.toString(),
        'originalError': error.toString(),
      },
    );

    return Failure(message, classifiedError);
  }
}

typedef _EmitEvent = void Function(Event event);

class _OperationLifecycle {
  _OperationLifecycle({
    required this.operationId,
    required this.operationName,
    required _ExecuteOptions options,
    required _EmitEvent emit,
  })  : _options = options,
        _emit = emit,
        _startTime = DateTime.now();

  final String operationId;
  final String operationName;
  final _ExecuteOptions _options;
  final _EmitEvent _emit;
  final DateTime _startTime;

  Duration get elapsed => DateTime.now().difference(_startTime);

  void start() {
    _emit(
      AsyncOperationStartedEvent(
        operationId: operationId,
        operationName: operationName,
        metadata: <String, Object?>{
          'timeout': _options.timeout.inMilliseconds,
          'checkConnectivity': _options.checkConnectivity,
          'queueIfOffline': _options.queueIfOffline,
        },
      ),
    );
  }

  void complete() {
    _emit(
      AsyncOperationCompletedEvent(
        operationId: operationId,
        operationName: operationName,
        success: true,
        duration: elapsed,
        metadata: <String, Object?>{
          'timeout': _options.timeout.inMilliseconds,
        },
      ),
    );
  }

  void fail({
    required String error,
    required Map<String, Object?> metadata,
  }) {
    _emit(
      AsyncOperationFailedEvent(
        operationId: operationId,
        operationName: operationName,
        error: error,
        duration: elapsed,
        metadata: metadata,
      ),
    );
  }
}

