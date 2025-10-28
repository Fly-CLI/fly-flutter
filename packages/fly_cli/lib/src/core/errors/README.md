# Simplified Error Handling System

This document describes the simplified error handling system implemented in Fly CLI, focusing on structured error codes and consistent error context.

## Overview

The simplified error handling system provides:
- **Structured Error Codes**: Semantic error codes for programmatic handling
- **Consistent Error Context**: Automatic collection of relevant context information
- **Simple Integration**: Easy to use in commands without complex abstractions

## Core Components

### 1. Error Codes (`error_codes.dart`)

Structured error codes organized by category:

```dart
enum ErrorCode {
  // User Errors (E1xxx)
  invalidProjectName('E1001', ...),
  invalidTemplateName('E1002', ...),
  missingRequiredArgument('E1003', ...),
  
  // System Errors (E2xxx)
  permissionDenied('E2001', ...),
  networkError('E2002', ...),
  fileSystemError('E2004', ...),
  
  // Integration Errors (E3xxx)
  flutterSdkNotFound('E3001', ...),
  templateNotFound('E3003', ...),
  templateGenerationFailed('E3005', ...),
  
  // Internal Errors (E4xxx)
  internalError('E4001', ...),
  unknownError('E4999', ...),
}
```

Each error code includes:
- **Code**: Unique identifier (e.g., "E1001")
- **Category**: Semantic grouping (user, system, integration, internal)
- **Severity**: Impact level (error, critical)
- **Message**: Default error message
- **Suggestion**: Default suggestion for resolution

### 2. Error Context (`error_context.dart`)

Simple static helper methods for creating consistent error context:

```dart
class ErrorContext {
  // Command context
  static Map<String, dynamic> forCommand(
    String commandName, {
    List<String>? arguments,
    Map<String, dynamic>? extra,
  });
  
  // Validation context
  static Map<String, dynamic> forValidation(
    String fieldName,
    dynamic value,
    String reason,
  );
  
  // File operation context
  static Map<String, dynamic> forFileOperation(
    String operation,
    String path, {
    String? error,
  });
  
  // Template operation context
  static Map<String, dynamic> forTemplateOperation(
    String operation,
    String templateName, {
    String? outputPath,
    Map<String, dynamic>? variables,
  });
  
  // Project operation context
  static Map<String, dynamic> forProjectOperation(
    String operation,
    String projectName, {
    String? projectPath,
    String? projectType,
  });
  
  // Network operation context
  static Map<String, dynamic> forNetworkOperation(
    String operation,
    String url, {
    int? statusCode,
    Duration? timeout,
  });
  
  // Permission error context
  static Map<String, dynamic> forPermissionError(
    String operation,
    String path, {
    String? requiredPermission,
  });
  
  // System error context
  static Map<String, dynamic> forSystemError(
    String operation, {
    String? resource,
    String? error,
  });
  
  // Basic context with custom fields
  static Map<String, dynamic> basic({
    required String operation,
    Map<String, dynamic>? extra,
  });
}
```

### 3. Enhanced CommandResult

Simplified `CommandResult` with error code and context support:

```dart
class CommandResult {
  // Core fields
  final bool success;
  final String command;
  final String message;
  final Map<String, dynamic>? data;
  final List<NextStep>? nextSteps;
  final String? suggestion;
  final Map<String, dynamic>? metadata;
  
  // New error fields
  final ErrorCode? errorCode;
  final Map<String, dynamic>? errorContext;
  
  // Simple factory methods
  factory CommandResult.success({...});
  factory CommandResult.error({
    required String message,
    String? suggestion,
    Map<String, dynamic>? metadata,
    ErrorCode? errorCode,
    Map<String, dynamic>? context,
  });
}
```

## Usage Examples

### Basic Error Handling

```dart
@override
Future<CommandResult> execute() async {
  final projectName = argResults!.rest.first;
  
  // Validate input
  if (!_isValidProjectName(projectName)) {
    return CommandResult.error(
      message: 'Invalid project name: $projectName',
      suggestion: 'Use lowercase letters, numbers, and underscores only',
      errorCode: ErrorCode.invalidProjectName,
      context: ErrorContext.forValidation(
        'project_name',
        projectName,
        'Must be lowercase with underscores',
      ),
    );
  }
  
  // Command logic...
  try {
    // ... create project
    return CommandResult.success(
      command: 'create',
      message: 'Project created successfully',
    );
  } catch (e) {
    return CommandResult.error(
      message: 'Failed to create project: $e',
      suggestion: 'Check permissions and try again',
      errorCode: ErrorCode.fileSystemError,
      context: ErrorContext.forFileOperation(
        'create_project',
        projectName,
        error: e.toString(),
      ),
    );
  }
}
```

### Template Operations

```dart
try {
  final result = await templateManager.generateProject(
    templateName: template,
    projectName: projectName,
    outputDirectory: context.workingDirectory,
    variables: templateVariables,
  );
  
  if (result is TemplateGenerationFailure) {
    return CommandResult.error(
      message: 'Failed to generate project: ${result.error}',
      suggestion: 'Check template availability and try again',
      errorCode: ErrorCode.templateGenerationFailed,
      context: ErrorContext.forTemplateOperation(
        'generate_project',
        template,
        outputPath: projectName,
        variables: templateVariables.toMap(),
      ),
    );
  }
  
  return CommandResult.success(
    command: 'create',
    message: 'Project created successfully',
  );
} catch (e) {
  return CommandResult.error(
    message: 'Template generation failed: $e',
    suggestion: 'Check template configuration',
    errorCode: ErrorCode.templateGenerationFailed,
    context: ErrorContext.forTemplateOperation(
      'generate_project',
      template,
      outputPath: projectName,
    ),
  );
}
```

### System Diagnostics

```dart
try {
  final results = await systemChecker.runAllChecks(checks);
  final issues = results.where((result) => !result.healthy).toList();
  
  if (issues.isNotEmpty) {
    return CommandResult.error(
      message: 'Found ${issues.length} system issues',
      suggestion: 'Run "fly doctor --fix" to attempt fixes',
      errorCode: ErrorCode.environmentError,
      context: ErrorContext.forSystemError(
        'system_diagnostics',
        error: 'Found ${issues.length} issues',
      ),
    );
  }
  
  return CommandResult.success(
    command: 'doctor',
    message: 'All system checks passed',
  );
} catch (e) {
  return CommandResult.error(
    message: 'Failed to run system checks: $e',
    suggestion: 'Check your system configuration',
    errorCode: ErrorCode.environmentError,
    context: ErrorContext.forCommand(
      'doctor',
      arguments: argResults?.arguments,
      extra: {'error': e.toString()},
    ),
  );
}
```

## Error Code Reference

### User Errors (E1xxx)
- `E1001` - Invalid project name
- `E1002` - Invalid template name
- `E1003` - Missing required argument
- `E1004` - Invalid argument value
- `E1005` - Project already exists
- `E1006` - Invalid organization identifier
- `E1007` - Invalid platform list
- `E1008` - Invalid feature name
- `E1009` - Invalid service name
- `E1010` - Invalid screen name

### System Errors (E2xxx)
- `E2001` - Permission denied
- `E2002` - Network connection error
- `E2003` - Insufficient disk space
- `E2004` - File system error
- `E2005` - Operation timed out
- `E2006` - Resource unavailable
- `E2007` - Process execution error
- `E2008` - Environment configuration error

### Integration Errors (E3xxx)
- `E3001` - Flutter SDK not found
- `E3002` - Dart SDK not found
- `E3003` - Template not found
- `E3004` - Template validation failed
- `E3005` - Template generation failed
- `E3006` - Mason template engine error
- `E3007` - Pub cache error
- `E3008` - Platform tools error

### Internal Errors (E4xxx)
- `E4001` - Internal error
- `E4002` - Invalid state
- `E4003` - Configuration error
- `E4004` - Dependency injection error
- `E4005` - Middleware error
- `E4006` - Validation error
- `E4007` - Lifecycle error
- `E4999` - Unknown error

## Best Practices

### 1. Use Appropriate Error Codes
- Choose the most specific error code that matches the situation
- Use `ErrorCode.unknownError` only as a last resort
- Prefer user errors (E1xxx) for input validation issues

### 2. Provide Helpful Context
- Use the appropriate `ErrorContext` helper method
- Include relevant information like file paths, template names, etc.
- Add custom fields using the `extra` parameter

### 3. Write Clear Messages
- Use clear, actionable error messages
- Avoid technical jargon when possible
- Include the specific value that caused the error

### 4. Provide Useful Suggestions
- Give specific steps to resolve the issue
- Suggest alternative approaches when appropriate
- Reference other commands that might help

### 5. Handle Errors Gracefully
- Catch exceptions and convert them to structured errors
- Don't let raw exceptions bubble up to the user
- Always provide context about what was being attempted

## Migration Guide

### From Complex Error System

If you were using the complex error system with `FlyError`, `RecoveryStrategy`, etc.:

1. **Remove complex imports**:
   ```dart
   // Remove these
   import '../../errors/fly_error.dart';
   import '../../errors/recovery_strategy.dart';
   import '../../errors/error_recovery_middleware.dart';
   
   // Keep these
   import '../../errors/error_codes.dart';
   import '../../errors/error_context.dart';
   ```

2. **Simplify error creation**:
   ```dart
   // Old complex way
   final flyError = FlyError.validation(
     code: ErrorCode.invalidProjectName,
     message: 'Invalid project name',
     recoveryStrategies: [RecoveryStrategy.retry],
   );
   final result = CommandResult.fromFlyError(flyError);
   
   // New simple way
   final result = CommandResult.error(
     message: 'Invalid project name',
     errorCode: ErrorCode.invalidProjectName,
     context: ErrorContext.forValidation('project_name', name, 'Invalid format'),
   );
   ```

3. **Remove recovery middleware**:
   ```dart
   // Remove from middleware list
   List<CommandMiddleware> get middleware => [
     // const ErrorRecoveryMiddleware(), // Remove this
   ];
   ```

### From Basic Error Handling

If you were using basic `CommandResult.error()`:

1. **Add error codes**:
   ```dart
   // Old
   return CommandResult.error(
     message: 'Invalid project name',
     suggestion: 'Use lowercase letters only',
   );
   
   // New
   return CommandResult.error(
     message: 'Invalid project name',
     suggestion: 'Use lowercase letters only',
     errorCode: ErrorCode.invalidProjectName,
     context: ErrorContext.forValidation('project_name', name, 'Invalid format'),
   );
   ```

2. **Add context where helpful**:
   ```dart
   // Add context for file operations
   context: ErrorContext.forFileOperation('create_file', filePath),
   
   // Add context for template operations
   context: ErrorContext.forTemplateOperation('generate', templateName),
   
   // Add context for network operations
   context: ErrorContext.forNetworkOperation('fetch', url),
   ```

## Benefits

### ✅ Achieved Goals
- **Structured Error Codes**: All errors have semantic codes for programmatic handling
- **Consistent Error Context**: Automatic collection of relevant context information
- **Simple Integration**: Easy to use without complex abstractions
- **Backward Compatible**: Existing code continues to work
- **Maintainable**: Much less code to maintain

### ✅ What We Kept
- Error codes with semantic categories
- Consistent error context collection
- Debug mode support
- JSON output for AI integration
- Human-readable error display

### ✅ What We Simplified
- Removed Freezed dependencies
- Removed automatic recovery middleware
- Removed complex error type hierarchy
- Removed operation batching system
- Removed multiple output formatters
- Simplified error context from fluent API to static methods

## Troubleshooting

### Common Issues

1. **Missing error codes**: Always provide an `ErrorCode` for new errors
2. **Missing context**: Use appropriate `ErrorContext` helper methods
3. **Generic error messages**: Write specific, actionable error messages
4. **Missing suggestions**: Always provide helpful suggestions for resolution

### Debug Mode

Use `--debug` flag to get verbose error output:

```bash
fly create my_app --debug
```

This will show:
- Full error context
- Stack traces
- Detailed JSON output

### JSON Output

Use `--output=json` for programmatic consumption:

```bash
fly create my_app --output=json
```

This provides structured JSON with error codes and context for AI integration.