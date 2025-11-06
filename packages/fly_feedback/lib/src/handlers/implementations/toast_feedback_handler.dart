import 'package:flutter/material.dart';
import 'package:fly_feedback/src/config/semantics_builder.dart';
import 'package:fly_feedback/src/config/toast_feedback_handler_config.dart';
import 'package:fly_feedback/src/events/feedback_event.dart';
import 'package:fly_feedback/src/handlers/fly_feedback_handler.dart';
import 'package:fly_feedback/src/types/feedback_types.dart';

/// Toast feedback handler
///
/// Displays feedback events as a toast notification using an overlay.
/// Toast notifications are small, unobtrusive messages that appear briefly
/// and automatically dismiss after a short duration.
class ToastFeedbackHandler with FeedbackHandlerMixin implements FlyFeedbackHandler {
  /// Configuration for this handler
  final ToastFeedbackHandlerConfig config;

  /// Create a toast feedback handler with optional configuration
  ///
  /// If [config] is not provided, uses default configuration matching
  /// the original behavior.
  ToastFeedbackHandler({
    ToastFeedbackHandlerConfig? config,
  }) : config = config ?? ToastFeedbackHandlerConfig.defaults();

  @override
  bool supports(FeedbackDisplay display) => display == FeedbackDisplay.toast;

  @override
  void handle(BuildContext context, FeedbackEvent event) {
    if (!isValidContext(context)) {
      debugPrint('⚠️ Invalid context for toast: ${event.message}');
      return;
    }

    try {
      final colors = _getColors(context);
      final backgroundColor = config.getBackgroundColor(event.type, colors) ??
          colors.surfaceContainer;
      final icon = config.getIcon(event.type) ?? Icons.info_outline;
      final iconColor =
          config.getIconColor(event.type, colors) ?? colors.onSurface;
      final textColor =
          config.getTextColor(event.type, colors) ?? colors.onSurface;
      final duration = event.duration ?? 
          config.getDefaultDuration(event.type) ?? 
          const Duration(seconds: 2);

      _showToast(
        context,
        message: event.message,
        feedbackType: event.type,
        backgroundColor: backgroundColor,
        icon: icon,
        iconColor: iconColor,
        textColor: textColor,
        duration: duration,
        event: event,
      );
    } catch (e) {
      debugPrint('❌ Error showing toast: $e');
      _fallbackDisplay(context, event);
    }
  }

  void _showToast(
    BuildContext context, {
    required String message,
    required FeedbackType feedbackType,
    required Color backgroundColor,
    required IconData icon,
    required Color iconColor,
    required Color textColor,
    required Duration duration,
    required FeedbackEvent event,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        feedbackType: feedbackType,
        backgroundColor: backgroundColor,
        icon: icon,
        iconColor: iconColor,
        textColor: textColor,
        config: config,
        onDismiss: () => overlayEntry.remove(),
        event: event,
      ),
    );

    overlay.insert(overlayEntry);

    // Auto-dismiss after duration
    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
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

  void _fallbackDisplay(BuildContext context, FeedbackEvent event) {
    // Simple fallback - use snackbar
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(event.message),
          duration: event.duration ?? const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('❌ Fallback display also failed: $e');
    }
  }
}

/// Toast widget displayed as an overlay
class _ToastWidget extends StatefulWidget {
  final String message;
  final FeedbackType feedbackType;
  final Color backgroundColor;
  final IconData icon;
  final Color iconColor;
  final Color textColor;
  final ToastFeedbackHandlerConfig config;
  final VoidCallback onDismiss;
  final FeedbackEvent? event;

  const _ToastWidget({
    required this.message,
    required this.feedbackType,
    required this.backgroundColor,
    required this.icon,
    required this.iconColor,
    required this.textColor,
    required this.config,
    required this.onDismiss,
    this.event,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    final animationDuration = widget.config.animationDuration ?? 
        const Duration(milliseconds: 300);
    final animationCurve = widget.config.animationCurve ?? Curves.easeOut;
    
    _controller = AnimationController(
      duration: animationDuration,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: animationCurve),
    );
    final slideBegin = widget.config.slideBeginOffset ?? const Offset(0, -1);
    _slideAnimation = Tween<Offset>(
      begin: slideBegin,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: animationCurve),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final topOffset = widget.config.topOffset ?? 16.0;
    final horizontalPadding = widget.config.horizontalPadding ?? 16.0;
    final verticalPadding = widget.config.verticalPadding ?? 12.0;
    final borderRadius = widget.config.borderRadius ?? 8.0;
    final iconSize = widget.config.iconSize ?? 20.0;
    final fontSize = widget.config.fontSize ?? 14.0;
    final shadowColor = widget.config.shadowColor ?? colors.shadow;
    final shadowBlurRadius = widget.config.shadowBlurRadius ?? 8.0;
    final shadowOffset = widget.config.shadowOffset ?? const Offset(0, 2);

    return Positioned(
      top: MediaQuery.of(context).padding.top + topOffset,
      left: horizontalPadding,
      right: horizontalPadding,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor.withValues(alpha: 0.2),
                    blurRadius: shadowBlurRadius,
                    offset: shadowOffset,
                  ),
                ],
              ),
              child: SemanticsBuilder.buildSemantics(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, color: widget.iconColor, size: iconSize),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          color: widget.textColor,
                          fontSize: fontSize,
                        ),
                      ),
                    ),
                  ],
                ),
                event: widget.event ?? _createFeedbackEvent(),
                config: widget.config.semanticsConfig,
                context: null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  FeedbackEvent _createFeedbackEvent() {
    switch (widget.feedbackType) {
      case FeedbackType.success:
        return SuccessFeedback(widget.message);
      case FeedbackType.error:
        return ErrorFeedback(widget.message);
      case FeedbackType.warning:
        return WarningFeedback(widget.message);
      case FeedbackType.info:
        return InfoFeedback(widget.message);
    }
  }
}

