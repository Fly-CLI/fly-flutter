import 'package:fly_feedback/src/handlers/implementations/banner_feedback_handler.dart';
import 'package:fly_feedback/src/handlers/implementations/bottom_sheet_feedback_handler.dart';
import 'package:fly_feedback/src/handlers/implementations/dialog_feedback_handler.dart';
import 'package:fly_feedback/src/handlers/fly_feedback_handler.dart';
import 'package:fly_feedback/src/handlers/implementations/snackbar_feedback_handler.dart';
import 'package:fly_feedback/src/handlers/implementations/toast_feedback_handler.dart';

/// Types of feedback
enum FeedbackType {
  /// Indicates a successful operation or positive outcome
  success,
  
  /// Indicates an error or failure that requires attention
  error,
  
  /// Indicates a warning or cautionary message
  warning,
  
  /// Indicates informational or neutral feedback
  info,
}

/// Display strategies for feedback
enum FeedbackDisplay {
  /// Displays feedback as a Material SnackBar at the bottom of the screen
  snackBar,
  
  /// Displays feedback as a modal dialog in the center of the screen
  dialog,
  
  /// Displays feedback as a bottom sheet that slides up from the bottom
  bottomSheet,
  
  /// Displays feedback as a temporary toast notification overlay
  toast,
  
  /// Displays feedback as a banner at the top of the screen
  banner,
  
  /// Custom display type that requires a user-provided handler
  custom,
}

extension FeedbackTypeEmoji on FeedbackType {
  /// Get the emoji representation for this feedback type.
  ///
  /// Returns a string emoji that visually represents the feedback type:
  /// - [FeedbackType.success]: ✅
  /// - [FeedbackType.error]: ❌
  /// - [FeedbackType.warning]: ⚠️
  /// - [FeedbackType.info]: ℹ️
  String get emoji {
    switch (this) {
      case FeedbackType.success:
        return '✅';
      case FeedbackType.error:
        return '❌';
      case FeedbackType.warning:
        return '⚠️';
      case FeedbackType.info:
        return 'ℹ️';
    }
  }
}

extension FeedbackDisplayFactory on FeedbackDisplay {
  /// Create a [FlyFeedbackHandler] appropriate for this display type.
  ///
  /// For [FeedbackDisplay.custom], this throws since a user-provided
  /// handler is required.
  FlyFeedbackHandler createDefaultHandler() {
    switch (this) {
      case FeedbackDisplay.snackBar:
        return SnackbarFeedbackHandler();
      case FeedbackDisplay.dialog:
        return DialogFeedbackHandler();
      case FeedbackDisplay.bottomSheet:
        return BottomSheetFeedbackHandler();
      case FeedbackDisplay.toast:
        return ToastFeedbackHandler();
      case FeedbackDisplay.banner:
        return BannerFeedbackHandler();
      case FeedbackDisplay.custom:
        throw UnsupportedError(
          'Custom display requires a user-provided handler.',
        );
    }
  }

  /// Get all default handlers for all display types (excluding custom).
  ///
  /// Returns a list of all default [FlyFeedbackHandler] instances.
  /// This can be used to create a composite handler with all handlers.
  ///
  /// This getter is exhaustive - it automatically includes all display types
  /// except [FeedbackDisplay.custom]. If a new display type is added, it will
  /// be included automatically.
  static List<FlyFeedbackHandler> get allDefaultHandlers {
    return FeedbackDisplay.values
        .where((display) => display != FeedbackDisplay.custom)
        .map((display) => display.createDefaultHandler())
        .toList();
  }
}
