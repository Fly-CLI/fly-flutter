import 'package:flutter/material.dart';
import 'package:fly_feedback/src/events/feedback_event.dart';
import 'package:fly_feedback/src/types/feedback_priority.dart';

/// A queued feedback item waiting to be processed
///
/// This class represents a feedback event that has been added to a queue
/// and is waiting to be displayed. It contains all necessary information
/// for queue management, including priority, timestamp, and context.
class QueuedFeedbackItem {
  /// The feedback event to display
  final FeedbackEvent event;

  /// The build context for displaying the feedback
  ///
  /// This context may become unmounted while the item is in the queue.
  /// The queue manager should validate this before processing.
  final BuildContext context;

  /// When this item was added to the queue
  final DateTime timestamp;

  /// The calculated priority for this item
  final FeedbackPriority priority;

  /// Unique identifier for this queue item
  ///
  /// This is the same as [event.id] for easy lookup and duplicate detection.
  final String id;

  /// Create a queued feedback item
  QueuedFeedbackItem({
    required this.event,
    required this.context,
    required this.timestamp,
    required this.priority,
  }) : id = event.id;

  /// Calculate the age of this item in the queue
  ///
  /// Returns the duration since [timestamp].
  Duration get age => DateTime.now().difference(timestamp);

  /// Check if the context is still mounted
  ///
  /// Returns true if the context is valid and mounted, false otherwise.
  bool get isContextValid => context.mounted;

  /// Check if this item is stale based on max wait time
  ///
  /// [maxWait] - Maximum time before an item is considered stale
  bool isStale(Duration maxWait) => age > maxWait;

  /// Compare this item with another by priority and timestamp
  ///
  /// Returns:
  /// - Negative if this item should be processed before [other]
  /// - Zero if items have equal priority and timestamp
  /// - Positive if this item should be processed after [other]
  ///
  /// Comparison order:
  /// 1. Priority (descending - higher priority first)
  /// 2. Timestamp (ascending - older items first within same priority)
  int compareTo(QueuedFeedbackItem other) {
    // First compare by priority (descending)
    final priorityComparison = other.priority.compareTo(priority);
    if (priorityComparison != 0) {
      return priorityComparison;
    }

    // Then compare by timestamp (ascending - FIFO within same priority)
    return timestamp.compareTo(other.timestamp);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QueuedFeedbackItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'QueuedFeedbackItem(id: $id, priority: $priority, age: ${age.inMilliseconds}ms)';
  }
}

