import 'package:flutter_test/flutter_test.dart';
import 'package:fly_operations/fly_operations.dart';
import '../test_helpers/mocks.dart';

void main() {
  group('QueuePriority', () {
    test('should have all priority levels', () {
      expect(QueuePriority.values.length, equals(4));
      expect(QueuePriority.values, contains(QueuePriority.low));
      expect(QueuePriority.values, contains(QueuePriority.normal));
      expect(QueuePriority.values, contains(QueuePriority.high));
      expect(QueuePriority.values, contains(QueuePriority.critical));
    });
  });

  group('QueuedOperation', () {
    test('should create operation with required fields', () {
      final operation = QueuedOperation<String>(
        id: 'test-id',
        operation: () async => 'result',
        operationType: 'test',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(operation.id, equals('test-id'));
      expect(operation.operationType, equals('test'));
      expect(operation.priority, equals(QueuePriority.normal));
      expect(operation.maxRetries, equals(3));
    });

    test('should create operation with custom priority', () {
      final operation = QueuedOperation<String>(
        id: 'test-id',
        operation: () async => 'result',
        operationType: 'test',
        priority: QueuePriority.high,
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(operation.priority, equals(QueuePriority.high));
    });

    test('should create operation with custom maxRetries', () {
      final operation = QueuedOperation<String>(
        id: 'test-id',
        operation: () async => 'result',
        operationType: 'test',
        maxRetries: 5,
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(operation.maxRetries, equals(5));
    });

    test('should execute operation', () async {
      final operation = QueuedOperation<String>(
        id: 'test-id',
        operation: () async => 'result',
        operationType: 'test',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      final result = await operation.operation();
      expect(result, equals('result'));
    });
  });

  group('MockOfflineQueue', () {
    test('should enqueue operations', () async {
      final queue = MockOfflineQueue();
      final operation = QueuedOperation<String>(
        id: 'test-id',
        operation: () async => 'result',
        operationType: 'test',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

      final result = await queue.enqueue(operation);
      expect(result, isTrue);
      expect(queue.operations.length, equals(1));
      expect(queue.operations.first.id, equals('test-id'));
    });

    test('should return false when shouldSucceed is false', () async {
      final queue = MockOfflineQueue();
      queue.setShouldSucceed(false);
      final operation = QueuedOperation<String>(
        id: 'test-id',
        operation: () async => 'result',
        operationType: 'test',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

      final result = await queue.enqueue(operation);
      expect(result, isFalse);
    });

    test('should process queue', () async {
      final queue = MockOfflineQueue();
      await queue.processQueue();
      // Should not throw
      expect(queue, isNotNull);
    });

    test('should provide queue stream', () async {
      final queue = MockOfflineQueue();
      final operation = QueuedOperation<String>(
        id: 'test-id',
        operation: () async => 'result',
        operationType: 'test',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

      await queue.enqueue(operation);
      final stream = queue.queueStream;
      expect(stream, isNotNull);
    });

    test('should clear operations', () {
      final queue = MockOfflineQueue();
      final operation = QueuedOperation<String>(
        id: 'test-id',
        operation: () async => 'result',
        operationType: 'test',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

      queue.enqueue(operation);
      expect(queue.operations.length, equals(1));

      queue.clear();
      expect(queue.operations.length, equals(0));
    });
  });
}

