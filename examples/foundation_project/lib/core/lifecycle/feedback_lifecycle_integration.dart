import 'package:fly_feedback/fly_feedback.dart';
import 'package:foundation_project/core/di/global_container.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_emitter.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_events.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_providers.dart';
import 'package:foundation_project/core/lifecycle/managers/feedback_stream_manager.dart';

/// Mixin to integrate FlyFeedbackEmitterMixin with lifecycle emitter
///
/// This mixin bridges the standalone feedback emitter with the lifecycle system,
/// allowing feedback events to be emitted to both the ViewModel's stream and
/// the lifecycle emitter for centralized management.
///
/// Usage:
/// ```dart
/// class MyViewModel extends FlyViewModel<MyState>
///     with FeedbackLifecycleIntegration {
///   // Feedback events will be emitted to both streams
/// }
/// ```
mixin FeedbackLifecycleIntegration on Object {
  AppLifecycleEmitter? _cachedEmitter;

  /// Get the lifecycle emitter instance
  AppLifecycleEmitter? get _emitter {
    try {
      _cachedEmitter ??= GlobalContainer.instance.read(lifecycleEmitterProvider);
      return _cachedEmitter;
    } catch (e) {
      // Emitter not available - this is OK for standalone usage
      return null;
    }
  }

  /// Emit feedback to lifecycle emitter (called by ViewModel after emitting to its own stream)
  void emitFeedbackToLifecycle(FeedbackEvent event) {
    final emitter = _emitter;
    if (emitter == null) {
      // Lifecycle emitter not available - this is OK for standalone usage
      return;
    }

    try {
      // Emit wrapper event that extends LifecycleEvent for lifecycle system compatibility
      // The FeedbackStreamManager will handle both the wrapper stream and direct FeedbackEvent stream
      final wrapper = FeedbackEventWrapper(event);
      emitter.emit(wrapper);
    } catch (e) {
      // Silently handle errors - feedback will still work via ViewModel's stream
    }
  }
}

