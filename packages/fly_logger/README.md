# fly_logger

Structured logging infrastructure with error reporting for Flutter applications.

## Features

- Standard log levels (TRACE, DEBUG, INFO, WARN, ERROR, FATAL)
- Structured logging with key-value metadata
- Child loggers with inherited context
- Lazy message evaluation for performance
- Automatic exception handling with stack traces
- Optional error reporting integration

## Usage

```dart
import 'package:fly_logger/fly_logger.dart';

// Create a logger
final logger = FlyLoggerImpl('MyService');

// Simple logging
logger.info('User logged in');

// Structured logging
logger.info('User logged in', fields: {
  'userId': user.id,
  'timestamp': DateTime.now().toIso8601String(),
});

// Error logging with exception
try {
  // ...
} catch (e, stackTrace) {
  logger.error('Operation failed', error: e, stackTrace: stackTrace);
}

// Child logger with context
final requestLogger = logger.child({'requestId': requestId});
requestLogger.debug('Processing request');
```

## Error Reporting

Implement the `ErrorReporter` interface to integrate with error reporting services:

```dart
class CrashlyticsErrorReporter implements ErrorReporter {
  @override
  void recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, String>? customKeys,
  }) {
    // Integrate with your error reporting service
  }
}

final logger = FlyLoggerImpl(
  'MyService',
  errorReporter: CrashlyticsErrorReporter(),
);
```

