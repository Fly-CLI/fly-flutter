# Screen Lifecycle Usage Guide

## Overview

The BaseScreen architecture now supports lifecycle notifications at both the screen and ViewModel
levels. This allows both screens and ViewModels to respond to lifecycle events automatically.

## Available Lifecycle Methods

Both screens and ViewModels can override these optional lifecycle methods:

### Screen Lifecycle Methods (BaseScreen)

Screens extending `BaseScreen` can override:

- `onInitialize()` - Called once when screen is first built
- `onAppear()` - Called every time the screen appears
- `onDisappear()` - Called when screen is popped or hidden

### ViewModel Lifecycle Methods (ViewModel)

ViewModels can override these optional lifecycle methods:

### 1. `onInitialize()`

- **Called:** Once when the ViewModel is first initialized (screen first built)
- **Use for:** One-time setup operations, initial data loading, subscriptions
- **Example:**

```dart
@override
void onInitialize() {
  super.onInitialize();
  // Load initial data
  loadInitialData();
  // Start listening to streams
  _startListening();
}
```

### 2. `onAppear()`

- **Called:** Every time the screen appears (including first time)
- **Use for:** Refreshing data, updating state when screen becomes visible
- **Example:**

```dart
@override
void onAppear() {
  super.onAppear();
  // Refresh data when screen appears
  refreshData();
}
```

### 3. `onDisappear()`

- **Called:** When the screen is popped or hidden
- **Use for:** Cleanup, canceling operations, saving state
- **Example:**

```dart
@override
void onDisappear() {
  super.onDisappear();
  // Cancel ongoing operations
  _cancelPendingRequests();
  // Save draft state
  _saveDraft();
}
```

## Complete Example

### Screen with Lifecycle Methods

```dart
class ProductScreen extends BaseListScreen<Product, ProductViewModel> {
  const ProductScreen({super.key});

  @override
  void onInitialize() {
    super.onInitialize();
    // Screen-level one-time setup
    print('ProductScreen UI initialized');
  }

  @override
  void onAppear() {
    super.onAppear();
    // Screen-level actions when appearing
    print('ProductScreen UI appeared - can show dialogs, animations, etc.');
  }

  @override
  void onDisappear() {
    super.onDisappear();
    // Screen-level cleanup
    print('ProductScreen UI disappeared');
  }

// ... rest of screen implementation
}
```

### ViewModel with Lifecycle Methods

```dart
class ProductViewModel extends ViewModel {
  StreamSubscription? _subscription;

  @override
  void onInitialize() {
    super.onInitialize();
    // One-time setup
    print('ProductViewModel initialized');
    _subscription = _productService.watchProducts().listen((products) {
      // Handle products
    });
  }

  @override
  void onAppear() {
    super.onAppear();
    // Refresh data every time screen appears
    print('ProductScreen appeared - refreshing data');
    refreshProducts();
  }

  @override
  void onDisappear() {
    super.onDisappear();
    // Cleanup when leaving screen
    print('ProductScreen disappeared');
    _cancelPendingRequests();
  }

  @override
  void dispose() {
    // Dispose resources when ViewModel is disposed
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> refreshProducts() async {
    // Refresh logic
  }

  void _cancelPendingRequests() {
    // Cancel logic
  }
}
```

## Best Practices

1. **Always call super** when overriding lifecycle methods
2. **Keep lifecycle methods lightweight** - avoid heavy computations
3. **Use screen methods for UI-related tasks** - dialogs, animations, navigation
4. **Use ViewModel methods for data/business logic** - API calls, state updates
5. **Use `onInitialize` for one-time setup** - data that doesn't change
6. **Use `onAppear` for refreshing** - data that should update when returning to screen
7. **Use `onDisappear` for cleanup** - cancel timers, save drafts, stop animations
8. **Prefer `onAppear` over `onInitialize`** for data that might become stale

## When to Use Screen vs ViewModel Lifecycle

### Use Screen Lifecycle (`onScreenXxx`) for:

- Showing dialogs or bottom sheets
- Starting/stopping animations
- Requesting permissions
- Showing welcome tours/onboarding
- UI-specific setup/cleanup
- Focus management

### Use ViewModel Lifecycle (`onXxx`) for:

- Loading/refreshing data
- API calls
- State management
- Business logic
- Stream subscriptions
- Database operations

## Lifecycle Flow

```
Screen Created
    ↓
onInitialize() [once] ← Screen lifecycle
    ↓
onInitialize() [once] ← ViewModel lifecycle
    ↓
onAppear() [every time] ← Screen lifecycle
    ↓
onAppear() [every time] ← ViewModel lifecycle
    ↓
[Screen is visible]
    ↓
onDisappear() [when leaving] ← Screen lifecycle
    ↓
onDisappear() [when leaving] ← ViewModel lifecycle
```

## Migration from Old Pattern

### Before (manual initialization):

```dart
// Old pattern - manual check in build
if (shouldRefresh && !viewModel.isInitialized) {
WidgetsBinding.instance.addPostFrameCallback((_) {
onRefresh(viewModel);
});
}
```

### After (lifecycle methods):

```dart
// New pattern - automatic lifecycle
class MyViewModel extends ViewModel {
  @override
  void onInitialize() {
    super.onInitialize();
    loadData();
  }

  @override
  void onAppear() {
    super.onAppear();
    refreshData();
  }
}
```

## Notes

- All lifecycle methods are **optional** - only override what you need
- The lifecycle system is **backward compatible** - existing screens and ViewModels work without
  changes
- Lifecycle methods are called automatically - no manual triggering needed
- Works with all BaseScreen variants: BaseSearchableScreen, BaseListScreen,
  BaseSearchableListScreen, BaseFormScreen
- **Execution order**: Screen lifecycle methods are called **before** ViewModel lifecycle methods
- Screen methods receive the `onScreenXxx` prefix to distinguish them from ViewModel methods

