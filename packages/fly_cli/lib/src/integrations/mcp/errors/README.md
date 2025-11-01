# MCP Error Handling

This directory contains error handling utilities for MCP (Model Context Protocol) tools, following
the patterns described in `docs/mcp/AI_INTEGRATION_GUIDE.md`.

## Overview

The MCP error handling system provides:

- **Structured error data** with actionable hints and remediation suggestions
- **Context-specific error messages** tailored to common failure scenarios
- **AI-friendly error responses** that help AI assistants resolve issues automatically

## Components

### McpError

The `McpError` class extends `StateError` and provides structured error information with hints and
remediation suggestions.

**Key Features:**

- MCP-specific error codes (aligned with MCP protocol)
- Structured error data with hints and remediation steps
- Factory methods for common error scenarios

**Example Usage:**

```dart
// Invalid parameters
throw McpError.invalidParams(
  tool: 'fly.template.apply',
  errors: ['Missing required parameter: templateId'],
  context: {'template_id': '', 'output_directory': './project'},
);

// Screen name validation
throw McpError.screenNameValidation(
  screenName: 'Home',
  context: {'suggested_name': 'home'},
);

// Template errors
throw McpError.templateError(
  templateId: 'riverpod',
  error: 'Template not found',
  variables: {'projectName': 'my_app'},
);
```

### McpErrorHints

The `McpErrorHints` class provides static methods for generating structured error data with hints
and remediation suggestions.

**Common Hint Generators:**

- `invalidParams()` - Parameter validation errors
- `toolNotFound()` - Tool not found errors
- `permissionDenied()` - Permission and concurrency errors
- `timeout()` - Timeout errors
- `resourceNotFound()` - Resource access errors
- `templateError()` - Template operation errors
- `validationError()` - Field validation errors
- `screenNameValidationError()` - Screen name validation (lowercase conversion)
- `fileSystemError()` - File system operation errors

**Example:**

```dart
final errorData = McpErrorHints.invalidParams(
  tool: 'fly.add.screen',
  errors: ['Missing required parameter: screenName'],
  context: {'feature': 'home'},
);
```

## Error Categories

### 1. Parameter Validation Errors

**MCP Error Code:** `-32602` (INVALID_PARAMS)

Errors that occur when tool parameters don't match the expected schema.

**Hints Include:**

- Missing required parameters
- Invalid parameter types
- Invalid enum values
- Nested object validation errors

### 2. Tool Not Found Errors

**MCP Error Code:** `-32804` (MCP_NOT_FOUND)

Errors that occur when a requested tool doesn't exist.

**Hints Include:**

- Suggestions to use `tools/list` to discover available tools
- Tool name spelling verification
- Workspace context requirements

### 3. Permission Denied Errors

**MCP Error Code:** `-32803` (MCP_PERMISSION_DENIED)

Errors that occur due to permission issues or concurrency limits.

**Hints Include:**

- Concurrency limit information (current/limit)
- Confirmation requirement reminders
- Workspace context verification

### 4. Timeout Errors

**MCP Error Code:** `-32801` (MCP_TIMEOUT)

Errors that occur when operations exceed timeout limits.

**Hints Include:**

- Timeout duration information
- Suggestions to check operation progress
- Recommendations to break operations into smaller steps

### 5. Template Errors

**MCP Error Code:** `-32603` (INTERNAL_ERROR)

Errors that occur during template operations.

**Hints Include:**

- Available template suggestions
- Template variable validation errors
- Compatibility issues

### 6. Validation Errors

**MCP Error Code:** `-32602` (INVALID_PARAMS)

Field-level validation errors with context-specific hints.

**Special Cases:**

- **Screen Names**: Automatic lowercase conversion hints
- **Paths**: Path traversal protection validation
- **Names**: Naming convention suggestions

## Integration with Tool Strategies

Tool strategies should use `McpError` for all error conditions:

```dart
@override
TypedToolHandler<TP, TR> createTypedHandler(
  CommandContext context,
  ResourceRegistry resourceRegistry,
) {
  return (params, {cancelToken, progressNotifier}) async {
    // Validate parameters
    if (params.screenName.isEmpty) {
      throw McpError.invalidParams(
        tool: name,
        errors: ['Missing required parameter: screenName'],
      );
    }

    // Validate conventions
    final screenNameLower = params.screenName.toLowerCase();
    if (params.screenName != screenNameLower) {
      throw McpError.screenNameValidation(
        screenName: params.screenName,
      );
    }

    // Operation-specific errors
    if (result is TemplateGenerationFailure) {
      throw McpError.templateError(
        templateId: 'screen',
        error: result.error,
      );
    }
  };
}
```

## Best Practices

1. **Always provide context** in error data to help AI assistants understand the failure
2. **Include actionable hints** that suggest specific remediation steps
3. **Use appropriate error codes** aligned with MCP protocol standards
4. **Include tool name** in all error data for better traceability
5. **Add validation hints** for common mistakes (e.g., lowercase conversion for screen names)

## Error Data Structure

All errors include structured data in the following format:

```dart
{
  'tool': 'fly.add.screen',           // Tool name
  'hint': 'Screen names must be lowercase',  // Actionable hint
  'remediation': [                    // Remediation steps
    'Convert screen name to lowercase: "Home" → "home"',
    'Use snake_case for multi-word names',
  ],
  'documentation': 'Fly convention: Screen names must be lowercase',
  // ... tool-specific context
}
```

## Future Enhancements

- Enhanced error correlation IDs for better tracing
- Error aggregation and statistics
- Machine-learned error pattern detection
- Context-aware error suggestions based on project state

