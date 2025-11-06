import 'package:fly_feedback/fly_feedback.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_emitter.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_events.dart';
import 'package:foundation_project/core/lifecycle/managers/feedback_stream_manager.dart';

/// Extension for type-safe navigation event streams
extension NavigationStreamExtension on AppLifecycleEmitter {
  /// Get type-safe navigation event stream
  ///
  /// Returns a stream of NavigationEvent, or an empty stream if not registered.
  Stream<NavigationEvent> getNavigationStream() {
    final stream = getStream('navigation');
    if (stream == null) return const Stream<NavigationEvent>.empty();
    return stream.cast<NavigationEvent>();
  }
}

/// Extension for type-safe screen event streams
extension ScreenStreamExtension on AppLifecycleEmitter {
  /// Get type-safe screen event stream
  ///
  /// Returns a stream of ScreenEvent, or an empty stream if not registered.
  Stream<ScreenEvent> getScreenStream() {
    final stream = getStream('screen');
    if (stream == null) return const Stream<ScreenEvent>.empty();
    return stream.cast<ScreenEvent>();
  }
}

/// Extension for type-safe foundation operation event streams
extension FoundationOperationStreamExtension on AppLifecycleEmitter {
  /// Get type-safe foundation operation event stream
  ///
  /// Returns a stream of FoundationOperationEvent, or an empty stream if not registered.
  Stream<FoundationOperationEvent> getFoundationOperationStream() {
    final stream = getStream('foundation_operation');
    if (stream == null) return const Stream<FoundationOperationEvent>.empty();
    return stream.cast<FoundationOperationEvent>();
  }
}

/// Extension for type-safe feedback event streams
extension FeedbackStreamExtension on AppLifecycleEmitter {
  /// Get type-safe feedback event stream
  ///
  /// Returns a stream of FeedbackEvent, or an empty stream if not registered.
  /// Uses the FeedbackStreamManager's direct feedbackStream for type safety.
  Stream<FeedbackEvent> getFeedbackStream() {
    // Try to get the manager directly to access its feedbackStream
    // Since we can't easily access the manager through the emitter API,
    // we'll unwrap from the wrapper stream
    final stream = getStream('feedback');
    if (stream == null) return const Stream<FeedbackEvent>.empty();
    
    // The stream contains FeedbackEventWrapper, so we need to unwrap
    return stream
        .where((event) => event is FeedbackEventWrapper)
        .map((event) => (event as FeedbackEventWrapper).feedbackEvent);
  }
}

/// Extension for filtering events by type
extension LifecycleEmitterFilterExtension on AppLifecycleEmitter {
  /// Get events of a specific type from a stream
  ///
  /// [key] - The stream key
  /// Returns a stream that only emits events of type T
  Stream<T> getEventsOfType<T extends LifecycleEvent>(String key) {
    final stream = getStream(key);
    if (stream == null) return Stream<T>.empty();
    return stream.where((event) => event is T).cast<T>();
  }
}
