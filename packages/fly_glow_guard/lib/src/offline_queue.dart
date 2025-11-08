/// Priority levels for queued operations.
enum QueuePriority {
  /// Low priority - operations that can be deferred
  low,

  /// Normal priority - standard operations
  normal,

  /// High priority - important operations that should be processed soon
  high,

  /// Critical priority - operations that must be processed as soon as possible
  critical,
}

/// Represents a queued operation that can be executed later.
/// 
/// This class encapsulates an operation along with its metadata for
/// offline queue processing.
class QueuedOperation<T> {
  /// Unique identifier for this operation
  final String id;

  /// The operation to execute
  final Future<T> Function() operation;

  /// Type/category of the operation (e.g., 'create', 'update', 'delete')
  final String operationType;

  /// Priority level for this operation
  final QueuePriority priority;

  /// When this operation expires (operations older than this will be removed)
  final DateTime expiresAt;

  /// Maximum number of retry attempts
  final int maxRetries;

  /// Creates a [QueuedOperation] instance.
  /// 
  /// [id] - Unique identifier for this operation
  /// [operation] - The async operation to execute
  /// [operationType] - Type/category of the operation
  /// [priority] - Priority level (defaults to [QueuePriority.normal])
  /// [expiresAt] - Expiration time for this operation
  /// [maxRetries] - Maximum retry attempts (defaults to 3)
  const QueuedOperation({
    required this.id,
    required this.operation,
    required this.operationType,
    required this.expiresAt,
    this.priority = QueuePriority.normal,
    this.maxRetries = 3,
  });
}

/// Abstract interface for offline queue management.
/// 
/// This interface allows the foundation to queue operations for later execution
/// without creating hard dependencies on specific implementations.
/// 
/// Applications should implement this interface to integrate their preferred
/// offline queue system.
/// 
/// **Example:**
/// ```dart
/// class AppOfflineQueue implements OfflineQueue {
///   @override
///   Future<bool> enqueue<T>(QueuedOperation<T> operation) async {
///     // Implementation
///   }
///   
///   // Implement other methods...
/// }
/// ```
abstract class OfflineQueue {
  /// Enqueues an operation for later execution.
  /// 
  /// [operation] - The operation to queue
  /// 
  /// Returns `true` if the operation was successfully queued, `false` otherwise.
  Future<bool> enqueue<T>(QueuedOperation<T> operation);

  /// Processes all queued operations.
  /// 
  /// This method should attempt to execute all queued operations in order
  /// of priority, removing successful operations and retrying failed ones
  /// according to their retry configuration.
  Future<void> processQueue();

  /// Stream of queued operations.
  /// 
  /// Emits operations as they are added to the queue.
  /// Useful for monitoring queue activity.
  Stream<QueuedOperation<dynamic>> get queueStream;
}

