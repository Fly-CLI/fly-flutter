import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_emitter.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_events.dart';
import 'package:foundation_project/core/lifecycle/managers/foundation_operation_stream_manager.dart';
import 'package:foundation_project/core/lifecycle/managers/navigation_stream_manager.dart';
import 'package:foundation_project/core/lifecycle/managers/screen_stream_manager.dart';

/// Provider for application lifecycle emitter
///
/// **Factory Pattern**: Creates default managers and registers them with emitter.
/// This is the ONLY place where default managers are created.
/// Defaults are NOT in emitter - ensures complete reusability.
///
/// The emitter is automatically disposed when the provider container
/// is disposed.
final lifecycleEmitterProvider =
    Provider<AppLifecycleEmitter>((ref) {
  final emitter = AppLifecycleEmitter();

  // Register default controllers
  emitter.register<NavigationEvent>(
    key: 'navigation',
    manager: NavigationStreamManager(),
  );

  emitter.register<ScreenEvent>(
    key: 'screen',
    manager: ScreenStreamManager(),
  );

  emitter.register<FoundationOperationEvent>(
    key: 'foundation_operation',
    manager: FoundationOperationStreamManager(),
  );

  // Note: Feedback events are handled through ViewModel streams directly
  // via FlyFeedbackEmitterMixin, not through the lifecycle emitter system.

  // Dispose emitter when provider is disposed
  ref.onDispose(() {
    emitter.dispose();
  });

  return emitter;
});
