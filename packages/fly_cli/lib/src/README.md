# Fly CLI Source Code Organization

## Overview

This directory contains the core implementation of the Fly CLI tool, organized into three main
areas:

- **`core/`** - Infrastructure, abstractions, and shared utilities
- **`features/`** - User-facing command implementations
- **`command_runner.dart`** - Main CLI entry point and command registration

## Directory Structure

```
lib/src/
├── command_runner.dart           # Main CLI runner
├── core/                         # Infrastructure & shared code
│   ├── cli/                      # CLI infrastructure (runner, bootstrapping, formatting)
│   │   ├── bootstrapping/        # Service bootstrapping
│   │   ├── formatting/            # Output formatting
│   │   ├── error_handling/       # Error handling
│   │   ├── interfaces/            # CLI-specific interfaces
│   │   └── registration/         # Command registration
│   ├── cache/                    # Template caching
│   ├── command_foundation/       # Command system abstractions
│   ├── command_metadata/         # Command introspection & schema
│   ├── definitions/              # Type definitions & enums
│   ├── dependency_injection/     # Service container
│   ├── diagnostics/              # System health checks
│   ├── errors/                   # Error codes & contexts
│   ├── logging/                  # Structured logging system
│   ├── manifest/                 # Project manifest parsing
│   ├── network/                  # Network utilities
│   ├── path_management/          # Path resolution
│   ├── security/                 # Template validation
│   ├── templates/                # Template management
│   ├── utils/                    # Shared utilities
│   └── validation/               # Validation rules
└── features/                     # Command implementations
    ├── add/                      # Component generation
    ├── completion/               # Shell completion
    ├── context/                  # Project analysis
    ├── create/                   # Project creation
    ├── doctor/                   # System diagnostics
    ├── schema/                   # Schema export
    └── version/                  # Version info
```

## Core Directory

### Architecture Patterns

The `core/` directory follows clean architecture principles with some inconsistency:

**Well-Organized Examples:**

- **`logging/`** - Excellent example with clear layering:
  ```
  logging/
  ├── domain/                    # Interfaces & abstractions
  ├── application/               # Business logic
  ├── infrastructure/            # Implementations
  │   ├── appenders/
  │   └── formatters/
  └── README.md
  ```

- **`templates/`** - Good organization with logical groupings:
  ```
  templates/
  ├── versioning/               # Template versioning
  └── (18 other files)          # Core template logic
  ```

**Areas Needing Improvement:**

- **`command_foundation/`** - Mixed domain/application/infrastructure concerns
- **`dependency_injection/`** - No clear layering
- Other directories - Inconsistent patterns

**Recommendation:**
See [FILE_SYSTEM_ANALYSIS_AND_RECOMMENDATIONS.md](../../FILE_SYSTEM_ANALYSIS_AND_RECOMMENDATIONS.md)
for detailed restructuring suggestions.

### Key Core Components

- **CLI Infrastructure** (`cli/`) - Command runner, bootstrapping, formatting, error handling
- **Command Foundation** - Base classes, middleware, lifecycle hooks
- **Command Metadata** - Introspection and schema generation for AI
- **Definitions** - Command types, categories, MCP tool types
- **Dependency Injection** - Simple service container pattern
- **Logging** - Structured, multi-appender logging system
- **Templates** - Mason brick integration with versioning
- **Validation** - Composable validation pipeline

## Features Directory

### Structure

Each feature typically contains:

- `{feature}_command.dart` - Main command implementation
- `{feature}_command_strategy.dart` - Metadata and factory
- Additional implementation files as needed

### Examples

**Simple Features:**

- `create/` - 2 files (command + strategy)
- `version/` - 2 files (command + strategy)

**Complex Features:**

- `context/` - 11 files with analyzers, models, utils
- `completion/` - 7 files with generators/ subdirectory

**Recommended Pattern:**

```dart
features/
  {feature}/
    ├── domain/                  # Interfaces, models
    ├── application/             # Command implementation
    ├── infrastructure/          # External integrations
    └── README.md               # Feature documentation
```

## Command Registration

Currently uses enum-based registration in `core/definitions/fly_command.dart`.

**Current Flow:**

1. Enum defines all commands
2. Strategies provide metadata
3. CommandRegistry builds groups
4. CommandRunner registers everything

**Proposed Flow (see analysis doc):**

1. Convention-based discovery
2. Strategy registry
3. Automatic registration
4. No enum needed

## Adding a New Command

### Current Process

1. Add enum variant to `FlyCommand`
2. Add switch cases (name, description, aliases, category, etc.)
3. Create command class
4. Create strategy class
5. Update tests

**Effort:** ~200 lines of boilerplate

### Future Process (with refactoring)

1. Create command class
2. Create strategy class with metadata
3. Run tests

**Effort:** ~50 lines of implementation

## Testing

Tests mirror the source structure:

```
test/
├── core/              # Core subsystem tests
├── features/          # Feature tests
├── integration/       # Integration tests
├── helpers/           # Test utilities
└── fixtures/          # Test data
```

## Import Conventions

Use package-relative imports:

```dart
// ✅ Good
import 'package:fly_cli/src/core/logging/logger.dart';
import 'package:fly_cli/src/features/generate/project/generate_project_command.dart';

// ❌ Avoid
import '../../core/logging/logger.dart';
```

## Documentation

- Each directory should have a README.md explaining its purpose
- Complex features should document their architecture
- See existing examples in `core/logging/` and `features/mcp/docs/`

## Next Steps

For detailed analysis and recommendations, see:

- `FILE_SYSTEM_ANALYSIS_AND_RECOMMENDATIONS.md` in project root

For feature-specific documentation:

- `features/README.md`
- `core/logging/README.md`
- `core/generation/versioning/README.md`

