import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fly_connectivity/fly_connectivity.dart';
import 'package:fly_errors/fly_errors.dart';
import 'package:fly_events/fly_events.dart';
import 'package:fly_logger/fly_logger.dart';
import 'package:fly_operations/src/async_operation_handler.dart';
import 'package:fly_operations/src/offline_queue.dart';
import 'package:fly_operations/src/result.dart';

void main() {
  group('AsyncOperationHandler', () {
    late RecordingOfflineQueue offlineQueue;
    late TestConnectivityChecker connectivityChecker;
    late TestLogger logger;
    late TestAsyncOperationHandler handler;

    setUp(() {
      offlineQueue = RecordingOfflineQueue();
      connectivityChecker = TestConnectivityChecker(hasConnection: true);
      logger = TestLogger();

      handler = TestAsyncOperationHandler(
        logger: logger,
        connectivityService: ConnectivityService(
          checker: connectivityChecker,
          logger: logger,
        ),
        offlineQueue: offlineQueue,
      );
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
  });
}

class TestAsyncOperationHandler extends AsyncOperationHandler {
  TestAsyncOperationHandler({
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

  @override
  Future<bool> hasInternetConnection() async => hasConnection;

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

