# Fly Feedback Example App

A comprehensive example application demonstrating all usage patterns of the `fly_feedback` package, from simple direct usage to advanced custom handlers and real-world scenarios.

## 📋 Table of Contents

- [Getting Started](#getting-started)
- [Examples Overview](#examples-overview)
- [Step-by-Step Guide](#step-by-step-guide)
  - [1. Simple Direct Usage](#1-simple-direct-usage)
  - [2. All Display Types](#2-all-display-types)
  - [3. All Feedback Types](#3-all-feedback-types)
  - [4. Emitter/Listener Pattern](#4-emitterlistener-pattern)
  - [5. Custom Handler](#5-custom-handler)
  - [6. Real-World Scenarios](#6-real-world-scenarios)
- [Best Practices](#best-practices)
- [Architecture Overview](#architecture-overview)

## 🚀 Getting Started

### Prerequisites

- Flutter SDK >=3.10.0
- Dart SDK >=3.5.0

### Running the Example

1. **Navigate to the example directory:**
   ```bash
   cd packages/fly_feedback/example
   ```

2. **Get dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

## 📱 Examples Overview

This example app provides 6 comprehensive examples, each demonstrating different aspects of the `fly_feedback` package:

| # | Example | Description |
|---|---------|-------------|
| 1 | **Simple Direct Usage** | Basic usage with FeedbackService |
| 2 | **All Display Types** | SnackBar, Dialog, BottomSheet, Toast, Banner |
| 3 | **All Feedback Types** | Success, Error, Warning, Info, Confirmation |
| 4 | **Emitter/Listener Pattern** | Decoupled feedback emission |
| 5 | **Custom Handler** | Custom feedback handlers |
| 6 | **Real-World Scenarios** | Practical use cases |

## 📚 Step-by-Step Guide

### 1. Simple Direct Usage

**What you'll learn:**
- Basic usage of `FeedbackService`
- Showing success, error, warning, and info messages
- Using `DefaultFeedbackService` with handlers

**Key Concepts:**

The simplest way to show feedback is using `FeedbackService` directly with `BuildContext`. This is perfect for:
- Quick feedback in widgets
- Simple UI interactions
- Learning the basics

**Code Example:**

```dart
import 'package:fly_feedback/fly_feedback.dart';

// Create a feedback service
final feedbackService = DefaultFeedbackService(
  handler: CompositeFeedbackHandler([
    SnackbarFeedbackHandler(),
    DialogFeedbackHandler(),
    // ... other handlers
  ]),
);

// Use it anywhere you have BuildContext
feedbackService.showSuccess(context, 'Operation completed!');
feedbackService.showError(context, 'Something went wrong');
```

**When to use:**
- Direct UI interactions (button clicks, form submissions)
- Quick feedback without complex architecture
- Prototyping and MVPs

---

### 2. All Display Types

**What you'll learn:**
- All available display strategies
- Choosing the right display type for your use case
- Customizing display behavior

**Available Display Types:**

| Display Type | Use Case | Example |
|--------------|----------|---------|
| **SnackBar** | Quick notifications | "Saved successfully" |
| **Dialog** | Important messages | "Confirm deletion" |
| **BottomSheet** | Detailed information | "Show more details" |
| **Toast** | Non-intrusive notifications | "Copied to clipboard" |
| **Banner** | Persistent notifications | "Network disconnected" |

**Code Example:**

```dart
// SnackBar (default)
feedbackService.showSuccess(
  context,
  'Message',
  display: FeedbackDisplay.snackBar,
);

// Dialog
feedbackService.showInfo(
  context,
  'Important message',
  display: FeedbackDisplay.dialog,
);

// Bottom Sheet
feedbackService.showInfo(
  context,
  'Detailed information',
  display: FeedbackDisplay.bottomSheet,
);
```

**Best Practices:**
- Use **SnackBar** for most feedback (quick, non-intrusive)
- Use **Dialog** for important decisions (confirmation, errors)
- Use **BottomSheet** for detailed information
- Use **Toast** for non-critical notifications
- Use **Banner** for persistent status messages

---

### 3. All Feedback Types

**What you'll learn:**
- All available feedback types
- Using actions and retry mechanisms
- Confirmation dialogs

**Available Feedback Types:**

| Type | Purpose | Features |
|------|---------|----------|
| **Success** | Positive outcomes | Action button, optional duration |
| **Error** | Failures | Retry action, technical details |
| **Warning** | Cautionary messages | Simple notification |
| **Info** | Neutral information | Simple notification |
| **Confirmation** | User decisions | Confirm/cancel actions |

**Code Examples:**

#### Success with Action

```dart
feedbackService.showSuccess(
  context,
  'Data saved successfully!',
  action: () {
    // Undo action
    undoSave();
  },
  actionLabel: 'Undo',
);
```

#### Error with Retry

```dart
feedbackService.showError(
  context,
  'Failed to save data',
  retryAction: () {
    // Retry the operation
    retrySave();
  },
  retryLabel: 'Retry',
  technicalDetails: 'HTTP 500: Internal Server Error',
  showTechnicalDetails: false,
);
```

#### Confirmation Dialog

```dart
feedbackService.showConfirmation(
  context: context,
  title: 'Delete Item',
  message: 'Are you sure you want to delete this item?',
  confirmLabel: 'Delete',
  cancelLabel: 'Cancel',
  isDangerous: true, // Red button for dangerous actions
  onConfirm: () {
    // Execute deletion
    deleteItem();
  },
  onCancel: () {
    // Handle cancellation
    feedbackService.showInfo(context, 'Deletion cancelled');
  },
);
```

**Best Practices:**
- Always provide a **retry action** for errors
- Use **confirmation dialogs** for destructive actions
- Keep **technical details** hidden from users (show in debug mode)
- Use **success actions** for undoable operations

---

### 4. Emitter/Listener Pattern

**What you'll learn:**
- Decoupled feedback architecture
- Using `FlyFeedbackEmitterMixin` in services/view models
- Using `FlyFeedbackListenerMixin` in widgets
- Stream-based communication

**Key Concepts:**

The emitter/listener pattern separates business logic from UI:
- **Services/ViewModels** emit feedback without knowing about UI
- **Widgets** listen to feedback streams and display automatically
- **No BuildContext needed** in business logic

**Service Example:**

```dart
class UserService with FlyFeedbackEmitterMixin {
  Future<void> saveUser(User user) async {
    try {
      await apiService.saveUser(user);
      emitSuccess('User saved successfully!');
    } catch (e) {
      emitError(
        'Failed to save user',
        retryAction: () => saveUser(user),
        retryLabel: 'Retry',
      );
    }
  }

  void dispose() {
    disposeFeedbackEmitter();
  }
}
```

**Widget Example:**

```dart
class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen>
    with FlyFeedbackListenerMixin<UserScreen> {
  final UserService _service = UserService();

  @override
  void initState() {
    super.initState();
    // Setup listener after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setupFeedbackListener();
    });
  }

  @override
  Stream<FeedbackEvent>? getFeedbackStream(BuildContext context) {
    // Connect to service feedback stream
    return _service.feedbackStream;
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ElevatedButton(
        onPressed: () => _service.saveUser(user),
        child: const Text('Save User'),
      ),
    );
  }
}
```

**Benefits:**
- ✅ **Separation of concerns**: Business logic doesn't know about UI
- ✅ **Testability**: Easy to test services without BuildContext
- ✅ **Reusability**: Services can be used in different UI contexts
- ✅ **MVVM compatibility**: Perfect for MVVM architecture

**When to use:**
- MVVM architecture
- Complex business logic
- Services that need to emit feedback
- Testing business logic without UI

---

### 5. Custom Handler

**What you'll learn:**
- Creating custom feedback handlers
- Implementing `FlyFeedbackHandler` interface
- Using custom handlers with the listener mixin
- Composite handlers

**Why Custom Handlers?**

Custom handlers allow you to:
- Log feedback to analytics
- Send feedback to crash reporting
- Store feedback in local database
- Create specialized display logic
- Integrate with third-party services

**Custom Handler Example:**

```dart
class AnalyticsFeedbackHandler implements FlyFeedbackHandler {
  final AnalyticsService analytics;

  AnalyticsFeedbackHandler(this.analytics);

  @override
  bool supports(FeedbackDisplay display) {
    // Support all display types
    return true;
  }

  @override
  void handle(BuildContext context, FeedbackEvent event) {
    // Log to analytics
    analytics.trackFeedback(
      type: event.type.name,
      message: event.message,
      timestamp: event.timestamp,
    );

    // Delegate to default handler for display
    // (In real apps, you'd use another handler here)
  }
}
```

**Using Custom Handler:**

```dart
class _MyScreenState extends State<MyScreen>
    with FlyFeedbackListenerMixin<MyScreen> {
  
  @override
  FlyFeedbackHandler getFeedbackHandler() {
    return CompositeFeedbackHandler([
      AnalyticsFeedbackHandler(analytics), // Custom handler
      SnackbarFeedbackHandler(),           // Default handlers
      DialogFeedbackHandler(),
    ]);
  }
}
```

**Best Practices:**
- Use **composite handlers** to chain multiple handlers
- **Logging handlers** should not display UI (delegate to other handlers)
- **Display handlers** should handle UI display
- Use `supports()` to filter which display types your handler supports

---

### 6. Real-World Scenarios

**What you'll learn:**
- Practical usage patterns
- Handling API calls
- Form validation
- File operations
- Network error handling
- Best practices for production apps

**Common Scenarios:**

#### API Call with Success/Error Handling

```dart
Future<void> fetchUserData() async {
  try {
    feedbackService.showInfo(
      context,
      'Loading user data...',
      display: FeedbackDisplay.toast,
    );

    final user = await apiService.getUser();
    
    feedbackService.showSuccess(
      context,
      'User data loaded successfully!',
    );
  } catch (e) {
    feedbackService.showError(
      context,
      'Failed to load user data. Please try again.',
      retryAction: () => fetchUserData(),
      retryLabel: 'Retry',
    );
  }
}
```

#### Form Validation

```dart
bool validateForm() {
  if (emailController.text.isEmpty) {
    feedbackService.showError(
      context,
      'Please enter your email address',
      display: FeedbackDisplay.banner,
    );
    return false;
  }

  if (!isValidEmail(emailController.text)) {
    feedbackService.showWarning(
      context,
      'Please enter a valid email address',
      display: FeedbackDisplay.snackBar,
    );
    return false;
  }

  return true;
}
```

#### Network Error Handling

```dart
void handleNetworkError(dynamic error) {
  if (error is SocketException) {
    feedbackService.showError(
      context,
      'No internet connection. Please check your network settings.',
      display: FeedbackDisplay.dialog,
      retryAction: () => checkConnection(),
      retryLabel: 'Check Again',
    );
  } else {
    feedbackService.showError(
      context,
      'Connection error. Please try again later.',
      retryAction: () => retryOperation(),
      retryLabel: 'Retry',
    );
  }
}
```

#### Delete Confirmation

```dart
void deleteItem(Item item) {
  feedbackService.showConfirmation(
    context: context,
    title: 'Delete Item',
    message: 'Are you sure you want to delete "${item.name}"? This action cannot be undone.',
    confirmLabel: 'Delete',
    cancelLabel: 'Cancel',
    isDangerous: true,
    onConfirm: () async {
      try {
        await itemService.delete(item);
        feedbackService.showSuccess(
          context,
          'Item deleted successfully',
        );
      } catch (e) {
        feedbackService.showError(
          context,
          'Failed to delete item',
          retryAction: () => deleteItem(item),
          retryLabel: 'Retry',
        );
      }
    },
    onCancel: () {
      feedbackService.showInfo(context, 'Deletion cancelled');
    },
  );
}
```

**Best Practices:**
- ✅ Always provide **retry actions** for errors
- ✅ Show **loading states** for async operations
- ✅ Use **confirmation dialogs** for destructive actions
- ✅ Provide **user-friendly error messages** (hide technical details)
- ✅ Use appropriate **display types** for different scenarios

---

## 🎯 Best Practices

### 1. Choose the Right Display Type

- **SnackBar**: Default for most feedback (quick, non-intrusive)
- **Dialog**: Important decisions or critical errors
- **BottomSheet**: Detailed information or forms
- **Toast**: Non-critical notifications
- **Banner**: Persistent status messages

### 2. Error Handling

Always provide:
- ✅ User-friendly error messages
- ✅ Retry actions when possible
- ✅ Technical details in debug mode only
- ✅ Appropriate display type (dialog for critical errors)

### 3. Success Feedback

- ✅ Show success for important operations
- ✅ Provide undo actions when applicable
- ✅ Keep messages concise and clear
- ✅ Use SnackBar for quick feedback

### 4. Architecture

- ✅ Use **direct service** for simple UI interactions
- ✅ Use **emitter/listener pattern** for MVVM architecture
- ✅ Create **custom handlers** for analytics/logging
- ✅ Use **composite handlers** for multiple strategies

### 5. Testing

- ✅ Test services without BuildContext (emitter pattern)
- ✅ Mock feedback handlers for unit tests
- ✅ Test error scenarios and retry mechanisms
- ✅ Verify confirmation dialogs work correctly

---

## 🏗️ Architecture Overview

### Direct Service Pattern

```
Widget → FeedbackService → Handler → UI
```

**Use when:**
- Simple UI interactions
- Quick feedback
- No complex architecture needed

### Emitter/Listener Pattern

```
Service → FlyFeedbackEmitterMixin → Stream
                                      ↓
Widget → FlyFeedbackListenerMixin → Handler → UI
```

**Use when:**
- MVVM architecture
- Complex business logic
- Separation of concerns needed
- Testing without UI

### Custom Handler Pattern

```
Service → FlyFeedbackEmitterMixin → Stream
                                      ↓
Widget → FlyFeedbackListenerMixin → CustomHandler → Analytics/Logging
                                      ↓
                                   DefaultHandler → UI
```

**Use when:**
- Analytics/logging needed
- Specialized display requirements
- Third-party integrations

---

## 📖 Additional Resources

- [Fly Feedback Package Documentation](../../README.md)
- [Fly CLI Documentation](https://github.com/fly-cli/fly)
- [Flutter Documentation](https://flutter.dev/docs)

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](../../LICENSE) file for details.

