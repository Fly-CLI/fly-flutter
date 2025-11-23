# Fly CLI Clean Architecture Guide

## Overview

The Fly CLI has been refactored to follow Clean Architecture principles, providing clear separation of concerns, improved testability, and better maintainability.

## Architecture Layers

### Presentation Layer
- **Location**: `packages/fly_cli/lib/src/features/generate/`
- **Responsibility**: CLI commands, MCP tools, user interface
- **Dependencies**: Application layer only

### Application Layer
- **Location**: `packages/fly_cli/lib/src/core/scaffolding/application/`
- **Responsibility**: Use cases, orchestration, DTOs
- **Dependencies**: Domain layer only

### Domain Layer
- **Location**: `packages/fly_cli/lib/src/core/scaffolding/domain/`
- **Responsibility**: Entities, value objects, domain services, interfaces
- **Dependencies**: None (pure business logic)

### Infrastructure Layer
- **Location**: `packages/fly_cli/lib/src/core/scaffolding/infrastructure/`
- **Responsibility**: Repository implementations, adapters, external services
- **Dependencies**: Domain and Application layers

## Key Components

### Use Cases
Use cases encapsulate business logic for specific operations:
- `GenerateFeatureUseCase` - Feature generation
- `GenerateServiceUseCase` - Service generation
- `GenerateProjectUseCase` - Project generation

### Repositories
Repositories provide abstraction over data access:
- `IBrickRepository` - Brick discovery and access
- `ITemplateRepository` - Template management

### Services
Services handle cross-cutting concerns:
- `IVariableProcessor` - Variable processing pipeline
- `IGenerationEngine` - Code generation execution
- `IWorkflowOrchestrator` - Workflow orchestration

## Dependency Flow

```
Presentation → Application → Domain ← Infrastructure
```

- Presentation depends on Application
- Application depends on Domain
- Infrastructure implements Domain interfaces
- Domain has no dependencies

## Benefits

1. **Testability**: Each layer can be tested independently with mocks
2. **Maintainability**: Clear boundaries make changes easier
3. **Extensibility**: New features can be added without modifying existing code
4. **SOLID Compliance**: Follows all SOLID principles

