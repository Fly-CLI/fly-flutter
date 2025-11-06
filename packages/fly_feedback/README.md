# fly_feedback

A completely decoupled, composable feedback system for Flutter applications.

## Features

- **Standalone Package**: No external dependencies beyond Flutter core
- **Composable Handlers**: Mix and match feedback display handlers
- **Type-Safe**: Generic feedback service for custom feedback types
- **Flexible**: Works with any state management solution (Riverpod, Provider, Bloc, etc.)
- **Multiple Display Types**: SnackBar, Dialog, BottomSheet, Toast, Banner
- **Lifecycle-Aware**: Automatic cleanup and context validation

## Installation

Add `fly_feedback` to your `pubspec.yaml`:

```yaml
dependencies:
  fly_feedback:
    path: ../../packages/fly_feedback  # or use pub.dev version when published
```

## Quick Start

### Basic Usage

```dart
import 'package:flutter/material.dart';
import 'package:fly_feedback/fly_feedback.dart';

// Create a feedback service
final feedbackService = DefaultFeedbackService<FeedbackEvent>(
  handler: CompositeFeedbackHandler([
    SnackbarFeedbackHandler(),
    DialogFeedbackHandler(),
    BottomSheetFeedbackHandler(),
  ]),
);

// Use it in your widgets
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        feedbackService.showSuccess(context, 'Operation successful!');
      },
      child: Text('Show Success'),
    );
  }
}
```

### Using with Riverpod (Optional)

If you're using Riverpod, you can create a provider:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fly_feedback/fly_feedback.dart';

final feedbackServiceProvider = Provider<FeedbackService<FeedbackEvent>>((ref) {
  return DefaultFeedbackService<FeedbackEvent>(
    handler: CompositeFeedbackHandler([
      SnackbarFeedbackHandler(),
      DialogFeedbackHandler(),
      BottomSheetFeedbackHandler(),
      ToastFeedbackHandler(),
      BannerFeedbackHandler(),
    ]),
  );
});

// Usage in widget
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedbackService = ref.read(feedbackServiceProvider);
    
    return ElevatedButton(
      onPressed: () {
        feedbackService.showSuccess(context, 'Success!');
      },
      child: Text('Show Success'),
    );
  }
}
```

### Listening to Feedback Streams

Use the `FlyFeedbackListenerMixin` to automatically listen to feedback events:

```dart
class _MyScreenState extends State<MyScreen>
    with FlyFeedbackListenerMixin<MyScreen> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setupFeedbackListener();
    });
  }

  @override
  Stream<FeedbackEvent>? getFeedbackStream(BuildContext context) {
    // Return your feedback stream (e.g., from ViewModel)
    return viewModel.feedbackStream;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(/* ... */);
  }
}
```

### Emitting Feedback

Use the `FlyFeedbackEmitterMixin` to emit feedback events:

```dart
class MyViewModel with FlyFeedbackEmitterMixin {
  void performAction() {
    // ... perform action ...
    emitFeedback(SuccessFeedback('Action completed!'));
  }
}
```

## Feedback Types

### Success Feedback

```dart
feedbackService.showSuccess(
  context,
  'Operation successful!',
  display: FeedbackDisplay.snackBar,
  action: () => print('Action clicked'),
  actionLabel: 'Undo',
);
```

### Error Feedback

```dart
feedbackService.showError(
  context,
  'Operation failed',
  technicalDetails: 'Error code: 404',
  retryAction: () => retryOperation(),
  retryLabel: 'Retry',
  showTechnicalDetails: true,
);
```

### Warning Feedback

```dart
feedbackService.showWarning(
  context,
  'Please check your input',
  display: FeedbackDisplay.dialog,
);
```

### Info Feedback

```dart
feedbackService.showInfo(
  context,
  'New features available',
  display: FeedbackDisplay.banner,
);
```

### Confirmation Dialog

```dart
feedbackService.showConfirmation(
  context: context,
  title: 'Delete Item',
  message: 'Are you sure you want to delete this item?',
  confirmLabel: 'Delete',
  cancelLabel: 'Cancel',
  isDangerous: true,
  onConfirm: () => deleteItem(),
  onCancel: () => print('Cancelled'),
);
```

## Custom Handlers

Create custom feedback handlers by implementing `FlyFeedbackHandler`:

```dart
class CustomFeedbackHandler implements FlyFeedbackHandler {
  @override
  bool supports(FeedbackDisplay display) {
    return display == FeedbackDisplay.custom;
  }

  @override
  void handle(BuildContext context, FeedbackEvent event) {
    // Your custom implementation
    showCustomFeedback(context, event);
  }
}
```

## Custom Feedback Types

You can create custom feedback types by extending `FeedbackEvent`:

```dart
class CustomFeedback extends FeedbackEvent {
  final String customField;

  CustomFeedback({
    required String message,
    required this.customField,
    super.display = FeedbackDisplay.snackBar,
  }) : super(
          message: message,
          type: FeedbackType.info,
        );
}

// Use with generic service
final customService = DefaultFeedbackService<CustomFeedback>(
  handler: CompositeFeedbackHandler([/* ... */]),
);
```

## Architecture

The package follows a clean architecture:

- **Events**: `FeedbackEvent` and its subclasses define feedback data
- **Handlers**: `FlyFeedbackHandler` implementations display feedback
- **Service**: `FeedbackService` provides high-level API
- **Mixins**: `FlyFeedbackEmitterMixin` and `FlyFeedbackListenerMixin` for integration

## License

This package is part of the Fly CLI project and follows the same license.
