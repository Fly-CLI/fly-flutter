# Standard Analyzer Plugin Implementation

## Overview

This package implements custom lint rules using the standard analyzer plugin (`analyzer_plugin`), which works with `flutter analyze` and `dart analyze`.

## Implementation

The standard analyzer plugin implementation includes:

1. **Server Plugin Implementation**: `FoundationProjectLintsAnalyzerPlugin` extends `ServerPlugin`
2. **Error Reporter**: Uses `AnalysisError` from `protocol_common.dart`
3. **File Resolution**: Handles file resolution through the analysis context
4. **Plugin Registration**: Registered via `bin/plugin.dart` entry point

### Plugin Structure

- **Host package**: `foundation_project_lints`
- **Plugin code**: `lib/analyzer_plugin/foundation_project_lints_analyzer.dart`
- **Entry point**: `bin/plugin.dart` with `main(List<String> args, SendPort sendPort)`
- **ServerPlugin implementation**: Extends `ServerPlugin` with `analyzeFile` method
- **Error reporting**: Uses `AnalysisErrorsParams` and `channel.sendNotification()`

### Implementation Details

The implementation:

1. ✅ Extends `ServerPlugin` with required getters (`name`, `version`, `fileGlobsToAnalyze`)
2. ✅ Implements `analyzeFile` method with correct signature
3. ✅ Uses AST visitor to analyze code (`_ViewModelAsyncAnalyzerVisitor`)
4. ✅ Creates `AnalysisError` objects with correct parameters
5. ✅ Sends notifications via `channel.sendNotification()`

### ViewModel Async Rule

The plugin enforces that async methods in ViewModels use `runAsyncOperation()` for error handling and loading state management.

**Rule Logic:**
- Checks for async methods in classes extending `ViewModel`
- Skips private methods (starting with `_`)
- Skips lifecycle methods (`onInitialize`, `onAppear`, `onDisappear`, `onDispose`)
- Verifies that the method body uses `runAsyncOperation()`
- Reports violations with clear error messages

### Usage

The plugin is configured in `analysis_options.yaml`:

```yaml
analyzer:
  plugins:
    - foundation_project_lints
```

The plugin works automatically with:
- `flutter analyze`
- `dart analyze`
- IDE analysis tools

### Example Violation

```dart
class HomeViewModel extends ViewModel<HomeViewModelState> {
  Future<void> test() async {
    // This will trigger the lint rule
  }
}
```

The rule will report: `Async methods in ViewModels must use runAsyncOperation() for error handling and loading state management.`
