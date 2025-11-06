import 'package:flutter/material.dart';
import 'package:fly_feedback/src/events/feedback_event.dart';
import 'package:fly_feedback/src/handlers/fly_feedback_handler.dart';
import 'package:fly_feedback/src/types/feedback_types.dart';

/// Bottom sheet feedback handler with queue management
///
/// Displays feedback events in a modal bottom sheet with:
/// - Queue management to prevent stacking
/// - Support for confirmation dialogs
/// - Color-coded feedback types
/// - Action buttons for success/error feedback
/// - Safe area handling
/// - Proper animations
class BottomSheetFeedbackHandler with FeedbackHandlerMixin implements FlyFeedbackHandler {
  bool _isShowingBottomSheet = false;
  final List<_PendingBottomSheet> _pendingQueue = [];
  static const Duration _queueRetryDelay = Duration(milliseconds: 300);
  static const Duration _maxQueueWait = Duration(seconds: 5);

  @override
  bool supports(FeedbackDisplay display) => display == FeedbackDisplay.bottomSheet;

  @override
  void handle(BuildContext context, FeedbackEvent event) {
    if (!isValidContext(context)) {
      debugPrint('⚠️ Invalid context for bottom sheet: ${event.message}');
      return;
    }

    // Prevent bottom sheet stacking with proper queue management
    if (_isShowingBottomSheet) {
      debugPrint('⚠️ Bottom sheet already showing, queuing: ${event.message}');
      _pendingQueue.add(_PendingBottomSheet(
        event: event,
        context: context,
        timestamp: DateTime.now(),
      ),);
      _processQueue();
      return;
    }

    _showBottomSheet(context, event);
  }

  /// Process the pending queue
  void _processQueue() {
    if (_pendingQueue.isEmpty || _isShowingBottomSheet) {
      return;
    }

    final pending = _pendingQueue.first;
    final waitTime = DateTime.now().difference(pending.timestamp);

    // Remove stale items from queue
    if (waitTime > _maxQueueWait) {
      debugPrint('⚠️ Removing stale bottom sheet from queue: ${pending.event.message}');
      _pendingQueue.removeAt(0);
      _processQueue();
      return;
    }

    // Try to show after a short delay
    Future.delayed(_queueRetryDelay, () {
      if (!_isShowingBottomSheet && _pendingQueue.isNotEmpty) {
        final next = _pendingQueue.removeAt(0);
        if (next.context.mounted) {
          _showBottomSheet(next.context, next.event);
        }
        _processQueue();
      }
    });
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
    _isShowingBottomSheet = true;

    showModalBottomSheet<void>(
      context: context,
      isDismissible: event.barrierDismissible,
      enableDrag: event.barrierDismissible,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar indicator
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
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
            child: ElevatedButton(
              onPressed: () => _handleConfirm(bottomSheetContext, event),
              style: event.isDangerous
                  ? ElevatedButton.styleFrom(
                      backgroundColor: _getErrorColor(context),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    )
                  : ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
              child: Text(event.confirmLabel ?? 'Confirm'),
            ),
          ),
          const SizedBox(height: 12),
          // Cancel button (secondary action)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _handleCancel(bottomSheetContext, event),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(event.cancelLabel ?? 'Cancel'),
            ),
          ),
        ],
      );
    }

    // Single button layout
    return SizedBox(
      width: double.infinity,
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
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              )
            : ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
        child: Text(
          event.confirmLabel ?? event.cancelLabel ?? 'OK',
        ),
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
    _isShowingBottomSheet = true;

    final colors = _getColors(context);
    final (backgroundColor, icon) = _getStyleForType(event.type, colors);

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar indicator
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Icon and message row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        event.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _handleClose(bottomSheetContext),
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
    if (event is SuccessFeedback && event.action != null && event.actionLabel != null) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _handleAction(context, event.action!),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: backgroundColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(event.actionLabel!),
        ),
      );
    }

    if (event is ErrorFeedback && event.retryAction != null && event.retryLabel != null) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _handleAction(context, event.retryAction!),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: backgroundColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(event.retryLabel!),
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

  Color _getErrorColor(BuildContext context) {
    try {
      return Theme.of(context).colorScheme.error;
    } catch (e) {
      return Colors.red;
    }
  }
}

/// Internal class for pending bottom sheet queue items
class _PendingBottomSheet {
  final FeedbackEvent event;
  final BuildContext context;
  final DateTime timestamp;

  _PendingBottomSheet({
    required this.event,
    required this.context,
    required this.timestamp,
  });
}

