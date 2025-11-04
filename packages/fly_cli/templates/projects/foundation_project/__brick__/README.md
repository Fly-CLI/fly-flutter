# Foundation Project

A comprehensive Flutter foundation project with Riverpod, MVVM architecture, and industry best practices.

## Overview

This foundation project serves as a playground for Flutter development and can be converted to a template for use with the `fly generate project` command. It includes a complete set of foundational components copied from a production-ready StockAI project.

## Features

### Architecture

- **MVVM Pattern**: Complete MVVM architecture with BaseScreen, ViewModel, and ViewModelState
- **Riverpod State Management**: Full Riverpod integration with providers and state management
- **Lifecycle Management**: Comprehensive screen and ViewModel lifecycle support
- **Error Handling**: Robust error handling with custom exceptions and error classification
- **Feedback System**: User feedback system with snackbars, dialogs, and custom displays
- **Async Operations**: Advanced async operation handling with retry logic and connectivity checking
- **Network Connectivity**: Connectivity service for checking internet connection and WiFi status

### Foundation Components

#### Core Foundation (`lib/core/foundation/`)

- **Error Handling** (`error/`):
  - `AppException`: Base exception class
  - `ErrorHandler`: Centralized error handling
  - `NetworkErrors`: Network-specific error classes
  - `ErrorMessageFormatter`: Error message formatting

- **Feedback System** (`feedback/`):
  - `FeedbackEvent`: Feedback event types
  - `FeedbackHandler`: Feedback display handlers
  - `FeedbackEmitterMixin`: Mixin for emitting feedback
  - `FeedbackListenerMixin`: Mixin for listening to feedback

- **MVVM** (`mvvm/`):
  - `BaseScreen`: Base screen class with lifecycle management
  - `ViewModel`: Base ViewModel class with state management
  - `ViewModelState`: Base state interface

- **Operations** (`operations/`):
  - `AsyncHandler`: Async operation handler with retry logic
  - `ConnectivityService`: Network connectivity checking
  - `Result`: Result pattern for operation outcomes
  - `RetryConfig`: Retry configuration

- **Forms** (`forms/`):
  - `FormViewModelInterface`: Form ViewModel interface
  - `FormViewModelMixin`: Form ViewModel mixin

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
├── core/
│   ├── foundation/          # Core foundation components
│   │   ├── error/          # Error handling
│   │   ├── feedback/       # Feedback system
│   │   ├── forms/          # Form handling
│   │   ├── mvvm/           # MVVM architecture
│   │   ├── operations/      # Async operations
│   │   ├── state/          # State management
│   │   └── utils/          # Utilities
│   └── features/          # Feature-specific code
├── shared/                 # Shared components
│   ├── localization/       # Localization
│   ├── themes/            # Theme configuration
│   ├── ui/                # UI components
│   └── widgets/           # Reusable widgets
└── main.dart              # Application entry point
```

## Usage Examples

### Creating a Screen

```dart
class MyScreen extends BaseScreen<MyViewModel, MyViewModelState> {
  const MyScreen({super.key});

  @override
  NotifierProvider<MyViewModel, MyViewModelState> getViewModelProvider() {
    return myViewModelProvider;
  }

  @override
  Color getBackgroundColor(AppThemeData theme) {
    return theme.colors.surface;
  }

  @override
  Future<void> onRefresh(MyViewModel viewModel) async {
    await viewModel.loadData();
  }

  @override
  Widget buildContent(
    BuildContext context,
    MyViewModel viewModel,
    MyViewModelState state,
    Color primary,
    WidgetRef ref,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      children: [
        // Your content here
      ],
    );
  }
}
```

### Creating a ViewModel

```dart
class MyViewModel extends ViewModel<MyViewModelState> {
  @override
  MyViewModelState build() {
    return MyViewModelState();
  }

  @override
  MyViewModelState copyState({bool? isLoading, String? error}) {
    return state.copyWith(
      isLoading: isLoading ?? state.isLoading,
      error: error ?? state.error,
    );
  }

  @override
  void onInitialize() {
    super.onInitialize();
    loadData();
  }

  Future<void> loadData() async {
    final result = await performAsync(
      () => repository.getData(),
      successMessage: 'Data loaded successfully',
      errorMessage: 'Failed to load data',
    );

    if (result.isSuccess) {
      // Handle success
    }
  }
}

class MyViewModelState extends BaseViewModelState {
  final List<Item> items;

  const MyViewModelState({
    super.isLoading = false,
    super.error,
    this.items = const [],
  });

  MyViewModelState copyWith({
    bool? isLoading,
    String? error,
    List<Item>? items,
  }) {
    return MyViewModelState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      items: items ?? this.items,
    );
  }
}
```

## Converting to Template

This foundation project can be converted to a template for use with the `fly generate project` command. The template should be placed in:

```
packages/fly_cli/templates/projects/foundation_project/
```

## Dependencies

### Core Dependencies

- `flutter_riverpod`: ^3.0.3 - State management
- `riverpod_annotation`: ^3.0.0 - Riverpod annotations
- `go_router`: ^12.1.0 - Navigation
- `logging`: ^1.3.0 - Logging
- `connectivity_plus`: ^7.0.0 - Connectivity checking
- `uuid`: ^4.2.1 - UUID generation

### Development Dependencies

- `flutter_lints`: ^5.0.0 - Linting
- `build_runner`: ^2.4.8 - Code generation
- `riverpod_generator`: ^3.0.3 - Riverpod code generation

## Best Practices

1. **State Management**: Use Riverpod providers for all state management
2. **Error Handling**: Always use the error handling system for consistent error display
3. **Lifecycle**: Override lifecycle methods when needed for proper resource management
4. **Feedback**: Use the feedback system for user notifications
5. **Async Operations**: Use AsyncHandler for all async operations with proper error handling

## License

This foundation project is part of the Fly CLI project.

