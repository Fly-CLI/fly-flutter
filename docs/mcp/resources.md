# MCP Resources Documentation

## Overview

Fly MCP provides two types of resources:
- **Workspace Resources**: Read-only access to workspace files
- **Log Resources**: Runtime and build logs from tool execution

All resources support:
- ✅ Pagination for large content
- ✅ Byte-range reads
- ✅ Path sandboxing (security)
- ✅ Size limits and bounds checking

---

## Workspace Resources (`workspace://`)

### Purpose
Read-only access to files in the workspace that are relevant to Flutter development.

### Supported File Types

**Dart Files**:
- `.dart` - Dart source files

**Configuration Files**:
- `.yaml`, `.yml` - YAML configuration
- `pubspec.yaml` - Flutter project manifest
- `analysis_options.yaml` - Dart analyzer configuration

**Native Platform Files**:
- `.gradle`, `.kt`, `.kts` - Android/Gradle files
- `.swift`, `.mm`, `.m` - iOS/Objective-C files
- `.xml`, `.plist` - Platform-specific configs

**Build Files**:
- `CMakeLists.txt` - CMake configuration
- `Podfile` - CocoaPods configuration
- `Info.plist` - iOS app info

### Security

- ✅ **Path sandboxing**: All paths must be within workspace root
- ✅ **Traversal prevention**: `..` paths are blocked
- ✅ **Allowlist only**: Only specific file types are accessible
- ✅ **Read-only**: No write operations allowed

### API

#### List Resources

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

**Returns**:
```json
{
  "items": [
    {
      "uri": "workspace:///path/to/file.dart",
      "size": 1234
    }
  ],
  "total": 42,
  "page": 0,
  "pageSize": 100
}
```

#### Read Resource

```json
{
  "method": "resources/read",
  "params": {
    "uri": "workspace:///path/to/pubspec.yaml",
    "start": 0,              // Optional: Byte offset (default: 0)
    "length": 1000           // Optional: Bytes to read (default: all)
  }
}
```

**Returns**:
```json
{
  "content": "string",
  "encoding": "utf-8",
  "total": 5678,
  "start": 0,
  "length": 1000
}
```

### Examples

**Read `pubspec.yaml`**:
```json
{
  "method": "resources/read",
  "params": {
    "uri": "workspace://./pubspec.yaml"
  }
}
```

**List all Dart files (paginated)**:
```json
{
  "method": "resources/list",
  "params": {
    "page": 0,
    "pageSize": 50
  }
}
```

**Read file with byte range**:
```json
{
  "method": "resources/read",
  "params": {
    "uri": "workspace://lib/main.dart",
    "start": 0,
    "length": 500
  }
}
```

---

## Log Resources (`logs://run`, `logs://build`)

### Purpose
Access runtime and build logs from tool execution.

### Log Types

#### `logs://run/{processId}`
Flutter run logs from `flutter.run` tool execution.

#### `logs://build/{buildId}`
Flutter build logs from `flutter.build` tool execution.

### Storage

- **Storage**: In-memory bounded buffers
- **Size Limit**: 100KB per log
- **Entry Limit**: 1000 entries per log
- **Encoding**: UTF-8
- **Behavior**: Circular buffer (oldest entries removed when full)

### API

#### List Logs

```json
{
  "method": "resources/list",
  "params": {
    "uri": "logs://run",      // Optional: Filter by prefix (logs://run or logs://build)
    "page": 0,
    "pageSize": 100
  }
}
```

**Returns**:
```json
{
  "items": [
    {
      "uri": "logs://run/flutter_run_1234567890",
      "size": 8192,
      "entries": 42
    },
    {
      "uri": "logs://build/flutter_build_1234567890",
      "size": 16384,
      "entries": 100
    }
  ],
  "total": 2,
  "page": 0,
  "pageSize": 100
}
```

#### Read Log

```json
{
  "method": "resources/read",
  "params": {
    "uri": "logs://run/flutter_run_1234567890",
    "start": 0,              // Optional: Byte offset
    "length": 5000           // Optional: Bytes to read
  }
}
```

**Returns**:
```json
{
  "content": "string",
  "encoding": "utf-8",
  "total": 8192,
  "start": 0,
  "length": 5000
}
```

### Examples

**Get logs from flutter.run**:
1. Call `flutter.run` - receive `logResourceUri` in response
2. Read log resource:
```json
{
  "method": "resources/read",
  "params": {
    "uri": "logs://run/flutter_run_1234567890"
  }
}
```

**Get logs from flutter.build**:
1. Call `flutter.build` - receive `logResourceUri` in response
2. Read log resource:
```json
{
  "method": "resources/read",
  "params": {
    "uri": "logs://build/flutter_build_1234567890"
  }
}
```

**List all available logs**:
```json
{
  "method": "resources/list",
  "params": {}
}
```

---

## Resource Limits

### Size Limits

- **Workspace files**: No hard limit (use pagination for large files)
- **Log resources**: 100KB per log, 1000 entries max
- **Message size**: Configurable via `--max-message-mb` (default: 2MB)

### Best Practices

1. **Use pagination**: For large directory listings, use `page` and `pageSize`
2. **Byte-range reads**: For large files, read in chunks using `start` and `length`
3. **Poll logs**: For long-running operations, poll log resources periodically
4. **Respect limits**: Large responses may be truncated; use resource URIs instead

### Error Handling

Resources return standard MCP errors:
- **MCP_NOT_FOUND**: Resource URI not found
- **MCP_TOO_LARGE**: Response exceeds size limits (use pagination)
- **MCP_PERMISSION_DENIED**: Access denied (outside workspace, not allowed file type)

---

## Security Considerations

### Workspace Resources

- ✅ All paths validated against workspace root
- ✅ `..` traversal attempts blocked
- ✅ Only allowlisted file types accessible
- ✅ No write operations (read-only)
- ✅ Path normalization prevents bypass attempts

### Log Resources

- ✅ Bounded buffers prevent memory exhaustion
- ✅ Automatic cleanup of old entries
- ✅ UTF-8 encoding with error handling
- ✅ Size limits enforced per log

---

## Integration Examples

### AI Assistant Workflow

**Step 1: List available files**
```json
{
  "method": "resources/list",
  "params": {
    "pageSize": 20
  }
}
```

**Step 2: Read project manifest**
```json
{
  "method": "resources/read",
  "params": {
    "uri": "workspace://pubspec.yaml"
  }
}
```

**Step 3: Run app and get logs**
```json
{
  "method": "tools/call",
  "params": {
    "name": "flutter.run",
    "arguments": {"debug": true}
  }
}
// Response includes logResourceUri

{
  "method": "resources/read",
  "params": {
    "uri": "logs://run/flutter_run_1234567890"
  }
}
```

---

**For more information**:
- See `docs/mcp/quickstart.md` for setup instructions
- See `docs/mcp/tools.md` for tool documentation
- See `docs/mcp/MCP_TOOLS_REPORT.md` for comprehensive catalog

