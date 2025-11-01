# AI-Assisted Development Workflow

This guide explains the standard workflow for developing Fly CLI using AI assistants like Cursor for
testing during development.

## Overview

When developing Fly CLI, you can use AI assistants (like Cursor) to test your changes via the MCP (
Model Context Protocol) server. This workflow allows you to:

- Make code changes to Fly CLI
- Quickly reload the CLI with your changes
- Test changes using AI assistants via MCP tools
- Iterate rapidly on features

## Prerequisites

Before starting, ensure you have:

1. **Fly CLI installed locally** for development
2. **Cursor configured** with MCP server
3. **Test project** set up at `examples/test_project/`
4. **Flutter SDK** installed and in PATH

## Initial Setup

### 1. Install CLI Locally

Install Fly CLI from local source:

```bash
./scripts/setup/install.sh
```

This activates the CLI using `dart pub global activate --source path`, so it will always use your
local code changes.

### 2. Set Up Cursor MCP Integration

Configure Cursor to use the Fly MCP server:

```bash
./scripts/mcp/setup-cursor.sh
```

This creates `.cursor/mcp.json` with the MCP server configuration.

### 3. Create Test Project

Set up the test project for validating CLI changes:

```bash
./scripts/mcp/test-project.sh reset
```

This creates a Flutter project at `examples/test_project/` using the riverpod template.

### 4. Restart Cursor

**Important**: After initial setup, restart Cursor to load the MCP configuration.

## Development Iteration Cycle

The standard workflow when making CLI changes:

### Step 1: Make Code Changes

Make your changes to Fly CLI code in `packages/fly_cli/`.

### Step 2: Reload CLI

After making changes, reload the CLI to use your updated code:

```bash
./scripts/development/reload-cli.sh
```

Or use the full development cycle script:

```bash
./scripts/development/dev-cycle.sh
```

### Step 3: Restart Cursor

**Critical**: After reloading the CLI, restart Cursor so it picks up the new CLI version.

The MCP server runs `fly mcp serve --stdio`, which uses the `fly` command. Since we're using
`dart pub global activate --source path`, the newly installed `fly` command will have your latest
changes.

### Step 4: Test with AI Assistant

Once Cursor is restarted, you can test your changes:

1. **In Cursor chat**, ask it to test CLI features:
    - "Test the `fly add screen` command on the test project"
    - "Add a new screen called ProductDetail to the catalog feature"
    - "Validate the test project structure"

2. **Cursor will use MCP tools** like:
    - `fly.add.screen` - Add a screen
    - `fly.add.service` - Add a service
    - `fly.template.list` - List templates
    - `flutter.build` - Build the project

3. **Results are validated** in `examples/test_project/`

### Step 5: Validate Results

Check that your CLI changes work correctly:

```bash
./scripts/mcp/test-project.sh validate
```

Or manually check:

- Files were created in correct locations
- Code follows Fly conventions
- Project compiles (`flutter analyze` in test project)
- Project builds (`flutter build apk --debug` in test project)

### Step 6: Reset Test Project (if needed)

If the test project gets into a bad state:

```bash
./scripts/mcp/test-project.sh reset
```

## Quick Reference

### Common Commands

**Reload CLI after changes:**

```bash
./scripts/development/reload-cli.sh
```

**Full development cycle:**

```bash
./scripts/development/dev-cycle.sh
```

**Check test project status:**

```bash
./scripts/mcp/test-project.sh status
```

**Validate test project:**

```bash
./scripts/mcp/test-project.sh validate
```

**Reset test project:**

```bash
./scripts/mcp/test-project.sh reset
```

**List available MCP tools:**

```bash
./scripts/mcp/list.sh --type=tools
```

### Development Workflow Scripts

The project includes automation scripts for common workflows:

1. **`reload-cli.sh`** - Quick CLI reinstall with Cursor restart reminder
2. **`dev-cycle.sh`** - Complete cycle (reload → validate → next steps)

## Testing Scenarios

### Scenario 1: Testing Screen Generation

1. Make changes to screen template generation code
2. Run `./scripts/development/reload-cli.sh`
3. Restart Cursor
4. In Cursor: "Add a ProductDetail screen to the catalog feature"
5. Verify files created in `examples/test_project/lib/features/catalog/`

### Scenario 2: Testing Service Generation

1. Modify service generation logic
2. Run `./scripts/development/dev-cycle.sh`
3. Restart Cursor
4. In Cursor: "Add an ApiService to the core feature"
5. Check service files and structure

### Scenario 3: Testing Template Changes

1. Update template files
2. Reload CLI
3. Restart Cursor
4. Reset test project: `./scripts/mcp/test-project.sh reset`
5. Test project creation via Cursor

## Troubleshooting

### Cursor Not Picking Up Changes

**Problem**: Cursor still uses old CLI version after changes.

**Solution**:

1. Ensure you ran `./scripts/development/reload-cli.sh`
2. **Restart Cursor completely** (quit and reopen)
3. Check CLI version: `fly --version` in terminal
4. Verify MCP server is using correct CLI: Check `.cursor/mcp.json`

### MCP Server Errors

**Problem**: MCP tools fail or timeout.

**Solution**:

1. Check Fly CLI is installed: `fly --version`
2. Verify MCP configuration: `./scripts/mcp/verify.sh`
3. Check Flutter SDK: `flutter doctor`
4. Restart Cursor and try again

### Test Project Issues

**Problem**: Test project is in bad state or won't compile.

**Solution**:

1. Reset test project: `./scripts/mcp/test-project.sh reset`
2. Validate project: `./scripts/mcp/test-project.sh validate`
3. Check Flutter SDK compatibility
4. Run `flutter pub get` in test project manually

### CLI Installation Fails

**Problem**: `./scripts/setup/install.sh` fails.

**Solution**:

1. Ensure you're in project root
2. Check `packages/fly_cli` exists
3. Verify Dart SDK is installed: `dart --version`
4. Try verbose mode: `./scripts/setup/install.sh --verbose`

## Integration with Other Testing

This AI-assisted testing complements other testing approaches:

- **Unit Tests** - `./scripts/development/test-unit.sh`
- **Integration Tests** - `./scripts/development/test-integration.sh`
- **E2E Tests** - `./scripts/development/test-e2e.sh`
- **AI-Assisted Testing** - This workflow (via MCP)

Run unit tests after making changes:

```bash
./scripts/development/test-changed.sh
```

Run all tests before committing:

```bash
./scripts/development/test.sh
```

## Best Practices

1. **Always reload CLI** after making changes before testing
2. **Restart Cursor** after reloading CLI to pick up changes
3. **Reset test project** between major feature tests
4. **Validate frequently** using `./scripts/mcp/test-project.sh validate`
5. **Run unit tests** in addition to AI-assisted testing
6. **Check generated code** manually to ensure it follows conventions

## Workflow Summary

```
1. Make CLI code changes
   ↓
2. Run ./scripts/development/reload-cli.sh
   ↓
3. Restart Cursor
   ↓
4. Test via Cursor (MCP tools)
   ↓
5. Validate results
   ↓
6. Reset test project if needed
   ↓
7. Iterate
```

## See Also

- **[AI Testing Guide](./ai-testing-guide.md)** - Guide for AI assistants using MCP
- **[Test Project README](../examples/test_project/README.md)** - Test project details
- **[MCP Quickstart](../mcp/quickstart.md)** - MCP setup and usage
- **[Development Scripts](../../scripts/README.md)** - All development scripts

