import 'package:flutter/material.dart';
import 'package:fly_feedback/src/config/dialog_feedback_handler_config.dart';
import 'package:fly_feedback/src/config/feedback_semantics_config.dart';
import 'package:fly_feedback/src/config/semantics_builder.dart';
import 'package:fly_feedback/src/events/feedback_event.dart';
import 'package:fly_feedback/src/handlers/fly_feedback_handler.dart';
import 'package:fly_feedback/src/queue/feedback_queue.dart';
import 'package:fly_feedback/src/types/feedback_types.dart';

/// Dialog feedback handler with queue management
///
/// This handler uses a reusable [FeedbackQueue] for managing dialog display
/// with priority-based sorting, duplicate prevention, stale item removal,
/// and context validation.
class DialogFeedbackHandler with FeedbackHandlerMixin implements FlyFeedbackHandler {
  /// Configuration for this handler
  final DialogFeedbackHandlerConfig config;

  /// Queue manager for dialog feedback events
  final FeedbackQueue _queue;

  bool _isShowingDialog = false;

  /// Create a dialog feedback handler with optional configuration
  ///
  /// If [config] is not provided, uses default configuration matching
  /// the original behavior.
  DialogFeedbackHandler({
    DialogFeedbackHandlerConfig? config,
  })  : config = config ?? DialogFeedbackHandlerConfig.defaults(),
        _queue = FeedbackQueue(
          config: (config ?? DialogFeedbackHandlerConfig.defaults()).queueConfig,
        );

  @override
  bool supports(FeedbackDisplay display) => display == FeedbackDisplay.dialog;

  @override
  void handle(BuildContext context, FeedbackEvent event) {
    if (!isValidContext(context)) {
      debugPrint('⚠️ Invalid context for dialog: ${event.message}');
      return;
    }

    // If dialog is already showing, add to queue
    if (_isShowingDialog) {
      debugPrint('⚠️ Dialog already showing, queuing: ${event.message}');
      _queue.add(context, event);
      return;
    }

    // Mark as showing immediately to prevent race conditions
    // when multiple handle() calls happen in quick succession
    _isShowingDialog = true;

    // Defer showing dialog until after the current build phase completes
    // This prevents "setState() called during build" errors
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isValidContext(context)) {
        debugPrint('⚠️ Context invalidated before showing dialog: ${event.message}');
        _isShowingDialog = false;
        _processQueue();
        return;
      }

      // Try to show immediately
      try {
        if (event is ConfirmationFeedback) {
          _showConfirmationDialog(context, event);
        } else {
          _showAlertDialog(context, event);
        }
      } catch (e) {
        debugPrint('❌ Error showing dialog: $e');
        _isShowingDialog = false;
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
        // Mark as showing immediately to prevent race conditions
        _isShowingDialog = true;

        // Defer showing dialog until after the current build phase completes
        // This prevents "setState() called during build" errors
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!isValidContext(context)) {
            debugPrint('⚠️ Context invalidated before showing queued dialog: ${event.message}');
            _isShowingDialog = false;
            _processQueue();
            return;
          }

          try {
            if (event is ConfirmationFeedback) {
              _showConfirmationDialog(context, event);
            } else {
              _showAlertDialog(context, event);
            }
          } catch (e) {
            debugPrint('❌ Error showing queued dialog: $e');
            _isShowingDialog = false;
            // Continue processing queue after error
            _processQueue();
          }
        });
      },
      () => _isShowingDialog,
    );
  }

  void _showConfirmationDialog(
    BuildContext context,
    ConfirmationFeedback event,
  ) {
    // _isShowingDialog is already set to true before this method is called
    final colors = _getColors(context);

    showDialog<void>(
      context: context,
      barrierDismissible: event.barrierDismissible,
      builder: (dialogContext) {
        return PopScope(
          canPop: event.barrierDismissible,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              _isShowingDialog = false;
              event.onCancel?.call();
              _processQueue();
            }
          },
          child: SemanticsBuilder.buildSemantics(
            child: AlertDialog(
              title: event.title == null ? null : Text(event.title!),
              content: Text(event.message),
              actions: [
                if (event.cancelLabel != null || event.onCancel != null)
                  SemanticsBuilder.buildActionSemantics(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        _isShowingDialog = false;
                        event.onCancel?.call();
                        _processQueue();
                      },
                      child: Text(event.cancelLabel ?? ''),
                    ),
                    actionType: SemanticsActionType.cancel,
                    config: config.semanticsConfig,
                    event: event,
                  ),
                if (event.confirmLabel != null || event.onConfirm != null)
                  SemanticsBuilder.buildActionSemantics(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        _isShowingDialog = false;
                        event.onConfirm?.call();
                        _processQueue();
                      },
                      style: event.isDangerous
                          ? ElevatedButton.styleFrom(
                              backgroundColor: _getErrorColor(context),
                              foregroundColor: colors.onError,
                            )
                          : null,
                      child: Text(event.confirmLabel ?? ''),
                    ),
                    actionType: SemanticsActionType.confirm,
                    config: config.semanticsConfig,
                    event: event,
                  ),
              ],
            ),
            event: event,
            config: config.semanticsConfig,
            context: dialogContext,
          ),
        );
      },
    ).then((_) {
      _isShowingDialog = false;
      _processQueue();
    }).catchError((Object error) {
      debugPrint('❌ Error in confirmation dialog: $error');
      _isShowingDialog = false;
      _processQueue();
    });
  }

  void _showAlertDialog(BuildContext context, FeedbackEvent event) {
    // _isShowingDialog is already set to true before this method is called

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return SemanticsBuilder.buildSemantics(
          child: AlertDialog(
            title: event.title != null ? Text(event.title!) : null,
            content: Text(event.message),
            actions: [
              if (event.okLabel != null)
                SemanticsBuilder.buildActionSemantics(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      _isShowingDialog = false;
                      _processQueue();
                    },
                    child: Text(event.okLabel!),
                  ),
                  actionType: SemanticsActionType.ok,
                  config: config.semanticsConfig,
                  event: event,
                )
              else
                // Show icon-only close button if no label provided
                SemanticsBuilder.buildActionSemantics(
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      _isShowingDialog = false;
                      _processQueue();
                    },
                  ),
                  actionType: SemanticsActionType.close,
                  config: config.semanticsConfig,
                  event: event,
                ),
            ],
          ),
          event: event,
          config: config.semanticsConfig,
          context: dialogContext,
        );
      },
    ).then((_) {
      _isShowingDialog = false;
      _processQueue();
    }).catchError((Object error) {
      debugPrint('❌ Error in alert dialog: $error');
      _isShowingDialog = false;
      _processQueue();
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

