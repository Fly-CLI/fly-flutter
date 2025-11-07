# Lifecycle Event System

A generic, registry-based event system for component communication in Flutter applications. This
system enables complete decoupling between components through event-driven architecture.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Core Concepts](#core-concepts)
- [Quick Start](#quick-start)
- [Usage Guide](#usage-guide)
- [Best Practices](#best-practices)
- [DOs and DON'Ts](#dos-and-donts)
- [Common Patterns](#common-patterns)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Advanced Usage](#advanced-usage)

## Overview

The lifecycle event system provides a **generic, registry-based** mechanism for components to
communicate without direct dependencies. It follows these key principles:

- **Generic APIs**: All methods work with `LifecycleEvent` base class
- **Dynamic Registry**: Controllers registered at runtime, no hardcoding
- **Complete Decoupling**: Components don't need to know about each other
- **Type Safety**: Generic type parameters ensure type safety
- **Extensibility**: Easy to add new event types without modifying core system

### Key Benefits

1. **Zero Direct Dependencies**: Components communicate via events, not direct calls
2. **Pluggability**: Components can be enabled/disabled without breaking compilation
3. **Testability**: Easy to mock and test components in isolation
4. **Flexibility**: Add new event types dynamically
5. **Maintainability**: Clear separation of concerns

## Architecture

### System Components

```
┌─────────────────────────────────────────────────────────┐
│              AppLifecycleEmitter                        │
│  (Generic Registry - No Concrete Types)                 │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │  ControllerRegistryEntry                         │  │
│  │  - key: String                                   │  │
│  │  - eventType: Type                              │  │
│  │  - manager: IEventStreamManager<LifecycleEvent> │  │
│  └──────────────────────────────────────────────────┘  │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐                    │
│  │ Navigation   │  │    Screen     │                    │
│  │ Manager      │  │   Manager     │                    │
│  └──────────────┘  └──────────────┘                    │
│                                                          │
│  register<T>()  │  getStream(key)  │  emit(event)      │
└─────────────────────────────────────────────────────────┘
```

### File Structure

```
lib/core/lifecycle/
├── lifecycle_events.dart              # Event class definitions
├── lifecycle_emitter.dart             # Generic registry emitter
├── lifecycle_emitter_mixin.dart       # Mixin for easy emission
├── lifecycle_providers.dart           # Riverpod providers
└── managers/                           # Stream managers
    ├── event_stream_manager.dart       # Base interface/implementation
    ├── navigation_stream_manager.dart   # Navigation events manager
    └── screen_stream_manager.dart      # Screen events manager
```

## Core Concepts

### 1. LifecycleEvent

Base sealed class for all events. All events must extend this class.

```dart
sealed class LifecycleEvent {
  final String id;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
}
```

### 2. Event Stream Managers

Managers own the `StreamController` and handle stream operations. Each manager handles one event type.

```dart
abstract class IEventStreamManager<T extends LifecycleEvent> {
  Stream<T> get stream;
  bool emit(T event);
  bool get isDisposed;
  void dispose();
}
```

### 3. AppLifecycleEmitter

Generic registry that manages controllers dynamically. **Zero concrete event types** in this class.

```dart
class AppLifecycleEmitter {
  void register<T extends LifecycleEvent>({required String key, required IEventStreamManager<T> manager});
  Stream<LifecycleEvent>? getStream(String key);
  bool emit(LifecycleEvent event);
  void dispose();
}
```

## Quick Start

### 1. Get the Emitter

```dart
import 'package:foundation_project/core/providers/providers.dart';
import 'package:foundation_project/core/di/global_container.dart';

final emitter = GlobalContainer.instance.read(lifecycleEmitterProvider);
```

### 2. Emit Events

```dart
// Generic API
emitter.emit(NavigationStartedEvent(feature: Feature.home));

// Using mixin (recommended)
class MyService with LifecycleEmitterMixin {
  void doWork() {
    emit(NavigationStartedEvent(feature: Feature.tasks));
  }
}
```

### 3. Listen to Events

```dart
final stream = emitter.getStream('navigation');
stream?.listen((event) {
  if (event is NavigationStartedEvent) {
    print('Navigation to ${event.feature.name} started');
  }
});
```

## Usage Guide

### Registering Controllers

Controllers are registered in the provider (default setup) or dynamically:

```dart
// In provider (default setup)
final emitter = AppLifecycleEmitter();
emitter.register<NavigationEvent>(
  key: 'navigation',
  manager: NavigationStreamManager(),
);

// Register custom controller
emitter.register<CustomEvent>(
  key: 'custom',
  manager: CustomStreamManager(),
);
```

### Emitting Events

#### Method 1: Direct Emitter Access

```dart
final emitter = GlobalContainer.instance.read(lifecycleEmitterProvider);
emitter.emit(NavigationStartedEvent(feature: Feature.home));
```

#### Method 2: Using Mixin (Recommended)

```dart
class NavigationService with LifecycleEmitterMixin {
  void navigateTo(Feature feature) {
    emit(NavigationStartedEvent(feature: feature));
    // ... navigation logic ...
    emit(NavigationCompletedEvent(feature: feature));
  }
}
```

#### Method 3: Convenience Methods (Mixin)

```dart
class MyViewModel with LifecycleEmitterMixin {
  void loadData() {
    emitNavigationStarted(Feature.home);
    // ... work ...
    emitNavigationCompleted(Feature.home);
  }
}
```

### Listening to Events

#### Method 1: Direct Stream Access

```dart
final emitter = GlobalContainer.instance.read(lifecycleEmitterProvider);
final stream = emitter.getStream('navigation');

stream?.listen((event) {
  if (event is NavigationStartedEvent) {
    handleNavigationStarted(event);
  } else if (event is NavigationCompletedEvent) {
    handleNavigationCompleted(event);
  }
});
```

#### Method 2: Type-Safe Stream (Recommended)

```dart
// Create extension for type safety
extension NavigationStreamExtension on AppLifecycleEmitter {
  Stream<NavigationEvent> getNavigationStream() {
    return getStream('navigation')?.cast<NavigationEvent>() 
      ?? Stream<NavigationEvent>.empty();
  }
}

// Usage
emitter.getNavigationStream().listen((event) {
  // Type-safe: event is NavigationEvent
  if (event is NavigationStartedEvent) {
    // Handle started
  }
});
```

#### Method 3: In Service Constructor

```dart
class AnalyticsService {
  final AppLifecycleEmitter _emitter;
  StreamSubscription<LifecycleEvent>? _subscription;

  AnalyticsService(this._emitter) {
    _subscription = _emitter.getStream('navigation')?.listen((event) {
      if (event is NavigationStartedEvent) {
        trackNavigation(event.feature);
      }
    });
  }

  void dispose() {
    _subscription?.cancel();
  }
}
```

### Creating Custom Event Types

1. **Extend LifecycleEvent** (or a base event class):

```dart
sealed class CustomEvent extends LifecycleEvent {
  final String customData;
  
  CustomEvent({
    required this.customData,
    super.id,
    super.timestamp,
    super.metadata,
  });
}

class CustomEventStarted extends CustomEvent {
  CustomEventStarted({
    required super.customData,
    super.id,
    super.timestamp,
    super.metadata,
  });
}
```

2. **Create a Stream Manager**:

```dart
class CustomStreamManager extends EventStreamManager<CustomEvent> {
  // Base class handles everything
}
```

3. **Register the Controller**:

```dart
emitter.register<CustomEvent>(
  key: 'custom',
  manager: CustomStreamManager(),
);
```

4. **Use It**:

```dart
emitter.emit(CustomEventStarted(customData: 'test'));
```

## Best Practices

### 1. Use Mixin for Event Emission

**✅ DO:**
```dart
class MyService with LifecycleEmitterMixin {
  void doWork() {
    emit(NavigationStartedEvent(feature: Feature.home));
  }
}
```

**❌ DON'T:**
```dart
class MyService {
  void doWork() {
    final emitter = GlobalContainer.instance.read(lifecycleEmitterProvider);
    emitter.emit(NavigationStartedEvent(feature: Feature.home));
  }
}
```

**Why:** Mixin provides automatic error handling and cleaner code.

### 2. Always Dispose Subscriptions

**✅ DO:**
```dart
class MyService {
  StreamSubscription<LifecycleEvent>? _subscription;
  
  void initialize() {
    _subscription = emitter.getStream('navigation')?.listen(...);
  }
  
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
```

**❌ DON'T:**
```dart
// Creating subscription without storing reference
emitter.getStream('navigation')?.listen(...); // Memory leak!
```

**Why:** Unsubscribed streams can cause memory leaks.

### 3. Use Type Checking for Event Handling

**✅ DO:**
```dart
stream.listen((event) {
  if (event is NavigationStartedEvent) {
    handleNavigationStarted(event);
  } else if (event is NavigationCompletedEvent) {
    handleNavigationCompleted(event);
  }
});
```

**❌ DON'T:**
```dart
stream.listen((event) {
  // Don't assume event type
  event.feature; // Error: LifecycleEvent doesn't have 'feature'
});
```

**Why:** Streams return `LifecycleEvent` base class, use type checking for specific types.

### 4. Handle Missing Streams Gracefully

**✅ DO:**
```dart
final stream = emitter.getStream('navigation');
if (stream != null) {
  stream.listen(...);
} else {
  // Handle case where controller not registered
  logger.warning('Navigation stream not available');
}
```

**❌ DON'T:**
```dart
emitter.getStream('navigation')!.listen(...); // Crashes if null
```

**Why:** Controllers may not be registered, always check for null.

### 5. Use Descriptive Keys

**✅ DO:**
```dart
emitter.register<NavigationEvent>(
  key: 'navigation',
  manager: NavigationStreamManager(),
);
```

**❌ DON'T:**
```dart
emitter.register<NavigationEvent>(
  key: 'nav', // Too short/ambiguous
  manager: NavigationStreamManager(),
);
```

**Why:** Clear keys make code more maintainable and debuggable.

### 6. Emit Events at Appropriate Times

**✅ DO:**
```dart
void navigateTo(Feature feature) {
  emit(NavigationStartedEvent(feature: feature));
  try {
    Navigator.pushNamed(context, feature.route);
    emit(NavigationCompletedEvent(feature: feature, result: true));
  } catch (e) {
    emit(NavigationCompletedEvent(feature: feature, result: false));
  }
}
```

**❌ DON'T:**
```dart
// Don't emit events inside async operations without proper handling
Future<void> navigate() async {
  emit(NavigationStartedEvent(...));
  await Future.delayed(Duration(seconds: 1)); // Event emitted but navigation not started
}
```

**Why:** Events should accurately reflect the actual state of operations.

### 7. Keep Events Pure Data

**✅ DO:**
```dart
class NavigationStartedEvent extends NavigationEvent {
  final Feature feature;
  final Map<String, dynamic> metadata;
  
  NavigationStartedEvent({
    required this.feature,
    this.metadata = const {},
  });
}
```

**❌ DON'T:**
```dart
class NavigationStartedEvent extends NavigationEvent {
  final VoidCallback onComplete; // Don't add callbacks
  final BuildContext context; // Don't add UI dependencies
}
```

**Why:** Events should be serializable pure data objects.

## DOs and DON'Ts

### DOs

✅ **DO use the mixin** for event emission in services and ViewModels
✅ **DO dispose subscriptions** in service dispose methods
✅ **DO use type checking** (`is` keyword) when handling events
✅ **DO handle null streams** gracefully
✅ **DO use descriptive keys** for controller registration
✅ **DO emit events synchronously** when operations start/complete
✅ **DO keep events immutable** and pure data
✅ **DO register controllers** in providers or initialization code
✅ **DO check emitter disposal** before emitting events
✅ **DO use sealed classes** for event type hierarchies

### DON'Ts

❌ **DON'T store BuildContext** in events
❌ **DON'T add callbacks** or functions to events
❌ **DON'T create subscriptions** without storing references
❌ **DON'T assume stream exists** - always check for null
❌ **DON'T use force unwrap** (`!`) on streams
❌ **DON'T emit events** from multiple threads (Flutter main isolate only)
❌ **DON'T register controllers** multiple times with same key
❌ **DON'T dispose emitter** while subscriptions are active
❌ **DON'T access concrete event properties** without type checking
❌ **DON'T create circular dependencies** via events

## Common Patterns

### Pattern 1: Service Listening to Events

```dart
class AnalyticsService {
  final AppLifecycleEmitter _emitter;
  StreamSubscription<LifecycleEvent>? _subscription;

  AnalyticsService(this._emitter) {
    _initialize();
  }

  void _initialize() {
    _subscription = _emitter.getStream('navigation')?.listen(
      (event) {
        if (event is NavigationStartedEvent) {
          _trackNavigation(event.feature);
        }
      },
      onError: (error) {
        // Handle errors gracefully
      },
    );
  }

  void _trackNavigation(Feature feature) {
    // Analytics logic
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
```

### Pattern 2: ViewModel Emitting Events

```dart
class TaskListViewModel extends ViewModel<TaskListState> 
    with LifecycleEmitterMixin {
  
  Future<void> loadTasks() async {
    emitScreenShown(screenName: 'task_list');
    
    try {
      final tasks = await repository.getTasks();
      state = state.copyWith(tasks: tasks);
    } catch (e) {
      // Handle error appropriately
      debugPrint('Failed to load tasks: $e');
    }
  }
}
```

### Pattern 3: Multiple Listeners for Same Event

```dart
// Multiple services can listen to the same stream
class AnalyticsService {
  void initialize(AppLifecycleEmitter emitter) {
    emitter.getStream('navigation')?.listen((event) {
      // Analytics tracking
    });
  }
}

class LoggingService {
  void initialize(AppLifecycleEmitter emitter) {
    emitter.getStream('navigation')?.listen((event) {
      // Logging
    });
  }
}
```

### Pattern 4: Custom Event Type

```dart
// 1. Define event
sealed class PaymentEvent extends LifecycleEvent {
  final String paymentId;
  
  PaymentEvent({
    required this.paymentId,
    super.id,
    super.timestamp,
    super.metadata,
  });
}

class PaymentProcessedEvent extends PaymentEvent {
  final double amount;
  
  PaymentProcessedEvent({
    required super.paymentId,
    required this.amount,
    super.id,
    super.timestamp,
    super.metadata,
  });
}

// 2. Create manager
class PaymentStreamManager extends EventStreamManager<PaymentEvent> {}

// 3. Register in provider
emitter.register<PaymentEvent>(
  key: 'payment',
  manager: PaymentStreamManager(),
);

// 4. Use
emitter.emit(PaymentProcessedEvent(
  paymentId: '123',
  amount: 99.99,
));
```

## Testing

### Unit Testing Event Emission

```dart
test('should emit navigation event', () {
  final emitter = AppLifecycleEmitter();
  emitter.register<NavigationEvent>(
    key: 'navigation',
    manager: NavigationStreamManager(),
  );
  
  final events = <LifecycleEvent>[];
  emitter.getStream('navigation')?.listen(events.add);
  
  emitter.emit(NavigationStartedEvent(feature: Feature.home));
  
  expect(events.length, 1);
  expect(events[0], isA<NavigationStartedEvent>());
  expect((events[0] as NavigationStartedEvent).feature, Feature.home);
});
```

### Testing Event Listeners

```dart
test('service listens to navigation events', () async {
  final emitter = AppLifecycleEmitter();
  emitter.register<NavigationEvent>(
    key: 'navigation',
    manager: NavigationStreamManager(),
  );
  
  final service = AnalyticsService(emitter);
  
  emitter.emit(NavigationStartedEvent(feature: Feature.tasks));
  
  // Wait for async processing
  await Future.delayed(Duration(milliseconds: 100));
  
  expect(service.trackedFeatures, contains(Feature.tasks));
  
  service.dispose();
});
```

### Mocking Emitter in Tests

```dart
class MockLifecycleEmitter extends AppLifecycleEmitter {
  final List<LifecycleEvent> emittedEvents = [];
  
  MockLifecycleEmitter() : super();
  
  @override
  bool emit(LifecycleEvent event) {
    emittedEvents.add(event);
    return true;
  }
}

test('view model emits events', () {
  final mockEmitter = MockLifecycleEmitter();
  final viewModel = MyViewModel();
  // Inject mock emitter
  
  viewModel.loadData();
  
  expect(mockEmitter.emittedEvents.length, greaterThan(0));
});
```

## Troubleshooting

### Issue: Stream Returns Null

**Problem:** `getStream('navigation')` returns null

**Solution:**
```dart
// Check if controller is registered
if (!emitter.isRegistered('navigation')) {
  // Register controller
  emitter.register<NavigationEvent>(
    key: 'navigation',
    manager: NavigationStreamManager(),
  );
}

// Or handle null gracefully
final stream = emitter.getStream('navigation');
if (stream != null) {
  stream.listen(...);
}
```

### Issue: Events Not Being Received

**Problem:** Events emitted but listeners not receiving them

**Checklist:**
1. ✅ Controller registered before emitting events?
2. ✅ Subscription active (not cancelled)?
3. ✅ Event type matches controller type?
4. ✅ Emitter not disposed?

**Solution:**
```dart
// Verify registration
print('Registered keys: ${emitter.registeredKeys}');

// Verify subscription
_subscription = emitter.getStream('navigation')?.listen(
  (event) {
    print('Received: $event'); // Debug
  },
);

// Verify event type
emitter.emit(NavigationStartedEvent(...)); // Correct type
```

### Issue: Memory Leaks

**Problem:** Subscriptions not being cancelled

**Solution:**
```dart
class MyService {
  StreamSubscription<LifecycleEvent>? _subscription;
  
  void initialize() {
    _subscription = emitter.getStream('navigation')?.listen(...);
  }
  
  void dispose() {
    _subscription?.cancel(); // ALWAYS cancel
    _subscription = null;
  }
}
```

### Issue: Type Cast Errors

**Problem:** Trying to access properties without type checking

**Solution:**
```dart
// ❌ Wrong
stream.listen((event) {
  event.feature; // Error: LifecycleEvent doesn't have 'feature'
});

// ✅ Correct
stream.listen((event) {
  if (event is NavigationEvent) {
    print(event.feature); // Type-safe
  }
});
```

### Issue: Duplicate Registration

**Problem:** Registering controller with same key twice

**Solution:**
```dart
// Check before registering
if (!emitter.isRegistered('navigation')) {
  emitter.register<NavigationEvent>(
    key: 'navigation',
    manager: NavigationStreamManager(),
  );
}

// Or use try-catch
try {
  emitter.register<NavigationEvent>(...);
} on StateError catch (e) {
  // Key already exists
}
```

## Advanced Usage

### Dynamic Controller Registration

```dart
class PluginManager {
  final AppLifecycleEmitter _emitter;
  
  PluginManager(this._emitter);
  
  void registerPlugin(String key, IEventStreamManager<LifecycleEvent> manager) {
    _emitter.register(
      key: key,
      manager: manager,
    );
  }
  
  void unregisterPlugin(String key) {
    _emitter.unregister(key);
  }
}
```

### Filtering Events by Type

```dart
extension LifecycleEmitterFilterExtension on AppLifecycleEmitter {
  Stream<T> getEventsOfType<T extends LifecycleEvent>(String key) {
    return getStream(key)?.whereType<T>() ?? Stream<T>.empty();
  }
}

// Usage
emitter.getEventsOfType<NavigationStartedEvent>('navigation')
  .listen((event) {
    // Only NavigationStartedEvent, not NavigationCompletedEvent
  });
```

### Event Batching

```dart
class BatchedEmitter {
  final AppLifecycleEmitter _emitter;
  final List<LifecycleEvent> _pendingEvents = [];
  
  void emit(LifecycleEvent event) {
    _pendingEvents.add(event);
  }
  
  void flush() {
    for (final event in _pendingEvents) {
      _emitter.emit(event);
    }
    _pendingEvents.clear();
  }
}
```

### Event Middleware

```dart
class EventMiddleware {
  final AppLifecycleEmitter _emitter;
  
  bool emit(LifecycleEvent event) {
    // Add logging
    print('Emitting: ${event.runtimeType}');
    
    // Transform if needed
    final transformedEvent = _transform(event);
    
    // Emit
    return _emitter.emit(transformedEvent);
  }
  
  LifecycleEvent _transform(LifecycleEvent event) {
    // Add metadata, etc.
    return event;
  }
}
```

## Summary

The lifecycle event system provides a powerful, generic mechanism for component communication:

- **Generic APIs** work with `LifecycleEvent` base class
- **Dynamic registry** allows runtime controller registration
- **Zero hardcoding** of event types in emitter
- **Type-safe** registration and emission
- **Completely decoupled** components

Follow the best practices and patterns outlined in this guide to build maintainable, testable, and
extensible applications.

