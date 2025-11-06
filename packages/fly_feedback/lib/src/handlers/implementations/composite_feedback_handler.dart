import 'package:flutter/material.dart';
import 'package:fly_feedback/src/events/feedback_event.dart';
import 'package:fly_feedback/src/handlers/fly_feedback_handler.dart';
import 'package:fly_feedback/src/handlers/implementations/snackbar_feedback_handler.dart';
import 'package:fly_feedback/src/types/feedback_types.dart';

/// Composite handler that delegates to multiple handlers
class CompositeFeedbackHandler with FeedbackHandlerMixin implements FlyFeedbackHandler {
  final List<FlyFeedbackHandler> handlers;

  const CompositeFeedbackHandler(this.handlers);

  @override
  bool supports(FeedbackDisplay display) {
    return handlers.any((h) => h.supports(display));
  }

  @override
  void handle(BuildContext context, FeedbackEvent event) {
    try {
      final handler = handlers.firstWhere(
        (h) => h.supports(event.display),
        orElse: () => throw UnsupportedError(
          'No handler found for display type: ${event.display}',
        ),
      );

      handler.handle(context, event);
    } catch (e) {
      debugPrint('❌ Error in composite handler: $e');
      // Fallback to snackbar if available
      try {
        final snackbarHandler = handlers.firstWhere(
          (h) => h is SnackbarFeedbackHandler,
        );
        snackbarHandler.handle(context, event);
      } catch (fallbackError) {
        debugPrint('❌ No fallback handler available: $fallbackError');
        rethrow;
      }
    }
  }
}

