# Foundation Project

A comprehensive Flutter foundation project with Riverpod, MVVM architecture, and industry best practices.

## Overview

This foundation project serves as a playground for Flutter development and can be converted to a template for use with the `fly generate project` command. It includes a complete set of foundational components copied from a production-ready StockAI project.

## Features

### Architecture

- **MVVM Pattern**: Complete MVVM architecture with FlyScreen, FlyViewModel, and FlyViewModelState
- **Riverpod State Management**: Full Riverpod integration with providers and state management
- **Lifecycle Management**: Comprehensive screen and FlyViewModel lifecycle support
- **Error Handling**: Robust error handling with custom exceptions and error classification
- **Feedback System**: User feedback system with snackbars, dialogs, and custom displays
- **Async Operations**: Advanced async operation handling with retry logic and connectivity checking
- **Network Connectivity**: Connectivity service for checking internet connection and WiFi status

### Foundation Components

#### Core Foundation (`lib/foundation/`)

- **Error Handling** (`error/`):
  - `AppException`: Base exception class
  - `ErrorHandler`: Centralized error handling
  - `NetworkErrors`: Network-specific error classes
  - `ErrorMessageFormatter`: Error message formatting

- **Feedback System** (`feedback/`):
  - `FeedbackEvent`: Feedback event types supplied by the `fly_feedback` package
  - `FeedbackLifecycleEvent`: Lifecycle wrapper that routes feedback through `AppLifecycleEmitter`
  - `LifecycleEmitterMixin`: Shared emitter mixin used by services and view models
  - `FlyFeedbackHandler`: Feedback display handlers (snackbar, dialog, toast, etc.)

- **MVVM** (`mvvm/`):
  - `FlyScreen`: Base screen class with lifecycle management
  - `FlyViewModel`: Base FlyViewModel class with state management
  - `FlyViewModelState`: Base state interface

- **Operations** (`operations/`):
  - `AsyncOperationHandler`: Async operation handler with retry logic
  - `ConnectivityService`: Network connectivity checking
  - `Result`: Result pattern for operation outcomes
  - `RetryConfig`: Retry configuration

- **Forms** (`forms/`):
  - `FormFlyViewModelInterface`: Form FlyViewModel interface
  - `FormFlyViewModelMixin`: Form FlyViewModel mixin (requires flutter_form package)

- **State** (`state/`):
  - `StateNotifier`: State notifier implementation

- **Utils** (`utils/`):
  - `AppLogger`: Application logging utility

## Getting Started

### Prerequisites

- Flutter SDK >=3.10.0
- Dart SDK >=3.0.0

### Installation

1. Navigate to the project directory:
```bash
cd examples/foundation_project
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── foundation/              # Core foundation components
│   ├── error/              # Error handling
│   ├── feedback/           # Feedback system
│   ├── forms/              # Form handling
│   ├── mvvm/               # MVVM architecture
│   ├── operations/         # Async operations
│   ├── state/              # State management
│   └── utils/              # Utilities
├── core/
│   ├── features/          # Feature-specific code
│   │   └── product/
│   │       └── services/
│   │           └── device_condition_service.dart
│   └── offline/          # Offline queue management
├── shared/                 # Shared components
│   ├── localization/       # Localization
│   ├── themes/            # Theme configuration
│   ├── ui/                # UI components
│   └── widgets/           # Reusable widgets
└── l10n/                  # Localization files
```

## Usage Examples

### Basic FlyViewModel

```dart
class MyFlyViewModelState extends FlyViewModelState {
  final bool isLoading;
  final String? error;
  final List<String> items;

  MyFlyViewModelState({
    this.isLoading = false,
    this.error,
    this.items = const [],
  });

  MyFlyViewModelState copyWith({
    bool? isLoading,
    String? error,
    List<String>? items,
  }) {
    return MyFlyViewModelState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      items: items ?? this.items,
    );
  }
}

class MyFlyViewModel extends FlyViewModel<MyFlyViewModelState> {
  @override
  MyFlyViewModelState build() => MyFlyViewModelState();

  @override
  MyFlyViewModelState copyState({bool? isLoading, String? error}) {
    return state.copyWith(isLoading: isLoading, error: error);
  }

  Future<void> loadData() async {
    await runAsyncOperation(
      () async {
        // Your async operation
        return ['Item 1', 'Item 2'];
      },
      successMessage: 'Data loaded successfully!',
      errorMessage: 'Failed to load data',
    );
  }
}
```

### Basic Screen

```dart
class MyScreen extends FlyScreen<MyFlyViewModel, MyFlyViewModelState> {
  const MyScreen({super.key});

  @override
  NotifierProvider<MyFlyViewModel, MyFlyViewModelState> getFlyViewModelProvider() {
    return myFlyViewModelProvider;
  }

  @override
  Color getBackgroundColor(theme) => theme.colors.background;

  @override
  Future<void> onRefresh(MyFlyViewModel FlyViewModel) => FlyViewModel.loadData();

  @override
  Widget buildContent(
    BuildContext context,
    MyFlyViewModel FlyViewModel,
    MyFlyViewModelState state,
    Color primary,
    WidgetRef ref,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.hasError) {
      return Center(child: Text(state.error ?? 'Error'));
    }

    return ListView.builder(
      itemCount: state.items.length,
      itemBuilder: (context, index) {
        return ListTile(title: Text(state.items[index]));
      },
    );
  }
}
```

## Dependencies

### Core Dependencies

- `flutter_riverpod`: ^3.0.3 - State management
- `riverpod_annotation`: ^3.0.0 - Riverpod annotations
- `go_router`: ^12.1.0 - Navigation
- `logging`: ^1.3.0 - Logging
- `connectivity_plus`: ^7.0.0 - Connectivity checking
- `uuid`: ^4.2.1 - UUID generation
- `battery_plus`: ^7.0.0 - Battery level checking

### Development Dependencies

- `flutter_lints`: ^5.0.0 - Linting
- `build_runner`: ^2.4.8 - Code generation
- `riverpod_generator`: ^3.0.3 - Riverpod code generation

### Fly Packages

- `fly_core`: Path dependency to `../../packages/fly_core`
- `fly_networking`: Path dependency to `../../packages/fly_networking`

## Best Practices

1. **State Management**: Use Riverpod providers for all state management
2. **Error Handling**: Always use the error handling system for consistent error display
3. **Lifecycle**: Override lifecycle methods when needed for proper resource management
4. **Feedback**: Use the feedback system for user notifications
5. **Async Operations**: Use AsyncOperationHandler for all async operations with proper error handling

## Converting to Template

This foundation project can be converted to a template for use with the `fly generate project` command. The template should be placed in:

```
packages/fly_cli/templates/projects/foundation_project/
```

## License

This foundation project is part of the Fly CLI project.
