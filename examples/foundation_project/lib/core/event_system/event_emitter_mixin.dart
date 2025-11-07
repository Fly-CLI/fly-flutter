import 'package:flutter/foundation.dart';
import 'package:foundation_project/core/di/global_container.dart';
import 'package:foundation_project/core/event_system/event_emitter.dart';
import 'package:foundation_project/core/event_system/events.dart';
import 'package:foundation_project/core/event_system/event_providers.dart';
import 'package:foundation_project/shared/navigation/feature_screen_type.dart';

/// Mixin to add app event emission capability to any class
///
/// **Thread Safety:** This mixin is designed for single-threaded Flutter
/// main isolate usage. Stream operations should only be called
/// from the main isolate.
///
/// **Lifecycle:** This mixin provides access to the event emitter
/// via GlobalContainer. The emitter is managed by the provider system
/// and handles its own lifecycle, so no disposal is needed from the mixin.
///
/// Example:
/// ```dart
/// class MyService with EventEmitterMixin {
///   Future<void> doWork() async {
///     emit(NavigationStartedEvent(feature: Feature.home));
///     // ... work ...
///     emit(NavigationCompletedEvent(feature: Feature.home));
///   }
/// }
/// ```
mixin EventEmitterMixin {
  AppEventEmitter? _cachedEmitter;

  /// Get the event emitter instance
  ///
  /// Uses lazy initialization and caching for performance.
  /// Accesses the emitter via GlobalContainer.
  AppEventEmitter get _emitter {
    if (_cachedEmitter == null) {
      try {
        _cachedEmitter = GlobalContainer.instance.read(eventEmitterProvider);
      } catch (e) {
        debugPrint('❌ Error accessing event emitter: $e');
        rethrow;
      }
    }

    return _cachedEmitter!;
  }

  /// Emit an app event (generic API)
  ///
  /// Emits the event to all registered controllers that handle the event type.
  /// Returns true if the event was emitted, false if ignored.
  bool emit(AppEvent event) {
    try {
      return _emitter.emit(event);
    } catch (e) {
      debugPrint('❌ Error emitting app event: $e');
      return false;
    }
  }

  /// Emit a navigation started event (convenience method)
  void emitNavigationStarted(
    FeatureScreenType feature, {
    Map<String, dynamic> metadata = const {},
  }) {
    emit(
      NavigationStartedEvent(
        feature: feature,
        metadata: metadata,
      ),
    );
  }

  /// Emit a navigation completed event (convenience method)
  void emitNavigationCompleted(
    FeatureScreenType feature, {
    dynamic result,
    Map<String, dynamic> metadata = const {},
  }) {
    emit(
      NavigationCompletedEvent(
        feature: feature,
        result: result,
        metadata: metadata,
      ),
    );
  }

  /// Emit a screen shown event (convenience method)
  void emitScreenShown({
    required String screenName,
    Map<String, dynamic> metadata = const {},
  }) {
    emit(
      ScreenShownEvent(
        screenName: screenName,
        metadata: metadata,
      ),
    );
  }

  /// Emit a screen hidden event (convenience method)
  void emitScreenHidden({
    required String screenName,
    Map<String, dynamic> metadata = const {},
  }) {
    emit(
      ScreenHiddenEvent(
        screenName: screenName,
        metadata: metadata,
      ),
    );
  }
}
