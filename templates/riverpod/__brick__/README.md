# {{project_name}}

{{description}}

## Getting Started

This project is a production-ready Flutter application created with Fly CLI using the Riverpod template.

### Prerequisites

- Flutter SDK ({{min_flutter_sdk}} or higher)
- Dart SDK ({{min_dart_sdk}} or higher)

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
{{project_name_snake}}/
├── lib/
│   ├── core/
│   │   ├── router/          # Navigation configuration
│   │   └── theme/           # App theming
│   ├── features/
│   │   └── home/            # Feature modules
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
- **Cross-platform**: Support for {{platforms}}

## Architecture

This project follows the Riverpod architecture pattern with:

- **Presentation Layer**: Screens and widgets
- **Business Logic**: ViewModels and providers
- **Data Layer**: Services and repositories
- **Core**: Shared utilities and configurations

## Development

This project was created with Fly CLI - the AI-native Flutter CLI tool.

For more information about Fly CLI, visit: https://github.com/fly-cli/fly

## Available Commands

- `fly add screen <name>` - Add a new screen
- `fly add service <name>` - Add a new service
- `fly schema export` - Export CLI schema for AI integration

## License

This project is licensed under the MIT License.
