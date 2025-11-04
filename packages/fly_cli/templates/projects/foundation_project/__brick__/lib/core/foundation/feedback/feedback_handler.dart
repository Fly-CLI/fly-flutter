import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:{{project_name_snake}}/core/foundation/feedback/feedback_event.dart';
import 'package:{{project_name_snake}}/shared/themes/extensions/theme_extensions.dart';

/// Abstract feedback handler
/// Implement this to create custom feedback displays
abstract class FeedbackHandler {
  /// Handle a feedback event
  ///
  /// [context] - Valid BuildContext (caller must ensure context is valid)
  /// [event] - Feedback event to display
  /// [ref] - Optional WidgetRef for theme access (may be null)
  void handle(BuildContext context, FeedbackEvent event, WidgetRef? ref);

  /// Check if this handler supports the given display type
  bool supports(FeedbackDisplay display);
}

/// Base mixin for feedback handlers with common utilities
mixin FeedbackHandlerMixin {
  /// Check if context is valid for display
  @protected
  bool isValidContext(BuildContext context) {
    return context.mounted;
  }
}

/// Snackbar feedback handler
class SnackbarFeedbackHandler with FeedbackHandlerMixin implements FeedbackHandler {
  @override
  bool supports(FeedbackDisplay display) => display == FeedbackDisplay.snackbar;

  @override
  void handle(BuildContext context, FeedbackEvent event, WidgetRef? ref) {
    if (!isValidContext(context)) {
      debugPrint('⚠️ Invalid context for snackbar: ${event.message}');
      return;
    }

    try {
      final colors = _getColors(ref);
      final (backgroundColor, icon) = _getStyleForType(event.type, colors);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
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
          duration: event.duration ?? _getDefaultDuration(event.type),
          behavior: SnackBarBehavior.floating,
          action: _buildAction(event),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error showing snackbar: $e');
      _fallbackDisplay(context, event);
    }
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

  Duration _getDefaultDuration(FeedbackType type) {
    return type == FeedbackType.error
        ? const Duration(seconds: 4)
        : const Duration(seconds: 3);
  }

  SnackBarAction? _buildAction(FeedbackEvent event) {
    if (event is SuccessFeedback && event.action != null) {
      return SnackBarAction(
        label: event.actionLabel ?? 'Action',
        textColor: Colors.white,
        onPressed: event.action!,
      );
    }

    if (event is ErrorFeedback && event.retryAction != null) {
      return SnackBarAction(
        label: 'Retry',
        textColor: Colors.white,
        onPressed: event.retryAction!,
      );
    }

    return null;
  }

  void _fallbackDisplay(BuildContext context, FeedbackEvent event) {
    // Simple fallback - just show text
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(event.message)),
      );
    } catch (e) {
      debugPrint('❌ Fallback display also failed: $e');
    }
  }
}

/// Dialog feedback handler with queue management
class DialogFeedbackHandler with FeedbackHandlerMixin implements FeedbackHandler {
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
            title: Text(event.title),
            content: Text(event.message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _isShowingDialog = false;
                  event.onCancel?.call();
                },
                child: Text(event.cancelLabel),
              ),
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
                child: Text(event.confirmLabel),
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
          title: Text(_getTitleForType(event.type)),
          content: Text(event.message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _isShowingDialog = false;
              },
              child: const Text('OK'),
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

  String _getTitleForType(FeedbackType type) {
    switch (type) {
      case FeedbackType.success:
        return 'Success';
      case FeedbackType.error:
        return 'Error';
      case FeedbackType.warning:
        return 'Warning';
      case FeedbackType.info:
        return 'Information';
    }
  }
}

/// Composite handler that delegates to multiple handlers
class CompositeFeedbackHandler with FeedbackHandlerMixin implements FeedbackHandler {
  final List<FeedbackHandler> handlers;

  const CompositeFeedbackHandler(this.handlers);

  @override
  bool supports(FeedbackDisplay display) {
    return handlers.any((h) => h.supports(display));
  }

  @override
  void handle(BuildContext context, FeedbackEvent event, WidgetRef? ref) {
    try {
      final handler = handlers.firstWhere(
        (h) => h.supports(event.display),
        orElse: () => throw UnsupportedError(
          'No handler found for display type: ${event.display}',
        ),
      );

      handler.handle(context, event, ref);
    } catch (e) {
      debugPrint('❌ Error in composite handler: $e');
      // Fallback to snackbar if available
      try {
        final snackbarHandler = handlers.firstWhere(
          (h) => h is SnackbarFeedbackHandler,
        );
        snackbarHandler.handle(context, event, ref);
      } catch (fallbackError) {
        debugPrint('❌ No fallback handler available: $fallbackError');
        rethrow;
      }
    }
  }
}

