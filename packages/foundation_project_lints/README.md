# Foundation Project Lints

Custom lint rules for the Foundation Project using the standard analyzer plugin.

## ViewModel Async Rule

The `view_model_async_must_use_perform_async` rule enforces that async methods in ViewModels use `performAsync()` instead of manual try-catch blocks.

### ✅ Status

**The analyzer plugin is working correctly!** It successfully detects async methods in ViewModels that don't use `performAsync()`.

The plugin works with `flutter analyze` and `dart analyze` commands.

### Installation

Add this package as a dev dependency in your project:

```yaml
dev_dependencies:
  foundation_project_lints:
    path: ../../packages/foundation_project_lints
```

### Configuration

Enable the analyzer plugin in your `analysis_options.yaml`:

```yaml
analyzer:
  plugins:
    - foundation_project_lints
```

### Usage

The rule is automatically enabled when you run `flutter analyze` or `dart analyze`. It will report warnings for:

- Async methods in ViewModels that don't use `performAsync`
- Methods with manual try-catch blocks and state management
- Direct state assignments for loading/error states

### Notes

- The rule only checks public methods (not private methods starting with `_`)
- Lifecycle methods (`onInitialize`, `onAppear`, etc.) are excluded
- The rule checks for patterns like manual try-catch blocks and state assignments

### Testing

To test the rule:
1. Create an async method in a ViewModel that doesn't use `performAsync`
2. Run `flutter analyze` or `dart analyze`
3. The rule will report a violation

### Example Violation

```dart
class HomeViewModel extends ViewModel<HomeViewModelState> {
  Future<void> test() async {
    // This will trigger the lint rule
  }
}
```

The rule will report: `Async methods in ViewModels must use performAsync() for error handling and loading state management.`
