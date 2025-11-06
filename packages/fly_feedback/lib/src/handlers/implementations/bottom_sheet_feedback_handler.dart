import 'package:flutter/material.dart';
import 'package:fly_feedback/src/config/bottom_sheet_feedback_handler_config.dart';
import 'package:fly_feedback/src/config/feedback_queue_config.dart';
import 'package:fly_feedback/src/config/feedback_semantics_config.dart';
import 'package:fly_feedback/src/config/semantics_builder.dart';
import 'package:fly_feedback/src/events/feedback_event.dart';
import 'package:fly_feedback/src/handlers/fly_feedback_handler.dart';
import 'package:fly_feedback/src/queue/feedback_queue.dart';
import 'package:fly_feedback/src/types/feedback_types.dart';

/// Bottom sheet feedback handler with queue management
///
/// Displays feedback events in a modal bottom sheet with:
/// - Queue management to prevent stacking using reusable FeedbackQueue
/// - Priority-based sorting for critical feedback
/// - Support for confirmation dialogs
/// - Color-coded feedback types
/// - Action buttons for success/error feedback
/// - Safe area handling
/// - Proper animations
class BottomSheetFeedbackHandler with FeedbackHandlerMixin implements FlyFeedbackHandler {
  /// Configuration for this handler
  final BottomSheetFeedbackHandlerConfig config;

  /// Queue manager for bottom sheet feedback events
  final FeedbackQueue _queue;

  bool _isShowingBottomSheet = false;

  /// Create a bottom sheet feedback handler with optional configuration
  ///
  /// If [config] is not provided, uses default configuration matching
  /// the original behavior.
  BottomSheetFeedbackHandler({
    BottomSheetFeedbackHandlerConfig? config,
  })  : config = config ?? BottomSheetFeedbackHandlerConfig.defaults(),
        _queue = FeedbackQueue(
          config: _createQueueConfigFromHandlerConfig(
            config ?? BottomSheetFeedbackHandlerConfig.defaults(),
          ),
        );

  /// Create queue config from handler config
  ///
  /// Handles backward compatibility by using deprecated properties
  /// if queueConfig is not provided.
  static FeedbackQueueConfig _createQueueConfigFromHandlerConfig(
    BottomSheetFeedbackHandlerConfig config,
  ) {
    if (config.queueConfig != null) {
      return config.queueConfig!;
    }

    // Backward compatibility: use deprecated properties if queueConfig is null
    return FeedbackQueueConfig(
      queueRetryDelay: config.queueRetryDelay,
      maxQueueWait: config.maxQueueWait,
    );
  }

  @override
  bool supports(FeedbackDisplay display) => display == FeedbackDisplay.bottomSheet;

  @override
  void handle(BuildContext context, FeedbackEvent event) {
    if (!isValidContext(context)) {
      debugPrint('⚠️ Invalid context for bottom sheet: ${event.message}');
      return;
    }

    // If bottom sheet is already showing, add to queue
    if (_isShowingBottomSheet) {
      debugPrint('⚠️ Bottom sheet already showing, queuing: ${event.message}');
      _queue.add(context, event);
      return;
    }

    // Set flag immediately to prevent race conditions when multiple calls
    // happen in the same frame before post-frame callbacks execute
    _isShowingBottomSheet = true;

    // Defer showing bottom sheet until after the current build phase completes
    // This prevents "setState() called during build" errors
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isValidContext(context)) {
        debugPrint('⚠️ Context invalidated before showing bottom sheet: ${event.message}');
        _isShowingBottomSheet = false;
        _processQueue();
        return;
      }

      // Try to show immediately
      try {
        _showBottomSheet(context, event);
      } catch (e) {
        debugPrint('❌ Error showing bottom sheet: $e');
        _isShowingBottomSheet = false;
        // Try to process queue after error
        _processQueue();
      }
    });
  }

  /// Process the queue
  ///
  /// This method delegates to the FeedbackQueue to process pending items.
  void _processQueue() {
    _queue.process(
      (context, event) {
        // Defer showing bottom sheet until after the current build phase completes
        // This prevents "setState() called during build" errors
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!isValidContext(context)) {
            debugPrint('⚠️ Context invalidated before showing queued bottom sheet: ${event.message}');
            _isShowingBottomSheet = false;
            _processQueue();
            return;
          }

          try {
            _showBottomSheet(context, event);
          } catch (e) {
            debugPrint('❌ Error showing queued bottom sheet: $e');
            _isShowingBottomSheet = false;
            // Continue processing queue after error
            _processQueue();
          }
        });
      },
      () => _isShowingBottomSheet,
    );
  }

  /// Show the bottom sheet (main entry point)
  void _showBottomSheet(BuildContext context, FeedbackEvent event) {
    if (!isValidContext(context)) {
      debugPrint('⚠️ Invalid context for bottom sheet: ${event.message}');
      return;
    }

    try {
      if (event is ConfirmationFeedback) {
        _showConfirmationBottomSheet(context, event);
      } else {
        _showFeedbackBottomSheet(context, event);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error showing bottom sheet: $e');
      debugPrint('Stack trace: $stackTrace');
      _isShowingBottomSheet = false;
      // Try to process next item in queue
      _processQueue();
    }
  }

  /// Show confirmation feedback in bottom sheet format
  void _showConfirmationBottomSheet(
    BuildContext context,
    ConfirmationFeedback event,
  ) {
    // Flag is already set in handle() to prevent race conditions

    final colors = _getColors(context);
    final borderRadius = config.borderRadius ?? 20.0;
    final useSafeArea = config.useSafeArea ?? true;

    showModalBottomSheet<void>(
      context: context,
      isDismissible: event.barrierDismissible,
      enableDrag: event.barrierDismissible,
      useSafeArea: useSafeArea,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
      ),
      builder: (bottomSheetContext) {
        return PopScope(
          canPop: event.barrierDismissible,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              _isShowingBottomSheet = false;
              event.onCancel?.call();
              _processQueue();
            }
          },
          child: SemanticsBuilder.buildSemantics(
            child: SafeArea(
              child: Container(
                padding: config.contentPadding ?? 
                    const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar indicator
                    Center(
                      child: Container(
                        width: config.handleBarWidth ?? 40,
                        height: config.handleBarHeight ?? 4,
                        margin: EdgeInsets.only(
                          bottom: config.handleBarMarginBottom ?? 20,
                        ),
                        decoration: BoxDecoration(
                          color: config.handleBarColor ?? colors.outline,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Title
                    if (event.title != null && event.title!.isNotEmpty) ...[
                      Text(
                        event.title!,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.start,
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Message
                    Text(
                      event.message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                          ),
                      textAlign: TextAlign.start,
                    ),
                    const SizedBox(height: 24),
                    // Action buttons
                    _buildConfirmationButtons(
                      context: context,
                      event: event,
                      bottomSheetContext: bottomSheetContext,
                    ),
                  ],
                ),
              ),
            ),
            event: event,
            config: config.semanticsConfig,
            context: bottomSheetContext,
          ),
        );
      },
    ).then((_) {
      _isShowingBottomSheet = false;
      _processQueue();
    }).catchError((Object error) {
      debugPrint('❌ Error in bottom sheet: $error');
      _isShowingBottomSheet = false;
      _processQueue();
    });
  }

  /// Build confirmation action buttons
  Widget _buildConfirmationButtons({
    required BuildContext context,
    required ConfirmationFeedback event,
    required BuildContext bottomSheetContext,
  }) {
    final colors = _getColors(context);
    final hasCancel = event.cancelLabel != null || event.onCancel != null;
    final hasConfirm = event.confirmLabel != null || event.onConfirm != null;

    if (!hasCancel && !hasConfirm) {
      return const SizedBox.shrink();
    }

    // Stack buttons vertically for better UX on small screens
    if (hasCancel && hasConfirm) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Confirm button (primary action)
          SizedBox(
            width: double.infinity,
            child: SemanticsBuilder.buildActionSemantics(
              child: ElevatedButton(
                onPressed: () => _handleConfirm(bottomSheetContext, event),
                style: event.isDangerous
                    ? ElevatedButton.styleFrom(
                        backgroundColor: _getErrorColor(context),
                        foregroundColor: colors.onError,
                        padding: EdgeInsets.symmetric(
                          vertical: config.buttonVerticalPadding ?? 16,
                        ),
                      )
                    : ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: config.buttonVerticalPadding ?? 16,
                        ),
                      ),
                child: Text(event.confirmLabel ?? 'Confirm'),
              ),
              actionType: SemanticsActionType.confirm,
              config: config.semanticsConfig,
              event: event,
            ),
          ),
          const SizedBox(height: 12),
          // Cancel button (secondary action)
          SizedBox(
            width: double.infinity,
            child: SemanticsBuilder.buildActionSemantics(
              child: OutlinedButton(
                onPressed: () => _handleCancel(bottomSheetContext, event),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: config.buttonVerticalPadding ?? 16,
                  ),
                ),
                child: Text(event.cancelLabel ?? 'Cancel'),
              ),
              actionType: SemanticsActionType.cancel,
              config: config.semanticsConfig,
              event: event,
            ),
          ),
        ],
      );
    }

    // Single button layout
    return SizedBox(
      width: double.infinity,
      child: SemanticsBuilder.buildActionSemantics(
        child: ElevatedButton(
          onPressed: () {
            if (hasConfirm) {
              _handleConfirm(bottomSheetContext, event);
            } else {
              _handleCancel(bottomSheetContext, event);
            }
          },
          style: event.isDangerous
              ? ElevatedButton.styleFrom(
                  backgroundColor: _getErrorColor(context),
                  foregroundColor: colors.onError,
                  padding: EdgeInsets.symmetric(
                    vertical: config.buttonVerticalPadding ?? 16,
                  ),
                )
              : ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: config.buttonVerticalPadding ?? 16,
                  ),
                ),
          child: Text(
            event.confirmLabel ?? event.cancelLabel ?? 'OK',
          ),
        ),
        actionType: hasConfirm ? SemanticsActionType.confirm : SemanticsActionType.cancel,
        config: config.semanticsConfig,
        event: event,
      ),
    );
  }

  /// Handle confirm action
  void _handleConfirm(BuildContext context, ConfirmationFeedback event) {
    Navigator.of(context).pop();
    _isShowingBottomSheet = false;
    try {
      event.onConfirm?.call();
    } catch (e) {
      debugPrint('❌ Error in confirm callback: $e');
    }
    _processQueue();
  }

  /// Handle cancel action
  void _handleCancel(BuildContext context, ConfirmationFeedback event) {
    Navigator.of(context).pop();
    _isShowingBottomSheet = false;
    try {
      event.onCancel?.call();
    } catch (e) {
      debugPrint('❌ Error in cancel callback: $e');
    }
    _processQueue();
  }

  /// Show regular feedback in bottom sheet format
  void _showFeedbackBottomSheet(
    BuildContext context,
    FeedbackEvent event,
  ) {
    // Flag is already set in handle() to prevent race conditions

    final colors = _getColors(context);
    final backgroundColor = config.getBackgroundColor(event.type, colors) ?? 
        colors.surfaceContainer;
    final icon = config.getIcon(event.type) ?? Icons.info_outline;
    final iconColor = config.getIconColor(event.type, colors) ?? 
        colors.onSurface;
    final textColor = config.getTextColor(event.type, colors) ?? 
        colors.onSurface;
    final iconSize = config.iconSize ?? 24.0;
    final borderRadius = config.borderRadius ?? 20.0;
    final useSafeArea = config.useSafeArea ?? true;

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: useSafeArea,
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
      ),
      builder: (bottomSheetContext) {
        return SemanticsBuilder.buildSemantics(
          child: SafeArea(
            child: Container(
              padding: config.contentPadding ?? 
                  const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar indicator
                  Center(
                    child: Container(
                      width: config.handleBarWidth ?? 40,
                      height: config.handleBarHeight ?? 4,
                      margin: EdgeInsets.only(
                        bottom: config.handleBarMarginBottom ?? 16,
                      ),
                      decoration: BoxDecoration(
                        color: colors.onSurface.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Icon and message row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, color: iconColor, size: iconSize),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          event.message,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                      SemanticsBuilder.buildActionSemantics(
                        child: IconButton(
                          icon: Icon(Icons.close, color: iconColor, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _handleClose(bottomSheetContext),
                        ),
                        actionType: SemanticsActionType.close,
                        config: config.semanticsConfig,
                        event: event,
                      ),
                    ],
                  ),
                  // Action button (if available)
                  if (_hasActionButton(event)) ...[
                    const SizedBox(height: 16),
                    _buildActionButton(
                      context: bottomSheetContext,
                      event: event,
                      backgroundColor: backgroundColor,
                    ),
                  ],
                ],
              ),
            ),
          ),
          event: event,
          config: config.semanticsConfig,
          context: bottomSheetContext,
        );
      },
    ).then((_) {
      _isShowingBottomSheet = false;
      _processQueue();
    }).catchError((Object error) {
      debugPrint('❌ Error in bottom sheet: $error');
      _isShowingBottomSheet = false;
      _processQueue();
    });
  }

  /// Check if event has an action button
  bool _hasActionButton(FeedbackEvent event) {
    if (event is SuccessFeedback) {
      return event.action != null && event.actionLabel != null && event.actionLabel!.isNotEmpty;
    }
    if (event is ErrorFeedback) {
      return event.retryAction != null && event.retryLabel != null && event.retryLabel!.isNotEmpty;
    }
    return false;
  }

  /// Build action button for feedback
  Widget _buildActionButton({
    required BuildContext context,
    required FeedbackEvent event,
    required Color backgroundColor,
  }) {
    final colors = _getColors(context);
    // Use onSurface for text color to ensure proper contrast on surface background
    // This maintains WCAG AA compliance (4.5:1 contrast ratio for text)
    final textColor = colors.onSurface;
    
    if (event is SuccessFeedback && event.action != null && event.actionLabel != null) {
      return SizedBox(
        width: double.infinity,
        child: SemanticsBuilder.buildActionSemantics(
          child: ElevatedButton(
            onPressed: () => _handleAction(context, event.action!),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.surface,
              foregroundColor: textColor,
              padding: EdgeInsets.symmetric(
                vertical: config.buttonVerticalPadding ?? 16,
              ),
            ),
            child: Text(event.actionLabel!),
          ),
          actionType: SemanticsActionType.action,
          config: config.semanticsConfig,
          event: event,
        ),
      );
    }

    if (event is ErrorFeedback && event.retryAction != null && event.retryLabel != null) {
      return SizedBox(
        width: double.infinity,
        child: SemanticsBuilder.buildActionSemantics(
          child: ElevatedButton(
            onPressed: () => _handleAction(context, event.retryAction!),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.surface,
              foregroundColor: textColor,
              padding: EdgeInsets.symmetric(
                vertical: config.buttonVerticalPadding ?? 16,
              ),
            ),
            child: Text(event.retryLabel!),
          ),
          actionType: SemanticsActionType.retry,
          config: config.semanticsConfig,
          event: event,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  /// Handle action button press
  void _handleAction(BuildContext context, VoidCallback action) {
    Navigator.of(context).pop();
    _isShowingBottomSheet = false;
    try {
      action();
    } catch (e) {
      debugPrint('❌ Error in action callback: $e');
    }
    _processQueue();
  }

  /// Handle close button press
  void _handleClose(BuildContext context) {
    Navigator.of(context).pop();
    _isShowingBottomSheet = false;
    _processQueue();
  }

  ColorScheme _getColors(BuildContext context) {
    try {
      return Theme.of(context).colorScheme;
    } catch (e) {
      debugPrint('⚠️ Error accessing colors from context: $e');
      return const ColorScheme.light();
    }
  }

  Color _getErrorColor(BuildContext context) {
    try {
      final colors = Theme.of(context).colorScheme;
      return config.getBackgroundColor(FeedbackType.error, colors) ?? 
          colors.error;
    } catch (e) {
      // Fallback to theme error color if available
      try {
        return Theme.of(context).colorScheme.error;
      } catch (_) {
        // Last resort - but this should never happen
        return const ColorScheme.light().error;
      }
    }
  }

}

