# Navigation Service

Router-agnostic navigation service for Fly MVVM foundation components with generic route type support.

## Overview

The NavigationService provides a clean abstraction over navigation operations with support for generic route types, allowing projects to use:
- String routes (e.g., `/home`)
- Feature enums (e.g., `Feature.home`)
- Custom route types

## Generic Route Types

The NavigationService is generic with a route type parameter `R`:

```dart
abstract class NavigationService<R> {
  Future<T?> navigateTo<T>(R route, {Object? arguments});
  // ... other methods
}
```

### Implementation Examples

**String-based service:**
```dart
NavigationService<String> service = DefaultNavigationService(...);
await service.navigateTo('/home');
```

**Feature enum-based service:**
```dart
// Note: FeatureScreenType enum is defined in your application layer
// (e.g., shared/navigation/feature_screen_type.dart)
NavigationService<FeatureScreenType> service = FlyRouter.instance;
await service.navigateTo(FeatureScreenType.home);
```

## Usage

### Basic Usage with String Routes

Access the service via Riverpod provider:

```dart
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () {
        ref.read(navigationServiceProvider).navigateTo('/home');
      },
      child: Text('Navigate'),
    );
  }
}
```

### Type-Safe Navigation with Feature Enum

Use AppNavigation directly for type-safe navigation:

```dart
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () {
        AppNavigation.instance.navigateTo(Feature.home);
      },
      child: Text('Navigate'),
    );
  }
}
```

### In FlyScreen

FlyScreen no longer includes NavigationMixin. Access the service directly:

```dart
class MyScreen extends FlyScreen<MyViewModel, MyState> {
  @override
  Widget buildContent(BuildContext context, MyViewModel viewModel, MyState state, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () {
        // String-based service
        ref.read(navigationServiceProvider).navigateTo('/details');
        
        // Or Feature enum-based service
        // Note: FeatureScreenType is defined in application layer
        FlyRouter.instance.navigateTo(FeatureScreenType.taskDetail);
      },
      child: Text('Navigate'),
    );
  }
}
```

### Available Methods

- `navigateTo<T>(R route, {Object? arguments})` - Navigate to a route
- `navigateBack<T>([T? result])` - Navigate back with optional result
- `navigateReplace<T>(R route, {Object? arguments})` - Replace current route
- `navigateClearStack<T>(R route, {Object? arguments})` - Clear stack and navigate
- `canGoBack()` - Check if navigation back is possible

## Custom Implementations

### Override Provider for GoRouter

To use GoRouter instead of default Navigator:

```dart
final container = ProviderContainer(
  overrides: [
    navigationServiceProvider.overrideWithValue(
      GoRouterNavigationService(router: AppRouter.router),
    ),
  ],
);
```

### Create Custom Implementation

Implement the `NavigationService` interface with your route type:

```dart
// String-based service
class CustomNavigationService implements NavigationService<String> {
  @override
  Future<T?> navigateTo<T>(String route, {Object? arguments}) {
    // Your custom implementation
  }
  
  // Implement other methods...
}

// Feature enum-based service
// Note: Define your Feature enum in the application layer
class CustomFeatureNavigationService implements NavigationService<FeatureScreenType> {
  @override
  Future<T?> navigateTo<T>(FeatureScreenType route, {Object? arguments}) {
    // Your custom implementation
  }
  
  // Implement other methods...
}
```

## Providers

### String-based Navigation Service

```dart
final navigationServiceProvider = Provider<NavigationService<String>>((ref) {
  return DefaultNavigationService(navigatorKey: App.navigatorKey);
});
```

### Feature enum-based Navigation Service

```dart
// Note: FeatureScreenType enum should be defined in your application layer
// (e.g., shared/navigation/feature_screen_type.dart)
final appNavigationProvider = Provider<NavigationService<FeatureScreenType>>((ref) {
  return FlyRouter.instance;
});
```

## Template Variables

For Mason brick template generation, the NavigatorKey should be a template variable:

```dart
final navigationServiceProvider = Provider<NavigationService<String>>((ref) {
  return DefaultNavigationService(
    navigatorKey: {{navigator_key}}, // Template variable
  );
});
```

## Error Handling

The service throws `StateError` if the NavigatorKey is not initialized:

```dart
try {
  await ref.read(navigationServiceProvider).navigateTo('/route');
} on StateError catch (e) {
  // Handle Navigator not initialized
}
```

## Migration from NavigationMixin

If you were using NavigationMixin:

**Before:**
```dart
class MyScreen extends FlyScreen with NavigationMixin {
  void navigate() {
    navigateTo(context, '/route');
  }
}
```

**After:**
```dart
class MyScreen extends FlyScreen {
  void navigate(WidgetRef ref) {
    // String-based
    ref.read(navigationServiceProvider).navigateTo('/route');
    
    // Or Feature enum-based
    // Note: FeatureScreenType is defined in application layer
    FlyRouter.instance.navigateTo(FeatureScreenType.home);
  }
}
```

Note: No BuildContext is required when using the service.

## Feature Enum Location

**Important:** The `FeatureScreenType` enum (or your application's feature enum) should be defined in the **application layer**, not in the foundation. This keeps foundation components generic and reusable.

**Example Location:** `shared/navigation/feature_screen_type.dart`

The foundation's `FlyRouter` class is generic and can work with any enum type that provides a `route` property (String). Define your feature enum in your application and use it with `FlyRouter` or create your own `NavigationService<YourFeatureEnum>` implementation.

## Benefits of Generic Route Types

1. **Type Safety** - Feature enum provides compile-time safety
2. **Consistent API** - Single interface method, no duplicates
3. **Flexibility** - Supports String, Feature enum, and custom types
4. **Cleaner Code** - Direct enum usage: `navigateTo(FeatureScreenType.home)` vs `navigateTo('/home')`
5. **Better DX** - Type-safe navigation with IDE autocomplete support
6. **Reusability** - Foundation remains generic, applications define their own routes
