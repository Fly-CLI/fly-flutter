import 'dart:async';
import 'package:foundation_project/core/di/global_container.dart';
import 'package:foundation_project/core/foundation/utils/app_logger.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_emitter.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_emitter_extensions.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_events.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_providers.dart';

/// Logging plugin that logs all lifecycle events
///
/// This plugin demonstrates how to create a logging system that
/// listens to all foundation lifecycle events for debugging and
/// observability purposes.
///
/// **Usage:**
/// ```dart
/// final plugin = LoggingLifecyclePlugin();
/// plugin.initialize();
///
/// // Enable/disable logging:
/// plugin.enabled = false;
///
/// // Later, when disposing:
/// plugin.dispose();
/// ```
class LoggingLifecyclePlugin {
  AppLifecycleEmitter? _emitter;
  StreamSubscription<LifecycleEvent>? _screenSubscription;
  StreamSubscription<LifecycleEvent>? _operationSubscription;
  final AppLogger _logger = AppLogger('LoggingLifecyclePlugin');
  /// Whether logging is enabled
  bool enabled = true;

  /// Initialize the plugin and start listening to events
  void initialize() {
    _emitter = GlobalContainer.instance.read(lifecycleEmitterProvider);

    // Listen to screen events
    _screenSubscription = _emitter!.getScreenStream().listen(
      (event) {
        if (enabled) {
          _logScreenEvent(event);
        }
      },
    );

    // Listen to foundation operation events
    _operationSubscription = _emitter!.getFoundationOperationStream().listen(
      (event) {
        if (enabled) {
          _logOperationEvent(event);
        }
      },
    );
  }

  void _logScreenEvent(ScreenEvent event) {
    if (event is ScreenShownEvent) {
      final customKeys = _convertMetadata(event.metadata);
      _logger.log(
        'Screen shown: ${event.screenName}',
        customKeys: customKeys,
      );
    } else if (event is ScreenHiddenEvent) {
      final customKeys = _convertMetadata(event.metadata);
      _logger.log(
        'Screen hidden: ${event.screenName}',
        customKeys: customKeys,
      );
    }
  }

  void _logOperationEvent(FoundationOperationEvent event) {
    if (event is AsyncOperationStartedEvent) {
      final customKeys = _convertMetadata(event.metadata);
      _logger.log(
        'Operation started: ${event.operationName} (id: ${event.operationId})',
        customKeys: customKeys,
      );
    } else if (event is AsyncOperationCompletedEvent) {
      final customKeys = _convertMetadata(event.metadata);
      _logger.log(
        'Operation completed: ${event.operationName} '
        '(id: ${event.operationId}, duration: ${event.duration.inMilliseconds}ms, '
        'success: ${event.success})',
        customKeys: customKeys,
      );
    } else if (event is AsyncOperationFailedEvent) {
      final customKeys = _convertMetadata(event.metadata);
      _logger.logError(
        'Operation failed: ${event.operationName} '
        '(id: ${event.operationId}, duration: ${event.duration.inMilliseconds}ms, '
        'error: ${event.error})',
        customKeys: customKeys,
      );
    }
  }

  Map<String, String> _convertMetadata(Map<String, dynamic> metadata) {
    return metadata.map(
      (key, value) => MapEntry(key, value.toString()),
    );
  }

  /// Dispose the plugin and cancel subscriptions
  void dispose() {
    _screenSubscription?.cancel();
    _screenSubscription = null;
    _operationSubscription?.cancel();
    _operationSubscription = null;
    _emitter = null;
  }
}

