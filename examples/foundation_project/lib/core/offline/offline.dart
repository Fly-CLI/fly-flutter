/// Simplified offline module for foundation project
/// This provides stub implementations for offline queue functionality
/// In production, this would be replaced with a full offline queue implementation

/// Stub class for queued operations
class QueuedOperation<T> {
  final String id;
  final Future<T> Function() operation;
  final String operationType;
  final QueuePriority priority;
  final DateTime expiresAt;
  final int maxRetries;

  const QueuedOperation({
    required this.id,
    required this.operation,
    required this.operationType,
    required this.priority,
    required this.expiresAt,
    required this.maxRetries,
  });
}

/// Priority levels for queued operations
enum QueuePriority {
  low,
  normal,
  high,
}

/// Stub offline queue manager
/// In production, this would manage offline operations
abstract class OfflineQueueManager {
  Future<bool> enqueue<T>(QueuedOperation<T> operation);
  Future<void> processQueue();
  Future<void> clearQueue();
}
