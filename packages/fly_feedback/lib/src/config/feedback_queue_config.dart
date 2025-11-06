import 'package:fly_feedback/src/events/feedback_event.dart';
import 'package:fly_feedback/src/types/feedback_priority.dart';
import 'package:fly_feedback/src/types/feedback_types.dart';

/// Configuration for feedback queue management
///
/// This class provides complete configurability for queue behavior,
/// including timing, size limits, feature flags, callbacks, and
/// custom priority mappings.
class FeedbackQueueConfig {
  /// Delay between queue processing attempts
  ///
  /// When a queue item cannot be processed immediately (e.g., another
  /// item is currently being displayed), the queue will wait this
  /// duration before attempting to process the next item.
  ///
  /// Default: 300ms
  final Duration? queueRetryDelay;

  /// Maximum time before removing stale items from queue
  ///
  /// Items that have been in the queue longer than this duration
  /// will be automatically removed as stale.
  ///
  /// Default: 5 seconds
  final Duration? maxQueueWait;

  /// Maximum number of items in queue
  ///
  /// When the queue exceeds this size, lowest priority items will be
  /// removed (FIFO within same priority level).
  ///
  /// Default: 10 items
  final int? maxQueueSize;

  /// Enable priority-based sorting
  ///
  /// When true, queue items are sorted by priority (descending) then
  /// timestamp (ascending) for FIFO within same priority.
  ///
  /// When false, items are processed in FIFO order only.
  ///
  /// Default: true
  final bool? enablePrioritySorting;

  /// Enable duplicate event prevention
  ///
  /// When true, events with the same ID will not be added to the queue
  /// if they already exist in the queue.
  ///
  /// Default: true
  final bool? enableDuplicatePrevention;

  /// Enable automatic stale item removal
  ///
  /// When true, items exceeding [maxQueueWait] will be automatically
  /// removed during queue processing.
  ///
  /// Default: true
  final bool? enableStaleItemRemoval;

  /// Enable context validation
  ///
  /// When true, items with unmounted contexts will be removed from
  /// the queue during processing.
  ///
  /// Default: true
  final bool? enableContextValidation;

  /// Custom priority mapping by FeedbackType
  ///
  /// Overrides default priority calculation for specific feedback types.
  /// If a FeedbackType is not in this map, default priority is used.
  ///
  /// Example:
  /// ```dart
  /// priorityMapping: {
  ///   FeedbackType.error: FeedbackPriority.critical,
  ///   FeedbackType.success: FeedbackPriority.normal,
  /// }
  /// ```
  final Map<FeedbackType, FeedbackPriority>? priorityMapping;

  /// Callback invoked when an item is dropped due to queue size limits
  ///
  /// This callback is called before removing the item from the queue.
  /// Useful for logging or analytics.
  final void Function(FeedbackEvent)? onItemDropped;

  /// Callback invoked when a stale item is removed from queue
  ///
  /// This callback is called before removing the stale item.
  /// Useful for logging or analytics.
  final void Function(FeedbackEvent)? onStaleItemRemoved;

  /// Create a feedback queue configuration
  const FeedbackQueueConfig({
    this.queueRetryDelay,
    this.maxQueueWait,
    this.maxQueueSize,
    this.enablePrioritySorting,
    this.enableDuplicatePrevention,
    this.enableStaleItemRemoval,
    this.enableContextValidation,
    this.priorityMapping,
    this.onItemDropped,
    this.onStaleItemRemoved,
  });

  /// Create default configuration
  ///
  /// Returns a configuration with sensible defaults:
  /// - queueRetryDelay: 300ms
  /// - maxQueueWait: 5 seconds
  /// - maxQueueSize: 10 items
  /// - enablePrioritySorting: true
  /// - enableDuplicatePrevention: true
  /// - enableStaleItemRemoval: true
  /// - enableContextValidation: true
  factory FeedbackQueueConfig.defaults() {
    return const FeedbackQueueConfig(
      queueRetryDelay: Duration(milliseconds: 300),
      maxQueueWait: Duration(seconds: 5),
      maxQueueSize: 10,
      enablePrioritySorting: true,
      enableDuplicatePrevention: true,
      enableStaleItemRemoval: true,
      enableContextValidation: true,
    );
  }

  /// Create a copy with updated values
  FeedbackQueueConfig copyWith({
    Duration? queueRetryDelay,
    Duration? maxQueueWait,
    int? maxQueueSize,
    bool? enablePrioritySorting,
    bool? enableDuplicatePrevention,
    bool? enableStaleItemRemoval,
    bool? enableContextValidation,
    Map<FeedbackType, FeedbackPriority>? priorityMapping,
    void Function(FeedbackEvent)? onItemDropped,
    void Function(FeedbackEvent)? onStaleItemRemoved,
  }) {
    return FeedbackQueueConfig(
      queueRetryDelay: queueRetryDelay ?? this.queueRetryDelay,
      maxQueueWait: maxQueueWait ?? this.maxQueueWait,
      maxQueueSize: maxQueueSize ?? this.maxQueueSize,
      enablePrioritySorting: enablePrioritySorting ?? this.enablePrioritySorting,
      enableDuplicatePrevention:
          enableDuplicatePrevention ?? this.enableDuplicatePrevention,
      enableStaleItemRemoval:
          enableStaleItemRemoval ?? this.enableStaleItemRemoval,
      enableContextValidation:
          enableContextValidation ?? this.enableContextValidation,
      priorityMapping: priorityMapping ?? this.priorityMapping,
      onItemDropped: onItemDropped ?? this.onItemDropped,
      onStaleItemRemoved: onStaleItemRemoved ?? this.onStaleItemRemoved,
    );
  }

  /// Merge with another configuration
  ///
  /// Returns a new configuration with values from [other] taking
  /// precedence over this configuration's values.
  FeedbackQueueConfig merge(FeedbackQueueConfig? other) {
    if (other == null) return this;

    return FeedbackQueueConfig(
      queueRetryDelay: other.queueRetryDelay ?? queueRetryDelay,
      maxQueueWait: other.maxQueueWait ?? maxQueueWait,
      maxQueueSize: other.maxQueueSize ?? maxQueueSize,
      enablePrioritySorting:
          other.enablePrioritySorting ?? enablePrioritySorting,
      enableDuplicatePrevention:
          other.enableDuplicatePrevention ?? enableDuplicatePrevention,
      enableStaleItemRemoval:
          other.enableStaleItemRemoval ?? enableStaleItemRemoval,
      enableContextValidation:
          other.enableContextValidation ?? enableContextValidation,
      priorityMapping: other.priorityMapping != null
          ? {...?priorityMapping, ...other.priorityMapping!}
          : priorityMapping,
      onItemDropped: other.onItemDropped ?? onItemDropped,
      onStaleItemRemoved: other.onStaleItemRemoved ?? onStaleItemRemoved,
    );
  }

  /// Get effective queue retry delay
  Duration get effectiveQueueRetryDelay =>
      queueRetryDelay ?? const Duration(milliseconds: 300);

  /// Get effective max queue wait
  Duration get effectiveMaxQueueWait =>
      maxQueueWait ?? const Duration(seconds: 5);

  /// Get effective max queue size
  int get effectiveMaxQueueSize => maxQueueSize ?? 10;

  /// Get effective enable priority sorting
  bool get effectiveEnablePrioritySorting =>
      enablePrioritySorting ?? true;

  /// Get effective enable duplicate prevention
  bool get effectiveEnableDuplicatePrevention =>
      enableDuplicatePrevention ?? true;

  /// Get effective enable stale item removal
  bool get effectiveEnableStaleItemRemoval =>
      enableStaleItemRemoval ?? true;

  /// Get effective enable context validation
  bool get effectiveEnableContextValidation =>
      enableContextValidation ?? true;
}

