# Command Workflow Architecture

## Overview

The Fly CLI command workflow has been completely redesigned to address critical issues with path
management, component decoupling, workflow clarity, and middleware enforcement. This document
describes the new architecture and execution flow.

## Core Principles

### 1. Single Source of Truth
- **PathResolver**: All path operations go through a single service
- **BrickMetadata**: Self-describing bricks with explicit type declarations
- **MandatoryMiddleware**: Core middleware that cannot be skipped

### 2. Clear Separation of Concerns
- **Discovery**: Finding and loading brick metadata
- **Validation**: Validating brick structure and compatibility  
- **Generation**: Orchestrating Mason brick generation
- **Path Resolution**: Centralized path computation and validation

### 3. Enforced Workflow Chain
- Mandatory middleware always runs first
- Dry-run properly short-circuits all operations
- Clear execution order with documentation

## Architecture Components

### Path Management

#### PathResolver Service
**Location**: `packages/fly_cli/lib/src/core/path_management/path_resolver.dart`

Single source of truth for all path operations:

```dart
class PathResolver {
  // Resolve working directory with fallbacks
  Future<PathResolutionResult> resolveWorkingDirectory(CommandContext context);
  
  // Resolve output directory with validation
  Future<PathResolutionResult> resolveOutputDirectory(CommandContext context, String? outputDir);
  
  // Resolve template directory (replaces TemplateManager.findTemplatesDirectory)
  Future<PathResolutionResult> resolveTemplatesDirectory();
  
  // Resolve project path (outputDir + projectName)
  Future<PathResolutionResult> resolveProjectPath(CommandContext context, String projectName, String? outputDir);
  
  // Resolve component path (projectPath + feature structure)
  Future<PathResolutionResult> resolveComponentPath(CommandContext context, String componentName, String componentType, String feature, String? outputDir);
}
```

#### Path Models
**Location**: `packages/fly_cli/lib/src/core/path_management/models/resolved_path.dart`

Immutable path results with validation status:

```dart
abstract class ResolvedPath {
  String get absolute;
  String get relative;
  bool get exists;
  bool get writable;
  bool get isValid;
  List<String> get validationErrors;
}

class WorkingDirectoryPath extends ResolvedPath { }
class TemplatePath extends ResolvedPath { }
class ProjectPath extends ResolvedPath { }
class ComponentPath extends ResolvedPath { }
```

### Brick System

#### Self-Describing Bricks
**Location**: `packages/fly_cli/lib/src/core/templates/models/brick_metadata.dart`

Bricks now declare their type explicitly in `brick.yaml`:

```yaml
name: screen_list
version: 1.0.0
type: screen  # Explicit type declaration
category: component  # Explicit category
description: "A list screen template"
variables:
  screen_name:
    type: string
    required: true
  feature:
    type: string
    required: true
    default: "home"
```

#### Brick Discovery Service
**Location**: `packages/fly_cli/lib/src/core/templates/brick_discovery_service.dart`

Responsible ONLY for finding and loading brick metadata:

```dart
class BrickDiscoveryService {
  Future<List<BrickMetadata>> discoverBricks(String templatesPath);
  Future<BrickMetadata?> loadBrickMetadata(String brickPath);
  Future<BrickMetadata?> getBrick(String name, {String? version});
  Future<List<BrickMetadata>> getBricksByType(BrickType type);
  Future<List<BrickMetadata>> getBricksByCategory(BrickCategory category);
}
```

#### Brick Validation Service
**Location**: `packages/fly_cli/lib/src/core/templates/brick_validation_service.dart`

Responsible ONLY for validating brick structure and compatibility:

```dart
class BrickValidationService {
  Future<BrickValidationResult> validate(BrickMetadata brick);
}
```

### Middleware System

#### Mandatory Middleware
**Location**: `packages/fly_cli/lib/src/core/command_foundation/domain/mandatory_middleware.dart`

Core middleware that cannot be skipped:

```dart
abstract class MandatoryMiddleware extends CommandMiddleware {
  @override
  bool shouldRun(CommandContext context, String commandName) => true; // Sealed
}

class MandatoryMiddlewarePipeline {
  List<MandatoryMiddleware> get mandatory => [
    DryRunMandatoryMiddleware(),  // Priority -100, runs first
    LoggingMandatoryMiddleware(), // Priority 10
    MetricsMandatoryMiddleware(), // Priority 20
  ];
}
```

## Command Execution Workflow

### Workflow Diagram
```
┌─────────────────────────────────────────────────────────────────┐
│                        Command Execution Flow                   │
└─────────────────────────────────────────────────────────────────┘

1. Command Initialization
   ┌─────────────┐    ┌──────────────┐    ┌─────────────────────┐
   │CommandRunner│───▶│_createContext│───▶│CommandContextImpl   │
   │    .run()   │    │              │    │+ PathResolver       │
   └─────────────┘    └──────────────┘    └─────────────────────┘

2. Path Resolution Phase
   ┌─────────────┐    ┌─────────────────┐    ┌──────────────────┐
   │Command.     │───▶│PathResolver.    │───▶│PathResolution    │
   │execute()    │    │resolve*Path()   │    │Result            │
   └─────────────┘    └─────────────────┘    └──────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │Early return if  │
                    │path resolution  │
                    │fails            │
                    └─────────────────┘

3. Mandatory Middleware Phase
   ┌─────────────┐    ┌─────────────────┐    ┌──────────────────┐
   │FlyCommand.  │───▶│middlewarePipeline│───▶│DryRunMiddleware  │
   │run()        │    │.validate()      │    │(priority -100)   │
   └─────────────┘    └─────────────────┘    └──────────────────┘
                              │
                              ▼
                    ┌─────────────────┐    ┌──────────────────┐
                    │_runMandatory    │───▶│LoggingMiddleware │
                    │MiddlewarePipeline│    │(priority 10)     │
                    └─────────────────┘    └──────────────────┘
                              │
                              ▼
                    ┌─────────────────┐    ┌──────────────────┐
                    │                 │───▶│MetricsMiddleware │
                    │                 │    │(priority 20)     │
                    └─────────────────┘    └──────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │Short-circuit if │
                    │plan mode active │
                    └─────────────────┘

4. Validation Phase
   ┌─────────────┐    ┌─────────────────┐    ┌──────────────────┐
   │FlyCommand.  │───▶│_runValidators() │───▶│RequiredArgument  │
   │run()        │    │                 │    │Validator         │
   └─────────────┘    └─────────────────┘    └──────────────────┘
                              │
                              ▼
                    ┌─────────────────┐    ┌──────────────────┐
                    │                 │───▶│ProjectName       │
                    │                 │    │Validator         │
                    └─────────────────┘    └──────────────────┘
                              │
                              ▼
                    ┌─────────────────┐    ┌──────────────────┐
                    │                 │───▶│FlutterProject    │
                    │                 │    │Validator         │
                    └─────────────────┘    └──────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │Early return if  │
                    │validation fails │
                    └─────────────────┘

5. Optional Middleware Phase
   ┌─────────────┐    ┌─────────────────┐    ┌──────────────────┐
   │FlyCommand.  │───▶│_runOptional     │───▶│CachingMiddleware │
   │run()        │    │MiddlewarePipeline│    │(command-specific)│
   └─────────────┘    └─────────────────┘    └──────────────────┘

6. Lifecycle and Execution Phase
   ┌─────────────┐    ┌─────────────────┐    ┌──────────────────┐
   │FlyCommand.  │───▶│onBeforeExecute  │───▶│execute()         │
   │run()        │    │(context)        │    │(command logic)   │
   └─────────────┘    └─────────────────┘    └──────────────────┘
                              │
                              ▼
                    ┌─────────────────┐    ┌──────────────────┐
                    │onAfterExecute   │───▶│_handleResult     │
                    │(context, result)│    │(result)          │
                    └─────────────────┘    └──────────────────┘

7. Error Handling Phase (if exception occurs)
   ┌─────────────┐    ┌─────────────────┐    ┌──────────────────┐
   │FlyCommand.  │───▶│onError          │───▶│_handleResult     │
   │run()        │    │(context, error, │    │(errorResult)     │
   │             │    │ stackTrace)     │    │                  │
   └─────────────┘    └─────────────────┘    └──────────────────┘
```

### Detailed Phase Descriptions

#### 1. Command Initialization
- CommandRunner creates context with all dependencies
- PathResolver is injected and ready for use
- Environment detection (development vs production)

#### 2. Path Resolution Phase
- Commands use PathResolver for all path operations
- Consistent validation and error handling
- Early return if path resolution fails

#### 3. Mandatory Middleware Phase
- DryRunMiddleware runs first (priority -100)
- Short-circuits ALL operations if plan mode active
- LoggingMiddleware and MetricsMiddleware always run
- Pipeline validation ensures required middleware present

#### 4. Validation Phase
- Command-specific validators run in priority order
- Early return on first validation failure
- Clear error messages and suggestions

#### 5. Optional Middleware Phase
- Command-specific middleware (caching, etc.)
- Can be skipped if not applicable
- Runs after validation passes

#### 6. Lifecycle and Execution Phase
- Pre-execution hook
- Command-specific logic execution
- Post-execution hook
- Result handling and output formatting

#### 7. Error Handling Phase
- Error lifecycle hook
- Error classification and suggestions
- Consistent error result format

## Directory Structure

### Templates Directory
```
templates/
  projects/
    minimal/
      brick.yaml
      __brick__/
    riverpod/
      brick.yaml
      __brick__/
  components/
    screen/
      list/
        brick.yaml
        __brick__/
      detail/
        brick.yaml
        __brick__/
    service/
      api/
        brick.yaml
        __brick__/
      local/
        brick.yaml
        __brick__/
  addons/
    analytics/
      brick.yaml
      __brick__/
```

### Brick Metadata Schema
```yaml
name: string                    # Required
version: string                 # Required (semver)
type: string                    # Required (project|screen|service|widget|addon)
category: string                # Required (project|component|addon)
description: string             # Required
variables:                      # Optional
  variable_name:
    type: string               # string|boolean|number|list
    required: boolean          # Default: false
    default: any               # Default value
    description: string        # Help text
features: [string]             # Optional feature list
packages: [string]             # Optional dependency list
min_flutter_sdk: string        # Optional minimum Flutter version
min_dart_sdk: string           # Optional minimum Dart version
```

## Migration Guide

### For Command Developers

#### Before (Old Way)
```dart
class MyCommand extends FlyCommand {
  @override
  Future<CommandResult> execute() async {
    final outputDir = argResults!['output-dir'] as String? ?? context.workingDirectory;
    final projectPath = path.join(outputDir, projectName);
    // Manual path construction and validation
  }
}
```

#### After (New Way)
```dart
class MyCommand extends FlyCommand {
  @override
  Future<CommandResult> execute() async {
    final outputDir = argResults!['output-dir'] as String?;
    
    // Use PathResolver for all path operations
    final pathResult = await context.pathResolver.resolveProjectPath(
      context,
      projectName,
      outputDir,
    );
    
    if (!pathResult.success) {
      return CommandResult.error(
        message: 'Path resolution failed: ${pathResult.errors.join(', ')}',
        suggestion: 'Check your output directory and permissions',
      );
    }
    
    final projectPath = pathResult.path as ProjectPath;
    // Use projectPath.absolute for file operations
  }
}
```

### For Brick Developers

#### Before (Old Way)
```yaml
name: my_screen
version: 1.0.0
description: "A screen template"
# Type inferred from directory structure
```

#### After (New Way)
```yaml
name: my_screen
version: 1.0.0
type: screen              # Explicit type declaration
category: component       # Explicit category
description: "A screen template"
variables:
  screen_name:
    type: string
    required: true
  feature:
    type: string
    required: true
    default: "home"
```

## Benefits

### 1. Path Management
- ✅ Single source of truth for all path operations
- ✅ Consistent validation and error handling
- ✅ No more scattered path construction
- ✅ Clear fallback strategies

### 2. Component Decoupling
- ✅ Self-describing bricks with explicit metadata
- ✅ Separated discovery, validation, and generation concerns
- ✅ No more path-based type inference
- ✅ Clear service boundaries

### 3. Workflow Clarity
- ✅ Documented execution order
- ✅ Mandatory middleware always runs
- ✅ Dry-run properly short-circuits operations
- ✅ Clear separation of phases

### 4. Middleware Enforcement
- ✅ Core middleware cannot be skipped
- ✅ Pipeline validation ensures completeness
- ✅ Dry-run runs with highest priority (-100)
- ✅ Clear execution order

### 5. Template Directory Management
- ✅ Single strategy per environment (dev vs prod)
- ✅ No more fallback confusion
- ✅ Clear directory structure
- ✅ Fail-fast on missing templates

## Testing

### Unit Tests
- PathResolver with various path scenarios
- BrickMetadata parsing and validation
- MandatoryMiddleware pipeline execution
- Command execution with new workflow

### Integration Tests
- End-to-end command execution
- Path resolution with real filesystem
- Brick discovery and validation
- Middleware pipeline with dry-run

### Error Scenarios
- Invalid paths and permissions
- Missing brick metadata
- Invalid middleware configuration
- Template directory not found

## Future Enhancements

1. **Caching**: Add intelligent caching for path resolution and brick discovery
2. **Parallel Processing**: Execute independent operations in parallel
3. **Plugin System**: Extensible middleware and validation plugins
4. **Metrics**: Detailed performance metrics and analytics
5. **Configuration**: User-configurable middleware and validation rules
