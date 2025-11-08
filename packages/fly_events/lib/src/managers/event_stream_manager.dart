import 'dart:async';
import 'package:flutter/foundation.dart';
import '../app_event.dart';

/// Interface for managing event streams
///
/// Provides a contract for stream management with:
/// - Lazy stream initialization
/// - Thread-safe operations
/// - Graceful disposal
///
/// Managers own the StreamController and handle all stream operations.
/// Emitter delegates to managers - no embedded controllers.
abstract class IEventStreamManager<T extends Event> {
  /// Stream of events
  Stream<T> get stream;

  /// Emit an event
  /// Returns true if emitted, false if ignored (disposed/no listeners)
  bool emit(T event);

  /// Check if manager is disposed
  bool get isDisposed;

  /// Dispose resources (closes StreamController)
  void dispose();
}

/// Base implementation of event stream manager
///
/// **Owns the StreamController** - this is the only place controllers exist.
/// Provides common functionality:
/// - Lazy stream initialization
/// - Broadcast stream controller
/// - Thread-safe emission
/// - Graceful error handling
///
/// **Thread Safety:** Designed for single-threaded Flutter main isolate usage.
abstract class EventStreamManager<T extends Event>
    implements IEventStreamManager<T> {
  StreamController<T>? _controller; // Manager owns this
  bool _isDisposed = false;

  /// Static factory method to create an event stream manager for a specific event type
  ///
  /// This eliminates the need for empty manager classes that just extend
  /// EventStreamManager. Use this static method instead of creating empty subclasses.
  ///
  /// Example:
  /// ```dart
  /// final manager = EventStreamManager.create<NavigationEvent>();
  /// ```
  static EventStreamManager<T> create<T extends Event>() {
    return _EventStreamManagerImpl<T>();
  }

  @override
  Stream<T> get stream {
    if (_isDisposed) {
      debugPrint('⚠️ Warning: Accessing stream after disposal');
      return Stream<T>.empty();
    }

    _controller ??= StreamController<T>.broadcast();
    return _controller!.stream;
  }

  @override
  bool emit(T event) {
    if (_isDisposed) {
      debugPrint('⚠️ Warning: Attempted to emit event after disposal');
      return false;
    }

    if (_controller == null) {
      // No listeners yet, skip silently (normal case)
      return false;
    }

    if (_controller!.isClosed) {
      debugPrint('⚠️ Warning: Stream controller is closed');
      return false;
    }

    try {
      _controller!.add(event);
      return true;
    } catch (e) {
      debugPrint('❌ Error emitting event: $e');
      return false;
    }
  }

  @override
  bool get isDisposed => _isDisposed;

  @override
  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;
    _controller?.close();
    _controller = null;
  }
}

/// Internal implementation class for factory-created managers
class _EventStreamManagerImpl<T extends Event>
    extends EventStreamManager<T> {
  // All functionality inherited from EventStreamManager base class
}

