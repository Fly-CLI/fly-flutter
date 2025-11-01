# Type Safety Improvements Guide

## Overview

This guide documents the type safety patterns used in Fly CLI's MCP integration and recommendations
for maintaining type safety.

## Current Implementation Status

### ✅ Type-Safe Tool Parameters

All MCP tools use typed parameter classes:

```dart
// Typed parameter class
class FlyTemplateApplyParams extends ToolParameter {
  final String templateId;
  final String outputDirectory;
  final Map<String, dynamic>? variables;
  final bool? dryRun;
  
  factory FlyTemplateApplyParams.fromJson(Map<String, Object?> json);
  Map<String, Object?> toJson();
}
```

### ✅ Type-Safe Tool Results

All MCP tools use typed result classes:

```dart
// Typed result class
class FlyTemplateApplyResult extends ToolResult {
  final bool success;
  final String message;
  final int filesGenerated;
  
  factory FlyTemplateApplyResult.fromJson(Map<String, Object?> json);
  Map<String, Object?> toJson();
}
```

### ✅ Type-Safe Tool Handlers

Tool handlers use typed signatures:

```dart
typedef TypedToolHandler<TP extends ToolParameter, TR extends ToolResult> = 
  Future<TR> Function(
    TP params, {
    CancellationToken? cancelToken,
    ProgressNotifier? progressNotifier,
  });
```

## Type Safety Patterns

### Parameter Parsing

Parameters are parsed with type checking:

```dart
factory FlyTemplateApplyParams.fromJson(Map<String, Object?> json) {
  return FlyTemplateApplyParams(
    templateId: json['templateId'] as String? ?? '',
    outputDirectory: json['outputDirectory'] as String? ?? '',
    variables: json['variables'] as Map<String, dynamic>?,
    dryRun: json['dryRun'] as bool?,
  );
}
```

### Null Safety

All nullable fields use explicit null checks:

```dart
final variables = params.variables ?? <String, dynamic>{};
final dryRun = params.dryRun ?? false;
```

### Schema Validation

Type validation happens at multiple levels:

1. **JSON Schema Validation**: Validates structure
2. **Enhanced Schema Validator**: Validates types and values
3. **Type Assertion**: Asserts types during parsing

## Protocol Boundary

### Map<String, Object?> Usage

The MCP protocol requires `Map<String, Object?>` at the protocol boundary. This is acceptable as
it's isolated to:

- Protocol handlers (MCP server)
- JSON serialization/deserialization
- Schema validation

### Type Conversion

Type conversion happens at the protocol boundary:

```dart
// Protocol handler converts Map to typed params
final params = paramsFromJson(mapParams);

// Typed handler processes typed params
final result = await typedHandler(params);

// Protocol handler converts typed result to Map
return result.toJson();
```

## Best Practices

### ✅ DO

1. **Use Typed Classes**: Always use typed parameter and result classes
2. **Type Assertions**: Use explicit type assertions in JSON parsing
3. **Null Safety**: Use null-safe operators and default values
4. **Schema Validation**: Validate types using JSON Schema and enhanced validator
5. **Document Types**: Document type requirements in schema descriptions

### ❌ DON'T

1. **Don't Use `dynamic`**: Avoid `dynamic` type in tool implementations
2. **Don't Skip Validation**: Always validate types before processing
3. **Don't Assume Types**: Never assume JSON types without validation
4. **Don't Bypass Type Safety**: Don't bypass type safety for convenience

## Future Improvements

### Potential Enhancements

1. **Code Generation**: Generate typed classes from JSON Schema
2. **Stronger Validation**: Runtime type checking for all parameters
3. **Type-Safe Schemas**: Generate Dart types from JSON Schema
4. **Compile-Time Checks**: Use code generation for compile-time safety

### Recommended Patterns

```dart
// Future: Code-generated types
@JsonSerializable()
class FlyTemplateApplyParams {
  final String templateId;
  final String outputDirectory;
  
  factory FlyTemplateApplyParams.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

## Migration Guide

### Replacing Map<String, Object?>

If you encounter `Map<String, Object?>` usage:

1. **Identify Usage**: Find all `Map<String, Object?>` in tool handlers
2. **Create Typed Class**: Create typed parameter/result class
3. **Update Handler**: Update handler to use typed class
4. **Update Protocol**: Update protocol boundary conversion
5. **Add Tests**: Add tests for type validation

### Example Migration

**Before:**

```dart
ToolHandler createHandler(...) {
  return (Map<String, Object?> params, ...) async {
    final templateId = params['templateId'] as String?;
    // ...
  };
}
```

**After:**

```dart
TypedToolHandler<FlyTemplateApplyParams, FlyTemplateApplyResult> createTypedHandler(...) {
  return (params, ...) async {
    final templateId = params.templateId;
    // ...
  };
}
```

## Testing Type Safety

### Unit Tests

Test type validation:

```dart
test('should validate parameter types', () {
  expect(
    () => FlyTemplateApplyParams.fromJson({
      'templateId': 123, // Invalid: should be String
    }),
    throwsA(isA<TypeError>()),
  );
});
```

### Integration Tests

Test type safety in integration:

```dart
test('should handle type mismatches gracefully', () async {
  try {
    await handler({
      'templateId': 123, // Invalid type
    });
    fail('Should have thrown error');
  } catch (error) {
    expect(error, isA<McpError>());
    expect((error as McpError).code, 'invalid_params');
  }
});
```

## Related Documentation

- [AI Integration Guide](./AI_INTEGRATION_GUIDE.md)
- [Practical Integration Guide](./PRACTICAL_INTEGRATION_GUIDE.md)
- [Schema Documentation Guide](../packages/fly_cli/lib/src/features/mcp/docs/SCHEMA_DOCUMENTATION_GUIDE.md)

