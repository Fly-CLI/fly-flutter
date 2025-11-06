import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fly_feedback/src/config/feedback_queue_config.dart';
import 'package:fly_feedback/src/events/feedback_event.dart';
import 'package:fly_feedback/src/queue/queued_feedback_item.dart';
import 'package:fly_feedback/src/types/feedback_priority.dart';

/// Reusable queue manager for feedback events
///
/// This class provides a single source of truth for queue management
/// that can be used by any feedback handler requiring queue functionality.
///
/// Features:
/// - Priority-based sorting
/// - Duplicate prevention
/// - Stale item removal
/// - Context validation
/// - Size limits
/// - Event callbacks
///
/// Example usage:
/// ```dart
/// final queue = FeedbackQueue(
///   config: FeedbackQueueConfig.defaults(),
/// );
///
/// // Add items to queue
/// queue.add(context, event);
///
/// // Process queue
/// queue.process(
///   (context, event) => showDialog(context: context, ...),
///   isProcessing: _isShowingDialog,
/// );
/// ```
class FeedbackQueue {
  /// Configuration for queue behavior
  final FeedbackQueueConfig config;

  /// Internal queue storage
  final List<QueuedFeedbackItem> _items = [];

  /// Timer for delayed queue processing
  Timer? _processTimer;

  /// Create a feedback queue with configuration
  FeedbackQueue({
    FeedbackQueueConfig? config,
  }) : config = config ?? FeedbackQueueConfig.defaults();

  /// Check if the queue is empty
  bool get isEmpty => _items.isEmpty;

  /// Get the number of items in the queue
  int get length => _items.length;

  /// Add an item to the queue
  ///
  /// [context] - Build context for displaying the feedback
  /// [event] - Feedback event to queue
  ///
  /// Returns true if the item was added, false if it was rejected
  /// (e.g., duplicate prevention).
  bool add(BuildContext context, FeedbackEvent event) {
    try {
      // Check for duplicates if enabled
      if (config.effectiveEnableDuplicatePrevention) {
        if (_checkDuplicates(event)) {
          debugPrint(
            '⚠️ Duplicate event prevented: ${event.message} (id: ${event.id})',
          );
          return false;
        }
      }

      // Calculate priority
      final priority = event.calculatePriority(
        customMapping: config.priorityMapping,
      );

      // Create queue item
      final item = QueuedFeedbackItem(
        event: event,
        context: context,
        timestamp: DateTime.now(),
        priority: priority,
      );

      // Add to queue
      _items.add(item);

      // Sort queue if priority sorting is enabled
      if (config.effectiveEnablePrioritySorting) {
        _sortQueue();
      }

      // Enforce size limits
      _enforceSizeLimit();

      debugPrint(
        '✅ Added to queue: ${event.message} (priority: $priority, queue size: ${_items.length})',
      );

      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Error adding item to queue: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Process the queue
  ///
  /// [processor] - Function to process each item (context, event) -> void
  /// [isProcessing] - Function that returns true if currently processing
  ///
  /// This method will:
  /// 1. Remove stale items if enabled
  /// 2. Remove items with invalid contexts if enabled
  /// 3. Process the highest priority item if not currently processing
  /// 4. Schedule next processing attempt if needed
  void process(
    void Function(BuildContext context, FeedbackEvent event) processor,
    bool Function() isProcessing,
  ) {
    try {
      // Early return if queue is empty or currently processing
      if (_items.isEmpty || isProcessing()) {
        return;
      }

      // Remove stale items if enabled
      if (config.effectiveEnableStaleItemRemoval) {
        _removeStaleItems();
      }

      // Remove items with invalid contexts if enabled
      if (config.effectiveEnableContextValidation) {
        _removeInvalidContexts();
      }

      // Early return if queue is now empty
      if (_items.isEmpty) {
        return;
      }

      // Get the next item to process (highest priority, oldest if same priority)
      final item = _items.first;

      // Validate context before processing
      if (config.effectiveEnableContextValidation) {
        if (!item.isContextValid) {
          debugPrint(
            '⚠️ Removing item with invalid context: ${item.event.message}',
          );
          _items.removeAt(0);
          // Recursively process next item
          process(processor, isProcessing);
          return;
        }
      }

      // Process the item
      try {
        processor(item.context, item.event);
        _items.removeAt(0);
        debugPrint(
          '✅ Processed queue item: ${item.event.message} (remaining: ${_items.length})',
        );
      } catch (e, stackTrace) {
        debugPrint('❌ Error processing queue item: $e');
        debugPrint('Stack trace: $stackTrace');
        // Remove the item that failed to process
        _items.removeAt(0);
        // Continue processing next item
        process(processor, isProcessing);
        return;
      }

      // Schedule next processing attempt if queue is not empty
      if (_items.isNotEmpty) {
        _scheduleNextProcessing(processor, isProcessing);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error in queue processing: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Clear all items from the queue
  void clear() {
    _items.clear();
    _processTimer?.cancel();
    _processTimer = null;
    debugPrint('🧹 Cleared feedback queue');
  }

  /// Manually remove stale items from the queue
  ///
  /// Returns the number of items removed.
  int removeStaleItems() {
    return _removeStaleItems();
  }

  /// Sort queue by priority and timestamp
  void _sortQueue() {
    _items.sort((a, b) => a.compareTo(b));
  }

  /// Remove stale items from the queue
  ///
  /// Returns the number of items removed.
  int _removeStaleItems() {
    if (!config.effectiveEnableStaleItemRemoval) {
      return 0;
    }

    final maxWait = config.effectiveMaxQueueWait;
    final removed = <QueuedFeedbackItem>[];

    for (final item in _items) {
      if (item.isStale(maxWait)) {
        removed.add(item);
        config.onStaleItemRemoved?.call(item.event);
        debugPrint(
          '⚠️ Removing stale item from queue: ${item.event.message} (age: ${item.age.inSeconds}s)',
        );
      }
    }

    _items.removeWhere((item) => removed.contains(item));
    return removed.length;
  }

  /// Remove items with invalid contexts
  void _removeInvalidContexts() {
    if (!config.effectiveEnableContextValidation) {
      return;
    }

    final removed = <QueuedFeedbackItem>[];

    for (final item in _items) {
      if (!item.isContextValid) {
        removed.add(item);
        debugPrint(
          '⚠️ Removing item with invalid context: ${item.event.message}',
        );
      }
    }

    _items.removeWhere((item) => removed.contains(item));
  }

  /// Check for duplicate events
  bool _checkDuplicates(FeedbackEvent event) {
    return _items.any((item) => item.id == event.id);
  }

  /// Enforce queue size limits
  void _enforceSizeLimit() {
    final maxSize = config.effectiveMaxQueueSize;
    if (_items.length <= maxSize) {
      return;
    }

    // Remove lowest priority items (FIFO within same priority)
    final toRemove = _items.length - maxSize;
    final removed = <QueuedFeedbackItem>[];

    // Sort by priority (ascending) then timestamp (descending) to get lowest priority items first
    final sorted = List<QueuedFeedbackItem>.from(_items);
    sorted.sort((a, b) {
      // First by priority (ascending - lower priority first)
      final priorityComparison = a.priority.compareTo(b.priority);
      if (priorityComparison != 0) {
        return priorityComparison;
      }
      // Then by timestamp (descending - newer items first within same priority)
      return b.timestamp.compareTo(a.timestamp);
    });

    // Remove the lowest priority items
    for (int i = 0; i < toRemove; i++) {
      final item = sorted[i];
      removed.add(item);
      config.onItemDropped?.call(item.event);
      debugPrint(
        '⚠️ Dropped item from queue (size limit): ${item.event.message} (priority: ${item.priority})',
      );
    }

    _items.removeWhere((item) => removed.contains(item));
  }

  /// Schedule next processing attempt
  void _scheduleNextProcessing(
    void Function(BuildContext context, FeedbackEvent event) processor,
    bool Function() isProcessing,
  ) {
    _processTimer?.cancel();
    _processTimer = Timer(
      config.effectiveQueueRetryDelay,
      () {
        process(processor, isProcessing);
      },
    );
  }

  /// Dispose resources
  void dispose() {
    _processTimer?.cancel();
    _processTimer = null;
    _items.clear();
  }
}

