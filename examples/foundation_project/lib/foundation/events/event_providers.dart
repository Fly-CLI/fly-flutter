import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fly_events/fly_events.dart';

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
///
/// **Note:** This provider only registers generic foundation events.
/// Application-specific events (like NavigationEvent) should be registered
/// separately in application code.
final eventEmitterProvider = Provider<AppEventEmitter>((ref) {
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
///
/// **Note:** Only registers generic foundation events. Application-specific
/// events should be registered separately.
void _registerDefaultManagers(AppEventEmitter emitter) {
  // Register default event types with string keys
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

