# AI Assistant Integration Guide for Fly CLI

## Overview

This guide provides comprehensive instructions for AI assistants (Cursor, Claude Desktop, GitHub
Copilot, etc.) to effectively integrate with the Fly CLI through the Model Context Protocol (MCP).
The Fly CLI is designed as an AI-native tool, providing structured JSON outputs, declarative
specifications, and a complete MCP server implementation for seamless AI integration.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Getting Started](#getting-started)
3. [MCP Tools Reference](#mcp-tools-reference)
4. [MCP Resources Reference](#mcp-resources-reference)
5. [MCP Prompts Reference](#mcp-prompts-reference)
6. [Best Practices](#best-practices)
7. [Error Handling](#error-handling)
8. [Common Patterns](#common-patterns)
9. [Troubleshooting](#troubleshooting)

---

## Architecture Overview

### Core Principles

1. **Always use MCP tools instead of direct CLI invocation**: The Fly CLI exposes all functionality
   through MCP tools. Never attempt to invoke the `fly` command directly from the command line.

2. **Structured JSON responses**: All MCP tools return structured JSON responses that are
   machine-readable and predictable.

3. **Safety-first design**: Tools include safety metadata (read-only, writes-to-disk,
   requires-confirmation) and built-in protections (timeouts, concurrency limits, cancellations).

4. **Resource-based file access**: Use MCP resources to read workspace files and logs instead of
   direct file system access.

5. **Prompt-driven scaffolding**: Use MCP prompts for common scaffolding tasks that require
   AI-generated code.

### Available Capabilities

- **7 Production-Ready Tools**: Diagnostic, template management, and Flutter development tools
- **3 Resource Types**: Workspace files, runtime logs, and build logs
- **4 Prompts**: Feature scaffolding, page scaffolding, API client generation, and lint fixing

---

## Getting Started

### Prerequisites

Before integrating with the Fly CLI MCP server, ensure:

1. **MCP Server is Running**: The server must be started with `fly mcp serve --stdio`
2. **Workspace Context**: Most tools require operating within a Flutter project workspace
3. **Flutter SDK**: Verify Flutter installation with `flutter.doctor` tool

### Initial Setup Verification

When beginning an interaction, verify the integration:

1. **Test Connectivity**: Call `fly.echo` with a test message
   ```json
   {
     "name": "fly.echo",
     "arguments": {
       "message": "Connection test"
     }
   }
   ```

2. **Check Environment**: Call `flutter.doctor` to verify Flutter SDK status
   ```json
   {
     "name": "flutter.doctor",
     "arguments": {}
   }
   ```

3. **Discover Available Tools**: Call `tools/list` to see all available tools
4. **Discover Available Resources**: Call `resources/list` to see resource types
5. **Discover Available Prompts**: Call `prompts/list` to see available prompts

### Understanding the Workspace

Before executing operations, understand the workspace context:

1. **Read Project Manifest**: Use `resources/read` to access `workspace://pubspec.yaml`
2. **Identify Project Type**: Check if this is a new project or existing project
3. **Verify Directory Structure**: Use `resources/list` to explore the workspace structure

---

## MCP Tools Reference

### Tool Categories

#### 1. Diagnostic Tools

##### `fly.echo`

- **Purpose**: Test MCP server connectivity
- **Safety**: Read-only, idempotent
- **Use When**: Verifying server connection at the start of interactions

**Example**:

```json
{
  "name": "fly.echo",
  "arguments": {
    "message": "Hello, Fly CLI"
  }
}
```

##### `flutter.doctor`

- **Purpose**: Run Flutter environment diagnostics
- **Safety**: Read-only, idempotent
- **Use When**: Verifying Flutter SDK installation and environment health
- **Returns**: Flutter doctor output (truncated to 8KB) and exit code

**Example**:

```json
{
  "name": "flutter.doctor",
  "arguments": {}
}
```

#### 2. Template Management Tools

##### `fly.template.list`

- **Purpose**: List all available Fly templates
- **Safety**: Read-only, idempotent
- **Use When**: Discovering available project templates before creation

**Example**:

```json
{
  "name": "fly.template.list",
  "arguments": {}
}
```

**Returns**:

```json
{
  "templates": [
    {
      "name": "riverpod",
      "description": "Riverpod-based project template",
      "version": "1.0.0",
      "features": ["state-management", "dependency-injection"],
      "minFlutterSdk": "3.0.0",
      "minDartSdk": "3.0.0"
    }
  ]
}
```

##### `fly.template.apply`

- **Purpose**: Apply a Fly template to the workspace
- **Safety**: ⚠️ Writes to disk, ⚠️ Requires confirmation
- **Use When**: Creating new features, screens, or services from templates
- **Best Practice**: Always use `dryRun: true` first to preview changes

**Parameters**:

```json
{
  "templateId": "string",      // Required: Template identifier
  "outputDirectory": "string",  // Required: Target directory
  "variables": {               // Optional: Template variables
    "projectName": "string",
    "organization": "string",
    "platforms": ["string"]
  },
  "dryRun": false,             // Optional: Preview without applying (RECOMMENDED)
  "confirm": true              // Required: Explicit confirmation
}
```

**Example with Dry Run**:

```json
{
  "name": "fly.template.apply",
  "arguments": {
    "templateId": "screen",
    "outputDirectory": "./lib/features/home/presentation",
    "variables": {
      "name": "home",
      "type": "list",
      "withViewModel": true
    },
    "dryRun": true,
    "confirm": true
  }
}
```

#### 3. Flutter Development Tools

##### `flutter.create`

- **Purpose**: Create a new Flutter project using Fly templates
- **Safety**: ⚠️ Writes to disk, ⚠️ Requires confirmation
- **Timeout**: 10 minutes (extended for project creation)
- **Use When**: Creating a new Flutter project from scratch

**Parameters**:

```json
{
  "projectName": "string",        // Required: Project name
  "template": "string",          // Optional: Template (default: "riverpod")
  "organization": "string",      // Optional: Organization (default: "com.example")
  "platforms": ["string"],       // Optional: Platforms (default: ["ios", "android"])
  "outputDirectory": "string",   // Optional: Output directory
  "confirm": true                 // Required: Explicit confirmation
}
```

**Example**:

```json
{
  "name": "flutter.create",
  "arguments": {
    "projectName": "my_flutter_app",
    "template": "riverpod",
    "organization": "com.mycompany",
    "platforms": ["ios", "android", "web"],
    "confirm": true
  }
}
```

##### `flutter.run`

- **Purpose**: Run the current Flutter application
- **Safety**: Read-only (doesn't modify files)
- **Timeout**: 1 hour (extended for long-running apps)
- **Concurrency Limit**: 2 concurrent runs
- **Returns**: Process ID and log resource URI for accessing logs

**Parameters**:

```json
{
  "deviceId": "string",       // Optional: Target device ID
  "debug": true,              // Optional: Debug mode (default: true)
  "release": false,           // Optional: Release mode
  "profile": false,           // Optional: Profile mode
  "target": "string",         // Optional: Target file path
  "dartDefine": {            // Optional: Dart define variables
    "API_URL": "string"
  }
}
```

**Example**:

```json
{
  "name": "flutter.run",
  "arguments": {
    "debug": true,
    "deviceId": "emulator-5554",
    "dartDefine": {
      "API_URL": "https://api.example.com"
    }
  }
}
```

**Accessing Logs**: After calling `flutter.run`, use the returned `logResourceUri` to read logs:

```json
{
  "method": "resources/read",
  "params": {
    "uri": "logs://run/flutter_run_1234567890"
  }
}
```

##### `flutter.build`

- **Purpose**: Build Flutter application for a target platform
- **Safety**: ⚠️ Writes to disk (build artifacts)
- **Timeout**: 30 minutes (extended for builds)
- **Concurrency Limit**: 3 concurrent builds
- **Returns**: Build path and log resource URI

**Parameters**:

```json
{
  "platform": "string",       // Required: "android" | "ios" | "web" | "macos" | "windows" | "linux"
  "release": true,             // Optional: Release build (default: true)
  "debug": false,             // Optional: Debug build
  "profile": false,            // Optional: Profile build
  "target": "string",          // Optional: Target file path
  "dartDefine": {             // Optional: Dart define variables
    "BUILD_NUMBER": "string"
  }
}
```

**Example**:

```json
{
  "name": "flutter.build",
  "arguments": {
    "platform": "android",
    "release": true,
    "dartDefine": {
      "BUILD_NUMBER": "42",
      "VERSION_NAME": "1.0.0"
    }
  }
}
```

**Accessing Build Logs**: Use the returned `logResourceUri` to read build logs:

```json
{
  "method": "resources/read",
  "params": {
    "uri": "logs://build/flutter_build_1234567890"
  }
}
```

### Tool Safety Metadata

All tools expose safety metadata in their definitions:

- **`readOnly`**: Tool doesn't modify files (e.g., `fly.echo`, `fly.template.list`)
- **`writesToDisk`**: Tool creates/modifies files (e.g., `fly.template.apply`, `flutter.build`)
- **`requiresConfirmation`**: Tool requires explicit `confirm: true` parameter
- **`idempotent`**: Tool can be safely retried (same result on repeat calls)

**Always check tool metadata before calling** to understand the safety implications.

---

## MCP Resources Reference

### Resource Types

#### 1. Workspace Resources (`workspace://`)

**Purpose**: Read-only access to workspace files relevant to Flutter development.

**Supported File Types**:

- Dart files: `.dart`
- Configuration: `.yaml`, `.yml`, `pubspec.yaml`, `analysis_options.yaml`
- Native platform files: `.gradle`, `.kt`, `.kts`, `.swift`, `.mm`, `.m`, `.xml`, `.plist`
- Build files: `CMakeLists.txt`, `Podfile`, `Info.plist`

**Security**: All paths are sandboxed to workspace root, path traversal is blocked, and only
allowlisted file types are accessible.

**List Resources**:

```json
{
  "method": "resources/list",
  "params": {
    "directory": "string",    // Optional: Directory to list (default: workspace root)
    "page": 0,                // Optional: Page number (default: 0)
    "pageSize": 100          // Optional: Items per page (default: 100)
  }
}
```

**Read Resource**:

```json
{
  "method": "resources/read",
  "params": {
    "uri": "workspace:///path/to/file.dart",
    "start": 0,              // Optional: Byte offset (default: 0)
    "length": 1000           // Optional: Bytes to read (default: all)
  }
}
```

**Example: Read Project Manifest**:

```json
{
  "method": "resources/read",
  "params": {
    "uri": "workspace://pubspec.yaml"
  }
}
```

#### 2. Log Resources

##### Runtime Logs (`logs://run/{processId}`)

**Purpose**: Access Flutter run logs from `flutter.run` tool execution.

**Usage**: After calling `flutter.run`, use the returned `logResourceUri` to read logs:

```json
{
  "method": "resources/read",
  "params": {
    "uri": "logs://run/flutter_run_1234567890"
  }
}
```

##### Build Logs (`logs://build/{buildId}`)

**Purpose**: Access Flutter build logs from `flutter.build` tool execution.

**Usage**: After calling `flutter.build`, use the returned `logResourceUri` to read logs:

```json
{
  "method": "resources/read",
  "params": {
    "uri": "logs://build/flutter_build_1234567890"
  }
}
```

**Log Limits**:

- Storage: In-memory bounded buffers
- Size Limit: 100KB per log
- Entry Limit: 1000 entries per log
- Behavior: Circular buffer (oldest entries removed when full)

### Resource Best Practices

1. **Use Pagination**: For large directory listings, use `page` and `pageSize` parameters
2. **Byte-Range Reads**: For large files, read in chunks using `start` and `length`
3. **Poll Logs**: For long-running operations, poll log resources periodically
4. **Respect Limits**: Large responses may be truncated; use resource URIs instead

---

## MCP Prompts Reference

MCP prompts provide pre-configured templates for common AI interactions, particularly useful for
scaffolding complex structures that require AI-generated code.

### Available Prompts

#### 1. `fly.scaffold.page`

**Purpose**: Generate a new Flutter page (widget + route) with Fly conventions.

**Parameters**:

```json
{
  "name": "string",           // Required: The name of the page
  "stateManagement": "string" // Optional: State management approach (default: "riverpod")
}
```

**Use When**: Creating a new page that requires a widget, route, and basic tests.

#### 2. `fly.scaffold.feature`

**Purpose**: Generate a complete Flutter feature module with screens, services, and routing.

**Parameters**:

```json
{
  "featureName": "string",     // Required: The name of the feature
  "screens": ["string"],      // Optional: Array of screen names
  "services": ["string"],     // Optional: Array of service names
  "stateManagement": "string" // Optional: State management approach (default: "riverpod")
}
```

**Use When**: Scaffolding a complete feature module with domain/data/presentation layers.

#### 3. `fly.scaffold.api_client`

**Purpose**: Generate an API client for network operations.

**Parameters**: Check `prompts/list` for current schema.

**Use When**: Creating API client services for network communication.

#### 4. `fly.fix_lints`

**Purpose**: Generate code fixes for linting issues.

**Parameters**: Check `prompts/list` for current schema.

**Use When**: Addressing linting errors in the codebase.

### Using Prompts

1. **List Available Prompts**: Call `prompts/list` to see all available prompts and their schemas
2. **Get Prompt**: Call `prompts/get` with the prompt ID and arguments to get AI-generated guidance
3. **Follow Prompt Output**: Use the prompt output as guidance for code generation or modifications

**Example**:

```json
{
  "method": "prompts/get",
  "params": {
    "id": "fly.scaffold.feature",
    "arguments": {
      "featureName": "catalog",
      "screens": ["ProductList", "ProductDetail"],
      "stateManagement": "riverpod"
    }
  }
}
```

---

## Best Practices

### 1. Command Discovery and Validation

**Always discover commands before executing them**:

1. **List available tools**: Call `tools/list` to see all available tools and their schemas
2. **Read tool schemas**: Understand required parameters, optional parameters, and safety metadata
3. **Verify workspace context**: Read `pubspec.yaml` to understand project structure before
   operations
4. **Check tool metadata**: Review `readOnly`, `writesToDisk`, `requiresConfirmation` flags

### 2. Safe Execution Patterns

#### Use Dry Run First

**Always use `dryRun: true` for destructive operations**:

```json
{
  "name": "fly.template.apply",
  "arguments": {
    "templateId": "screen",
    "dryRun": true,  // Preview changes first
    "confirm": true
  }
}
```

#### Confirm Destructive Operations

**Always provide explicit confirmation**:

```json
{
  "name": "fly.template.apply",
  "arguments": {
    "confirm": true  // Required for writes-to-disk operations
  }
}
```

#### Validate Parameters

**Validate all parameters match tool schemas before calling**:

- Check required vs optional parameters
- Verify parameter types (string, number, boolean, array, object)
- Ensure enum values match allowed options
- Validate nested objects match schema structure

### 3. Error Handling

#### Understand Error Codes

The MCP server uses structured error codes:

- **`-32602`** (`MCP_INVALID_PARAMS`): Invalid parameters - check parameter schema
- **`-32800`** (`MCP_CANCELED`): Operation was cancelled
- **`-32801`** (`MCP_TIMEOUT`): Operation timed out - consider increasing timeout
- **`-32802`** (`MCP_TOO_LARGE`): Response too large - use pagination or resource URIs
- **`-32803`** (`MCP_PERMISSION_DENIED`): Permission denied or concurrency limit exceeded
- **`-32804`** (`MCP_NOT_FOUND`): Tool/resource/prompt not found

#### Handle Errors Gracefully

1. **Read error messages**: MCP errors include helpful hints for remediation
2. **Check concurrency limits**: If you get permission denied, check if concurrency limit is
   exceeded
3. **Retry idempotent operations**: For idempotent tools, safely retry after errors
4. **Validate input**: If you get invalid params, re-read the tool schema and validate inputs

### 4. Resource Management

#### Use Resources for File Access

**Never access files directly**. Always use MCP resources:

```json
{
  "method": "resources/read",
  "params": {
    "uri": "workspace://lib/main.dart"
  }
}
```

#### Paginate Large Lists

**For large directory listings, use pagination**:

```json
{
  "method": "resources/list",
  "params": {
    "page": 0,
    "pageSize": 50  // Reasonable page size
  }
}
```

#### Read Logs for Long-Running Operations

**After calling `flutter.run` or `flutter.build`, read logs using the returned URI**:

```json
{
  "method": "resources/read",
  "params": {
    "uri": "logs://run/flutter_run_1234567890"
  }
}
```

### 5. Timeout and Concurrency Management

#### Respect Timeout Limits

- **Default timeout**: 5 minutes
- **Extended timeouts**: Some tools have longer timeouts (flutter.build: 30 min, flutter.run: 1
  hour)
- **Handle timeouts**: If operations timeout, consider breaking them into smaller operations

#### Understand Concurrency Limits

- **Global limit**: 10 concurrent tool executions (configurable)
- **Per-tool limits**:
    - `flutter.run`: 2 concurrent runs
    - `flutter.build`: 3 concurrent builds
- **Check before calling**: If you need to call multiple tools, be aware of limits

### 6. Command Validation

#### Validate Command Names

**Before executing a command**:

1. List available tools with `tools/list`
2. Verify the tool name exists
3. Check tool parameters match your intended operation

#### Validate Command Parameters

**Ensure all parameters match tool schema**:

1. Required parameters are provided
2. Parameter types are correct
3. Enum values are valid
4. Nested objects match schema structure

#### Example Validation Flow

```
1. User request: "add a screen called Home"
2. List tools: Call tools/list
3. Find relevant tool: fly.template.apply (or specific screen tool if available)
4. Read tool schema: Understand parameters (name, type, withViewModel, etc.)
5. Validate parameters: 
   - Screen name "Home" → convert to lowercase "home" (Fly convention)
   - Determine screen type (list, detail, form, etc.)
   - Check if withViewModel is needed
6. Use dry-run: Preview changes first
7. Execute: Apply template with confirm: true
```

---

## Error Handling

### Common Error Scenarios

#### 1. Invalid Parameters

**Error**: `MCP_INVALID_PARAMS` (-32602)

**Resolution**:

1. Re-read tool schema from `tools/list`
2. Verify all required parameters are provided
3. Check parameter types match schema
4. Validate nested objects match structure

**Example**: If you get invalid params for `fly.template.apply`, check:

- `templateId` is a valid template name
- `outputDirectory` is a valid path
- `variables` match template variable schema
- `confirm: true` is provided for writes-to-disk operations

#### 2. Tool Not Found

**Error**: `MCP_NOT_FOUND` (-32804)

**Resolution**:

1. Call `tools/list` to see available tools
2. Verify tool name spelling
3. Check if tool requires specific workspace context
4. Verify MCP server is properly initialized

#### 3. Permission Denied

**Error**: `MCP_PERMISSION_DENIED` (-32803)

**Possible Causes**:

- Concurrency limit exceeded
- Missing confirmation for destructive operations
- Invalid workspace context

**Resolution**:

1. Check concurrency limits - wait for other operations to complete
2. Ensure `confirm: true` is provided for writes-to-disk operations
3. Verify workspace context is correct
4. Check if operation requires specific permissions

#### 4. Timeout

**Error**: `MCP_TIMEOUT` (-32801)

**Resolution**:

1. Check if operation is still running (read logs if available)
2. Consider breaking operation into smaller steps
3. Verify system resources are sufficient
4. Retry operation if it's idempotent

#### 5. Response Too Large

**Error**: `MCP_TOO_LARGE` (-32802)

**Resolution**:

1. Use pagination for large lists (`page`, `pageSize`)
2. Use byte-range reads for large files (`start`, `length`)
3. Use resource URIs instead of direct responses
4. Break large operations into smaller chunks

### Error Response Structure

All errors include structured information:

```json
{
  "code": -32602,
  "message": "Invalid parameters",
  "data": {
    "tool": "fly.template.apply",
    "errors": [
      "Missing required parameter: templateId",
      "Invalid parameter type: outputDirectory (expected string)"
    ],
    "hint": "Check tool schema with tools/list for correct parameters"
  }
}
```

**Always read error data** for actionable remediation hints.

---

## Common Patterns

### Pattern 1: Adding a Screen

```
1. Verify workspace context: Read pubspec.yaml to understand project
2. Discover screen template: Call tools/list and find screen-related tool
3. Validate screen name: Convert to lowercase (Fly convention: "Home" → "home")
4. Determine screen type: List, detail, form, auth, settings, etc.
5. Use dry-run: Preview screen generation
6. Execute: Apply template with confirm: true
7. Verify: Read generated files using resources/read
8. Fix any issues: Address template bugs or missing code
```

### Pattern 2: Creating a New Project

```
1. Verify environment: Call flutter.doctor
2. List templates: Call fly.template.list to see available templates
3. Choose template: Select appropriate template (e.g., "riverpod")
4. Create project: Call flutter.create with project parameters
5. Verify creation: Read generated pubspec.yaml
6. Initialize: Suggest next steps (flutter pub get, etc.)
```

### Pattern 3: Running and Debugging

```
1. Verify project: Read pubspec.yaml to confirm Flutter project
2. Run app: Call flutter.run with appropriate parameters
3. Access logs: Read logs using returned logResourceUri
4. Monitor: Poll logs periodically for updates
5. Debug: Analyze logs for errors or issues
6. Cancel if needed: Use cancelRequest if app needs to be stopped
```

### Pattern 4: Building for Production

```
1. Verify project: Confirm Flutter project structure
2. Determine platform: Identify target platform (android, ios, web, etc.)
3. Build: Call flutter.build with platform and release mode
4. Access logs: Read build logs using returned logResourceUri
5. Verify output: Check build path in response
6. Handle errors: Address any build errors from logs
```

### Pattern 5: Scaffolding a Feature

```
1. Understand requirements: Parse user request for feature details
2. Use prompt: Call prompts/get with fly.scaffold.feature
3. Follow guidance: Use prompt output to generate feature structure
4. Generate screens: Use fly.template.apply for individual screens
5. Generate services: Use appropriate tools for service generation
6. Configure routing: Set up routes based on prompt guidance
7. Verify structure: Use resources/list to confirm feature structure
```

---

## Troubleshooting

### Issue: Tool calls fail with "Tool not found"

**Diagnosis**:

1. Call `tools/list` to verify tool exists
2. Check tool name spelling (case-sensitive)
3. Verify MCP server is running and initialized

**Resolution**:

- Re-read tool list
- Use exact tool names from `tools/list` response
- Restart MCP server if needed

### Issue: Commands fail with validation errors

**Diagnosis**:

1. Read tool schema from `tools/list`
2. Compare parameters with schema requirements
3. Check for required vs optional parameters

**Resolution**:

- Validate all parameters match schema
- Provide all required parameters
- Check parameter types and structure

### Issue: Template generation produces incorrect code

**Diagnosis**:

1. Read generated files using resources
2. Compare with Fly conventions
3. Check for template bugs or missing code

**Resolution**:

- Use dry-run first to preview changes
- Fix template issues if found
- Report template bugs if systematic

### Issue: Concurrency limits exceeded

**Diagnosis**:

- Error message includes current/limit information
- Multiple operations running simultaneously

**Resolution**:

- Wait for other operations to complete
- Queue operations if needed
- Reduce concurrent operations

### Issue: Timeout errors on long operations

**Diagnosis**:

- Operation exceeds default or per-tool timeout
- Check operation logs for progress

**Resolution**:

- Verify operation is making progress (read logs)
- Consider breaking into smaller operations
- Retry if operation is idempotent

---

## Additional Resources

### Documentation

- **Quickstart**: `docs/mcp/quickstart.md` - Setup and configuration
- **Tools Reference**: `docs/mcp/tools.md` - Detailed tool documentation
- **Resources Reference**: `docs/mcp/resources.md` - Resource documentation
- **Architecture**: `docs/mcp/SERVER_ARCHITECTURE.md` - Server implementation details
- **Tools Report**: `docs/mcp/MCP_TOOLS_REPORT.md` - Comprehensive tool catalog

### Testing

- **Test Project**: `examples/test_project/` - Dedicated test bed for CLI features
- **Testing Guide**: `docs/testing/ai-testing-guide.md` - AI assistant testing workflows

### Support

- **MCP Tools List**: Use `tools/list` to see all available tools
- **MCP Resources List**: Use `resources/list` to see available resources
- **MCP Prompts List**: Use `prompts/list` to see available prompts

---

## Summary

The Fly CLI MCP integration provides a robust, safe, and comprehensive interface for AI assistants.
Key principles:

1. **Always use MCP tools** - Never invoke CLI commands directly
2. **Validate before executing** - Read tool schemas and verify parameters
3. **Use dry-run first** - Preview changes before applying
4. **Handle errors gracefully** - Read error messages and follow hints
5. **Use resources for file access** - Never access files directly
6. **Respect safety metadata** - Understand tool safety implications
7. **Follow Fly conventions** - Screen names lowercase, feature-based structure, etc.

By following this guide, AI assistants can effectively integrate with the Fly CLI to provide
powerful Flutter development assistance while maintaining safety, reliability, and correctness.

