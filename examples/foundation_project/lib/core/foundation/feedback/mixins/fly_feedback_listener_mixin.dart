import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation_project/core/di/global_container.dart';
import 'package:foundation_project/core/foundation/feedback/handlers/fly_feedback_handler.dart';
import 'package:foundation_project/core/foundation/feedback/handlers/composite_feedback_handler.dart';
import 'package:foundation_project/core/foundation/feedback/handlers/snackbar_feedback_handler.dart';
import 'package:foundation_project/core/foundation/feedback/handlers/dialog_feedback_handler.dart';
import 'package:foundation_project/core/foundation/feedback/handlers/bottom_sheet_feedback_handler.dart';
import 'package:foundation_project/core/foundation/feedback/handlers/toast_feedback_handler.dart';
import 'package:foundation_project/core/foundation/feedback/handlers/banner_feedback_handler.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_emitter_extensions.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_events.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_providers.dart';

/// Mixin for StatefulWidgets to listen to feedback events
///
/// **Lifecycle:** This mixin automatically disposes the listener in `dispose()`.
///
/// By default, this mixin listens to the lifecycle emitter's feedback stream.
/// Override `getFeedbackStream()` to provide a custom feedback source.
///
/// **Usage:**
/// ```dart
/// class _MyScreenState extends ConsumerState<MyScreen>
///     with FeedbackListenerMixin<MyScreen> {
///
///   @override
///   void initState() {
///     super.initState();
///     WidgetsBinding.instance.addPostFrameCallback((_) {
///       setupFeedbackListener();
///     });
///   }
///
///   // Optional: Override to use custom feedback source
///   // @override
///   // Stream<FeedbackEvent>? getFeedbackStream(BuildContext context) {
///   //   return customStream;
///   // }
/// }
/// ```
mixin FlyFeedbackListenerMixin<T extends StatefulWidget> on State<T> {
  StreamSubscription<FeedbackEvent>? _feedbackSubscription;
  FlyFeedbackHandler? _feedbackHandler;
  bool _isListening = false;

  /// Get the feedback stream to listen to
  ///
  /// Default implementation returns the lifecycle emitter's feedback stream.
  /// Override this to provide a custom feedback source (e.g., from a specific ViewModel).
  /// Return null to disable feedback listening.
  Stream<FeedbackEvent>? getFeedbackStream(BuildContext context) {
    try {
      final emitter = GlobalContainer.instance.read(lifecycleEmitterProvider);
      return emitter.getFeedbackStream();
    } catch (e) {
      debugPrint('⚠️ Error accessing lifecycle emitter: $e');
      return null;
    }
  }

  /// Get the feedback handler to use
  /// Override to provide custom handler, or use default
  FlyFeedbackHandler getFeedbackHandler() {
    return _feedbackHandler ??= CompositeFeedbackHandler([
      SnackbarFeedbackHandler(),
      DialogFeedbackHandler(),
      BottomSheetFeedbackHandler(),
      ToastFeedbackHandler(),
      BannerFeedbackHandler(),
    ]);
  }

  /// Setup feedback listener
  /// Call this in initState or didChangeDependencies after first frame
  /// Safe to call multiple times - will cancel previous subscription
  @protected
  void setupFeedbackListener() {
    if (_isListening) {
      debugPrint('⚠️ Feedback listener already set up');
      return;
    }

    if (!mounted) {
      debugPrint('⚠️ Cannot setup feedback listener - widget not mounted');
      return;
    }

    _feedbackSubscription?.cancel();

    final stream = getFeedbackStream(context);
    if (stream == null) {
      debugPrint('ℹ️ No feedback stream available');
      return;
    }

    _isListening = true;
    _feedbackSubscription = stream.listen(
      (event) {
        if (!mounted) return;
        _handleFeedbackEvent(event);
      },
      onError: (error, stackTrace) {
        debugPrint('❌ Feedback stream error: $error');
        onFeedbackStreamError(error, stackTrace);
      },
      onDone: () {
        debugPrint('ℹ️ Feedback stream closed');
        _isListening = false;
      },
      cancelOnError: false, // Continue listening after errors
    );
  }

  /// Handle a feedback event
  @protected
  void _handleFeedbackEvent(FeedbackEvent event) {
    if (!mounted) {
      debugPrint('⚠️ Cannot handle feedback - widget not mounted');
      return;
    }

    final handler = getFeedbackHandler();

    if (!handler.supports(event.display)) {
      onUnsupportedFeedback(event);
      return;
    }

    try {
      final ref = this is ConsumerState ? (this as ConsumerState).ref : null;
      handler.handle(context, event, ref);
      onFeedbackHandled(event);
    } catch (error, stackTrace) {
      onFeedbackHandlingError(event, error, stackTrace);
    }
  }

  /// Called when feedback stream has an error
  @protected
  void onFeedbackStreamError(Object error, StackTrace stackTrace) {
    // Override for custom error handling
    debugPrint('Feedback stream error: $error');
  }

  /// Called when feedback display type is not supported
  @protected
  void onUnsupportedFeedback(FeedbackEvent event) {
    debugPrint('⚠️ Unsupported feedback display: ${event.display}');
  }

  /// Called after feedback is successfully handled
  /// Override for analytics, logging, etc.
  @protected
  void onFeedbackHandled(FeedbackEvent event) {
    // Override to add analytics tracking
    // Example: Analytics.trackFeedback(event);
  }

  /// Called when there's an error handling feedback
  @protected
  void onFeedbackHandlingError(
    FeedbackEvent event,
    Object error,
    StackTrace stackTrace,
  ) {
    debugPrint('❌ Error handling feedback: $error');
    // Could show fallback UI here
  }

  /// Dispose feedback listener
  @protected
  void disposeFeedbackListener() {
    _isListening = false;
    _feedbackSubscription?.cancel();
    _feedbackSubscription = null;
  }

  @override
  void dispose() {
    disposeFeedbackListener();
    super.dispose();
  }
}

