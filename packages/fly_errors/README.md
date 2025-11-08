# fly_errors

Centralized error handling and user-friendly message formatting for Flutter applications.

## Features

- Base exception classes (AppException and subclasses)
- Error message formatter with localization support
- Network error classification
- Riverpod provider integration

## Usage

```dart
import 'package:fly_errors/fly_errors.dart';
import 'package:fly_logger/fly_logger.dart';
import 'package:fly_localization/fly_localization.dart';

// Create error formatter
final logger = FlyLoggerImpl('MyApp');
final formatter = ErrorMessageFormatter(
  logger: logger,
  defaultLocalizations: DefaultFoundationLocalizationProvider(),
);

// Format errors
try {
  await someOperation();
} catch (e) {
  final userMessage = formatter.format(e);
  // Display to user
}

// Use Riverpod provider
final formatter = ref.read(errorMessageFormatterProvider);
final userMessage = formatter.format(error);
```

## Network Errors

```dart
// Classify network errors
final error = NetworkErrorClassifier.classifyError(
  exception,
  timeout: Duration(seconds: 30),
  localizations: localizations,
);

// Check if retryable
if (NetworkErrorClassifier.isRetryable(error)) {
  // Retry logic
}
```

