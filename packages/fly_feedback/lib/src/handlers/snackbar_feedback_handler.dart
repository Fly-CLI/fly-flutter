import 'package:flutter/material.dart';
import 'package:fly_feedback/src/events/feedback_event.dart';
import 'package:fly_feedback/src/handlers/fly_feedback_handler.dart';
import 'package:fly_feedback/src/types/feedback_types.dart';

/// Snackbar feedback handler
class SnackbarFeedbackHandler with FeedbackHandlerMixin implements FlyFeedbackHandler {
  @override
  bool supports(FeedbackDisplay display) => display == FeedbackDisplay.snackBar;

  @override
  void handle(BuildContext context, FeedbackEvent event) {
    if (!isValidContext(context)) {
      debugPrint('⚠️ Invalid context for snackbar: ${event.message}');
      return;
    }

    try {
      final colors = _getColors(context);
      final (backgroundColor, icon) = _getStyleForType(event.type, colors);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  event.message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: backgroundColor,
          duration: event.duration ?? _getDefaultDuration(event.type),
          behavior: SnackBarBehavior.floating,
          action: _buildAction(event, context),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error showing snackbar: $e');
      _fallbackDisplay(context, event);
    }
  }

  ColorScheme _getColors(BuildContext context) {
    try {
      return Theme.of(context).colorScheme;
    } catch (e) {
      debugPrint('⚠️ Error accessing colors from context: $e');
      return const ColorScheme.light();
    }
  }

  (Color, IconData) _getStyleForType(FeedbackType type, ColorScheme colors) {
    switch (type) {
      case FeedbackType.success:
        return (Colors.green, Icons.check_circle);
      case FeedbackType.error:
        return (colors.error, Icons.error_outline);
      case FeedbackType.warning:
        return (Colors.orange, Icons.warning_amber);
      case FeedbackType.info:
        return (Colors.blue, Icons.info_outline);
    }
  }

  Duration _getDefaultDuration(FeedbackType type) {
    return type == FeedbackType.error
        ? const Duration(seconds: 4)
        : const Duration(seconds: 3);
  }

  SnackBarAction? _buildAction(FeedbackEvent event, BuildContext context) {
    if (event is SuccessFeedback && event.action != null && event.actionLabel != null) {
      return SnackBarAction(
        label: event.actionLabel!,
        textColor: Colors.white,
        onPressed: event.action!,
      );
    }

    if (event is ErrorFeedback && event.retryAction != null && event.retryLabel != null) {
      return SnackBarAction(
        label: event.retryLabel!,
        textColor: Colors.white,
        onPressed: event.retryAction!,
      );
    }

    return null;
  }

  void _fallbackDisplay(BuildContext context, FeedbackEvent event) {
    // Simple fallback - just show text
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(event.message)),
      );
    } catch (e) {
      debugPrint('❌ Fallback display also failed: $e');
    }
  }
}

