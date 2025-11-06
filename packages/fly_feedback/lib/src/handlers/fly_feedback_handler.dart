import 'package:flutter/material.dart';
import 'package:fly_feedback/src/types/feedback_types.dart';
import 'package:fly_feedback/src/events/feedback_event.dart';

/// Abstract feedback handler
/// Implement this to create custom feedback displays
abstract class FlyFeedbackHandler {
  /// Check if this handler supports the given display type
  bool supports(FeedbackDisplay display);

  /// Handle a feedback event
  ///
  /// [context] - Valid BuildContext (caller must ensure context is valid)
  /// [event] - Feedback event to display
  void handle(BuildContext context, FeedbackEvent event);
}

/// Base mixin for feedback handlers with common utilities
mixin FeedbackHandlerMixin {
  /// Check if context is valid for display
  @protected
  bool isValidContext(BuildContext context) {
    return context.mounted;
  }
}

