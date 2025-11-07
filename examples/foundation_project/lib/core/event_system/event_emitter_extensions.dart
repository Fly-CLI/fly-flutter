import 'package:foundation_project/core/event_system/event_emitter.dart';
import 'package:foundation_project/core/event_system/events.dart';

/// Extension for type-safe navigation event streams
///
/// **Deprecated**: Use `getStreamFor<NavigationEvent>()` instead.
/// This extension is kept for backward compatibility.
@Deprecated('Use getStreamFor<NavigationEvent>() instead')
extension NavigationStreamExtension on AppEventEmitter {
  /// Get type-safe navigation event stream
  ///
  /// Returns a stream of NavigationEvent, or an empty stream if not registered.
  Stream<NavigationEvent> getNavigationStream() {
    return getStreamFor<NavigationEvent>();
  }
}

/// Extension for type-safe screen event streams
///
/// **Deprecated**: Use `getStreamFor<ScreenEvent>()` instead.
/// This extension is kept for backward compatibility.
@Deprecated('Use getStreamFor<ScreenEvent>() instead')
extension ScreenStreamExtension on AppEventEmitter {
  /// Get type-safe screen event stream
  ///
  /// Returns a stream of ScreenEvent, or an empty stream if not registered.
  Stream<ScreenEvent> getScreenStream() {
    return getStreamFor<ScreenEvent>();
  }
}

/// Extension for type-safe foundation operation event streams
///
/// **Deprecated**: Use `getStreamFor<FoundationOperationEvent>()` instead.
/// This extension is kept for backward compatibility.
@Deprecated('Use getStreamFor<FoundationOperationEvent>() instead')
extension FoundationOperationStreamExtension on AppEventEmitter {
  /// Get type-safe foundation operation event stream
  ///
  /// Returns a stream of FoundationOperationEvent, or an empty stream if not registered.
  Stream<FoundationOperationEvent> getFoundationOperationStream() {
    return getStreamFor<FoundationOperationEvent>();
  }
}

/// Extension for type-safe feedback event streams
///
/// **Deprecated**: Use `getStreamFor<FeedbackAppEvent>()` instead.
/// This extension is kept for backward compatibility.
@Deprecated('Use getStreamFor<FeedbackAppEvent>() instead')
extension FeedbackStreamExtension on AppEventEmitter {
  /// Get type-safe feedback event stream
  ///
  /// Returns a stream of FeedbackAppEvent, or an empty stream if not registered.
  Stream<FeedbackAppEvent> getFeedbackStream() {
    return getStreamFor<FeedbackAppEvent>();
  }
}

/// Extension for filtering events by type
///
/// **Deprecated**: Use `getStreamFor<T>()` instead for type-safe access.
/// This extension is kept for backward compatibility when filtering by key.
@Deprecated('Use getStreamFor<T>() instead for type-safe access')
extension EventEmitterFilterExtension on AppEventEmitter {
  /// Get events of a specific type from a stream
  ///
  /// [key] - The stream key
  /// Returns a stream that only emits events of type T
  Stream<T> getEventsOfType<T extends AppEvent>(String key) {
    try {
      final stream = getStream(key);
      if (stream == null) return Stream<T>.empty();
      return stream.where((event) => event is T).cast<T>();
    } on StateError {
      return Stream<T>.empty();
    }
  }
}
