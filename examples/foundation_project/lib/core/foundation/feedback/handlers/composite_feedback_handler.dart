import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation_project/core/foundation/feedback/types/feedback_types.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_events.dart';
import 'package:foundation_project/core/foundation/feedback/handlers/fly_feedback_handler.dart';
import 'package:foundation_project/core/foundation/feedback/handlers/snackbar_feedback_handler.dart';

/// Composite handler that delegates to multiple handlers
class CompositeFeedbackHandler with FeedbackHandlerMixin implements FlyFeedbackHandler {
  final List<FlyFeedbackHandler> handlers;

  const CompositeFeedbackHandler(this.handlers);

  @override
  bool supports(FeedbackDisplay display) {
    return handlers.any((h) => h.supports(display));
  }

  @override
  void handle(BuildContext context, FeedbackEvent event, WidgetRef? ref) {
    try {
      final handler = handlers.firstWhere(
        (h) => h.supports(event.display),
        orElse: () => throw UnsupportedError(
          'No handler found for display type: ${event.display}',
        ),
      );

      handler.handle(context, event, ref);
    } catch (e) {
      debugPrint('❌ Error in composite handler: $e');
      // Fallback to snackbar if available
      try {
        final snackbarHandler = handlers.firstWhere(
          (h) => h is SnackbarFeedbackHandler,
        );
        snackbarHandler.handle(context, event, ref);
      } catch (fallbackError) {
        debugPrint('❌ No fallback handler available: $fallbackError');
        rethrow;
      }
    }
  }
}

