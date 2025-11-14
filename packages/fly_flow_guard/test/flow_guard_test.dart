import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fly_connectivity/fly_connectivity.dart';
import 'package:fly_errors/fly_errors.dart';
import 'package:fly_events/fly_events.dart';
import 'package:fly_flow_guard/fly_flow_guard.dart';
import 'package:fly_logger/fly_logger.dart';

void main() {
  group('FlowGuard', () {
    late RecordingOfflineQueue offlineQueue;
    late TestConnectivityChecker connectivityChecker;
    late TestLogger logger;
    late TestFlowGuard handler;

    setUp(() {
      offlineQueue = RecordingOfflineQueue();
      connectivityChecker = TestConnectivityChecker(hasConnection: true);
      logger = TestLogger();

      handler = TestFlowGuard(
        logger: logger,
        connectivityService: ConnectivityService(
          checker: connectivityChecker,
          logger: logger,
        ),
        offlineQueue: offlineQueue,
      );
    });

    test('emits lifecycle events on success', () async {
      final result = await handler.execute<int>(
        () async => 42,
        checkConnectivity: true,
      );

      expect(result, isA<Success<int>>());
      final events = handler.events;
      expect(events.length, 2);
      expect(events.first, isA<AsyncOperationStartedEvent>());
      expect(events.last, isA<AsyncOperationCompletedEvent>());

      final startedEvent = handler.findEvent<AsyncOperationStartedEvent>()!;
      expect(startedEvent.metadata['checkConnectivity'], isTrue);
      expect(startedEvent.metadata['timeout'],
          AsyncOperationConfig.standardTimeout.inMilliseconds);

      final completedEvent = handler.findEvent<AsyncOperationCompletedEvent>()!;
      expect(completedEvent.success, isTrue);
      expect(completedEvent.metadata['timeout'],
          AsyncOperationConfig.standardTimeout.inMilliseconds);
    });

    test('queues operation when offline', () async {
      connectivityChecker.hasConnection = false;

      final result = await handler.execute<int>(
        () async => 1,
        queueIfOffline: true,
        checkConnectivity: true,
      );

      expect(result, isA<Failure<int>>());
      final failure = result as Failure<int>;
      expect(failure.originalError, isA<NoInternetError>());
      expect(offlineQueue.operations.length, 1);

      final failedEvent = handler.findEvent<AsyncOperationFailedEvent>();
      expect(failedEvent, isNotNull);
      expect(failedEvent!.metadata['queued'], isTrue);
      expect(failedEvent.metadata['errorType'], 'NoInternetError');
    });

    test('translates timeout failures via failure translator', () async {
      connectivityChecker.hasConnection = true;

      final result = await handler.execute<int>(
        () async => Future<int>.delayed(
          const Duration(milliseconds: 100),
          () => 1,
        ),
        timeout: const Duration(milliseconds: 10),
        checkConnectivity: true,
      );

      expect(result, isA<Failure<int>>());
      final failure = result as Failure<int>;
      expect(failure.originalError, isA<TimeoutError>());

      final failedEvent = handler.findEvent<AsyncOperationFailedEvent>();
      expect(failedEvent, isNotNull);
      expect(failedEvent!.metadata['errorType'], 'TimeoutException');
      expect(failedEvent.metadata['timeout'], isA<int>());
    });

    test('fails with NoInternetError when offline without queueing', () async {
      connectivityChecker.hasConnection = false;

      final result = await handler.execute<int>(
        () async => 1,
        queueIfOffline: false,
        checkConnectivity: true,
      );

      expect(result, isA<Failure<int>>());
      final failure = result as Failure<int>;
      expect(failure.originalError, isA<NoInternetError>());
      expect(offlineQueue.operations, isEmpty);

      final failedEvent = handler.findEvent<AsyncOperationFailedEvent>()!;
      expect(failedEvent.metadata['queued'], isFalse);
    });

    test('fails with NoInternetError when queue unavailable', () async {
      final handlerWithoutQueue = TestFlowGuard(
        logger: logger,
        connectivityService: ConnectivityService(
          checker: connectivityChecker..hasConnection = false,
          logger: logger,
        ),
      );

      final result = await handlerWithoutQueue.execute<int>(
        () async => 1,
        queueIfOffline: true,
        checkConnectivity: true,
      );

      expect(result, isA<Failure<int>>());
      final failure = result as Failure<int>;
      expect(failure.originalError, isA<NoInternetError>());
      expect(handlerWithoutQueue.events.whereType<AsyncOperationFailedEvent>(),
          isNotEmpty);
    });

    test('skips connectivity check when service not provided', () async {
      final handlerWithoutConnectivity = TestFlowGuard(
        logger: logger,
      );

      final result = await handlerWithoutConnectivity.execute<int>(
        () async => 7,
        checkConnectivity: true,
      );

      expect(result, isA<Success<int>>());
      expect(handlerWithoutConnectivity.events,
          contains(isA<AsyncOperationCompletedEvent>()));
    });

    test('translates socket exceptions via failure translator', () async {
      connectivityChecker.hasConnection = true;

      final result = await handler.execute<int>(
        () async => throw const SocketException('Failed host lookup'),
        checkConnectivity: true,
      );

      expect(result, isA<Failure<int>>());
      final failure = result as Failure<int>;
      expect(failure.originalError, isA<DnsError>());

      final failedEvent = handler.findEvent<AsyncOperationFailedEvent>()!;
      expect(failedEvent.metadata['errorType'], 'SocketException');
      expect(failedEvent.metadata['originalError'], contains('SocketException'));
    });

    test('translates generic failures via failure translator', () async {
      connectivityChecker.hasConnection = true;

      final result = await handler.execute<int>(
        () async => throw StateError('bad state'),
        checkConnectivity: true,
      );

      expect(result, isA<Failure<int>>());
      final failure = result as Failure<int>;
      expect(failure.originalError, isA<UnknownNetworkError>());

      final failedEvent = handler.findEvent<AsyncOperationFailedEvent>()!;
      expect(failedEvent.metadata['errorType'], 'StateError');
      expect('${failedEvent.metadata['originalError']}',
          contains('Bad state'));
    });

    test('executeWithRetry retries until success and checks connectivity once',
        () async {
      connectivityChecker.hasConnection = true;
      var attempts = 0;

      final result = await handler.executeWithRetry<int>(
        () async {
          attempts += 1;
          if (attempts < 3) {
            throw TimeoutException('timeout');
          }
          return 99;
        },
        retryConfig: const RetryConfig(
          maxAttempts: 2,
          baseDelay: Duration.zero,
          maxDelay: Duration.zero,
          backoffMultiplier: 1,
          useJitter: false,
        ),
        checkConnectivity: true,
      );

      expect(result, isA<Success<int>>());
      expect(attempts, 3);
      expect(connectivityChecker.connectionChecks, 1);
    });

    test('executeWithRetry stops when error is not retryable', () async {
      connectivityChecker.hasConnection = false;

      final result = await handler.executeWithRetry<int>(
        () async => 1,
        retryConfig: const RetryConfig(
          maxAttempts: 3,
          baseDelay: Duration.zero,
          maxDelay: Duration.zero,
          backoffMultiplier: 1,
          useJitter: false,
        ),
        checkConnectivity: true,
        queueIfOffline: true,
      );

      expect(result, isA<Failure<int>>());
      final failure = result as Failure<int>;
      expect(failure.originalError, isA<NoInternetError>());
      expect(connectivityChecker.connectionChecks, 1);
      expect(offlineQueue.operations.length, 1);
    });

    test('executeNetworkOperation enables connectivity check and queueing',
        () async {
      final spyHandler = SpyFlowGuard(
        logger: logger,
        connectivityService: ConnectivityService(
          checker: connectivityChecker,
          logger: logger,
        ),
        offlineQueue: offlineQueue,
      );

      final result =
          await spyHandler.executeNetworkOperation<int>(() async => 5);

      expect(result, isA<Success<int>>());
      expect(spyHandler.executeWithRetryCallCount, 1);
      expect(spyHandler.lastCheckConnectivity, isTrue);
      expect(spyHandler.lastQueueIfOffline, isTrue);
    });

    test('runAsyncOperation handles success callbacks correctly', () async {
      final loadingStates = <bool>[];
      final errorStates = <String?>[];
      var notifyCount = 0;
      var finallyCalled = false;

      final result = await handler.runAsyncOperation<int>(
        () async => 123,
        onLoadingChanged: ({required bool isLoading}) {
          loadingStates.add(isLoading);
        },
        onErrorChanged: errorStates.add,
        onNotify: () => notifyCount++,
        onFinally: () => finallyCalled = true,
        checkConnectivity: true,
      );

      expect(result, isA<Success<int>>());
      expect(loadingStates, [true, false]);
      expect(errorStates, [null, null]);
      expect(notifyCount, 2);
      expect(finallyCalled, isTrue);
    });

    test('runAsyncOperation handles failure callbacks correctly', () async {
      final loadingStates = <bool>[];
      final errorStates = <String?>[];
      var notifyCount = 0;
      var finallyCalled = false;

      final result = await handler.runAsyncOperation<int>(
        () async => throw Exception('failure'),
        onLoadingChanged: ({required bool isLoading}) {
          loadingStates.add(isLoading);
        },
        onErrorChanged: errorStates.add,
        onNotify: () => notifyCount++,
        onFinally: () => finallyCalled = true,
        checkConnectivity: true,
      );

      expect(result, isA<Failure<int>>());
      final failure = result as Failure<int>;
      expect(failure.originalError, isA<UnknownNetworkError>());
      expect(loadingStates, [true, false]);
      expect(errorStates.length, 2);
      expect(errorStates.first, isNull);
      expect(errorStates.last, isNotNull);
      expect(errorStates.last, failure.error);
      expect(notifyCount, 2);
      expect(finallyCalled, isTrue);
    });

    test('executeWithProgress returns failure and toggles progress on error',
        () async {
      final loadingStates = <bool>[];

      final result = await handler.executeWithProgress<int>(
        () async => throw const FormatException('invalid format'),
        ({bool isLoading = false}) => loadingStates.add(isLoading),
      );

      expect(result, isA<Failure<int>>());
      final failure = result as Failure<int>;
      expect(failure.originalError, isA<HttpError>());
      expect(loadingStates, [true, false]);
    });
  });
}

class TestFlowGuard extends FlowGuard {
  TestFlowGuard({
    required FlyLogger logger,
    ConnectivityService? connectivityService,
    OfflineQueue? offlineQueue,
  })  : _events = <Event>[],
        super(
          logger: logger,
          connectivityService: connectivityService,
          offlineQueue: offlineQueue,
        );

  final List<Event> _events;

  @override
  bool emit(Event event) {
    _events.add(event);
    return true;
  }

  List<Event> get events => List<Event>.unmodifiable(_events);

  T? findEvent<T extends Event>() {
    for (final event in _events) {
      if (event is T) {
        return event;
      }
    }
    return null;
  }
}

class RecordingOfflineQueue implements OfflineQueue {
  RecordingOfflineQueue() : operations = <QueuedOperation<dynamic>>[];

  final List<QueuedOperation<dynamic>> operations;

  @override
  Future<bool> enqueue<T>(QueuedOperation<T> operation) async {
    operations.add(operation);
    return true;
  }

  @override
  Future<void> processQueue() async {}

  @override
  Stream<QueuedOperation<dynamic>> get queueStream =>
      Stream<QueuedOperation<dynamic>>.empty();
}

class TestConnectivityChecker implements ConnectivityChecker {
  TestConnectivityChecker({required this.hasConnection});

  bool hasConnection;
  int connectionChecks = 0;

  @override
  Future<bool> hasInternetConnection() async {
    connectionChecks += 1;
    return hasConnection;
  }

  @override
  Future<ConnectivityType> getConnectivityStatus() async =>
      hasConnection ? ConnectivityType.wifi : ConnectivityType.none;

  @override
  Future<bool> isConnectedToWifi() async => hasConnection;

  @override
  Stream<List<ConnectivityType>> get onConnectivityChanged =>
      Stream<List<ConnectivityType>>.empty();
}

class TestLogger implements FlyLogger {
  @override
  String get name => 'test';

  @override
  FlyLogger child(LogFields fields) => this;

  @override
  FlyLogger withFields(LogFields fields) => this;

  @override
  void log(
    LogLevel level,
    Object message, {
    Object? error,
    StackTrace? stackTrace,
    LogFields? fields,
  }) {}

  @override
  bool isEnabled(LogLevel level) => true;

  @override
  void trace(
    Object message, {
    Object? error,
    StackTrace? stackTrace,
    LogFields? fields,
  }) {}

  @override
  void debug(
    Object message, {
    Object? error,
    StackTrace? stackTrace,
    LogFields? fields,
  }) {}

  @override
  void info(
    Object message, {
    Object? error,
    StackTrace? stackTrace,
    LogFields? fields,
  }) {}

  @override
  void warn(
    Object message, {
    Object? error,
    StackTrace? stackTrace,
    LogFields? fields,
  }) {}

  @override
  void error(
    Object message, {
    Object? error,
    StackTrace? stackTrace,
    LogFields? fields,
  }) {}

  @override
  void fatal(
    Object message, {
    Object? error,
    StackTrace? stackTrace,
    LogFields? fields,
  }) {}
}


class SpyFlowGuard extends TestFlowGuard {
  SpyFlowGuard({
    required super.logger,
    ConnectivityService? connectivityService,
    OfflineQueue? offlineQueue,
  }) : super(
          connectivityService: connectivityService,
          offlineQueue: offlineQueue,
        );

  int executeWithRetryCallCount = 0;
  bool? lastCheckConnectivity;
  bool? lastQueueIfOffline;
  RetryConfig? lastRetryConfig;

  @override
  Future<AppResult<T>> executeWithRetry<T>(
    Future<T> Function() operation, {
    RetryConfig? retryConfig,
    String? errorMessage,
    Duration? timeout,
    bool? checkConnectivity,
    bool? queueIfOffline,
  }) async {
    executeWithRetryCallCount += 1;
    lastCheckConnectivity = checkConnectivity;
    lastQueueIfOffline = queueIfOffline;
    lastRetryConfig = retryConfig;

    try {
      final value = await operation();
      return Success<T>(value);
    } catch (error, stackTrace) {
      return Future<AppResult<T>>.error(error, stackTrace);
    }
  }
}

