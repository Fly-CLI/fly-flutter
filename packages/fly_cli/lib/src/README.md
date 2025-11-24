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

## Module Organization

### Architecture Patterns

All modules follow clean architecture principles with consistent layering:

**Standard Module Structure:**

```
{module}/
├── domain/                      # Interfaces, abstractions, value objects
├── application/                 # Business logic, use cases, orchestration
├── infrastructure/              # Concrete implementations, adapters
└── README.md                    # Module documentation
```

### Key Modules

- **`shared/`** - Cross-cutting concerns used by all modules (logging, errors, DI, utils)
- **`commands/`** - Command system foundation, metadata, and registration
- **`generation/`** - Template/project generation with caching and security
- **`integrations/`** - External system integrations (MCP, etc.)
- **`diagnostics/`** - System health checks and diagnostics
- **`context/`** - Project analysis and context generation
- **`completion/`** - Shell completion generation
- **`schema/`** - Command schema export
- **`version/`** - Version information
- **`cli/`** - CLI infrastructure (bootstrapping, formatting, middleware, etc.)

### Module Principles

1. **Full Encapsulation**: Each module contains all related functionality
2. **Business Domain Focus**: Modules organized by business capability, not technical layer
3. **Internal Layering**: Each module has domain/application/infrastructure internally
4. **Minimal Shared**: Only truly cross-cutting concerns in `shared/`
5. **Clear Boundaries**: Module boundaries align with business capabilities

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
import 'package:fly_cli/src/shared/logging/infrastructure/logger.dart';
import 'package:fly_cli/src/generation/application/generate/project/generate_project_command.dart';
import 'package:fly_cli/src/features/commands/domain/command_context.dart';

// ❌ Avoid
import '../../shared/logging/infrastructure/logger.dart';
```

## Documentation

- Each module should have a README.md explaining its purpose and structure
- Complex modules should document their architecture
- See existing examples in `shared/logging/README.md` and `integrations/mcp/docs/`

## Module Documentation

- `shared/logging/README.md` - Logging system documentation
- `commands/README.md` - Command system architecture
- `generation/README.md` - Generation system documentation
- `integrations/README.md` - Integration modules documentation

