import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation_project/core/event_system/event_emitter.dart';
import 'package:foundation_project/core/event_system/events.dart';
import 'package:foundation_project/core/event_system/managers/event_stream_manager.dart';

/// Provider for application event emitter
///
/// **Factory Pattern**: Creates default managers and registers them with emitter.
/// This is the ONLY place where default managers are created.
/// Defaults are NOT in emitter - ensures complete reusability.
///
/// Uses type-safe registration via `registerType<T>()` which eliminates
/// the need for magic strings and empty manager classes.
///
/// The emitter is automatically disposed when the provider container
/// is disposed.
final eventEmitterProvider =
    Provider<AppEventEmitter>((ref) {
  final emitter = AppEventEmitter();

  // Register default controllers using type-safe registration
  _registerDefaultManagers(emitter);

  // Dispose emitter when provider is disposed
  ref.onDispose(() {
    emitter.dispose();
  });

  return emitter;
});

/// Register default event stream managers
///
/// This helper method centralizes the registration of default managers,
/// making it easier to add or remove default event types.
void _registerDefaultManagers(AppEventEmitter emitter) {
  // Register with backward-compatible string keys for existing code
  emitter.register<NavigationEvent>(
    key: 'navigation',
    manager: EventStreamManager.create<NavigationEvent>(),
  );

  emitter.register<ScreenEvent>(
    key: 'screen',
    manager: EventStreamManager.create<ScreenEvent>(),
  );

  emitter.register<FoundationOperationEvent>(
    key: 'foundation_operation',
    manager: EventStreamManager.create<FoundationOperationEvent>(),
  );

  emitter.register<FeedbackAppEvent>(
    key: 'feedback',
    manager: EventStreamManager.create<FeedbackAppEvent>(),
  );
}
