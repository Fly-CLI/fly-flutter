# MCP Feature Tests

## Overview

This directory contains comprehensive unit tests for the MCP (Model Context Protocol) feature of Fly
CLI, covering validation, error handling, progress notifications, structured logging, and
resource/prompt management.

## Test Coverage

### Validation Tests

- **`validation/enhanced_schema_validator_test.dart`**: Tests for enhanced JSON Schema validation
    - Required field validation
    - Type mismatch detection
    - Enum value validation with suggestions
    - Nested object validation
    - Array item validation
    - Additional properties restriction
    - Multiple error reporting

### Error Handling Tests

- **`errors/mcp_error_test.dart`**: Tests for structured tool errors
    - Invalid parameter errors
    - Template errors
    - Screen name validation errors
    - Field-level error context

- **`resources/resource_error_test.dart`**: Tests for structured resource errors
    - Invalid URI errors
    - Path traversal detection
    - File not found errors
    - Permission denied errors
    - Resource type validation

- **`prompts/prompt_error_test.dart`**: Tests for structured prompt errors
    - Missing variable errors
    - Invalid variable type errors
    - Invalid variable value errors
    - Template syntax errors
    - Template rendering errors

### Validation Tests

- **`prompts/prompt_validator_test.dart`**: Tests for prompt variable validation
    - Required variable validation
    - Variable type validation
    - Value constraint validation (length, pattern, enum)
    - Arguments format validation

### Utility Tests

- **`utils/progress_helpers_test.dart`**: Tests for progress notification helpers
    - Progress stage enums
    - Stage notification
    - Multiple stage notifications

- **`utils/tool_logger_test.dart`**: Tests for structured logging utilities
    - Correlation ID generation
    - Tool start/complete/error logging
    - Progress logging
    - Performance metrics tracking
    - Child logger creation

## Running Tests

### Run all MCP tests

```bash
cd packages/fly_cli
dart test test/features/mcp/
```

### Run specific test categories

```bash
# Validation tests
dart test test/features/mcp/validation/

# Error handling tests
dart test test/features/mcp/errors/

# Prompt tests
dart test test/features/mcp/prompts/

# Utility tests
dart test test/features/mcp/utils/
```

### Run with coverage

```bash
dart test test/features/mcp/ --coverage=coverage
genhtml coverage/lcov.info -o coverage/html
```

## Test Structure

Tests follow the standard Dart test structure:

- Use `test` package for unit tests
- Group related tests with `group()`
- Use descriptive test names
- Mock external dependencies
- Test both success and error paths

## Coverage Goals

- **Validation Logic**: >80% coverage
- **Error Handling**: >70% coverage
- **Utility Functions**: >70% coverage
- **Overall MCP Feature**: >60% coverage

## Adding New Tests

When adding new MCP features:

1. **Create test file** in appropriate subdirectory
2. **Test error paths** - All error conditions should be tested
3. **Test validation** - All validation logic should be covered
4. **Test edge cases** - Null values, empty strings, invalid types
5. **Mock dependencies** - Use test doubles for external services

### Example Test Structure

```dart
import 'package:fly_cli/src/integrations/mcp/...';
import 'package:test/test.dart';

void main() {
  group('FeatureName', () {
    setUp(() {
      // Setup test fixtures
    });

    tearDown(() {
      // Cleanup
    });

    group('success cases', () {
      test('should handle valid input', () {
        // Test implementation
      });
    });

    group('error cases', () {
      test('should handle invalid input', () {
        // Test error handling
      });
    });
  });
}
```

## Notes

- Tests use `package:test` framework
- Mock implementations are provided where needed
- Test fixtures should be reusable
- Tests should be independent and isolated
- Use descriptive assertions

