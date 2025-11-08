# fly_di

Dependency injection container abstraction for Flutter applications.

## Features

- Framework-agnostic dependency injection interface
- Riverpod implementation
- Global container singleton
- Testing support

## Usage

```dart
import 'package:fly_di/fly_di.dart';

// In your app initialization
void main() {
  final container = RiverpodDependencyContainer();
  DependencyContainer.setInstance(container);
  container.initialize();

  runApp(MyApp());
}

// In your components
final logger = DependencyContainer.instance.read<FlyLogger>(loggerProvider);
```

## Testing

```dart
void main() {
  test('my test', () {
    final testContainer = ProviderContainer(
      overrides: [myProvider.overrideWith((ref) => MockService())],
    );
    final container = RiverpodDependencyContainer.withContainer(testContainer);
    DependencyContainer.setInstance(container);
    container.initialize();

    // Your test code here

    DependencyContainer.reset();
  });
}
```

