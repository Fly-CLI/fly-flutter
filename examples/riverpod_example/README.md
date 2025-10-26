# Riverpod Example

A production-ready Flutter application created with Fly CLI using the Riverpod template.

## Getting Started

This project is a production-ready Flutter application created with Fly CLI using the Riverpod template. It demonstrates best practices for state management, navigation, and architecture.

### Prerequisites

- Flutter SDK (3.10.0 or higher)
- Dart SDK (3.0.0 or higher)

### Running the App

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Generate code (if needed):
   ```bash
   flutter packages pub run build_runner build
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Building the App

- **Debug build:**
  ```bash
  flutter build apk --debug
   ```

- **Release build:**
  ```bash
  flutter build apk --release
   ```

## Project Structure

```
riverpod_example/
├── lib/
│   ├── core/
│   │   ├── router/          # Navigation configuration
│   │   └── theme/           # App theming
│   ├── features/
│   │   ├── home/            # Home feature module
│   │   │   ├── presentation/
│   │   │   └── providers/
│   │   └── profile/         # Profile feature module
│   │       ├── presentation/
│   │       └── providers/
│   └── main.dart           # Main application entry point
├── test/
│   └── widget_test.dart    # Widget tests
├── pubspec.yaml            # Project dependencies
└── README.md               # This file
```

## Features

- **State Management**: Riverpod with code generation
- **Navigation**: GoRouter for declarative routing
- **Architecture**: Feature-based structure with clean separation
- **Theming**: Material Design 3 with light/dark themes
- **Error Handling**: Structured error handling with Fly Core
- **Networking**: HTTP client with interceptors (Fly Networking)
- **Testing**: Comprehensive widget tests
- **Cross-platform**: Support for iOS, Android, Web, macOS, Windows, Linux

## Architecture

This project follows the Riverpod architecture pattern with:

- **Presentation Layer**: Screens and widgets
- **Business Logic**: ViewModels and providers
- **Data Layer**: Services and repositories
- **Core**: Shared utilities and configurations

## Demo Features

### Counter Demo
- Increment, decrement, and reset functionality
- State managed with Riverpod StateProvider
- Demonstrates basic state management patterns

### Todos Demo
- Add and remove todos
- AsyncValue for loading states
- StateNotifier for complex state management

### Profile Screen
- User information display
- Theme switching (light/dark mode)
- Navigation between screens
- Demonstrates feature-based architecture

## Development

This project was created with Fly CLI - the AI-native Flutter CLI tool.

For more information about Fly CLI, visit: https://github.com/fly-cli/fly

## Available Commands

- `fly add screen <name>` - Add a new screen
- `fly add service <name>` - Add a new service
- `fly schema export` - Export CLI schema for AI integration

## License

This project is licensed under the MIT License.
