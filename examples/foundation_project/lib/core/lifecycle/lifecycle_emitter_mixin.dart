import 'package:flutter/foundation.dart';
import 'package:foundation_project/core/di/global_container.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_emitter.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_events.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_providers.dart';
import 'package:foundation_project/core/navigation/fly_router.dart';
import 'package:foundation_project/shared/localization/localizations.dart';

/// Mixin to add lifecycle event emission capability to any class
///
/// **Thread Safety:** This mixin is designed for single-threaded Flutter
/// main isolate usage. Stream operations should only be called
/// from the main isolate.
///
/// **Lifecycle:** This mixin provides access to the lifecycle emitter
/// via GlobalContainer. No disposal is needed as the emitter is managed
/// by the provider system.
///
/// Example:
/// ```dart
/// class MyService with LifecycleEmitterMixin {
///   Future<void> doWork() async {
///     emit(NavigationStartedEvent(feature: Feature.home));
///     // ... work ...
///     emit(NavigationCompletedEvent(feature: Feature.home));
///   }
/// }
/// ```
mixin LifecycleEmitterMixin {
  AppLifecycleEmitter? _cachedEmitter;
  bool _isDisposed = false;

  /// Get the lifecycle emitter instance
  ///
  /// Uses lazy initialization and caching for performance.
  /// Accesses the emitter via GlobalContainer.
  AppLifecycleEmitter get _emitter {
    if (_isDisposed) {
      debugPrint('⚠️ Warning: Accessing lifecycle emitter after disposal');
      throw StateError(localizations.lifecycleEmitterMixinDisposed);
    }

    if (_cachedEmitter == null) {
      try {
        _cachedEmitter = GlobalContainer.instance.read(lifecycleEmitterProvider);
      } catch (e) {
        final errorMessage = localizations.lifecycleEmitterAccessError(e.toString());
        debugPrint('❌ $errorMessage');
        rethrow;
      }
    }

    return _cachedEmitter!;
  }

  /// Check if mixin is disposed
  bool get isDisposed => _isDisposed;

  /// Emit a lifecycle event (generic API)
  ///
  /// Emits the event to all registered controllers that handle the event type.
  /// Returns true if the event was emitted, false if ignored.
  bool emit(LifecycleEvent event) {
    if (_isDisposed) {
      debugPrint('⚠️ Warning: Attempted to emit event after disposal');
      return false;
    }

    try {
      return _emitter.emit(event);
    } catch (e) {
      debugPrint('❌ Error emitting lifecycle event: $e');
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

  /// Dispose lifecycle emitter mixin
  ///
  /// Clears the cached emitter reference.
  /// Should be called when the object is disposed.
  void disposeLifecycleEmitter() {
    if (_isDisposed) return;

    _isDisposed = true;
    _cachedEmitter = null;
  }
}
