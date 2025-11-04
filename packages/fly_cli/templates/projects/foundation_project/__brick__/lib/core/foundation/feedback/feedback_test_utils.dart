import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:{{project_name_snake}}/core/foundation/feedback/feedback_event.dart';
import 'package:{{project_name_snake}}/core/foundation/feedback/feedback_handler.dart';

/// Mock feedback handler for testing
/// Records all handled events for verification
class MockFeedbackHandler with FeedbackHandlerMixin implements FeedbackHandler {
  final List<FeedbackEvent> handledEvents = [];

  @override
  bool supports(FeedbackDisplay display) => true;

  @override
  void handle(BuildContext context, FeedbackEvent event, WidgetRef? ref) {
    handledEvents.add(event);
  }

  void clear() {
    handledEvents.clear();
  }

  /// Check if a specific feedback type was handled
  bool hasHandledType(FeedbackType type) {
    return handledEvents.any((e) => e.type == type);
  }

  /// Get all events of a specific type
  List<FeedbackEvent> getEventsOfType(FeedbackType type) {
    return handledEvents.where((e) => e.type == type).toList();
  }

  /// Get the last handled event
  FeedbackEvent? get lastEvent =>
      handledEvents.isEmpty ? null : handledEvents.last;
}

/// No-op feedback handler for when feedback should be silent
class SilentFeedbackHandler with FeedbackHandlerMixin implements FeedbackHandler {
  @override
  bool supports(FeedbackDisplay display) => true;

  @override
  void handle(BuildContext context, FeedbackEvent event, WidgetRef? ref) {
    // Do nothing - silent feedback
  }
}

