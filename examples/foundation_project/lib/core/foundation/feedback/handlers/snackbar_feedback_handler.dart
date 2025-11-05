import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_events.dart';
import 'package:foundation_project/shared/themes/extensions/theme_extensions.dart';
import 'package:foundation_project/core/foundation/feedback/handlers/fly_feedback_handler.dart';
import 'package:foundation_project/core/foundation/feedback/types/feedback_types.dart';

/// Snackbar feedback handler
class SnackbarFeedbackHandler with FeedbackHandlerMixin implements FlyFeedbackHandler {
  @override
  bool supports(FeedbackDisplay display) => display == FeedbackDisplay.snackBar;

  @override
  void handle(BuildContext context, FeedbackEvent event, WidgetRef? ref) {
    if (!isValidContext(context)) {
      debugPrint('⚠️ Invalid context for snackbar: ${event.message}');
      return;
    }

    try {
      final colors = _getColors(ref);
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

  dynamic _getColors(WidgetRef? ref) {
    try {
      return ref?.colors;
    } catch (e) {
      debugPrint('⚠️ Error accessing colors from ref: $e');
      return null;
    }
  }

  (Color, IconData) _getStyleForType(FeedbackType type, dynamic colors) {
    switch (type) {
      case FeedbackType.success:
        return (colors?.success ?? Colors.green, Icons.check_circle);
      case FeedbackType.error:
        return (colors?.error ?? Colors.red, Icons.error_outline);
      case FeedbackType.warning:
        return (colors?.warning ?? Colors.orange, Icons.warning_amber);
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

