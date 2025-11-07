# Async Operations Guide

This guide explains how to handle async operations in ViewModels using the `runAsyncOperation` method and `AsyncOperationHandler` class.

## Table of Contents

- [Overview](#overview)
- [Why Use runAsyncOperation?](#why-use-performasync)
- [Basic Usage](#basic-usage)
- [Advanced Usage](#advanced-usage)
- [Timeout Configuration](#timeout-configuration)
- [Error Handling](#error-handling)
- [Loading State Management](#loading-state-management)
- [Feedback Messages](#feedback-messages)
- [Best Practices](#best-practices)
- [Common Patterns](#common-patterns)
- [Troubleshooting](#troubleshooting)

## Overview

The `runAsyncOperation` method is the recommended way to handle async operations in ViewModels. It provides:

- ✅ Automatic loading state management
- ✅ Consistent error handling
- ✅ Network connectivity awareness
- ✅ Retry logic support
- ✅ Timeout configuration
- ✅ Optional feedback messages
- ✅ Result pattern integration

## Why Use runAsyncOperation?

### ❌ Without runAsyncOperation (Manual Approach)

```dart
Future<void> loadData() async {
  try {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await repository.fetchData();
    if (result.isSuccess) {
      state = state.copyWith(
        data: result.data,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        error: result.error ?? 'Failed to load data',
        isLoading: false,
      );
    }
  } catch (e) {
    state = state.copyWith(
      error: 'Failed to load data: ${e.toString()}',
      isLoading: false,
    );
  }
}
```

**Problems:**
- Manual loading state management (easy to forget)
- Inconsistent error handling
- No network awareness
- No retry logic
- Duplicate code across methods

### ✅ With runAsyncOperation (Recommended)

```dart
Future<void> loadData() async {
  final result = await runAsyncOperation(
    () => repository.fetchData(),
    errorMessage: 'Failed to load data',
  );
  
  if (result.isSuccess && result.data != null) {
    state = state.copyWith(data: result.data);
  }
}
```

**Benefits:**
- Automatic loading state management
- Consistent error handling
- Network connectivity checking
- Retry logic support
- Less boilerplate code

## Basic Usage

### Simple Async Operation

```dart
Future<void> fetchUserData() async {
  final result = await runAsyncOperation(
    () => userService.getUser(userId),
    errorMessage: 'Failed to fetch user data',
  );
  
  if (result.isSuccess && result.data != null) {
    state = state.copyWith(user: result.data);
  }
}
```

### With Success Message

```dart
Future<void> saveData() async {
  final result = await runAsyncOperation(
    () => repository.save(data),
    successMessage: 'Data saved successfully!',
    errorMessage: 'Failed to save data',
  );
  
  if (result.isSuccess) {
    // Data saved, UI will show success message automatically
  }
}
```

## Advanced Usage

### Custom Timeout

```dart
Future<void> uploadLargeFile(File file) async {
  final result = await runAsyncOperation(
    () => fileService.upload(file),
    timeout: AsyncHandlerConfig.veryLongTimeout, // 120 seconds
    errorMessage: 'Upload failed',
    successMessage: 'File uploaded successfully',
  );
}
```

### Custom Loading Handler

```dart
Future<void> backgroundSync() async {
  // Don't show loading indicator for background operations
  final result = await runAsyncOperation(
    () => syncService.sync(),
    loadingHandler: (_) {}, // Empty handler = no loading state changes
    errorMessage: 'Sync failed',
  );
}
```

### Custom Error Handler

```dart
Future<void> performCriticalOperation() async {
  final result = await runAsyncOperation(
    () => criticalService.execute(),
    errorMessage: 'Operation failed',
    onError: (errorMessage) {
      // Custom error handling (e.g., send to analytics)
      analytics.logError('critical_operation_failed', errorMessage);
    },
  );
}
```

### OnFinally Callback

```dart
Future<void> loadData() async {
  bool wasRefreshing = state.isRefreshing;
  
  final result = await runAsyncOperation(
    () => repository.fetchData(),
    errorMessage: 'Failed to load data',
    onFinally: () {
      // Always executed, even on error
      if (wasRefreshing) {
        state = state.copyWith(isRefreshing: false);
      }
    },
  );
}
```

## Timeout Configuration

The `runAsyncOperation` method uses `AsyncHandlerConfig.standardTimeout` (30 seconds) by default.

### Available Timeouts

```dart
// Quick operations (10 seconds)
AsyncHandlerConfig.quickTimeout

// Standard operations (30 seconds) - DEFAULT
AsyncHandlerConfig.standardTimeout

// Long operations (60 seconds)
AsyncHandlerConfig.longTimeout

// Very long operations (120 seconds)
AsyncHandlerConfig.veryLongTimeout

// Background operations (100 minutes)
AsyncHandlerConfig.backgroundTimeout
```

### When to Use Each Timeout

- **quickTimeout**: Validations, checks, lookups
- **standardTimeout**: Most CRUD operations (create, read, update, delete)
- **longTimeout**: Complex queries, large data fetches
- **veryLongTimeout**: File uploads, large report generation
- **backgroundTimeout**: Non-critical background tasks

### Example

```dart
// Validation
await runAsyncOperation(
  () => validationService.validate(data),
  timeout: AsyncHandlerConfig.quickTimeout,
);

// Standard operation (uses default)
await runAsyncOperation(
  () => repository.save(data),
);

// Large file upload
await runAsyncOperation(
  () => fileService.uploadLargeFile(file),
  timeout: AsyncHandlerConfig.veryLongTimeout,
);
```

## Error Handling

### Automatic Error Handling

`runAsyncOperation` automatically:
- Catches exceptions
- Formats error messages
- Updates error state
- Handles network errors
- Provides retry logic (when configured)

### Error State

Errors are automatically stored in the ViewModel state:

```dart
// Check for errors
if (state.hasError) {
  // Show error message
  Text(state.error ?? 'An error occurred');
}

// Clear error
clearError(); // Method from ViewModel base class
```

### Custom Error Messages

```dart
final result = await runAsyncOperation(
  () => repository.fetchData(),
  errorMessage: 'Unable to load data. Please check your connection.',
);
```

### Error Feedback

```dart
final result = await runAsyncOperation(
  () => repository.save(data),
  errorMessage: 'Failed to save data',
  showError: true, // Show error feedback (default: true)
);
```

## Loading State Management

### Automatic Loading State

`runAsyncOperation` automatically manages loading state:

```dart
// Loading state is automatically set to true at start
// and false when operation completes (success or error)
final result = await runAsyncOperation(
  () => repository.fetchData(),
);

// In UI:
if (state.isLoading) {
  return CircularProgressIndicator();
}
```

### Disable Loading State

For background operations that shouldn't show loading indicators:

```dart
final result = await runAsyncOperation(
  () => syncService.syncInBackground(),
  loadingHandler: (_) {}, // Empty handler = no loading state changes
);
```

### Custom Loading Handler

```dart
final result = await runAsyncOperation(
  () => repository.fetchData(),
  loadingHandler: (isLoading) {
    // Custom loading state management
    if (isLoading) {
      state = state.copyWith(isRefreshing: true);
    } else {
      state = state.copyWith(isRefreshing: false);
    }
  },
);
```

## Feedback Messages

### Success Feedback

```dart
await runAsyncOperation(
  () => repository.save(data),
  successMessage: 'Data saved successfully!',
  showSuccess: true, // Show success feedback (default: true)
);
```

### Error Feedback

```dart
await runAsyncOperation(
  () => repository.save(data),
  errorMessage: 'Failed to save data',
  showError: true, // Show error feedback (default: true)
);
```

### Disable Feedback

```dart
await runAsyncOperation(
  () => repository.fetchData(),
  showSuccess: false, // Don't show success feedback
  showError: false,   // Don't show error feedback
);
```

## Best Practices

### ✅ DO

1. **Always use runAsyncOperation for async operations**
   ```dart
   Future<void> loadData() async {
     await runAsyncOperation(() => repository.fetchData());
   }
   ```

2. **Provide meaningful error messages**
   ```dart
   await runAsyncOperation(
     () => repository.save(data),
     errorMessage: 'Failed to save data. Please try again.',
   );
   ```

3. **Use appropriate timeouts**
   ```dart
   await runAsyncOperation(
     () => fileService.uploadLargeFile(file),
     timeout: AsyncHandlerConfig.veryLongTimeout,
   );
   ```

4. **Handle success results explicitly**
   ```dart
   final result = await runAsyncOperation(
     () => repository.fetchData(),
   );
   
   if (result.isSuccess && result.data != null) {
     state = state.copyWith(data: result.data);
   }
   ```

5. **Use success messages for user actions**
   ```dart
   await runAsyncOperation(
     () => repository.save(data),
     successMessage: 'Changes saved successfully!',
   );
   ```

### ❌ DON'T

1. **Don't manually manage loading/error states**
   ```dart
   // ❌ BAD
   try {
     state = state.copyWith(isLoading: true);
     final result = await repository.fetchData();
     state = state.copyWith(isLoading: false);
   } catch (e) {
     state = state.copyWith(isLoading: false, error: e.toString());
   }
   ```

2. **Don't forget to check result.isSuccess**
   ```dart
   // ❌ BAD - might crash if result is failure
   final result = await runAsyncOperation(() => repository.fetchData());
   state = state.copyWith(data: result.data!); // Unsafe!
   ```

3. **Don't use generic error messages**
   ```dart
   // ❌ BAD
   await runAsyncOperation(
     () => repository.save(data),
     errorMessage: 'Error', // Too generic
   );
   ```

4. **Don't ignore errors**
   ```dart
   // ❌ BAD - errors are silently ignored
   await runAsyncOperation(() => repository.save(data));
   // Always check result or provide error message
   ```

## Common Patterns

### Pattern 1: Load Data on Initialize

```dart
@override
void onInitialize() {
  super.onInitialize();
  loadData();
}

Future<void> loadData() async {
  final result = await runAsyncOperation(
    () => repository.fetchData(),
    errorMessage: 'Failed to load data',
  );
  
  if (result.isSuccess && result.data != null) {
    state = state.copyWith(data: result.data);
  }
}
```

### Pattern 2: Refresh Data

```dart
Future<void> refresh() async {
  state = state.copyWith(isRefreshing: true, clearError: true);
  
  try {
    await loadData();
  } finally {
    state = state.copyWith(isRefreshing: false);
  }
}
```

### Pattern 3: Save with Feedback

```dart
Future<void> saveData() async {
  final result = await runAsyncOperation(
    () => repository.save(data),
    successMessage: 'Data saved successfully!',
    errorMessage: 'Failed to save data',
  );
  
  if (result.isSuccess) {
    // Optionally reload data
    await loadData();
  }
}
```

### Pattern 4: Concurrent Operations

```dart
Future<void> loadAllData() async {
  await Future.wait([
    loadStatistics(),
    loadSyncStatus(),
  ]);
}

Future<void> loadStatistics() async {
  final result = await runAsyncOperation(
    () => statisticsService.getStatistics(),
    errorMessage: 'Failed to load statistics',
  );
  
  if (result.isSuccess && result.data != null) {
    state = state.copyWith(statistics: result.data);
  }
}

Future<void> loadSyncStatus() async {
  // Don't show loading for background sync status
  final result = await runAsyncOperation(
    () => syncService.getSyncStatus(),
    errorMessage: 'Failed to load sync status',
    loadingHandler: (_) {}, // No loading state changes
  );
  
  if (result.isSuccess && result.data != null) {
    state = state.copyWith(syncStatus: result.data);
  }
}
```

### Pattern 5: Conditional Operations

```dart
Future<void> syncIfNeeded() async {
  if (!state.needsSync) return;
  
  final result = await runAsyncOperation(
    () => syncService.sync(),
    errorMessage: 'Sync failed',
    successMessage: 'Sync completed successfully',
  );
  
  if (result.isSuccess) {
    state = state.copyWith(needsSync: false);
    await loadData(); // Reload after sync
  }
}
```

## Troubleshooting

### Issue: Loading state not updating

**Solution**: Ensure you're using `runAsyncOperation` and not manually managing loading state.

```dart
// ✅ Correct
await runAsyncOperation(() => repository.fetchData());

// ❌ Incorrect
try {
  setLoading(true);
  await repository.fetchData();
  setLoading(false);
} catch (e) {
  setLoading(false);
}
```

### Issue: Errors not showing

**Solution**: Provide an `errorMessage` parameter or check `state.error`.

```dart
// ✅ Correct
await runAsyncOperation(
  () => repository.fetchData(),
  errorMessage: 'Failed to load data',
);

// Check error in UI
if (state.hasError) {
  Text(state.error ?? 'An error occurred');
}
```

### Issue: Operation timing out

**Solution**: Use an appropriate timeout for the operation type.

```dart
// For long operations
await runAsyncOperation(
  () => fileService.uploadLargeFile(file),
  timeout: AsyncHandlerConfig.veryLongTimeout,
  errorMessage: 'Upload timed out',
);
```

### Issue: Multiple operations affecting loading state

**Solution**: Use `loadingHandler` to control loading state for concurrent operations.

```dart
// For background operations
await runAsyncOperation(
  () => backgroundService.sync(),
  loadingHandler: (_) {}, // Don't change loading state
);
```

## Related Documentation

- [ViewModel Lifecycle](./../mvvm/LIFECYCLE_USAGE.md) - ViewModel lifecycle methods
- [Feedback System](./../feedback/README.md) - Feedback message system
- [Error Handling](./../error/) - Error handling patterns
- [AsyncHandlerConfig](async_operation_config.dart) - Timeout and retry configuration

## Examples

See `examples/foundation_project/lib/features/home/presentation/view_models/home_view_model.dart` for a complete example of using `runAsyncOperation` in a real ViewModel.

