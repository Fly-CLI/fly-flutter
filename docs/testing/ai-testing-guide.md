# AI Assistant Testing Guide for Fly CLI

This guide explains how AI assistants can test Fly CLI capabilities using the test project via MCP
protocol.

## Overview

The `examples/test_project/` directory contains a Flutter project specifically designed as a test
bed for validating Fly CLI features. AI assistants can use MCP tools and prompts to test CLI
capabilities naturally.

## Prerequisites

1. MCP server is running (via `fly mcp serve --stdio`)
2. AI assistant is configured to use Fly MCP server
3. Test project exists at `examples/test_project/`

## Testing Workflow

### 1. Discover Available Features

First, discover what CLI features are available:

**List MCP Tools:**

```bash
./scripts/mcp/list.sh --type=tools
```

**List MCP Prompts:**

```bash
./scripts/mcp/list.sh --type=prompts
```

**List MCP Resources:**

```bash
./scripts/mcp/list.sh --type=resources
```

### 2. Test MCP Tools

Call MCP tools to execute CLI commands:

**Example: Test Template Listing**

- Call MCP tool: `fly.template.list`
- Verify it returns available templates
- Validate JSON structure

**Example: Test Adding a Screen**

- Call MCP tool: `fly.add.screen` with parameters:
  ```json
  {
    "name": "ProductDetail",
    "feature": "catalog",
    "withViewModel": true
  }
  ```
- Verify screen files are created in test project
- Check that files follow Fly conventions
- Validate code compiles

**Example: Test Adding a Service**

- Call MCP tool: `fly.add.service` with parameters:
  ```json
  {
    "name": "ApiService",
    "feature": "core",
    "type": "api"
  }
  ```
- Verify service files are created
- Check service structure matches Fly conventions

### 3. Test MCP Prompts

Call MCP prompts to test template rendering:

**Example: Test Feature Scaffolding Prompt**

- Call MCP prompt: `fly.scaffold.feature` with arguments:
  ```json
  {
    "featureName": "Checkout",
    "screens": ["Cart", "Payment", "Confirmation"],
    "services": ["PaymentService"],
    "stateManagement": "riverpod"
  }
  ```
- Verify prompt renders correctly
- Check rendered output structure
- Validate template variables are substituted

### 4. Validate Results

After executing CLI commands via MCP:

1. **Check Project Structure**:
    - Verify files are created in correct locations
    - Check directory structure matches Fly conventions
    - Ensure imports are correct

2. **Validate Code Quality**:
    - Run `flutter analyze` on test project
    - Check for compilation errors
    - Verify code follows Fly patterns

3. **Test Functionality**:
    - Run `flutter pub get` in test project
    - Run `flutter build apk --debug`
    - Check that project compiles successfully

### 5. Reset Project When Needed

To start fresh testing:

1. **Delete Test Project**:
   ```bash
   rm -rf examples/test_project
   ```

2. **Recreate Project** (via MCP or CLI):
    - Call `fly.template.apply` with riverpod template
    - Or use CLI: `cd examples && fly create test_project --template=riverpod`

## Common Test Scenarios

### Scenario 1: Add a New Feature

1. Discover available tools: `fly.add.screen`, `fly.add.service`
2. Add feature screens via `fly.add.screen`
3. Add feature services via `fly.add.service`
4. Verify files are created correctly
5. Check imports and routing are updated

### Scenario 2: Build and Run

1. Build project via `flutter.build` MCP tool
2. Run project via `flutter.run` MCP tool
3. Verify project runs without errors
4. Check build output is valid

### Scenario 3: Template Application

1. List templates via `fly.template.list`
2. Apply template via `fly.template.apply`
3. Verify project structure matches template
4. Check generated code follows conventions

### Scenario 4: Prompt Rendering

1. List prompts via `mcp/list.sh --type=prompts`
2. Call prompt with sample arguments
3. Verify rendered output structure
4. Check template variables are substituted correctly

## Validation Checklist

After testing CLI features, verify:

- [ ] Files are created in correct locations
- [ ] Code compiles without errors
- [ ] Project structure follows Fly conventions
- [ ] Imports are correct
- [ ] Routing is updated (if applicable)
- [ ] Services are properly structured
- [ ] State management is set up correctly
- [ ] Tests can be generated (if applicable)
- [ ] Build succeeds
- [ ] Project runs without errors

## Troubleshooting

**Project doesn't compile:**

- Check Flutter SDK version compatibility
- Verify all dependencies are in pubspec.yaml
- Run `flutter pub get` to fetch dependencies
- Check for syntax errors in generated code

**Files not created:**

- Verify MCP tool was called with correct parameters
- Check working directory is correct
- Ensure project path is valid
- Check file permissions

**MCP tool errors:**

- Verify MCP server is running
- Check tool parameters match schema
- Review error messages in MCP server logs
- Ensure CLI is installed and in PATH

## Best Practices

1. **Start Fresh**: Reset test project between major test runs
2. **Test Incrementally**: Test one feature at a time
3. **Validate Early**: Check results immediately after each command
4. **Use Real Scenarios**: Test realistic user workflows
5. **Document Issues**: Report any problems found during testing

## Integration with Development

This testing system complements formal tests:

- **Unit Tests**: Test individual functions and classes
- **Integration Tests**: Test component interactions
- **Natural Usage Testing**: Test CLI via MCP (this system)
- **Manual Testing**: Human validation of UI/UX

All testing approaches work together to ensure CLI quality.

