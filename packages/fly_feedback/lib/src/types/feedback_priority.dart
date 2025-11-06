import 'package:fly_feedback/src/events/feedback_event.dart';
import 'package:fly_feedback/src/types/feedback_types.dart';

/// Priority levels for feedback events in queue management
///
/// Higher priority values indicate more important feedback that should
/// be processed first. Priorities are used to sort queue items when
/// multiple feedback events are waiting to be displayed.
enum FeedbackPriority {
  /// Critical priority - highest importance
  ///
  /// Used for:
  /// - ConfirmationFeedback (requires user interaction)
  /// - Critical errors requiring immediate user action
  ///
  /// Value: 5
  critical(5),

  /// High priority - very important
  ///
  /// Used for:
  /// - ErrorFeedback (critical errors)
  /// - Warnings requiring immediate attention
  ///
  /// Value: 4
  high(4),

  /// Normal priority - standard importance
  ///
  /// Used for:
  /// - WarningFeedback (important warnings)
  /// - Important informational messages
  ///
  /// Value: 3
  normal(3),

  /// Low priority - lowest importance
  ///
  /// Used for:
  /// - InfoFeedback (informational messages)
  /// - SuccessFeedback (success notifications)
  ///
  /// Value: 2
  low(2);

  /// Numeric value of the priority (higher = more important)
  final int value;

  const FeedbackPriority(this.value);

  /// Compare two priorities
  ///
  /// Returns:
  /// - Negative if this priority is lower than [other]
  /// - Zero if priorities are equal
  /// - Positive if this priority is higher than [other]
  int compareTo(FeedbackPriority other) {
    return value.compareTo(other.value);
  }

  /// Check if this priority is higher than [other]
  bool isHigherThan(FeedbackPriority other) {
    return value > other.value;
  }

  /// Check if this priority is lower than [other]
  bool isLowerThan(FeedbackPriority other) {
    return value < other.value;
  }
}

/// Extension on FeedbackType to map to priority
extension FeedbackTypePriority on FeedbackType {
  /// Get the default priority for this feedback type
  FeedbackPriority get defaultPriority {
    switch (this) {
      case FeedbackType.error:
        return FeedbackPriority.high;
      case FeedbackType.warning:
        return FeedbackPriority.normal;
      case FeedbackType.info:
        return FeedbackPriority.low;
      case FeedbackType.success:
        return FeedbackPriority.low;
    }
  }
}

/// Extension on FeedbackEvent to calculate priority
extension FeedbackEventPriority on FeedbackEvent {
  /// Calculate the priority for this feedback event
  ///
  /// Priority is determined in the following order:
  /// 1. Custom priority from metadata['priority'] (if FeedbackPriority)
  /// 2. Custom priority from metadata['priority'] (if int, mapped to enum)
  /// 3. ConfirmationFeedback → critical
  /// 4. ErrorFeedback → high
  /// 5. WarningFeedback → normal
  /// 6. InfoFeedback → low
  /// 7. SuccessFeedback → low
  ///
  /// [customMapping] - Optional custom priority mapping by FeedbackType
  ///                   (takes precedence over default mapping)
  FeedbackPriority calculatePriority({
    Map<FeedbackType, FeedbackPriority>? customMapping,
  }) {
    // Check for custom priority in metadata
    final metadataPriority = metadata['priority'];
    if (metadataPriority != null) {
      if (metadataPriority is FeedbackPriority) {
        return metadataPriority;
      }
      if (metadataPriority is int) {
        // Map int to FeedbackPriority
        for (final priority in FeedbackPriority.values) {
          if (priority.value == metadataPriority) {
            return priority;
          }
        }
      }
    }

    // Check custom mapping
    if (customMapping != null && customMapping.containsKey(type)) {
      return customMapping[type]!;
    }

    // Special case: ConfirmationFeedback is always critical
    if (this is ConfirmationFeedback) {
      return FeedbackPriority.critical;
    }

    // Use default priority based on type
    return type.defaultPriority;
  }
}

