import 'package:flutter/material.dart';
import 'package:fly_feedback/src/config/banner_feedback_handler_config.dart';
import 'package:fly_feedback/src/config/feedback_semantics_config.dart';
import 'package:fly_feedback/src/config/semantics_builder.dart';
import 'package:fly_feedback/src/events/feedback_event.dart';
import 'package:fly_feedback/src/handlers/fly_feedback_handler.dart';
import 'package:fly_feedback/src/types/feedback_types.dart';

/// Banner feedback handler
///
/// Displays feedback events as a MaterialBanner at the top of the screen.
/// Banners are persistent until dismissed by the user or programmatically.
class BannerFeedbackHandler with FeedbackHandlerMixin implements FlyFeedbackHandler {
  /// Configuration for this handler
  final BannerFeedbackHandlerConfig config;

  /// Create a banner feedback handler with optional configuration
  ///
  /// If [config] is not provided, uses default configuration matching
  /// the original behavior.
  BannerFeedbackHandler({
    BannerFeedbackHandlerConfig? config,
  }) : config = config ?? BannerFeedbackHandlerConfig.defaults();

  @override
  bool supports(FeedbackDisplay display) => display == FeedbackDisplay.banner;

  @override
  void handle(BuildContext context, FeedbackEvent event) {
    if (!isValidContext(context)) {
      debugPrint('⚠️ Invalid context for banner: ${event.message}');
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
      final iconSize = config.iconSize ?? 24.0;
      final leadingPadding = config.leadingPadding ?? const EdgeInsets.only(left: 16);
      final padding = config.padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12);

      ScaffoldMessenger.of(context).showMaterialBanner(
        MaterialBanner(
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
          leadingPadding: leadingPadding,
          padding: padding,
          actions: _buildActions(event, context, iconColor),
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

  List<Widget> _buildActions(FeedbackEvent event, BuildContext context, Color iconColor) {
    final actions = <Widget>[];

    // Add action button for success feedback
    if (event is SuccessFeedback && event.action != null && event.actionLabel != null) {
      actions.add(
        SemanticsBuilder.buildActionSemantics(
          child: TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              event.action?.call();
            },
            child: Text(
              event.actionLabel!,
              style: TextStyle(color: iconColor),
            ),
          ),
          actionType: SemanticsActionType.action,
          config: config.semanticsConfig,
          event: event,
        ),
      );
    }

    // Add retry button for error feedback
    if (event is ErrorFeedback && event.retryAction != null && event.retryLabel != null) {
      actions.add(
        SemanticsBuilder.buildActionSemantics(
          child: TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              event.retryAction?.call();
            },
            child: Text(
              event.retryLabel!,
              style: TextStyle(color: iconColor),
            ),
          ),
          actionType: SemanticsActionType.retry,
          config: config.semanticsConfig,
          event: event,
        ),
      );
    }

    // Always add close button
    actions.add(
      SemanticsBuilder.buildActionSemantics(
        child: IconButton(
          icon: Icon(Icons.close, color: iconColor, size: 20),
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
          },
        ),
        actionType: SemanticsActionType.close,
        config: config.semanticsConfig,
        event: event,
      ),
    );

    return actions;
  }

  ColorScheme _getColors(BuildContext context) {
    try {
      return Theme.of(context).colorScheme;
    } catch (e) {
      debugPrint('⚠️ Error accessing colors from context: $e');
      return const ColorScheme.light();
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


