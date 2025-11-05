import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation_project/core/foundation/feedback/service/feedback_service.dart';
import 'package:foundation_project/core/foundation/feedback/service/default_feedback_service.dart';
import 'package:foundation_project/core/foundation/feedback/handlers/composite_feedback_handler.dart';
import 'package:foundation_project/core/foundation/feedback/handlers/snackbar_feedback_handler.dart';
import 'package:foundation_project/core/foundation/feedback/handlers/dialog_feedback_handler.dart';
import 'package:foundation_project/core/foundation/feedback/handlers/bottom_sheet_feedback_handler.dart';
import 'package:foundation_project/core/foundation/feedback/handlers/toast_feedback_handler.dart';
import 'package:foundation_project/core/foundation/feedback/handlers/banner_feedback_handler.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_events.dart';

/// Provider for FeedbackService<FeedbackEvent>
///
/// Default implementation uses standard Flutter feedback handlers (SnackBar, Dialog, BottomSheet, Toast, Banner).
/// Override this provider to use custom feedback implementations.
///
/// Example override for custom service:
/// ```dart
/// final container = ProviderContainer(
///   overrides: [
///     feedbackServiceProvider.overrideWithValue(
///       CustomFeedbackService(),
///     ),
///   ],
/// );
/// ```
///
/// For Mason brick template generation, the handler should be a template variable:
/// ```dart
/// final feedbackServiceProvider = Provider<FeedbackService<FeedbackEvent>>((ref) {
///   return DefaultFeedbackService<FeedbackEvent>(
///     handler: {{feedback_handler}}, // Template variable
///   );
/// });
/// ```
///
/// For custom feedback types, use the service directly or create a custom provider:
/// ```dart
/// final customFeedbackServiceProvider = Provider<FeedbackService<CustomFeedback>>((ref) {
///   return DefaultFeedbackService<CustomFeedback>(
///     handler: CompositeFeedbackHandler([
///       SnackbarFeedbackHandler(),
///       DialogFeedbackHandler(),
///       BottomSheetFeedbackHandler(),
///       ToastFeedbackHandler(),
///       BannerFeedbackHandler(),
///     ]),
///   );
/// });
/// ```
final feedbackServiceProvider =
    Provider<FeedbackService<FeedbackEvent>>((ref) {
  return DefaultFeedbackService<FeedbackEvent>(
    handler: CompositeFeedbackHandler([
      SnackbarFeedbackHandler(),
      DialogFeedbackHandler(),
      BottomSheetFeedbackHandler(),
      ToastFeedbackHandler(),
      BannerFeedbackHandler(),
    ]),
  );
});

