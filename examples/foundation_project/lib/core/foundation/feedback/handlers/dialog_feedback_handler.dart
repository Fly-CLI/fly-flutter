import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation_project/core/foundation/feedback/types/feedback_types.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_events.dart';
import 'package:foundation_project/shared/themes/extensions/theme_extensions.dart';
import 'package:foundation_project/core/foundation/feedback/handlers/fly_feedback_handler.dart';

/// Dialog feedback handler with queue management
class DialogFeedbackHandler with FeedbackHandlerMixin implements FlyFeedbackHandler {
  bool _isShowingDialog = false;

  @override
  bool supports(FeedbackDisplay display) => display == FeedbackDisplay.dialog;

  @override
  void handle(BuildContext context, FeedbackEvent event, WidgetRef? ref) {
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
          handle(context, event, ref);
        }
      });
      return;
    }

    try {
      if (event is ConfirmationFeedback) {
        _showConfirmationDialog(context, event, ref);
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
    WidgetRef? ref,
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
                          backgroundColor: _getErrorColor(ref),
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

  Color _getErrorColor(WidgetRef? ref) {
    try {
      final colors = ref?.colors;
      return colors?.error ?? Colors.red;
    } catch (e) {
      return Colors.red;
    }
  }
}

