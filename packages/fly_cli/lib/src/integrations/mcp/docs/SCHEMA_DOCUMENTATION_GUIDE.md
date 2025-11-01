# Tool Schema Documentation Guide

This guide describes best practices for documenting MCP tool schemas in Fly CLI.

## Overview

Tool schemas should include comprehensive descriptions, examples, validation rules, and enum value
documentation to help AI assistants understand tool usage and provide better assistance.

## Documentation Standards

### 1. Tool Description

The tool description should:

- Explain what the tool does
- Mention any important constraints (e.g., "Screen names must be lowercase")
- Note timeout or concurrency requirements for long-running operations
- Include relevant safety information

**Example:**

```dart
@override
String get description =>
    'Add a new screen component to the current Flutter project. '
    'Screen names must be lowercase (e.g., "home" not "Home"). '
    'The tool generates a screen widget with optional view model, tests, validation, and navigation setup.';
```

### 2. Parameter Schema Description

The `paramsSchema` should have:

- A top-level description explaining the parameter set
- Individual property descriptions for each field
- Examples where helpful
- Validation rules and constraints
- Default values documented

**Example:**

```dart
@override
ObjectSchema get paramsSchema => ObjectSchema(
  description:
      'Parameters for adding a screen. Screen names follow Fly conventions: lowercase with snake_case for multi-word names.',
  properties: {
    'screenName': Schema.string(
      description:
          'The name of the screen to create. Must be lowercase and contain only letters, numbers, and underscores. '
          'Examples: "home", "product_list", "user_profile". '
          'Note: Names will be automatically converted to lowercase if provided in uppercase.',
    ),
    // ... more properties
  },
  required: ['screenName'],
  additionalProperties: false,
);
```

### 3. Enum Value Documentation

Enum values should have:

- Clear descriptions explaining what each value means
- Use cases for each enum option
- Examples where appropriate

**Example:**

```dart
'screenType': Schema.string(
  description:
      'The type of screen to generate. Each type has different structure and behavior: '
      '- "list": Displays a list of items (e.g., product list) '
      '- "detail": Shows detailed information about a single item '
      '- "form": Input form for creating/editing data '
      '- "auth": Authentication screen (login, signup) '
      '- "settings": Application settings screen',
  enumValues: ['list', 'detail', 'form', 'auth', 'settings'],
),
```

### 4. Result Schema Description

The `resultSchema` should:

- Describe what the result contains
- Explain each field's purpose
- Document special URIs or resource references (e.g., logResourceUri)
- Note any nullable fields

**Example:**

```dart
@override
ObjectSchema get resultSchema => ObjectSchema(
  description:
      'Result from Flutter build. Contains success status, build path, and log resource URI for accessing build logs.',
  properties: {
    'success': Schema.bool(
      description: 'Whether the build completed successfully',
    ),
    'logResourceUri': Schema.string(
      description:
          'URI for accessing build logs via resources/read. Format: logs://build/{buildId}. '
          'Use this to read build logs and diagnose issues.',
    ),
    // ... more properties
  },
  required: ['success', 'message'],
);
```

## Common Patterns

### Required Parameters

Always document why a parameter is required and what happens if it's missing:

```dart
'projectName': Schema.string(
  description:
      'The name of the Flutter project to create. Required: used as the project identifier and directory name.',
),
```

### Optional Parameters with Defaults

Document default values clearly:

```dart
'template': Schema.string(
  description:
      'The Fly template to use. Defaults to "riverpod" if not specified. '
      'Use fly.template.list to see all available templates.',
),
```

### Mutually Exclusive Options

Document when parameters are mutually exclusive:

```dart
'release': Schema.bool(
  description:
      'Build in release mode (optimized, production-ready). Defaults to true if no build mode specified. '
      'Mutually exclusive with debug and profile modes.',
),
'debug': Schema.bool(
  description:
      'Build in debug mode (unoptimized, with debugging symbols). '
      'Mutually exclusive with release and profile modes.',
),
```

### Resource URIs

Always document resource URI formats and how to use them:

```dart
'logResourceUri': Schema.string(
  description:
      'URI for accessing runtime logs via resources/read. Format: logs://run/{processId}. '
      'Use this to read application logs and monitor execution. Poll periodically for long-running apps.',
),
```

### Confirmation Requirements

Document when confirmation is required:

```dart
'confirm': Schema.bool(
  description:
      'Explicit confirmation required for writes-to-disk operations. Must be true to create project.',
),
```

### Dry-Run Support

Document dry-run functionality:

```dart
'dryRun': Schema.bool(
  description:
      'If true, preview the template application without actually creating files. '
      'Recommended for testing template parameters before applying.',
),
```

## Validation Rules

Document validation rules in parameter descriptions:

- **Naming conventions**: "Must be lowercase", "Use snake_case", etc.
- **Format requirements**: "Reverse domain notation", "Must start with a letter", etc.
- **Allowed values**: List enum values or valid ranges
- **Constraints**: "Maximum 100 characters", "Must be a valid path", etc.

## Examples in Descriptions

Include examples in descriptions where helpful:

```dart
'projectName': Schema.string(
  description:
      'The name of the Flutter project to create. Must be lowercase, start with a letter, and contain only '
      'letters, numbers, and underscores. Examples: "my_app", "flutter_project".',
),
```

## Checklist

When documenting a tool schema, ensure:

- [ ] Tool description explains purpose and constraints
- [ ] Parameter schema has top-level description
- [ ] All parameters have individual descriptions
- [ ] Required parameters are clearly marked
- [ ] Default values are documented
- [ ] Enum values have explanations
- [ ] Validation rules are documented
- [ ] Examples are provided where helpful
- [ ] Result schema has description
- [ ] Result fields are documented
- [ ] Resource URIs are explained
- [ ] Mutually exclusive options are noted
- [ ] Confirmation requirements are clear
- [ ] Timeout/concurrency info is mentioned in description

## See Also

- `docs/mcp/AI_INTEGRATION_GUIDE.md` - AI integration patterns
- `docs/mcp/AI_ASSISTANT_PROMPT.md` - AI assistant guidelines
- `packages/fly_cli/lib/src/features/mcp/errors/README.md` - Error handling documentation

