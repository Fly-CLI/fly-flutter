# fly_events

Event system with plugin architecture for analytics, logging, and performance.

## Features

- Generic event emitter with type-safe registration
- Event stream management
- Plugin architecture for extensibility
- Riverpod provider integration
- JSON serialization support

## Usage

```dart
import 'package:fly_events/fly_events.dart';

// Get event emitter from provider
final emitter = ref.read(eventEmitterProvider);

// Register event type
emitter.registerType<NavigationEvent>();

// Emit events
emitter.emit(NavigationStartedEvent(feature: Feature.home));

// Listen to events
emitter.getStreamFor<NavigationEvent>().listen((event) {
  if (event is NavigationStartedEvent) {
    // Handle navigation started
  }
});
```

## Event Emitter Mixin

```dart
class MyService with EventEmitterMixin {
  Future<void> doWork() async {
    emit(ScreenShownEvent(screenName: 'home'));
    // ... work ...
    emit(ScreenHiddenEvent(screenName: 'home'));
  }
}
```

## Plugins

```dart
// Analytics plugin
final analyticsPlugin = AnalyticsEventPlugin();
analyticsPlugin.initialize();

// Logging plugin
final loggingPlugin = LoggingEventPlugin(logger: logger);
loggingPlugin.initialize();

// Performance plugin
final performancePlugin = PerformanceEventPlugin();
performancePlugin.initialize();
final metrics = performancePlugin.getMetrics();
```

