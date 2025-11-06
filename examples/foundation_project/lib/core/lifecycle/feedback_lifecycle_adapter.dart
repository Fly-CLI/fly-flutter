import 'package:fly_feedback/fly_feedback.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_events.dart';

/// Adapter to make FeedbackEvent from fly_feedback package work with LifecycleEvent
/// This provides backward compatibility for the lifecycle system
///
/// This adapter allows FeedbackEvent from fly_feedback to be used with
/// the lifecycle emitter system while maintaining the standalone nature
/// of the fly_feedback package.
extension FeedbackEventLifecycleAdapter on FeedbackEvent {
  /// Convert FeedbackEvent to LifecycleEvent for lifecycle integration
  /// Returns a wrapper that extends LifecycleEvent
  LifecycleEvent toLifecycleEvent() {
    // FeedbackEventWrapper is defined in lifecycle_events.dart
    // because LifecycleEvent is sealed and can only be extended within that library
    return FeedbackEventWrapper(this);
  }
}

/// Extension to convert LifecycleEvent back to FeedbackEvent if it's a wrapper
extension LifecycleEventFeedbackAdapter on LifecycleEvent {
  /// Convert LifecycleEvent to FeedbackEvent if it's a feedback event wrapper
  FeedbackEvent? toFeedbackEvent() {
    if (this is FeedbackEventWrapper) {
      return (this as FeedbackEventWrapper).feedbackEvent;
    }
    return null;
  }
}

