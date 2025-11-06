import 'package:flutter/material.dart';
import 'package:fly_feedback/src/config/dialog_feedback_handler_config.dart';
import 'package:fly_feedback/src/config/feedback_semantics_config.dart';
import 'package:fly_feedback/src/config/semantics_builder.dart';
import 'package:fly_feedback/src/events/feedback_event.dart';
import 'package:fly_feedback/src/handlers/fly_feedback_handler.dart';
import 'package:fly_feedback/src/types/feedback_types.dart';

/// Dialog feedback handler with queue management
class DialogFeedbackHandler with FeedbackHandlerMixin implements FlyFeedbackHandler {
  /// Configuration for this handler
  final DialogFeedbackHandlerConfig config;

  bool _isShowingDialog = false;

  /// Create a dialog feedback handler with optional configuration
  ///
  /// If [config] is not provided, uses default configuration matching
  /// the original behavior.
  DialogFeedbackHandler({
    DialogFeedbackHandlerConfig? config,
  }) : config = config ?? DialogFeedbackHandlerConfig.defaults();

  @override
  bool supports(FeedbackDisplay display) => display == FeedbackDisplay.dialog;

  @override
  void handle(BuildContext context, FeedbackEvent event) {
    if (!isValidContext(context)) {
      debugPrint('⚠️ Invalid context for dialog: ${event.message}');
      return;
    }

    // Prevent dialog stacking
    if (_isShowingDialog) {
      debugPrint('⚠️ Dialog already showing, queuing: ${event.message}');
      // Queue the dialog (simple implementation - could be enhanced)
      Future.delayed(const Duration(milliseconds: 500), () {
        if (context.mounted) {
          handle(context, event);
        }
      });
      return;
    }

    try {
      if (event is ConfirmationFeedback) {
        _showConfirmationDialog(context, event);
      } else {
        _showAlertDialog(context, event);
      }
    } catch (e) {
      debugPrint('❌ Error showing dialog: $e');
      _isShowingDialog = false;
    }
  }

  void _showConfirmationDialog(
    BuildContext context,
    ConfirmationFeedback event,
  ) {
    _isShowingDialog = true;

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
                      },
                      style: event.isDangerous
                          ? ElevatedButton.styleFrom(
                              backgroundColor: _getErrorColor(context),
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
    });
  }

  void _showAlertDialog(BuildContext context, FeedbackEvent event) {
    _isShowingDialog = true;

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
    });
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

