<!-- 668418e9-1501-42e8-98dc-e411049c4695 0501b122-021a-4c84-b528-599655c31e7e -->

# Fly CLI Architectural Analysis and Refactoring Plan

## Executive Summary

This plan addresses architectural improvements for three critical modules in the Fly CLI codebase:

1. **Scaffolding System** (`/packages/fly_cli/lib/src/core/scaffolding/`)
2. **Generate Commands** (`/packages/fly_cli/lib/src/features/generate/`)
3. **MCP Integration** (`/packages/fly_cli/lib/src/integrations/mcp/`)

The refactoring focuses on improving SOLID compliance, reducing coupling, enhancing testability, and
establishing clear architectural boundaries.

---

## 1. Current State Assessment

### 1.1 Scaffolding System Architecture

**Current Structure:**

- **Brick Layer**: `BrickRegistry`, `BrickInfo`, `BrickMetadata`, `BrickDiscoveryService`,
  `BrickValidationService`
- **Template Layer**: `TemplateManager`, `TemplateInfo`, `TemplateVariable`, `TemplateCompatibility`
- **Generation Layer**: `GenerationService`, `GenerationAdapter`, `GenerationPreviewService`,
  `GenerationVariableBuilder`
- **Foundation Layer**: `GenerationOrchestrator`, `FoundationBrickExecutor`, workflow
  inference
- **Variable Layer**: Variable derivers pipeline, `VariableValidationService`
- **Versioning Layer**: `VersionRegistry`, `CompatibilityChecker`, `VersionParser`

**Key Issues Identified:**

1. **Duplication**: `BrickInfo` and `BrickMetadata` serve similar purposes with overlapping
   responsibilities
2. **God Object**: `TemplateManager` (682+ lines) handles discovery, validation, caching,
   versioning, and generation
3. **Tight Coupling**: Direct dependencies on concrete classes throughout the system
4. **Inconsistent Patterns**: Mix of factory methods, direct instantiation, and registry patterns
5. **Variable Processing Scatter**: Variable builders, derivers, and validators are not cohesively
   organized
6. **Limited Testability**: Hard dependencies on file system, Mason, and concrete implementations

### 1.2 Generate Commands Architecture

**Current Structure:**

- **Commands**: `GenerateFeatureCommand`, `GenerateProjectCommand`, `GenerateServiceCommand`
- **Strategies**: `FeatureCommandStrategy`, `ProjectCommandStrategy`, `ServiceCommandStrategy`
- **Generators**: `FeatureGenerator`, `ServiceGenerator` (project uses orchestrator directly)
- **Variable Builders**: `FeatureVariableBuilder`, `ServiceVariableBuilder`,
  `ProjectVariableBuilder`

**Key Issues Identified:**

1. **Inconsistent Patterns**: Feature/Service use generators, Project uses orchestrator directly
2. **Tight Coupling**: Commands directly instantiate services and generators
3. **Duplication**: Similar validation and variable building logic across commands
4. **Mixed Responsibilities**: Commands handle validation, variable building, path resolution, and
   generation
5. **Limited Reusability**: MCP tools duplicate similar logic

### 1.3 MCP Integration Architecture

**Current Structure:**

- **Tool Strategies**: `McpToolStrategy` base class, concrete implementations per tool
- **Registries**: `McpToolStrategyRegistry`, `ResourceStrategyRegistry`, `PromptStrategyRegistry`
- **Resources**: Multiple resource strategies with `PathSandbox` security
- **Error Handling**: `McpError`, `ResourceError`, structured validation

**Key Issues Identified:**

1. **Registry Duplication**: Multiple registry patterns with similar structure
2. **Strategy Creation**: Switch-based factory in `McpToolStrategyRegistry` violates OCP
3. **Dependency Injection**: Strategies receive `CommandContext` but lack abstraction
4. **Error Handling**: Good structure but could be more consistent across modules

---

## 2. SOLID Violations Analysis

### 2.1 Single Responsibility Principle (SRP) Violations

**Violations:**

- `TemplateManager`: Handles discovery, validation, caching, versioning, and generation
- `GenerationService`: Orchestrates generation but also handles variable derivation and validation
- `BrickRegistry`: Manages registry, discovery, validation, and caching
- Generate Commands: Handle argument parsing, validation, variable building, path resolution, and
  generation

**Impact**: Difficult to test, modify, and extend individual responsibilities.

### 2.2 Open/Closed Principle (OCP) Violations

**Violations:**

- `McpToolStrategyRegistry._createStrategy()`: Switch statement requires modification for new tools
- `GenerationService._getBrickNameForMode()`: Hard-coded brick names
- Variable derivers: Fixed pipeline composition, not easily extensible
- Workflow inference: Hard-coded mode-to-workflow mapping

**Impact**: Adding new features requires modifying existing code.

### 2.3 Liskov Substitution Principle (LSP) Violations

**Minor Issues:**

- Variable builders have consistent interface but different internal implementations
- Resource strategies have good abstraction but some inconsistencies

**Impact**: Low - mostly compliant.

### 2.4 Interface Segregation Principle (ISP) Violations

**Violations:**

- `TemplateManager` exposes too many methods (discovery, validation, generation, caching)
- `CommandContext` is a large interface with many responsibilities
- `GenerationVariableBuilder` interface is used inconsistently

**Impact**: Clients depend on methods they don't use.

### 2.5 Dependency Inversion Principle (DIP) Violations

**Major Violations:**

- Commands depend on concrete `GenerationService`, `TemplateManager`, `FeatureGenerator`
- `GenerationService` depends on concrete `TemplateManager`
- `TemplateManager` depends on concrete `BrickRegistry`, cache managers
- MCP strategies depend on concrete `CommandContext` implementation
- No dependency injection container or service locator pattern

**Impact**: High coupling, difficult to test, cannot swap implementations.

---

## 3. Proposed Architecture

### 3.1 Clean Architecture Layers

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│  (Commands, MCP Tools, CLI Interface)                    │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│                  Application Layer                       │
│  (Use Cases, Orchestration, Coordination)              │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│                    Domain Layer                         │
│  (Entities, Value Objects, Domain Services)             │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│                Infrastructure Layer                     │
│  (Mason, File System, External Services)               │
└─────────────────────────────────────────────────────────┘
```

### 3.2 Module Reorganization

**New Structure:**

```
scaffolding/
├── domain/
│   ├── entities/          # Brick, Template, GenerationRequest
│   ├── value_objects/     # BrickMetadata, TemplateVariable, Version
│   ├── repositories/      # Interfaces for brick/template access
│   └── services/          # Domain services (validation, compatibility)
├── application/
│   ├── use_cases/         # GenerateFeature, GenerateProject, etc.
│   ├── dto/               # Data transfer objects
│   └── ports/             # Application interfaces
├── infrastructure/
│   ├── brick/             # BrickRegistry, BrickDiscovery, MasonAdapter
│   ├── template/          # TemplateRepository, TemplateCache
│   ├── generation/        # MasonGenerationEngine, FileSystemAdapter
│   └── versioning/        # VersionRegistry, CompatibilityChecker
└── presentation/
    └── adapters/          # CLI adapters, MCP adapters
```

### 3.3 Dependency Injection Strategy

**Proposed Approach:**

- Introduce a lightweight DI container (or use existing patterns)
- Define interfaces for all major dependencies
- Inject dependencies through constructors
- Use factory pattern for complex object creation

**Key Interfaces:**

- `IBrickRepository` - Brick discovery and access
- `ITemplateRepository` - Template management
- `IGenerationEngine` - Code generation execution
- `IVariableProcessor` - Variable derivation and validation
- `ICacheManager` - Caching operations
- `IWorkflowOrchestrator` - Foundation workflow execution

---

## 4. Refactoring Strategy

### Phase 1: Foundation (Weeks 1-2)

**Goal**: Establish interfaces and dependency injection infrastructure.

**Tasks:**

1. Create domain interfaces for repositories and services
2. Extract interfaces from concrete classes
3. Implement lightweight DI container or service locator
4. Create adapter interfaces for external dependencies (Mason, FileSystem)

**Files to Create:**

- `scaffolding/domain/repositories/ibrick_repository.dart`
- `scaffolding/domain/repositories/itemplate_repository.dart`
- `scaffolding/application/ports/igeneration_engine.dart`
- `scaffolding/application/ports/ivariable_processor.dart`
- `scaffolding/infrastructure/di/service_container.dart`

**Files to Refactor:**

- Extract interfaces from `TemplateManager`
- Extract interfaces from `BrickRegistry`
- Extract interfaces from `GenerationService`

### Phase 2: Domain Layer (Weeks 3-4)

**Goal**: Establish clear domain boundaries and entities.

**Tasks:**

1. Consolidate `BrickInfo` and `BrickMetadata` into single domain entity
2. Create value objects for versioning, compatibility
3. Move domain logic out of infrastructure classes
4. Establish domain services for validation and business rules

**Files to Create:**

- `scaffolding/domain/entities/brick.dart` (consolidated)
- `scaffolding/domain/value_objects/version_range.dart`
- `scaffolding/domain/services/brick_validator.dart`
- `scaffolding/domain/services/compatibility_service.dart`

**Files to Refactor:**

- Merge `BrickInfo` and `BrickMetadata`
- Extract validation logic from `BrickValidationService`
- Extract compatibility logic from `CompatibilityChecker`

### Phase 3: Application Layer (Weeks 5-6)

**Goal**: Create use cases and orchestration logic.

**Tasks:**

1. Create use case classes for each generation type
2. Implement variable processing pipeline as a service
3. Create DTOs for data transfer between layers
4. Implement application services for coordination

**Files to Create:**

- `scaffolding/application/use_cases/generate_feature_use_case.dart`
- `scaffolding/application/use_cases/generate_project_use_case.dart`
- `scaffolding/application/use_cases/generate_service_use_case.dart`
- `scaffolding/application/services/variable_processing_service.dart`
- `scaffolding/application/dto/generation_request_dto.dart`

**Files to Refactor:**

- Split `GenerationService` into use cases
- Extract variable processing from `GenerationService`
- Move orchestration logic to use cases

### Phase 4: Infrastructure Refactoring (Weeks 7-8)

**Goal**: Refactor infrastructure to implement interfaces.

**Tasks:**

1. Refactor `TemplateManager` into smaller, focused classes
2. Implement repository pattern for brick and template access
3. Create adapters for Mason and file system operations
4. Refactor caching to be pluggable

**Files to Create:**

- `scaffolding/infrastructure/brick/brick_repository_impl.dart`
- `scaffolding/infrastructure/template/template_repository_impl.dart`
- `scaffolding/infrastructure/generation/mason_generation_engine.dart`
- `scaffolding/infrastructure/generation/file_system_adapter.dart`

**Files to Refactor:**

- Split `TemplateManager` into `TemplateRepository`, `TemplateCache`, `TemplateValidator`
- Refactor `BrickRegistry` to implement `IBrickRepository`
- Extract Mason operations to `MasonAdapter`

### Phase 5: Command Refactoring (Weeks 9-10)

**Goal**: Refactor commands to use use cases and improve consistency.

**Tasks:**

1. Refactor all generate commands to use use cases
2. Extract common command logic to base classes
3. Create command handlers that delegate to use cases
4. Unify variable building across commands

**Files to Create:**

- `features/generate/common/generation_command_handler.dart`
- `features/generate/common/generation_command_base.dart`

**Files to Refactor:**

- `GenerateFeatureCommand` - use `GenerateFeatureUseCase`
- `GenerateProjectCommand` - use `GenerateProjectUseCase`
- `GenerateServiceCommand` - use `GenerateServiceUseCase`
- Extract common validation and variable building

### Phase 6: MCP Integration Refactoring (Weeks 11-12)

**Goal**: Improve MCP integration architecture and consistency.

**Tasks:**

1. Refactor tool strategy registry to use DI and be extensible
2. Create MCP adapters that use the same use cases as commands
3. Unify error handling across MCP and CLI
4. Improve resource strategy consistency

**Files to Create:**

- `integrations/mcp/adapters/generation_mcp_adapter.dart`
- `integrations/mcp/registry/tool_registry_factory.dart`

**Files to Refactor:**

- `McpToolStrategyRegistry` - use DI and plugin pattern
- MCP tool strategies - use use cases instead of direct service calls
- Unify error handling with CLI commands

### Phase 7: Testing and Documentation (Weeks 13-14)

**Goal**: Add comprehensive tests and update documentation.

**Tasks:**

1. Add unit tests for all use cases
2. Add integration tests for generation flows
3. Add tests for MCP integration
4. Update architecture documentation
5. Create migration guide

---

## 5. Specific Refactoring Details

### 5.1 TemplateManager Decomposition

**Current**: 682+ line class with multiple responsibilities

**Proposed Split:**

```dart
// Domain interface
abstract class ITemplateRepository {
  Future<Template?> getTemplate(String name);

  Future<List<Template>> discoverTemplates();

  Future<bool> validateTemplate(Template template);
}

// Infrastructure implementation
class TemplateRepository implements ITemplateRepository {
  final IBrickRepository _brickRepository;
  final ITemplateCache _cache;
  final ITemplateValidator _validator;

// Focused, single-responsibility methods
}

// Separate cache interface
abstract class ITemplateCache {
  Future<Template?> get(String key);

  Future<void> set(String key, Template template);
}

// Separate validator
abstract class ITemplateValidator {
  ValidationResult validate(Template template);
}
```

### 5.2 Variable Processing Unification

**Current**: Scattered across builders, derivers, and validators

**Proposed**: Unified pipeline service

```dart
abstract class IVariableProcessor {
  Future<ProcessedVariables> process({
    required Map<String, dynamic> rawVars,
    required GenerationMode mode,
    required Brick brick,
  });
}

class VariableProcessor implements IVariableProcessor {
  final List<VariableDeriver> _derivers;
  final IVariableValidator _validator;

  @override
  Future<ProcessedVariables> process

  (

  ...

  )

  async {
  // 1. Apply derivers in sequence
  var processed = rawVars;
  for (final deriver in _derivers) {
  processed = await deriver.derive(processed, mode);
  }

  // 2. Validate
  final validation = await _validator.validate(processed, brick);
  if (!validation.isValid) {
  throw ValidationException(validation.errors);
  }

  return ProcessedVariables(processed, validation);
  }
}
```

### 5.3 Use Case Pattern for Generation

**Proposed Structure:**

```dart
abstract class GenerateFeatureUseCase {
  Future<GenerationResult> execute(GenerateFeatureRequest request);
}

class GenerateFeatureUseCaseImpl implements GenerateFeatureUseCase {
  final IBrickRepository _brickRepository;
  final IVariableProcessor _variableProcessor;
  final IGenerationEngine _generationEngine;

  @override
  Future<GenerationResult> execute(GenerateFeatureRequest request) async {
    // 1. Get brick
    final brick = await _brickRepository.getBrick('feature');
    if (brick == null) throw BrickNotFoundException();

    // 2. Process variables
    final processed = await _variableProcessor.process(
      rawVars: request.variables,
      mode: GenerationMode.feature,
      brick: brick,
    );

    // 3. Generate
    return await _generationEngine.generate(
      brick: brick,
      variables: processed.values,
      outputDirectory: request.outputDirectory,
    );
  }
}
```

### 5.4 MCP Tool Strategy Registry Improvement

**Current**: Switch-based factory

**Proposed**: Plugin-based registry with DI

```dart
abstract class IToolStrategyFactory {
  McpToolStrategy create(McpTool toolType);
}

class ToolStrategyFactory implements IToolStrategyFactory {
  final Map<McpTool, McpToolStrategy Function()> _factories;

  ToolStrategyFactory({
    required IBrickRepository brickRepository,
    required IGenerationEngine generationEngine,
    // ... other dependencies
  }) : _factories = {
    McpTool.generateFeature: () =>
        FlyGenerateFeatureStrategy(
          useCase: GenerateFeatureUseCase(...),
        ),
    McpTool.generateProject: () =>
        FlyGenerateProjectStrategy(
          useCase: GenerateProjectUseCase(...),
        ),
    // ... other tools
  };

  @override
  McpToolStrategy create(McpTool toolType) {
    final factory = _factories[toolType];
    if (factory == null) {
      throw UnsupportedToolException(toolType);
    }
    return factory();
  }
}
```

---

## 6. Migration Strategy

### 6.1 Backward Compatibility

**Approach**: Maintain existing public APIs during transition

- Keep old classes as facades that delegate to new architecture
- Deprecate old APIs with migration guides
- Provide adapter layers for external consumers

### 6.2 Incremental Migration

**Strategy**: Feature flags and gradual rollout

1. Implement new architecture alongside old
2. Use feature flags to switch between implementations
3. Migrate one command/feature at a time
4. Remove old code after validation

### 6.3 Risk Mitigation

**Testing Strategy**:

- Comprehensive unit tests before refactoring
- Integration tests for critical paths
- E2E tests for user-facing commands
- Performance benchmarks to ensure no regression

**Rollback Plan**:

- Git branches for each phase
- Feature flags for easy rollback
- Monitoring and metrics to detect issues

---

## 7. Success Criteria

### 7.1 Code Quality Metrics

- **Cyclomatic Complexity**: Reduce average complexity by 40%
- **Coupling**: Reduce inter-module dependencies by 50%
- **Test Coverage**: Achieve 80%+ coverage for core modules
- **SOLID Compliance**: Zero critical SOLID violations

### 7.2 Maintainability Metrics

- **File Size**: No file > 300 lines
- **Class Responsibility**: Single clear responsibility per class
- **Interface Usage**: 90%+ of dependencies through interfaces
- **Documentation**: 100% public API documentation

### 7.3 Performance Metrics

- **Generation Time**: No regression in generation performance
- **Memory Usage**: Monitor for memory leaks
- **Startup Time**: No significant increase in CLI startup time

### 7.4 Developer Experience

- **Ease of Testing**: All use cases easily testable with mocks
- **Extensibility**: Adding new generation types requires minimal changes
- **Documentation**: Clear architecture documentation and examples

---

## 8. Implementation Roadmap

### Week 1-2: Foundation

- Create domain interfaces
- Implement DI container
- Extract interfaces from existing classes

### Week 3-4: Domain Layer

- Consolidate brick entities
- Create value objects
- Establish domain services

### Week 5-6: Application Layer

- Implement use cases
- Create variable processing service
- Define DTOs

### Week 7-8: Infrastructure

- Refactor TemplateManager
- Implement repositories
- Create adapters

### Week 9-10: Commands

- Refactor generate commands
- Extract common logic
- Unify patterns

### Week 11-12: MCP Integration

- Refactor tool registry
- Create MCP adapters
- Unify error handling

### Week 13-14: Testing & Documentation

- Comprehensive test suite
- Architecture documentation
- Migration guides

---

## 9. Key Files and Changes

### Critical Files to Refactor

1. **`template_manager.dart`** (682 lines) → Split into 5+ focused classes
2. **`generation_service.dart`** (326 lines) → Split into use cases
3. **`brick_registry.dart`** (445 lines) → Implement repository pattern
4. **`brick_info.dart` + `brick_metadata.dart`** → Consolidate into single entity
5. **Generate commands** → Use use cases, extract common logic
6. **MCP tool strategies** → Use use cases, improve registry

### New Files to Create

- Domain interfaces (10+ files)
- Use case implementations (5+ files)
- Repository implementations (5+ files)
- Adapter classes (5+ files)
- DI container and configuration (3+ files)

---

## 10. Dependencies and Prerequisites

### External Dependencies

- No new external dependencies required
- Existing packages: `mason`, `fly_brick_composer`, `fly_mcp`

### Internal Dependencies

- Command foundation system (already exists)
- Error handling system (already exists)
- Logging infrastructure (already exists)

### Team Prerequisites

- Understanding of Clean Architecture principles
- Familiarity with dependency injection patterns
- Knowledge of SOLID principles
- Testing best practices

---

## 11. Risk Assessment

### High Risk Areas

1. **TemplateManager refactoring**: Large, widely used class
2. **Breaking changes**: May affect external integrations
3. **Performance regression**: Need careful benchmarking

### Mitigation Strategies

1. Incremental refactoring with feature flags
2. Comprehensive testing at each phase
3. Performance monitoring and benchmarks
4. Clear migration documentation

---

## 12. Long-term Benefits

### Maintainability

- Clear separation of concerns
- Easy to locate and modify code
- Reduced cognitive load

### Testability

- All use cases easily testable
- Mockable dependencies
- Isolated unit tests

### Extensibility

- Easy to add new generation types
- Plugin-based architecture
- Open/closed principle compliance

### Developer Experience

- Clear architecture
- Better IDE support
- Easier onboarding

### To-dos

- [ ] Create domain interfaces (IBrickRepository, ITemplateRepository, IGenerationEngine,
  IVariableProcessor) and DI container infrastructure
- [ ] Extract interfaces from TemplateManager, BrickRegistry, and GenerationService
- [ ] Consolidate BrickInfo and BrickMetadata into single domain entity (Brick)
- [ ] Create value objects for versioning (VersionRange, CompatibilityResult) and domain services
- [ ] Create use case classes (GenerateFeatureUseCase, GenerateProjectUseCase,
  GenerateServiceUseCase) and VariableProcessingService
- [ ] Create DTOs for data transfer between layers (GenerationRequestDto, ProcessedVariables)
- [ ] Refactor TemplateManager into TemplateRepository, TemplateCache, TemplateValidator
  implementing interfaces
- [ ] Create MasonAdapter and FileSystemAdapter, refactor BrickRegistry to implement
  IBrickRepository
- [ ] Refactor GenerateFeatureCommand, GenerateProjectCommand, GenerateServiceCommand to use use
  cases
- [ ] Extract common command logic to GenerationCommandBase and GenerationCommandHandler
- [ ] Refactor McpToolStrategyRegistry to use DI and plugin pattern, remove switch statement
- [ ] Create MCP adapters that use same use cases as commands, unify error handling
- [ ] Add comprehensive unit tests for all use cases, repositories, and services
- [ ] Add integration tests for generation flows and MCP integration
- [ ] Update architecture documentation, create migration guide, and add code examples