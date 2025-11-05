import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation_project/core/foundation/feedback/types/feedback_types.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_events.dart';


/// Abstract feedback handler
/// Implement this to create custom feedback displays
abstract class FlyFeedbackHandler {

  /// Check if this handler supports the given display type
  bool supports(FeedbackDisplay display);

  /// Handle a feedback event
  ///
  /// [context] - Valid BuildContext (caller must ensure context is valid)
  /// [event] - Feedback event to display
  /// [ref] - Optional WidgetRef for theme access (may be null)
  void handle(BuildContext context, FeedbackEvent event, WidgetRef? ref);
}

/// Base mixin for feedback handlers with common utilities
mixin FeedbackHandlerMixin {
  /// Check if context is valid for display
  @protected
  bool isValidContext(BuildContext context) {
    return context.mounted;
  }
}

