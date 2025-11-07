import 'dart:async';
import 'package:foundation_project/foundation/di/dependency_container.dart';
import 'package:foundation_project/foundation/events/event_emitter.dart';
import 'package:foundation_project/foundation/events/app_event.dart';
import 'package:foundation_project/foundation/events/event_providers.dart';

/// Analytics plugin that listens to screen events
///
/// This plugin demonstrates how to build completely decoupled components
/// that react to foundation events without knowing about the
/// foundation system directly.
///
/// **Usage:**
/// ```dart
/// final plugin = AnalyticsEventPlugin();
/// plugin.initialize();
///
/// // Later, when disposing:
/// plugin.dispose();
/// ```
class AnalyticsEventPlugin {
  AppEventEmitter? _emitter;
  StreamSubscription<ScreenEvent>? _screenSubscription;
  final Map<String, DateTime> _screenViewTimes = {};
  final List<String> _screenViews = [];

  /// Initialize the plugin and start listening to events
  void initialize() {
    _emitter = DependencyContainer.instance.read(eventEmitterProvider);

    // Listen to screen events
    _screenSubscription = _emitter!.getStreamFor<ScreenEvent>().listen((event) {
      if (event is ScreenShownEvent) {
        _onScreenShown(event);
      } else if (event is ScreenHiddenEvent) {
        _onScreenHidden(event);
      }
    });
  }

  void _onScreenShown(ScreenShownEvent event) {
    _screenViewTimes[event.screenName] = DateTime.now();
    _screenViews.add(event.screenName);
    // In a real implementation, you would send analytics data here
    // e.g., analyticsService.trackScreenView(event.screenName);
  }

  void _onScreenHidden(ScreenHiddenEvent event) {
    final shownTime = _screenViewTimes[event.screenName];
    if (shownTime != null) {
      // In a real implementation, you would track screen duration
      // final duration = DateTime.now().difference(shownTime);
      // e.g., analyticsService.trackScreenDuration(event.screenName, duration);
      _screenViewTimes.remove(event.screenName);
    }
  }

  /// Get tracked screen views
  List<String> get trackedScreenViews => List.unmodifiable(_screenViews);

  /// Get screen view times
  Map<String, DateTime> get screenViewTimes => Map.unmodifiable(_screenViewTimes);

  /// Dispose the plugin and cancel subscriptions
  void dispose() {
    _screenSubscription?.cancel();
    _screenSubscription = null;
    _emitter = null;
    _screenViewTimes.clear();
    _screenViews.clear();
  }
}

