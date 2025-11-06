import 'package:flutter/material.dart';
import 'package:fly_feedback/src/config/semantics_builder.dart';
import 'package:fly_feedback/src/config/snackbar_feedback_handler_config.dart';
import 'package:fly_feedback/src/events/feedback_event.dart';
import 'package:fly_feedback/src/handlers/fly_feedback_handler.dart';
import 'package:fly_feedback/src/types/feedback_types.dart';

/// Snackbar feedback handler
///
/// Displays feedback events as a SnackBar at the bottom of the screen.
///
/// **Queue Management**: This handler does not use FeedbackQueue because:
/// - Flutter's ScaffoldMessenger automatically handles queue management for SnackBar
/// - Multiple snackbars are automatically queued and shown one at a time
/// - The framework provides built-in queue management, so no custom queue is needed
class SnackbarFeedbackHandler with FeedbackHandlerMixin implements FlyFeedbackHandler {
  /// Configuration for this handler
  final SnackbarFeedbackHandlerConfig config;

  /// Create a snackbar feedback handler with optional configuration
  ///
  /// If [config] is not provided, uses default configuration matching
  /// the original behavior.
  SnackbarFeedbackHandler({
    SnackbarFeedbackHandlerConfig? config,
  }) : config = config ?? SnackbarFeedbackHandlerConfig.defaults();

  @override
  bool supports(FeedbackDisplay display) => display == FeedbackDisplay.snackBar;

  @override
  void handle(BuildContext context, FeedbackEvent event) {
    if (!isValidContext(context)) {
      debugPrint('⚠️ Invalid context for snackbar: ${event.message}');
      return;
    }

    // Defer showing snackbar until after the current build phase completes
    // This prevents "setState() called during build" errors
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isValidContext(context)) {
        debugPrint('⚠️ Context invalidated before showing snackbar: ${event.message}');
        return;
      }

      try {
        final colors = _getColors(context);
        final backgroundColor = config.getBackgroundColor(event.type, colors) ?? 
            colors.surfaceContainer;
        final icon = config.getIcon(event.type) ?? Icons.info_outline;
        final iconColor = config.getIconColor(event.type, colors) ?? 
            colors.onSurface;
        final textColor = config.getTextColor(event.type, colors) ?? 
            colors.onSurface;
        final iconSize = config.iconSize ?? 20.0;
        final duration = event.duration ?? 
            config.getDefaultDuration(event.type) ?? 
            const Duration(seconds: 3);
        final behavior = config.behavior ?? SnackBarBehavior.floating;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SemanticsBuilder.buildSemantics(
              child: Row(
                children: [
                  Icon(icon, color: iconColor, size: iconSize),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      event.message,
                      style: TextStyle(color: textColor),
                    ),
                  ),
                ],
              ),
              event: event,
              config: config.semanticsConfig,
              context: context,
            ),
            backgroundColor: backgroundColor,
            duration: duration,
            behavior: behavior,
            action: _buildAction(event, context, iconColor),
          ),
        );
      } catch (e) {
        debugPrint('❌ Error showing snackbar: $e');
        _fallbackDisplay(context, event);
      }
    });
  }

  ColorScheme _getColors(BuildContext context) {
    try {
      return Theme.of(context).colorScheme;
    } catch (e) {
      debugPrint('⚠️ Error accessing colors from context: $e');
      return const ColorScheme.light();
    }
  }

  SnackBarAction? _buildAction(FeedbackEvent event, BuildContext context, Color textColor) {
    if (event is SuccessFeedback && event.action != null && event.actionLabel != null) {
      return SnackBarAction(
        label: event.actionLabel!,
        textColor: textColor,
        onPressed: event.action!,
      );
    }

    if (event is ErrorFeedback && event.retryAction != null && event.retryLabel != null) {
      return SnackBarAction(
        label: event.retryLabel!,
        textColor: textColor,
        onPressed: event.retryAction!,
      );
    }

    return null;
  }

  void _fallbackDisplay(BuildContext context, FeedbackEvent event) {
    // Simple fallback - just show text
    // Defer showing snackbar until after the current build phase completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isValidContext(context)) {
        return;
      }
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(event.message)),
        );
      } catch (e) {
        debugPrint('❌ Fallback display also failed: $e');
      }
    });
  }
}

