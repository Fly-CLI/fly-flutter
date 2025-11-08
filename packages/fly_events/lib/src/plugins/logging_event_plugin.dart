import 'dart:async';
import 'package:fly_di/fly_di.dart';
import 'package:fly_logger/fly_logger.dart';
import '../event_emitter.dart';
import '../app_event.dart';
import '../event_providers.dart';

/// Logging plugin that logs all app events
///
/// This plugin demonstrates how to create a logging system that
/// listens to all foundation events for debugging and
/// observability purposes.
///
/// **Usage:**
/// ```dart
/// final plugin = LoggingEventPlugin();
/// plugin.initialize();
///
/// // Enable/disable logging:
/// plugin.enabled = false;
///
/// // Later, when disposing:
/// plugin.dispose();
/// ```
class LoggingEventPlugin {
  AppEventEmitter? _emitter;
  StreamSubscription<AppEvent>? _screenSubscription;
  StreamSubscription<AppEvent>? _operationSubscription;
  final FlyLogger _logger;
  /// Whether logging is enabled
  bool enabled = true;

  LoggingEventPlugin({required FlyLogger logger}) : _logger = logger;

  /// Initialize the plugin and start listening to events
  void initialize() {
    _emitter = DependencyContainer.instance.read(eventEmitterProvider);

    // Listen to screen events
    _screenSubscription = _emitter!.getStreamFor<ScreenEvent>().listen(
      (event) {
        if (enabled) {
          _logScreenEvent(event);
        }
      },
    );

    // Listen to foundation operation events
    _operationSubscription = _emitter!.getStreamFor<FoundationOperationEvent>().listen(
      (event) {
        if (enabled) {
          _logOperationEvent(event);
        }
      },
    );
  }

  void _logScreenEvent(ScreenEvent event) {
    if (event is ScreenShownEvent) {
      final fields = _convertMetadata(event.metadata);
      _logger.info(
        'Screen shown: ${event.screenName}',
        fields: fields,
      );
    } else if (event is ScreenHiddenEvent) {
      final fields = _convertMetadata(event.metadata);
      _logger.info(
        'Screen hidden: ${event.screenName}',
        fields: fields,
      );
    }
  }

  void _logOperationEvent(FoundationOperationEvent event) {
    if (event is AsyncOperationStartedEvent) {
      final fields = _convertMetadata(event.metadata);
      _logger.info(
        'Operation started: ${event.operationName} (id: ${event.operationId})',
        fields: fields,
      );
    } else if (event is AsyncOperationCompletedEvent) {
      final fields = _convertMetadata(event.metadata);
      _logger.info(
        'Operation completed: ${event.operationName} '
        '(id: ${event.operationId}, duration: ${event.duration.inMilliseconds}ms, '
        'success: ${event.success})',
        fields: fields,
      );
    } else if (event is AsyncOperationFailedEvent) {
      final fields = _convertMetadata(event.metadata);
      _logger.error(
        'Operation failed: ${event.operationName} '
        '(id: ${event.operationId}, duration: ${event.duration.inMilliseconds}ms, '
        'error: ${event.error})',
        fields: fields,
      );
    }
  }

  Map<String, Object?> _convertMetadata(Map<String, dynamic> metadata) {
    return metadata.map(
      (key, value) => MapEntry(key, value),
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

