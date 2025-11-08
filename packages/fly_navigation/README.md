# fly_navigation

Router-agnostic navigation service with generic route type support for Flutter applications.

## Features

- Generic navigation interface supporting any route type
- Default Flutter Navigator implementation
- Riverpod provider integration
- No BuildContext required for navigation

## Usage

```dart
import 'package:fly_navigation/fly_navigation.dart';

// Get navigation service from provider
final navigationService = ref.read(navigationServiceProvider);

// Navigate to a route
await navigationService.navigateTo('/home');

// Navigate back
navigationService.navigateBack();

// Replace current route
await navigationService.navigateReplace('/settings');

// Clear stack and navigate
await navigationService.navigateClearStack('/login');
```

## Custom Route Types

```dart
// Implement NavigationService for custom route types
class FeatureNavigationService implements NavigationService<Feature> {
  @override
  Future<T?> navigateTo<T>(Feature route, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamed<T>(
      route.route, // Convert enum to string
      arguments: arguments,
    );
  }
  
  // ... implement other methods
}
```

