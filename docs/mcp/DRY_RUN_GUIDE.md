# Dry-Run Pattern Guide

## Overview

Dry-run is a critical safety feature that allows AI assistants to preview changes before applying
them. This guide explains how dry-run is implemented in Fly CLI's MCP tools and how to use it
effectively.

## Implementation Status

### Tools with Dry-Run Support

✅ **fly.template.apply** - Full dry-run support

- Preview template generation without applying
- Shows files that would be generated
- Returns preview structure in response

✅ **fly.add.screen** - Supports dry-run via template system

- Uses `fly.template.apply` under the hood
- Can preview screen generation

✅ **flutter.create** - Supports dry-run via template system

- Uses `fly.template.apply` under the hood
- Can preview project creation

## Dry-Run Pattern

### Schema Definition

Dry-run is supported through a boolean `dryRun` parameter in tool schemas:

```dart
'dryRun': Schema.bool(
  description: 'If true, preview changes without applying them. '
    'Returns preview structure instead of actual generation result.',
),
```

### Tool Handler Implementation

Tools that support dry-run check the `dryRun` parameter and delegate to the template system:

```dart
final dryRun = params.dryRun ?? false;

if (dryRun) {
  // Generate preview without applying
  final preview = await templateManager.generatePreview(...);
  return TemplateGenerationDryRun(...);
} else {
  // Perform actual generation
  return await templateManager.generate(...);
}
```

### Result Format

Dry-run results use `TemplateGenerationDryRun`:

```dart
class TemplateGenerationDryRun extends TemplateGenerationResult {
  final TemplateInfo template;
  final String targetDirectory;
  final TemplateVariables variables;
}
```

## Usage Examples

### Preview Template Application

```json
{
  "tool": "fly.template.apply",
  "params": {
    "templateId": "screen",
    "outputDirectory": "/path/to/output",
    "variables": {
      "screenName": "home",
      "feature": "main"
    },
    "dryRun": true
  }
}
```

**Response:**

```json
{
  "success": true,
  "type": "dryRun",
  "template": {
    "name": "screen",
    "version": "1.0.0"
  },
  "targetDirectory": "/path/to/output",
  "variables": {
    "screenName": "home",
    "feature": "main"
  },
  "preview": {
    "files": [
      {
        "path": "lib/features/main/presentation/home_screen.dart",
        "content": "..."
      }
    ]
  }
}
```

### Apply Template After Preview

```json
{
  "tool": "fly.template.apply",
  "params": {
    "templateId": "screen",
    "outputDirectory": "/path/to/output",
    "variables": {
      "screenName": "home",
      "feature": "main"
    },
    "dryRun": false,
    "confirm": true
  }
}
```

## Best Practices

### For AI Assistants

1. **Always Preview First**: Use `dryRun: true` for destructive operations
2. **Review Preview**: Check the preview structure before applying
3. **Confirm Before Apply**: Only set `dryRun: false` after user confirmation
4. **Handle Preview Errors**: Dry-run validation errors should be caught early

### For Tool Implementations

1. **Support Dry-Run**: All destructive tools should support dry-run
2. **Validate in Dry-Run**: Perform full validation in dry-run mode
3. **Clear Preview Format**: Return structured preview data
4. **Document Preview Structure**: Clearly document what preview includes

## Validation

Dry-run performs full validation:

- ✅ Parameter validation
- ✅ Variable validation
- ✅ Template compatibility checks
- ✅ Path validation
- ✅ Permission checks

## Error Handling

Dry-run errors follow the same pattern as regular operations:

```dart
try {
  final result = await tool(params.copyWith(dryRun: true));
  if (result is TemplateGenerationDryRun) {
    // Preview successful
    return result;
  }
} catch (error) {
  // Handle validation or preview errors
}
```

## Future Enhancements

Potential improvements:

- [ ] Enhanced preview format with file diffs
- [ ] Preview visualization in structured format
- [ ] Incremental preview (show changes only)
- [ ] Preview comparison (compare multiple previews)
- [ ] Preview validation (check for conflicts)

## Related Documentation

- [AI Integration Guide](./AI_INTEGRATION_GUIDE.md)
- [Practical Integration Guide](./PRACTICAL_INTEGRATION_GUIDE.md)
- [Tool Schema Documentation Guide](../packages/fly_cli/lib/src/features/mcp/docs/SCHEMA_DOCUMENTATION_GUIDE.md)

