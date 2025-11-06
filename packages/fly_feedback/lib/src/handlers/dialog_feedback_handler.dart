import 'package:flutter/material.dart';
import 'package:fly_feedback/src/types/feedback_types.dart';
import 'package:fly_feedback/src/events/feedback_event.dart';
import 'package:fly_feedback/src/handlers/fly_feedback_handler.dart';

/// Dialog feedback handler with queue management
class DialogFeedbackHandler with FeedbackHandlerMixin implements FlyFeedbackHandler {
  bool _isShowingDialog = false;

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
          child: AlertDialog(
            title: event.title == null ? null : Text(event.title!),
            content: Text(event.message),
            actions: [
              if (event.cancelLabel != null || event.onCancel != null)
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    _isShowingDialog = false;
                    event.onCancel?.call();
                  },
                  child: Text(event.cancelLabel ?? ''),
                ),
              if (event.confirmLabel != null || event.onConfirm != null)
                ElevatedButton(
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
            ],
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
        return AlertDialog(
          title: event.title != null ? Text(event.title!) : null,
          content: Text(event.message),
          actions: [
            if (event.okLabel != null)
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _isShowingDialog = false;
                },
                child: Text(event.okLabel!),
              )
            else
              // Show icon-only close button if no label provided
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _isShowingDialog = false;
                },
              ),
          ],
        );
      },
    ).then((_) {
      _isShowingDialog = false;
    });
  }

  Color _getErrorColor(BuildContext context) {
    try {
      return Theme.of(context).colorScheme.error;
    } catch (e) {
      return Colors.red;
    }
  }
}

