import 'package:foundation_project/core/lifecycle/lifecycle_emitter.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_events.dart';

/// Extension for type-safe navigation event streams
extension NavigationStreamExtension on AppLifecycleEmitter {
  /// Get type-safe navigation event stream
  ///
  /// Returns a stream of NavigationEvent, or an empty stream if not registered.
  Stream<NavigationEvent> getNavigationStream() {
    try {
      final stream = getStream('navigation');
      if (stream == null) return const Stream<NavigationEvent>.empty();
      return stream.cast<NavigationEvent>();
    } on StateError {
      return const Stream<NavigationEvent>.empty();
    }
  }
}

/// Extension for type-safe screen event streams
extension ScreenStreamExtension on AppLifecycleEmitter {
  /// Get type-safe screen event stream
  ///
  /// Returns a stream of ScreenEvent, or an empty stream if not registered.
  Stream<ScreenEvent> getScreenStream() {
    try {
      final stream = getStream('screen');
      if (stream == null) return const Stream<ScreenEvent>.empty();
      return stream.cast<ScreenEvent>();
    } on StateError {
      return const Stream<ScreenEvent>.empty();
    }
  }
}

/// Extension for type-safe foundation operation event streams
extension FoundationOperationStreamExtension on AppLifecycleEmitter {
  /// Get type-safe foundation operation event stream
  ///
  /// Returns a stream of FoundationOperationEvent, or an empty stream if not registered.
  Stream<FoundationOperationEvent> getFoundationOperationStream() {
    try {
      final stream = getStream('foundation_operation');
      if (stream == null) return const Stream<FoundationOperationEvent>.empty();
      return stream.cast<FoundationOperationEvent>();
    } on StateError {
      return const Stream<FoundationOperationEvent>.empty();
    }
  }
}

/// Extension for type-safe feedback event streams
extension FeedbackStreamExtension on AppLifecycleEmitter {
  /// Get type-safe feedback event stream
  ///
  /// Returns a stream of FeedbackLifecycleEvent, or an empty stream if not registered.
  Stream<FeedbackLifecycleEvent> getFeedbackStream() {
    try {
      final stream = getStream('feedback');
      if (stream == null) return const Stream<FeedbackLifecycleEvent>.empty();
      return stream.cast<FeedbackLifecycleEvent>();
    } on StateError {
      return const Stream<FeedbackLifecycleEvent>.empty();
    }
  }
}

/// Extension for filtering events by type
extension LifecycleEmitterFilterExtension on AppLifecycleEmitter {
  /// Get events of a specific type from a stream
  ///
  /// [key] - The stream key
  /// Returns a stream that only emits events of type T
  Stream<T> getEventsOfType<T extends LifecycleEvent>(String key) {
    try {
      final stream = getStream(key);
      if (stream == null) return Stream<T>.empty();
      return stream.where((event) => event is T).cast<T>();
    } on StateError {
      return Stream<T>.empty();
    }
  }
}
