import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_events.dart';
import 'package:foundation_project/shared/themes/extensions/theme_extensions.dart';
import 'package:foundation_project/core/foundation/feedback/handlers/fly_feedback_handler.dart';
import 'package:foundation_project/core/foundation/feedback/types/feedback_types.dart';

/// Banner feedback handler
///
/// Displays feedback events as a MaterialBanner at the top of the screen.
/// Banners are persistent until dismissed by the user or programmatically.
class BannerFeedbackHandler with FeedbackHandlerMixin implements FlyFeedbackHandler {
  @override
  bool supports(FeedbackDisplay display) => display == FeedbackDisplay.banner;

  @override
  void handle(BuildContext context, FeedbackEvent event, WidgetRef? ref) {
    if (!isValidContext(context)) {
      debugPrint('⚠️ Invalid context for banner: ${event.message}');
      return;
    }

    try {
      final colors = _getColors(ref);
      final (backgroundColor, icon) = _getStyleForType(event.type, colors);

      ScaffoldMessenger.of(context).showMaterialBanner(
        MaterialBanner(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
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
          leadingPadding: const EdgeInsets.only(left: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: _buildActions(event, context),
        ),
      );

      // Auto-dismiss after duration if specified
      if (event.duration != null) {
        Future.delayed(event.duration!, () {
          if (context.mounted) {
            ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Error showing banner: $e');
      _fallbackDisplay(context, event);
    }
  }

  List<Widget> _buildActions(FeedbackEvent event, BuildContext context) {
    final actions = <Widget>[];

    // Add action button for success feedback
    if (event is SuccessFeedback && event.action != null && event.actionLabel != null) {
      actions.add(
        TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
            event.action?.call();
          },
          child: Text(
            event.actionLabel!,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    // Add retry button for error feedback
    if (event is ErrorFeedback && event.retryAction != null && event.retryLabel != null) {
      actions.add(
        TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
            event.retryAction?.call();
          },
          child: Text(
            event.retryLabel!,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    // Always add close button
    actions.add(
      IconButton(
        icon: const Icon(Icons.close, color: Colors.white, size: 20),
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
        },
      ),
    );

    return actions;
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

  void _fallbackDisplay(BuildContext context, FeedbackEvent event) {
    // Simple fallback - use snackbar
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(event.message)),
      );
    } catch (e) {
      debugPrint('❌ Fallback display also failed: $e');
    }
  }
}

