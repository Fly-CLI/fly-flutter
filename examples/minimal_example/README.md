# Minimal Example

A minimal Flutter application created with Fly CLI.

## Getting Started

This project is a minimal Flutter application created with Fly CLI to demonstrate the basic template functionality.

### Prerequisites

- Flutter SDK (3.10.0 or higher)
- Dart SDK (3.0.0 or higher)

### Running the App

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Run the app:
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
minimal_example/
├── lib/
│   └── main.dart          # Main application entry point
├── test/
│   └── widget_test.dart   # Widget tests
├── pubspec.yaml           # Project dependencies
└── README.md              # This file
```

## Features

- Minimal Flutter project structure
- Material Design 3
- Basic counter functionality
- Widget tests
- Cross-platform support

## Development

This project was created with Fly CLI - the AI-native Flutter CLI tool.

For more information about Fly CLI, visit: https://github.com/fly-cli/fly

## Available Commands

- `fly add screen <name>` - Add a new screen
- `fly add service <name>` - Add a new service
- `fly schema export` - Export CLI schema for AI integration

## License

This project is licensed under the MIT License.
