# Fly MCP Tools Documentation

## Overview

Fly MCP provides 7 production-ready tools across 3 categories:
- **Diagnostic Tools**: Test connectivity and environment
- **Template Tools**: Manage Fly templates
- **Flutter Development Tools**: Project creation, running, and building

All tools support:
- ✅ JSON Schema validation
- ✅ Cancellation (`$/cancelRequest`)
- ✅ Progress notifications (`$/progress`)
- ✅ Timeout protection
- ✅ Concurrency limiting
- ✅ Safety metadata (readOnly, writesToDisk, requiresConfirmation)

---

## Diagnostic Tools

### `fly.echo`

**Purpose**: Test MCP server connectivity and basic functionality  
**Safety**: Read-only, idempotent  
**Timeout**: Default (5 minutes)

**Parameters**:
```json
{
  "message": "string" // Required: Message to echo back
}
```

**Returns**:
```json
{
  "message": "string" // Echoed message
}
```

**Example**:
```json
{
  "name": "fly.echo",
  "arguments": {
    "message": "Hello, MCP!"
  }
}
```

---

### `flutter.doctor`

**Purpose**: Run Flutter environment diagnostics  
**Safety**: Read-only, idempotent  
**Timeout**: Default (5 minutes)

**Parameters**: None

**Returns**:
```json
{
  "stdout": "string", // Flutter doctor output (truncated to 8KB)
  "exitCode": 0       // Process exit code
}
```

**Features**:
- Supports cancellation
- Progress notifications
- Output automatically truncated to fit assistant limits

**Use Case**: Verify Flutter SDK installation and environment health

---

## Template Management Tools

### `fly.template.list`

**Purpose**: List all available Fly templates  
**Safety**: Read-only, idempotent  
**Timeout**: Default (5 minutes)

**Parameters**: None

**Returns**:
```json
{
  "templates": [
    {
      "name": "string",           // Template identifier
      "description": "string",    // Template description
      "version": "string",       // Template version
      "features": ["string"],     // List of features
      "minFlutterSdk": "string",  // Minimum Flutter SDK
      "minDartSdk": "string"      // Minimum Dart SDK
    }
  ]
}
```

**Example**:
```json
{
  "name": "fly.template.list",
  "arguments": {}
}
```

---

### `fly.template.apply`

**Purpose**: Apply a Fly template to the workspace  
**Safety**: ✅ Writes to disk, ✅ Requires confirmation  
**Timeout**: 15 minutes (extended for generation)

**Parameters**:
```json
{
  "templateId": "string",      // Required: Template identifier
  "outputDirectory": "string", // Required: Target directory
  "variables": {               // Optional: Template variables
    "projectName": "string",
    "organization": "string",
    "platforms": ["string"]
  },
  "dryRun": false,             // Optional: Preview without applying
  "confirm": true              // Required: Explicit confirmation
}
```

**Returns**:
```json
{
  "success": true,
  "targetDirectory": "string",
  "filesGenerated": 42,
  "duration_ms": 5000,
  "message": "string"
}
```

**Safety Notes**:
- ⚠️ **Writes to disk**: Creates files in outputDirectory
- ⚠️ **Requires confirmation**: Must pass `confirm: true`
- ✅ **Dry-run available**: Use `dryRun: true` for safe preview

**Example**:
```json
{
  "name": "fly.template.apply",
  "arguments": {
    "templateId": "riverpod",
    "outputDirectory": "./my_project",
    "variables": {
      "projectName": "my_project",
      "organization": "com.example",
      "platforms": ["ios", "android"]
    },
    "dryRun": false,
    "confirm": true
  }
}
```

---

## Flutter Development Tools

### `flutter.create`

**Purpose**: Create a new Flutter project using Fly templates  
**Safety**: ✅ Writes to disk, ✅ Requires confirmation  
**Timeout**: 10 minutes (extended for project creation)

**Parameters**:
```json
{
  "projectName": "string",        // Required: Project name
  "template": "string",          // Optional: Template (default: "riverpod")
  "organization": "string",      // Optional: Organization (default: "com.example")
  "platforms": ["string"],       // Optional: Platforms (default: ["ios", "android"])
  "outputDirectory": "string",    // Optional: Output directory
  "confirm": true                 // Required: Explicit confirmation
}
```

**Returns**:
```json
{
  "success": true,
  "projectPath": "string",
  "filesGenerated": 42,
  "message": "string"
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

---

### `flutter.run`

**Purpose**: Run the current Flutter application  
**Safety**: Read-only (doesn't modify files)  
**Timeout**: 1 hour (extended for long-running apps)  
**Concurrency Limit**: 2 concurrent runs

**Parameters**:
```json
{
  "deviceId": "string",       // Optional: Target device ID
  "debug": true,              // Optional: Debug mode (default: true)
  "release": false,           // Optional: Release mode
  "profile": false,           // Optional: Profile mode
  "target": "string",         // Optional: Target file path
  "dartDefine": {             // Optional: Dart define variables
    "API_URL": "string"
  }
}
```

**Returns**:
```json
{
  "success": true,
  "processId": "string",
  "logResourceUri": "logs://run/{processId}",
  "exitCode": 0,
  "message": "string"
}
```

**Features**:
- Returns immediately (async execution)
- Logs available via `logs://run/{processId}` resource
- Supports cancellation (kills process)
- Progress notifications

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

**Access Logs**:
```json
{
  "method": "resources/read",
  "params": {
    "uri": "logs://run/flutter_run_1234567890"
  }
}
```

---

### `flutter.build`

**Purpose**: Build Flutter application for a target platform  
**Safety**: ✅ Writes to disk (build artifacts)  
**Timeout**: 30 minutes (extended for builds)  
**Concurrency Limit**: 3 concurrent builds

**Parameters**:
```json
{
  "platform": "string",       // Required: "android" | "ios" | "web" | "macos" | "windows" | "linux"
  "release": true,             // Optional: Release build (default: true)
  "debug": false,              // Optional: Debug build
  "profile": false,            // Optional: Profile build
  "target": "string",          // Optional: Target file path
  "dartDefine": {              // Optional: Dart define variables
    "BUILD_NUMBER": "string"
  }
}
```

**Returns**:
```json
{
  "success": true,
  "exitCode": 0,
  "buildPath": "string",
  "logResourceUri": "logs://build/{buildId}",
  "message": "string"
}
```

**Build Paths by Platform**:
- Android: `build/app/outputs/flutter-apk/app-release.apk`
- iOS: `build/ios/iphoneos/Runner.app`
- Web: `build/web`
- Others: `build/{platform}`

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

---

## Tool Safety Metadata

All tools expose safety metadata in `tools/list`:

- **readOnly**: Tool doesn't modify files (e.g., `fly.echo`, `fly.template.list`)
- **writesToDisk**: Tool creates/modifies files (e.g., `fly.template.apply`, `flutter.build`)
- **requiresConfirmation**: Tool requires explicit `confirm: true` parameter
- **idempotent**: Tool can be safely retried (same result on repeat calls)

---

## Timeout Configuration

Tools have configurable timeouts:

- **Default**: 5 minutes (300 seconds)
- **Extended timeouts**:
  - `flutter.build`: 30 minutes
  - `flutter.run`: 1 hour
  - `flutter.create`: 10 minutes
  - `fly.template.apply`: 15 minutes

Configure via `--default-timeout-seconds` flag or per-tool settings.

---

## Concurrency Limits

- **Global limit**: 10 concurrent tool executions (configurable)
- **Per-tool limits**:
  - `flutter.run`: 2 concurrent runs
  - `flutter.build`: 3 concurrent builds

When limit exceeded, tool returns `MCP_PERMISSION_DENIED` error with current/limit information.

---

## Error Handling

Tools return structured errors with MCP error codes:

- **-32602** (`MCP_INVALID_PARAMS`): Invalid parameters (with validation errors)
- **-32800** (`MCP_CANCELED`): Operation was cancelled
- **-32801** (`MCP_TIMEOUT`): Operation timed out
- **-32802** (`MCP_TOO_LARGE`): Response too large (use pagination)
- **-32803** (`MCP_PERMISSION_DENIED`): Permission denied or concurrency limit
- **-32804** (`MCP_NOT_FOUND`): Tool/resource not found

All errors include:
- `requestId`: Request identifier for correlation
- `tool`: Tool name (if applicable)
- `hint`: Helpful remediation message

---

## Best Practices

1. **Always use dry-run first**: Test destructive operations with `dryRun: true`
2. **Handle timeouts**: Configure appropriate timeouts for long-running operations
3. **Monitor concurrency**: Respect per-tool limits to avoid errors
4. **Use cancellation**: Cancel long-running operations when needed
5. **Check logs**: Use log resources for run/build operations
6. **Validate schemas**: All tools validate input; provide correct parameters

---

## Response Size Limits

- **Tool responses**: Automatically truncated if >8KB (assistant-friendly)
- **Resource reads**: Use pagination (`start`, `length` parameters)
- **Message size**: Configurable via `--max-message-mb` (default: 2MB)

For large outputs, use resource URIs (`logs://`, `workspace://`) instead of direct tool responses.

