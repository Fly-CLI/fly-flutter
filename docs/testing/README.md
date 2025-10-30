# Fly CLI Testing Documentation

## Overview

This directory contains documentation and guides for testing Fly CLI features through natural usage scenarios.

## Quick Start

### For Developers

1. **Set up test project:**
   ```bash
   ./scripts/mcp/test-project.sh reset
   ```

2. **Test your CLI changes:**
   - Make changes to Fly CLI
   - Reload CLI: `./scripts/development/reload-cli.sh`
   - Restart Cursor to pick up changes
   - Use the test project to validate your changes
   - Reset project when needed

3. **Validate project:**
   ```bash
   ./scripts/mcp/test-project.sh validate
   ```

**For AI-Assisted Development with Cursor**, see [AI-Assisted Development Guide](./ai-assisted-development.md) for the complete workflow.

### For AI Assistants

1. **Discover available features:**
   ```bash
   ./scripts/mcp/list.sh --type=tools
   ./scripts/mcp/list.sh --type=prompts
   ```

2. **Use test project for testing:**
   - Test project is located at `examples/test_project/`
   - Call MCP tools to execute CLI commands on the test project
   - Validate results by checking project state

3. **Reset when needed:**
   - Delete and recreate test project as needed
   - Use `./scripts/mcp/test-project.sh reset`

## Guides

- **[AI Testing Guide](./ai-testing-guide.md)** - Comprehensive guide for AI assistants to test Fly CLI via MCP protocol
- **[AI-Assisted Development](./ai-assisted-development.md)** - Workflow guide for developers using AI assistants (Cursor) during CLI development

## Test Project

The test project at `examples/test_project/` serves as a dedicated Flutter project for validating Fly CLI capabilities. It includes:

- Feature-based architecture
- Multiple screens for testing navigation
- Services directory for testing service generation
- Test directory for testing test generation
- Realistic app structure that exercises all CLI capabilities

See `examples/test_project/README.md` for more details about the test project.

## Testing Workflow

1. **Discover** - List available CLI features via `mcp/list.sh`
2. **Execute** - Call MCP tools/prompts to test features on test project
3. **Validate** - Check project state after CLI commands
4. **Reset** - Clean up and recreate test project as needed

## Integration

This testing approach complements formal tests:

- **Unit Tests** - Test individual functions and classes
- **Integration Tests** - Test component interactions  
- **Natural Usage Testing** - Test CLI via MCP on test project (this system)
- **Manual Testing** - Human validation of UI/UX

All testing approaches work together to ensure CLI quality.

