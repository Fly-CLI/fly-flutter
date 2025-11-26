# Generation Workflow Documentation

## Table of Contents

1. [Overview](#overview)
2. [Complete Generation Workflow](#complete-generation-workflow)
3. [Architecture Layers](#architecture-layers)
4. [Component Interactions](#component-interactions)
5. [Variable Processing and Validation](#variable-processing-and-validation)
6. [Template Discovery and Execution](#template-discovery-and-execution)
7. [Error Handling and Result Propagation](#error-handling-and-result-propagation)
8. [Developer Guide: Adding New Generation Types](#developer-guide-adding-new-generation-types)

---

## Overview

The Fly CLI generation system provides a unified, extensible framework for generating Flutter
project components. It follows Clean Architecture principles with clear separation between
presentation, application, domain, and infrastructure layers.

### Key Concepts

- **Generation Modes**: `project`, `feature`, `service` (extensible)
- **Bricks**: Mason-based templates stored in `templates/bricks/`
- **Workflows**: Multi-step generation processes (primarily for projects)
- **Variables**: User inputs processed through derivation pipelines
- **Orchestration**: Coordination of complex generation tasks

---

## Complete Generation Workflow

### High-Level Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    CLI Command Execution                        │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│              Command Registration & Discovery                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ CommandDescriptor (Feature/Service/Project)              │   │
│  │  - Registers command metadata                            │   │
│  │  - Creates command instance via factory                  │   │
│  └──────────────────────────────────────────────────────────┘   │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Command Execution                            │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ GenerateFeatureCommand / GenerateServiceCommand /         │  │
│  │ GenerateProjectCommand                                    │  │
│  │  - Parse flags and arguments                              │  │
│  │  - Build variables from context                           │  │
│  │  - Validate inputs                                        │  │
│  │  - Create GenerationRequestDto                            │  │
│  └───────────────────────────────────────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│              GenerationCommandHandler                           │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  - Routes to appropriate use case                        │   │
│  │  - Converts results to CommandResult                     │   │
│  └──────────────────────────────────────────────────────────┘   │
└────────────────────────────┬────────────────────────────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        ▼                    ▼                    ▼
    ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
    │ Generate     │   │ Generate     │   │ Generate     │
    │ Feature      │   │ Service      │   │ Project      │
    │ Use Case     │   │ Use Case     │   │ Use Case     │
    └──────┬───────┘   └──────┬───────┘   └──────┬───────┘
           │                  │                  │
           └──────────────────┼──────────────────┘
                              │
                              ▼
            ┌────────────────────────────────────┐
            │      Workflow Orchestrator         │
            │      (all generation modes)        │
            └────────────────┬───────────────────┘
                             │
                             ▼
            ┌────────────────────────────────────┐
            │   Variable Processing Service      │
            │   - Derive additional variables    │
            │   - Validate against brick schema  │
            └────────────────┬───────────────────┘
                            │
                            ▼
            ┌────────────────────────────────────┐
            │   Brick Repository                 │
            │   - Discover bricks                │
            │   - Load brick metadata            │
            └────────────────┬───────────────────┘
                            │
                            ▼
            ┌────────────────────────────────────┐
            │   Generation Engine                │
            │   - Execute Mason generation        │
            │   - Generate files                 │
            └────────────────┬───────────────────┘
                            │
                            ▼
            ┌────────────────────────────────────┐
            │   GenerationResultDto              │
            │   - Success/Failure status         │
            │   - Generated files list           │
            │   - Error messages                 │
            └────────────────┬───────────────────┘
                            │
                            ▼
            ┌────────────────────────────────────┐
            │   CommandResult                   │
            │   - User-friendly message           │
            │   - Next steps                     │
            └────────────────────────────────────┘
```

### Detailed Execution Flow

#### 1. Command Invocation

**Entry Point**: User runs `fly generate feature <name>` or similar command

**Process**:
- `CommandRunner` parses arguments
- `CommandRegistrar` looks up command descriptor
- Command instance created via `CommandDescriptor.createInstance()`

**Example**:
```dart
// User command: fly generate feature home_screen
// CommandDescriptor: FeatureCommandDescriptor
// Creates: GenerateFeatureCommand(context)
```

#### 2. Command Execution

**Location**: `GenerateFeatureCommand.execute()`, `GenerateServiceCommand.execute()`, or
`GenerateProjectCommand.execute()`

**Steps**:
1. **Parse Flags**: Extract user inputs (name, feature, screenType, etc.)
2. **Build Variables**: Use `VariableBuilder` to construct variable map
3. **Validate**: Run validators (required args, format checks, etc.)
4. **Resolve Output Directory**: Determine where files will be generated
5. **Create Request DTO**: Build type-safe `GenerationRequestDto`

**Code Example**:
```dart
// From GenerateFeatureCommand.execute()
final executionContext = context.factory.createExecutionContext(argResults!);
const variableBuilder = FeatureVariableBuilder();
final rawVars = await variableBuilder.buildFromContext(
  context: executionContext,
  interactive: interactive,
  outputDir: outputDir,
);

final request = FeatureGenerationRequest(
  name: rawVars['name'] as String,
  feature: rawVars['feature'] as String? ?? 'home',
  screenType: ScreenType.tryFromKey(rawVars['screen_type'] as String?),
  // ... other properties
  outputDirectory: targetDir,
  dryRun: context.planMode,
);
```

#### 3. Handler Routing

**Location**: `GenerationCommandHandler`

**Process**:
- Receives `GenerationRequestDto`
- Routes to appropriate use case based on `mode` property
- Converts `GenerationResultDto` to `CommandResult`

**Code Example**:
```dart
// From GenerationCommandHandler
Future<CommandResult> executeFeature(FeatureGenerationRequest request) async {
  final result = await _generateFeatureUseCase.execute(request);
  return _convertToCommandResult(result, GenerationMode.feature);
}
```

#### 4. Use Case Execution

**Location**: `GenerateFeatureUseCase`, `GenerateServiceUseCase`, or `GenerateProjectUseCase`

All generation use cases delegate to the `IWorkflowOrchestrator`, which applies
mode-specific workflows:

- **Features/Services** (Simple Flow inside orchestrator):
  1. Get brick from repository
  2. Process variables through pipeline
  3. Validate variables
  4. Generate using engine
- **Projects** (Complex Flow inside orchestrator):
  1. Use workflow orchestrator
  2. Orchestrator handles multi-step generation
  3. Supports nested generation (features, services within project)

**Code Example** (Feature):
```dart
// From GenerateFeatureUseCase.execute()
final result = await _workflowOrchestrator.executeWorkflow(
  mode: GenerationMode.feature,
  variables: request.toJson(),
  outputDirectory: request.outputDirectory,
  dryRun: request.dryRun,
);

return GenerationResultDto.fromResult(result);
```

**Code Example** (Project):
```dart
// From GenerateProjectUseCase.execute()
// Uses workflow orchestrator for complex multi-step generation
final result = await _workflowOrchestrator.executeWorkflow(
  mode: GenerationMode.project,
  variables: request.toJson(),
  outputDirectory: request.outputDirectory,
  dryRun: request.dryRun,
);

return GenerationResultDto.fromResult(result);
```

#### 5. Variable Processing

**Location**: `VariableProcessingService`

**Process**:
1. Create `GenerationContext` from raw variables
2. Run variable derivation pipeline
3. Merge derived variables with raw variables
4. Validate against brick schema

**Code Example**:
```dart
// From VariableProcessingService.process()
// 1. Create context
final context = GenerationContext.fromVars(rawVars, mode: mode);

// 2. Run pipeline
var bag = VariableBag.fromMap(rawVars);
bag = _pipeline.run(context, _logger);

// 3. Merge
final processed = {...rawVars, ...bag.toMap()};

// 4. Validate (using processor-specific validator)
final validationErrors = _validator.validateAll(
  brick: brick,
  variables: processed,
);
```

#### 6. Template Discovery

**Location**: `BrickRepository`, `BrickDiscoveryService`

**Process**:
1. Scan `templates/bricks/` directory
2. Load `brick.yaml` or `template.yaml` metadata
3. Parse brick variables and requirements
4. Validate brick structure
5. Cache brick metadata

**Code Example**:
```dart
// From BrickDiscoveryService.loadBrickMetadata()
final brickYamlFile = File(path.join(brickPath, 'brick.yaml'));
final yamlContent = await brickYamlFile.readAsString();
final yaml = loadYaml(yamlContent) as Map<dynamic, dynamic>;

final brick = Brick.fromYaml(mergedYaml, brickPath);
```

#### 7. File Generation

**Location**: `MasonGenerationEngine` or `TemplateManager`

**Process**:
1. Create Mason brick instance from brick path
2. Create `MasonGenerator` from brick
3. Create target directory
4. Generate files using Mason
5. Return list of generated files

**Code Example**:
```dart
// From TemplateManager._performGeneration()
final brickInstance = mason.Brick.path(brick.path);
final generator = await mason.MasonGenerator.fromBrick(brickInstance);
final targetDir = Directory(outputDirectory);
final target = mason.DirectoryGeneratorTarget(targetDir);

final generatedFiles = await generator.generate(
  target,
  vars: variables,
  logger: logger,
  fileConflictResolution: mason.FileConflictResolution.overwrite,
);
```

#### 8. Result Propagation

**Location**: All layers

**Flow**:
- `GenerationResult` (domain) → `GenerationResultDto` (application) → `CommandResult` (presentation)

**Code Example**:
```dart
// Use case returns GenerationResultDto
return GenerationResultDto.fromResult(result);

// Handler converts to CommandResult
return CommandResult.success(
  command: 'generate ${mode.key}',
  message: '${mode.key.capitalize()} generated successfully',
  data: {
    ...result.data,
    'files_generated': result.generatedFiles.length,
  },
);
```

---

## Architecture Layers

The generation system follows Clean Architecture with four distinct layers:

### 1. Presentation Layer

**Location**: `lib/src/features/generate/`

**Components**:

- **Commands**: `GenerateFeatureCommand`, `GenerateServiceCommand`, `GenerateProjectCommand`
- **Command Descriptors**: `FeatureCommandDescriptor`, `ServiceCommandDescriptor`,
  `ProjectCommandDescriptor`
- **Handler**: `GenerationCommandHandler`

**Responsibilities**:
- Parse CLI arguments and flags
- Build variable maps from user input
- Create type-safe request DTOs
- Convert results to user-friendly messages
- Handle interactive prompts

**Key Files**:
```
features/generate/
├── common/
│   ├── generation_command_base.dart
│   └── generation_command_handler.dart
├── feature/
│   ├── generate_feature_command.dart
│   └── feature_command_descriptor.dart
├── service/
│   ├── generate_service_command.dart
│   └── service_command_descriptor.dart
└── project/
    ├── generate_project_command.dart
    └── project_command_descriptor.dart
```

### 2. Application Layer

**Location**: `lib/src/generation/application/`

**Components**:
- **Use Cases**: `GenerateFeatureUseCase`, `GenerateServiceUseCase`, `GenerateProjectUseCase`
- **DTOs**: `GenerationRequestDto`, `GenerationResultDto`
- **Ports**: `IGenerationEngine`, `IVariableProcessor`, `IWorkflowOrchestrator`
- **Services**: `VariableProcessingService`

**Responsibilities**:
- Orchestrate business logic
- Coordinate between domain and infrastructure
- Process variables through pipelines
- Validate business rules
- Transform domain results to DTOs

**Key Files**:
```
generation/application/
├── dto/
│   ├── generation_request_dto.dart
│   └── generation_result_dto.dart
├── ports/
│   ├── igeneration_engine.dart
│   ├── ivariable_processor.dart
│   └── iworkflow_orchestrator.dart
├── services/
│   └── variable_processing_service.dart
└── use_cases/
    ├── generate_feature_use_case.dart
    ├── generate_service_use_case.dart
    └── generate_project_use_case.dart
```

### 3. Domain Layer

**Location**: `lib/src/generation/domain/`

**Components**:
- **Entities**: `Brick`
- **Repositories**: `IBrickRepository`, `ITemplateRepository`
- **Value Objects**: `BrickVariable`, `VersionRange`
- **Services**: `BrickValidator`, `CompatibilityService`

**Responsibilities**:
- Define core business entities
- Enforce business rules
- Provide repository interfaces
- Define value objects

**Key Files**:
```
generation/domain/
├── entities/
│   └── brick.dart
├── repositories/
│   ├── ibrick_repository.dart
│   └── itemplate_repository.dart
└── value_objects/
    └── brick_variable.dart
```

### 4. Infrastructure Layer

**Location**: `lib/src/generation/infrastructure/`

**Components**:
- **Generation Engine**: `MasonGenerationEngine`
- **Brick Repository**: `BrickRepositoryImpl`
- **Workflow Orchestrator**: `WorkflowOrchestratorImpl`
- **Adapters**: `MasonAdapter`, `FileSystemAdapter`

**Responsibilities**:
- Implement domain interfaces
- Interact with external systems (Mason, file system)
- Handle platform-specific concerns
- Provide concrete implementations

**Key Files**:
```
generation/infrastructure/
├── generation/
│   └── mason_generation_engine.dart
├── brick/
│   └── brick_repository_impl.dart
├── workflow/
│   └── workflow_orchestrator_impl.dart
└── adapters/
    ├── mason_adapter.dart
    └── file_system_adapter.dart
```

### Layer Interaction Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Commands   │  │  Descriptors │  │   Handler     │     │
│  └──────┬───────┘  └──────────────┘  └──────┬─────────┘     │
└─────────┼────────────────────────────────────┼──────────────┘
          │                                    │
          │ Uses                               │ Uses
          ▼                                    ▼
┌─────────────────────────────────────────────────────────────┐
│                    Application Layer                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Use Cases  │  │     DTOs     │  │   Services    │     │
│  └──────┬───────┘  └──────────────┘  └──────┬─────────┘     │
└─────────┼────────────────────────────────────┼──────────────┘
          │                                    │
          │ Implements                         │ Implements
          ▼                                    ▼
┌─────────────────────────────────────────────────────────────┐
│                      Domain Layer                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Entities   │  │ Repositories │  │ Value Objects│     │
│  └──────┬───────┘  └──────┬────────┘  └──────────────┘     │
└─────────┼─────────────────┼───────────────────────────────┘
          │                  │
          │                  │ Implemented by
          │                  ▼
┌─────────────────────────────────────────────────────────────┐
│                 Infrastructure Layer                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Engines    │  │ Repositories │  │   Adapters   │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

---

## Component Interactions

### Command → Handler → Use Case Flow

```
┌──────────────────┐
│ GenerateCommand  │
│  (Presentation)  │
└────────┬─────────┘
         │
         │ 1. Creates GenerationRequestDto
         │
         ▼
┌──────────────────┐
│ CommandHandler   │
│  (Presentation)  │
└────────┬─────────┘
         │
         │ 2. Routes to Use Case
         │
         ▼
┌──────────────────┐
│ GenerateUseCase  │
│  (Application)   │
└────────┬─────────┘
         │
         │ 3. Coordinates domain services
         │
         ├─────────────────┬─────────────────┐
         │                 │                 │
         ▼                 ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│   Variable   │  │    Brick     │  │  Generation   │
│  Processor   │  │  Repository  │  │    Engine     │
└──────────────┘  └──────────────┘  └──────────────┘
```

### Variable Processing Pipeline

```
┌─────────────────────────────────────────────────────────────┐
│                    Raw Variables                            │
│  { name: "home_screen", feature: "home", ... }             │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              VariableProcessingService                       │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ 1. Create GenerationContext                          │   │
│  │ 2. Run Variable Pipeline                              │   │
│  │    - FoundationPipeline (for projects)               │   │
│  │    - FeaturePipeline (for features)                 │   │
│  │    - ServicePipeline (for services)                  │   │
│  │ 3. Merge derived variables                           │   │
│  │ 4. Validate against brick schema                     │   │
│  └──────────────────────────────────────────────────────┘   │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              Processed Variables                            │
│  { name: "home_screen", feature: "home",                   │
│    snake_name: "home_screen",                               │
│    pascal_name: "HomeScreen", ... }                        │
└─────────────────────────────────────────────────────────────┘
```

### Brick Discovery Flow

```
┌─────────────────────────────────────────────────────────────┐
│              BrickRepository.getBrick(name)                 │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              BrickRegistry.getBrick(name)                   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ 1. Check cache                                        │   │
│  │ 2. If not cached:                                     │   │
│  │    - Scan templates/bricks/ directory                │   │
│  │    - Load brick.yaml metadata                        │   │
│  │    - Parse variables and requirements                │   │
│  │    - Validate structure                              │   │
│  │    - Cache result                                    │   │
│  └──────────────────────────────────────────────────────┘   │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                    Brick Entity                             │
│  { name, version, path, variables, type, ... }              │
└─────────────────────────────────────────────────────────────┘
```

---

## Variable Processing and Validation

### Variable Builders

**Location**: `lib/src/generation/generation_variable_builder.dart`

**Purpose**: Convert CLI flags and user input into normalized variable maps

**Types**:
- `FeatureVariableBuilder`: Builds variables for feature generation
- `ServiceVariableBuilder`: Builds variables for service generation
- `ProjectVariableBuilder`: Builds variables for project generation

**Example**:
```dart
class FeatureVariableBuilder implements GenerationVariableBuilder {
  @override
  Future<Map<String, dynamic>> buildFromContext({
    required CommandContext context,
    required bool interactive,
    String? outputDir,
  }) async {
    if (interactive) {
      return _buildInteractive(context);
    } else {
      return _buildFromFlags(context.argResults);
    }
  }

  Map<String, dynamic> _buildFromFlags(ArgResults? argResults) {
    return {
      'name': FlagAccessor.getString(argResults, const NameFlag()),
      'feature': FlagAccessor.getString(argResults, const FeatureFlag()) ?? 'home',
      'screen_type': FlagAccessor.getString(argResults, const ScreenTypeFlag()) ?? 'list',
      'with_viewmodel': FlagAccessor.getBool(argResults, const WithViewModelFlag()),
      // ... more variables
    };
  }
}
```

### Variable Derivation Pipeline

**Location**: `lib/src/generation/variables/variable_derivers/`

**Purpose**: Derive additional variables from raw inputs (e.g., `snake_name`, `pascal_name` from `name`)

**Pipeline Structure**:
```dart
// Foundation pipeline for projects
final foundationPipeline = VariablePipeline([
  ProjectNameDeriver(),
  OrganizationDeriver(),
  PlatformDeriver(),
  FeatureDeriver(),
  ServiceDeriver(),
  // ... more derivers
]);

// Feature pipeline for features
final featurePipeline = VariablePipeline([
  NameDeriver(),
  FeatureDeriver(),
  ScreenTypeDeriver(),
  // ... more derivers
]);
```

**Example Deriver**:
```dart
class NameDeriver implements VariableDeriver {
  @override
  VariableBag derive(GenerationContext context, VariableBag bag) {
    final name = bag.getString('name');
    if (name != null) {
      bag.set('snake_name', name.toLowerCase().replaceAll(' ', '_'));
      bag.set('pascal_name', _toPascalCase(name));
      bag.set('camel_name', _toCamelCase(name));
    }
    return bag;
  }
}
```

### Variable Validation

**Location**: `lib/src/generation/variables/validation/`

**Purpose**: Validate variables against brick schema and business rules

**Architecture**: Validation follows SOLID principles with processor-specific validators:

- Each processor (`ProjectVariableProcessor`, `FeatureVariableProcessor`,
  `ServiceVariableProcessor`) owns its validation logic
- Validators implement `IVariableValidator` interface
- Shared brick-level validation is handled by `BrickVariableValidator`
- Business rule validation is encapsulated per processor

**Validation Components**:

1. **IVariableValidator**: Interface that all validators implement
2. **BrickVariableValidator**: Shared brick-level validation (required vars, types, choices)
3. **ProjectVariableValidator**: Project-specific business rules (project name, organization,
   platforms)
4. **FeatureVariableValidator**: Feature-specific business rules (component name, feature name,
   screen type)
5. **ServiceVariableValidator**: Service-specific business rules (component name, feature name,
   service type, API URL)

**Validation Levels**:

1. **Brick-Level Validation**: Check required variables, types, constraints (shared across all
   modes)
2. **Business Rule Validation**: Check naming conventions, format requirements (mode-specific)
3. **Cross-Variable Validation**: Check relationships between variables (mode-specific)

**Example** (Processor with Validator):
```dart
class ProjectVariableProcessor implements IVariableProcessor {
  ProjectVariableProcessor({
    IVariableValidator? validator,
    // ... other dependencies
  }) : _validator = validator ?? ProjectVariableValidator();

  final IVariableValidator _validator;

  @override
  Future<ProcessedVariables> process({
    required Map<String, dynamic> rawVars,
    required GenerationMode mode,
    required Brick brick,
  }) async {
    // ... variable processing ...

    // Validate using processor-specific validator
    final validationErrors = _validator.validateAll(
      brick: brick,
      variables: processed,
    );

    final validationResult = validationErrors.isEmpty
        ? VariableValidationResult.success()
        : VariableValidationResult.failure(validationErrors);

    return ProcessedVariables(
      values: processed,
      validationResult: validationResult,
    );
  }
}
```

**Example** (Validator Implementation):
```dart
class ProjectVariableValidator implements IVariableValidator {
  @override
  List<String> validateAll({
    required Brick? brick,
    required Map<String, dynamic> variables,
  }) {
    final errors = <String>[];

    // 1. Brick-level validation (shared)
    if (brick != null) {
      errors.addAll(BrickVariableValidator.validate(brick, variables));
    }

    // 2. Business rule validation (project-specific)
    errors.addAll(validateBusinessRules(variables));

    return errors;
  }

  @override
  List<String> validateBusinessRules(Map<String, dynamic> variables) {
    final errors = <String>[];
    // Project-specific validation logic
    // - Project name format
    // - Organization format
    // - Platform validation
    return errors;
  }
}
```

---

## Template Discovery and Execution

### Brick Discovery

**Location**: `lib/src/generation/brick/brick_discovery_service.dart`

**Process**:
1. Scan `templates/bricks/` directory structure
2. Load `brick.yaml` or `template.yaml` metadata
3. Parse brick variables and requirements
4. Validate brick structure
5. Cache results

**Directory Structure**:
```
templates/
└── bricks/
    ├── project/
    │   └── fly_foundation/
    │       ├── brick.yaml
    │       ├── fly_metadata.yaml (optional)
    │       └── __brick__/
    │           └── (template files)
    ├── feature/
    │   └── feature/
    │       ├── brick.yaml
    │       └── __brick__/
    └── service/
        └── service/
            ├── brick.yaml
            └── __brick__/
```

**Brick Metadata Example**:
```yaml
# brick.yaml
name: feature
version: 1.0.0
description: Generate a new feature component

variables:
  name:
    type: string
    description: Component name
    required: true
    prompt: What is the component name?
  feature:
    type: string
    description: Feature name
    default: home
  screen_type:
    type: enum
    description: Type of screen
    default: list
    values:
      - list
      - detail
      - form
      - auth
      - settings
```

### Brick Execution

**Location**: `lib/src/generation/template/template_manager.dart`

**Process**:
1. Load brick from repository
2. Create Mason brick instance
3. Create Mason generator
4. Generate files to target directory
5. Return generated file list

**Code Flow**:
```dart
// 1. Get brick
final brick = await _brickRepository.getBrick('feature');

// 2. Create Mason brick
final masonBrick = mason.Brick.path(brick.path);

// 3. Create generator
final generator = await mason.MasonGenerator.fromBrick(masonBrick);

// 4. Generate
final target = mason.DirectoryGeneratorTarget(Directory(outputDirectory));
final files = await generator.generate(
  target,
  vars: variables,
  logger: logger,
);
```

### Special Handling: Project Generation with Features

For project generation, the system handles nested feature generation:

```dart
// From TemplateManager._performGeneration()
if (brick.type == BrickType.project && 
    variables.containsKey('features')) {
  final features = variables['features'] as List<dynamic>;
  
  // Generate base project with first feature
  final baseVariables = Map<String, dynamic>.from(variables);
  baseVariables['feature'] = features.first;
  await generator.generate(target, vars: baseVariables);
  
  // Generate each additional feature
  for (int i = 1; i < features.length; i++) {
    final featureVariables = Map<String, dynamic>.from(variables);
    featureVariables['feature'] = features[i];
    await generator.generate(target, vars: featureVariables);
  }
}
```

---

## Error Handling and Result Propagation

### Error Types

**Domain Errors**:
- `BrickNotFoundException`: Brick not found in repository
- `VariableValidationError`: Variable validation failed
- `GenerationError`: File generation failed

**Infrastructure Errors**:
- `MasonException`: Mason generation error
- `FileSystemException`: File system operation failed

### Error Propagation Flow

```
┌─────────────────────────────────────────────────────────────┐
│              Generation Engine                               │
│  (Infrastructure Layer)                                      │
│  └─► Catches MasonException, FileSystemException             │
│      └─► Returns GenerationResult.failure()                  │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              Use Case                                        │
│  (Application Layer)                                        │
│  └─► Catches exceptions                                     │
│      └─► Returns GenerationResultDto with error              │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              Command Handler                                 │
│  (Presentation Layer)                                        │
│  └─► Converts to CommandResult.error()                      │
│      └─► Adds user-friendly message and suggestions         │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              User                                            │
│  └─► Sees actionable error message                         │
└─────────────────────────────────────────────────────────────┘
```

### Error Handling Example

```dart
// In Use Case
try {
  final brick = await _brickRepository.getBrick(brickName);
  if (brick == null) {
    return GenerationResultDto(
      success: false,
      error: 'Brick "$brickName" not found',
      data: {'brick_name': brickName},
    );
  }
  
  // ... generation logic
} catch (e) {
  return GenerationResultDto(
    success: false,
    error: 'Generation failed: $e',
    data: {'error_type': e.runtimeType.toString()},
  );
}

// In Handler
CommandResult _convertToCommandResult(
  GenerationResultDto result,
  GenerationMode mode,
) {
  if (!result.success) {
    return CommandResult.error(
      message: result.error ?? 'Generation failed',
      suggestion: 'Check your input and try again',
      errorCode: ErrorCode.templateGenerationFailed,
    );
  }
  // ... success case
}
```

### Result Types

**GenerationResult** (Domain):
```dart
sealed class GenerationResult {
  final bool success;
  final String? error;
  final Map<String, dynamic>? data;
}
```

**GenerationResultDto** (Application):
```dart
class GenerationResultDto {
  final bool success;
  final String? error;
  final List<String> generatedFiles;
  final Map<String, dynamic>? data;
}
```

**CommandResult** (Presentation):
```dart
sealed class CommandResult {
  final bool success;
  final String message;
  final List<NextStep>? nextSteps;
  final Map<String, dynamic>? data;
}
```

---

## Mode Strategy Pattern

The generation system uses a **Mode Strategy Pattern** to decouple command handling from
mode-specific logic. This allows new generation modes to be added without modifying central
components like `GenerationCommandHandler`.

### Architecture

**GenerationModeStrategy** (`lib/src/generation/application/strategies/generation_mode_strategy.dart`):
- Abstract interface that encapsulates mode-specific behavior
- Each strategy knows how to:
  - Execute generation for its mode (delegates to use case)
  - Provide next-step suggestions for successful generation

**GenerationModeRegistry** (`lib/src/generation/application/strategies/generation_mode_registry.dart`):
- Central registry mapping `GenerationMode` → `GenerationModeStrategy`
- Enables mode-agnostic command handling

**Benefits**:
- **Reduced coupling**: Adding a new mode only requires:
  - Creating a new strategy
  - Registering it in DI
  - Adding a command/DTO
- **No central switch statements**: Handler uses registry lookup instead
- **Easier testing**: Strategies can be tested independently

### Example Strategy

```dart
class FeatureGenerationModeStrategy implements GenerationModeStrategy {
  FeatureGenerationModeStrategy({
    required GenerateFeatureUseCase useCase,
  }) : _useCase = useCase;

  final GenerateFeatureUseCase _useCase;

  @override
  GenerationMode get mode => GenerationMode.feature;

  @override
  Future<GenerationResultDto> execute(GenerationRequestDto request) async {
    if (request is! FeatureGenerationRequest) {
      throw ArgumentError('Expected FeatureGenerationRequest');
    }
    return await _useCase.execute(request);
  }

  @override
  List<NextStep> getNextSteps(GenerationResultDto result) {
    return [
      const NextStep(
        command: 'flutter run',
        description: 'Run the application to see the new screen',
      ),
    ];
  }
}
```

## Error Modeling

The generation system uses structured error types for better error handling and user guidance.

### GenerationErrorType

**Location**: `lib/src/generation/domain/generation_error_type.dart`

```dart
enum GenerationErrorType {
  brickNotFound,      // Brick was not found
  variableValidation, // Variable validation failed
  generationFailure,  // Generation operation failed
  infrastructure,     // Infrastructure error (file system, Mason, etc.)
  unknown,            // Unknown or unclassified error
}
```

### Error Mapping

**GenerationErrorMapper** (`lib/src/generation/domain/generation_error_mapper.dart`):
- Maps exceptions and error conditions to `GenerationErrorType`
- Provides consistent error categorization across the pipeline
- Used in use cases and workflow orchestrator to tag errors

### Error Flow

1. **Domain/Infrastructure**: Exceptions or error conditions occur
2. **Use Cases/Orchestrator**: Map to `GenerationErrorType` using `GenerationErrorMapper`
3. **GenerationResult**: Includes `errorType` field
4. **GenerationResultDto**: Carries `errorType` to presentation layer
5. **CommandResult**: Uses `errorType` for contextual suggestions

### Benefits

- **Better user guidance**: Error-specific suggestions (e.g., "Verify brick name" for `brickNotFound`)
- **Analytics**: Structured error data for monitoring and improvement
- **Consistent handling**: All errors follow the same categorization pattern

## Validation Boundaries

The system maintains clear boundaries between CLI-level and business-level validation:

### CLI-Level Validation (Presentation Layer)

**Location**: Command validators (`*Command.validators`)

**Responsibility**:
- Check presence of required positional arguments
- Validate basic format (e.g., file paths, directory existence)
- Provide immediate feedback for CLI usage errors

**Example**:
```dart
@override
List<CommandValidator> get validators => [
  RequiredArgumentValidator('screen_name'),
  ScreenNameValidator(),  // Basic format check
  FlutterProjectValidator(),
];
```

### Business-Level Validation (Application Layer)

**Location**: Variable processors and validators

**Responsibility**:
- Validate business rules (naming conventions, compatibility)
- Cross-variable validation
- Brick schema conformance

**Example**:
```dart
// In FeatureVariableValidator
List<String> validateBusinessRules(Map<String, dynamic> variables) {
  // Business rules: snake_case naming, required fields, etc.
}
```

### Key Principle

**Builders** (`*VariableBuilder`) focus on:
- Reading CLI flags/interactive input
- Normalizing into variable maps
- **NOT** performing business rule validation

**Processors/Validators** are the **single source of truth** for business rules.

## Developer Guide: Adding New Generation Types

This guide walks through adding a new generation type (e.g., `widget`, `model`, `repository`)
following the existing patterns. With the mode strategy pattern, adding new types is simpler
and requires fewer central changes.

### Step 1: Create Command Descriptor

**Location**: `lib/src/features/generate/{type}/{type}_command_descriptor.dart`

**Example** (for a `widget` type):
```dart
import 'package:args/command_runner.dart';
import 'package:fly_cli/src/features/commands/domain/categories.dart';
import 'package:fly_cli/src/features/commands/domain/command_context.dart';
import 'package:fly_cli/src/features/commands/domain/fly_command_strategy.dart';
import 'package:fly_cli/src/features/generate/widget/generate_widget_command.dart';

/// Strategy for widget command
class WidgetCommandDescriptor extends FlyCommandDescriptor {
  @override
  String get name => 'widget';

  @override
  String get description =>
      'Generate a new widget component to the current project';

  @override
  List<String> get aliases => [
    'generate-widget',
    'add-widget',
    'new-widget',
    'make-widget',
  ];

  @override
  CommandGroup? get group => const CommandGroup(
    name: 'generate',
    description: 'Generate new components for the current project',
  );

  @override
  CommandCategory get category => CommandCategory.generation;

  @override
  Command<int> createInstance(CommandContext context) {
    return GenerateWidgetCommand.create(context);
  }
}
```

### Step 2: Create Generation Command

**Location**: `lib/src/features/generate/{type}/generate_{type}_command.dart`

**Example**:
```dart
import 'package:fly_cli/src/features/commands/application/command_base.dart';
import 'package:fly_cli/src/features/commands/domain/command_context.dart';
import 'package:fly_cli/src/features/commands/domain/command_result.dart';
import 'package:fly_cli/src/features/commands/infrastructure/flags/cli_flags.dart';
import 'package:fly_cli/src/features/commands/infrastructure/flags/flag_accessor.dart';
import 'package:fly_cli/src/features/generate/common/generation_command_handler.dart';
import 'package:fly_cli/src/generation/application/dto/generation_request_dto.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';
import 'package:fly_cli/src/generation/generation_variable_builder.dart';

class GenerateWidgetCommand extends FlyCommand {
  GenerateWidgetCommand(super.context);

  factory GenerateWidgetCommand.create(CommandContext context) =>
      GenerateWidgetCommand(context);

  @override
  String get name => 'widget';

  @override
  String get description =>
      'Generate a new widget component for the current project';

  @override
  List<CliFlag> get flags => [
    const NameFlag(),
    const OutputDirFlag(),
    const InteractiveFlag(),
    // Add type-specific flags here
  ];

  @override
  List<CommandValidator> get validators => [
    RequiredArgumentValidator('widget_name'),
    // Add validators here
  ];

  @override
  Future<CommandResult> execute() async {
    try {
      final interactive = FlagAccessor.getBool(
        argResults,
        const InteractiveFlag(),
      );
      final outputDir = FlagAccessor.getString(
        argResults,
        const OutputDirFlag(),
      );

      // Build variables
      final executionContext = context.factory.createExecutionContext(
        argResults!,
      );
      const variableBuilder = WidgetVariableBuilder();
      final rawVars = await variableBuilder.buildFromContext(
        context: executionContext,
        interactive: interactive,
        outputDir: outputDir,
      );

      // Validate
      final validationResult = variableBuilder.validate(rawVars);
      if (!validationResult.isValid) {
        return CommandResult.error(
          message: 'Validation failed: ${validationResult.errors.join(', ')}',
          suggestion: 'Check your input and try again',
        );
      }

      // Resolve output directory
      final outputDirResult = await context.pathResolver.resolveOutputDirectory(
        context,
        outputDir,
      );
      if (!outputDirResult.success) {
        return CommandResult.error(
          message: 'Failed to resolve output directory',
        );
      }
      final targetDir = outputDirResult.path!.absolute;

      // Create request
      final request = WidgetGenerationRequest(
        name: rawVars['name'] as String,
        outputDirectory: targetDir,
        dryRun: context.planMode,
      );

      // Get handler and execute
      final handler = context.getService<GenerationCommandHandler>();
      final result = await handler.executeWidget(request);

      return result;
    } catch (e) {
      return CommandResult.error(
        message: 'Failed to generate widget: $e',
      );
    }
  }
}
```

### Step 3: Create Generation Request DTO

**Location**: `lib/src/generation/application/dto/generation_request_dto.dart`

**Add to existing file**:
```dart
/// Request for widget generation.
@JsonSerializable(explicitToJson: true, includeIfNull: false)
final class WidgetGenerationRequest extends GenerationRequestDto {
  const WidgetGenerationRequest({
    required this.name,
    required super.outputDirectory,
    this.widgetType = WidgetType.stateless,
    super.dryRun = false,
  });

  final String name;
  final WidgetType widgetType;

  factory WidgetGenerationRequest.fromJson(Map<String, dynamic> json) =>
      _$WidgetGenerationRequestFromJson(json);

  @override
  GenerationMode get mode => GenerationMode.widget;

  @override
  Map<String, dynamic> toJson() {
    return _$WidgetGenerationRequestToJson(this);
  }
}
```

**Update sealed class** (if needed):
```dart
sealed class GenerationRequestDto {
  // ... existing code
}
```

### Step 4: Add Generation Mode Enum

**Location**: `lib/src/generation/foundation/foundation_enums.dart`

**Add to enum**:
```dart
enum GenerationMode {
  project('project'),
  feature('feature'),
  service('service'),
  widget('widget'), // Add new mode
  ;

  final String key;
  const GenerationMode(this.key);
}
```

### Step 5: Create Variable Validator

**Location**: `lib/src/generation/variables/validation/widget_variable_validator.dart`

**Create validator class**:
```dart
import 'package:fly_cli/src/generation/domain/entities/brick.dart';
import 'package:fly_cli/src/generation/variables/validation/brick_variable_validator.dart';
import 'package:fly_cli/src/generation/variables/validation/ivariable_validator.dart';

/// Validator for widget generation mode variables.
class WidgetVariableValidator implements IVariableValidator {
  @override
  List<String> validateAll({
    required Brick? brick,
    required Map<String, dynamic> variables,
  }) {
    final errors = <String>[];

    // Brick-level validation (if brick is provided)
    if (brick != null) {
      errors.addAll(BrickVariableValidator.validate(brick, variables));
    }

    // Business rule validation
    errors.addAll(validateBusinessRules(variables));

    return errors;
  }

  @override
  List<String> validateBusinessRules(Map<String, dynamic> variables) {
    final errors = <String>[];
    // Add widget-specific validation logic here
    // - Widget name format
    // - Widget type validation
    // - Other widget-specific rules
    return errors;
  }
}
```

### Step 6: Create Variable Builder

**Location**: `lib/src/generation/generation_variable_builder.dart`

**Add new builder class**:
```dart
/// Builder for widget generation variables.
class WidgetVariableBuilder implements GenerationVariableBuilder {
  const WidgetVariableBuilder();

  @override
  Future<Map<String, dynamic>> buildFromContext({
    required CommandContext context,
    required bool interactive,
    String? outputDir,
  }) async {
    if (interactive) {
      return _buildInteractive(context);
    } else {
      return _buildFromFlags(context.argResults);
    }
  }

  @override
  Map<String, dynamic> buildFromMap(Map<String, dynamic> input) {
    return {
      'name': input['name'] as String,
      'generation_mode': 'widget',
      'widget_type': input['widget_type'] as String? ?? 'stateless',
    };
  }

  @override
  ValidationResult validate(Map<String, dynamic> rawVars) {
    // Use widget-specific validator
    final validator = WidgetVariableValidator();
    final errors = validator.validateBusinessRules(rawVars);
    return errors.isEmpty
        ? ValidationResult.success()
        : ValidationResult.failure(errors);
  }

  Future<Map<String, dynamic>> _buildInteractive(CommandContext context) async {
    // Interactive prompt logic
    // ...
  }

  Map<String, dynamic> _buildFromFlags(ArgResults? argResults) {
    return {
      'name': FlagAccessor.getString(argResults, const NameFlag()),
      'widget_type': FlagAccessor.getString(argResults, const WidgetTypeFlag()) ?? 'stateless',
    };
  }
}
```

### Step 7: Create Variable Processor

**Location**: `lib/src/generation/application/services/processors/widget_variable_processor.dart`

**Create processor class**:
```dart
import 'package:fly_cli/src/generation/application/ports/ivariable_processor.dart';
import 'package:fly_cli/src/generation/domain/entities/brick.dart';
import 'package:fly_cli/src/generation/variables/validation/ivariable_validator.dart';
import 'package:fly_cli/src/generation/variables/validation/widget_variable_validator.dart';

class WidgetVariableProcessor implements IVariableProcessor {
  WidgetVariableProcessor({
    IVariableValidator? validator,
    // ... other dependencies
  }) : _validator = validator ?? WidgetVariableValidator();

  final IVariableValidator _validator;

  @override
  Future<ProcessedVariables> process({
    required Map<String, dynamic> rawVars,
    required GenerationMode mode,
    required Brick brick,
  }) async {
    // ... variable processing ...

    // Validate using processor-specific validator
    final validationErrors = _validator.validateAll(
      brick: brick,
      variables: processed,
    );

    final validationResult = validationErrors.isEmpty
        ? VariableValidationResult.success()
        : VariableValidationResult.failure(validationErrors);

    return ProcessedVariables(
      values: processed,
      validationResult: validationResult,
    );
  }
}
```

### Step 8: Create Use Case

**Location**: `lib/src/generation/application/use_cases/generate_widget_use_case.dart`

**Example**:
```dart
import 'package:fly_cli/src/generation/application/dto/generation_request_dto.dart';
import 'package:fly_cli/src/generation/application/dto/generation_result_dto.dart';
import 'package:fly_cli/src/generation/application/ports/igeneration_engine.dart';
import 'package:fly_cli/src/generation/application/ports/ivariable_processor.dart';
import 'package:fly_cli/src/generation/domain/repositories/ibrick_repository.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';

/// Use case for generating widgets.
class GenerateWidgetUseCase {
  GenerateWidgetUseCase({
    required IBrickRepository brickRepository,
    required IVariableProcessor variableProcessor,
    required IGenerationEngine generationEngine,
  }) : _brickRepository = brickRepository,
       _variableProcessor = variableProcessor,
       _generationEngine = generationEngine;

  final IBrickRepository _brickRepository;
  final IVariableProcessor _variableProcessor;
  final IGenerationEngine _generationEngine;

  Future<GenerationResultDto> execute(WidgetGenerationRequest request) async {
    try {
      // 1. Get brick
      const brickName = 'widget';
      final brick = await _brickRepository.getBrick(brickName);
      if (brick == null) {
        return const GenerationResultDto(
          success: false,
          error: 'Brick "widget" not found',
          data: {'brick_name': 'widget'},
        );
      }

      // 2. Process variables
      final processed = await _variableProcessor.process(
        rawVars: request.toJson(),
        mode: GenerationMode.widget,
        brick: brick,
      );

      if (!processed.validationResult.isValid) {
        return GenerationResultDto(
          success: false,
          error: 'Variable validation failed: ${processed.validationResult.errors.join(', ')}',
          data: {
            'validation_errors': processed.validationResult.errors,
            'brick_name': brickName,
          },
        );
      }

      // 3. Generate
      final result = await _generationEngine.generate(
        brick: brick,
        variables: processed.values,
        outputDirectory: request.outputDirectory,
        dryRun: request.dryRun,
      );

      return GenerationResultDto.fromResult(result);
    } catch (e) {
      return GenerationResultDto(
        success: false,
        error: 'Generation failed: $e',
        data: {'error_type': e.runtimeType.toString()},
      );
    }
  }
}
```

### Step 9: Create Mode Strategy

**Location**: `lib/src/generation/application/strategies/widget_generation_mode_strategy.dart`

**Create strategy**:
```dart
import 'package:fly_cli/src/features/commands/domain/command_result.dart';
import 'package:fly_cli/src/generation/application/dto/generation_request_dto.dart';
import 'package:fly_cli/src/generation/application/dto/generation_result_dto.dart';
import 'package:fly_cli/src/generation/application/strategies/generation_mode_strategy.dart';
import 'package:fly_cli/src/generation/application/use_cases/generate_widget_use_case.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';

class WidgetGenerationModeStrategy implements GenerationModeStrategy {
  WidgetGenerationModeStrategy({
    required GenerateWidgetUseCase useCase,
  }) : _useCase = useCase;

  final GenerateWidgetUseCase _useCase;

  @override
  GenerationMode get mode => GenerationMode.widget;

  @override
  Future<GenerationResultDto> execute(GenerationRequestDto request) async {
    if (request is! WidgetGenerationRequest) {
      throw ArgumentError('Expected WidgetGenerationRequest');
    }
    return await _useCase.execute(request);
  }

  @override
  List<NextStep> getNextSteps(GenerationResultDto result) {
    return [
      const NextStep(
        command: 'flutter run',
        description: 'Run the application to see the new widget',
      ),
    ];
  }
}
```

**Note**: With the mode strategy pattern, you no longer need to modify `GenerationCommandHandler`
directly. The handler automatically uses the registry to find the appropriate strategy.

### Step 10: Register Command Descriptor

**Location**: `lib/src/features/commands/application/command_registration.dart` (or similar)

**Add registration**:
```dart
// In command registration
registry.registerStrategy(
  'widget',
  () => WidgetCommandDescriptor(),
);
```

### Step 11: Create Brick Template

**Location**: `templates/bricks/widget/widget/`

**Structure**:
```
templates/bricks/widget/widget/
├── brick.yaml
└── __brick__/
    └── lib/
        └── widgets/
            └── {{snake_name}}/
                └── {{snake_name}}_widget.dart
```

**brick.yaml**:
```yaml
name: widget
version: 1.0.0
description: Generate a new widget component

variables:
  name:
    type: string
    description: Widget name
    required: true
    prompt: What is the widget name?
  widget_type:
    type: enum
    description: Type of widget
    default: stateless
    values:
      - stateless
      - stateful
```

### Step 12: Update Dependency Injection

**Location**: `lib/src/cli/application/bootstrapping/service_bootstrapper.dart`

**Add services**:
```dart
// Register use case (if not already registered)
..registerSingleton<GenerateWidgetUseCase>(
  GenerateWidgetUseCase(
    workflowOrchestrator: container.get<IWorkflowOrchestrator>(),
  ),
)

// Register mode strategy
..registerSingleton<WidgetGenerationModeStrategy>(
  WidgetGenerationModeStrategy(
    useCase: container.get<GenerateWidgetUseCase>(),
  ),
)

// Update registry registration
..registerSingleton<GenerationModeRegistry>(
  GenerationModeRegistry({
    GenerationMode.feature: container.get<FeatureGenerationModeStrategy>(),
    GenerationMode.service: container.get<ServiceGenerationModeStrategy>(),
    GenerationMode.project: container.get<ProjectGenerationModeStrategy>(),
    GenerationMode.widget: container.get<WidgetGenerationModeStrategy>(), // Add
  }),
)

// Note: GenerationCommandHandler is already registered and will automatically
// use the updated registry. No changes needed to handler registration!
```

### Step 13: Add Tests

**Location**: `test/features/generate/widget/`

**Example test structure**:
```dart
// test/features/generate/widget/generate_widget_command_test.dart
void main() {
  group('GenerateWidgetCommand', () {
    test('should generate widget successfully', () async {
      // Test implementation
    });

    test('should validate widget name', () async {
      // Test validation
    });
  });
}
```

### Step 14: Update Documentation

- Add new type to this documentation
- Update command help text
- Add examples to README files

---

## Integration Points Summary

### Required Files Checklist

- [ ] Command Descriptor: `features/generate/{type}/{type}_command_descriptor.dart`
- [ ] Command: `features/generate/{type}/generate_{type}_command.dart`
- [ ] Request DTO: `generation/application/dto/generation_request_dto.dart` (add variant)
- [ ] Variable Validator: `generation/variables/validation/{type}_variable_validator.dart`
- [ ] Variable Builder: `generation/generation_variable_builder.dart` (add builder)
- [ ] Variable Processor: `generation/application/services/processors/{type}_variable_processor.dart`
- [ ] Use Case: `generation/application/use_cases/generate_{type}_use_case.dart`
- [ ] Handler Method: `features/generate/common/generation_command_handler.dart` (add method)
- [ ] Enum Update: `generation/foundation/foundation_enums.dart` (add mode)
- [ ] Brick Template: `templates/bricks/{type}/{type}/`
- [ ] DI Registration: `generation/infrastructure/di/generation_service_container.dart`
- [ ] Tests: `test/features/generate/{type}/`

### Code Patterns to Follow

1. **Command Pattern**: Follow `GenerateFeatureCommand` structure
2. **Use Case Pattern**: Follow `GenerateFeatureUseCase` structure
3. **Variable Builder**: Follow `FeatureVariableBuilder` structure
4. **Error Handling**: Always return `GenerationResultDto` with clear error messages
5. **Validation**: Create a processor-specific validator implementing `IVariableValidator` (e.g.,
   `WidgetVariableValidator`)

### Testing Requirements

1. **Unit Tests**: Test variable building, validation, use case logic
2. **Integration Tests**: Test end-to-end generation flow
3. **Error Cases**: Test error handling and validation failures
4. **Edge Cases**: Test with various input combinations

---

## Examples Reference

### Existing Implementations

1. **Feature Generation** (`feature/`):
   - Simple single-brick generation
   - Interactive and flag-based modes
   - Variable derivation pipeline

2. **Service Generation** (`service/`):
   - Similar to feature but for services
   - Service type selection
   - API configuration

3. **Project Generation** (`project/`):
   - Complex multi-step workflow
   - Nested generation (features, services)
   - Manifest file support

### Key Differences

- **Feature/Service**: Simple single-brick workflows implemented inside the workflow orchestrator
- **Project**: Complex multi-step workflows (including nested feature/service generation)
  implemented inside the workflow orchestrator

---

## Troubleshooting

### Common Issues

1. **Brick Not Found**
   - Check brick exists in `templates/bricks/{type}/{name}/`
   - Verify `brick.yaml` is valid
   - Check brick registry discovery

2. **Variable Validation Fails**
   - Check variable names match brick schema
   - Verify required variables are provided
   - Check variable types match

3. **Generation Fails**
   - Check Mason brick structure
   - Verify template files in `__brick__/`
   - Check file permissions

4. **Command Not Registered**
   - Verify command descriptor is registered
   - Check command runner initialization
   - Verify factory method exists

---

## Related Documentation

- [Command System](../commands/README.md)
- [Template Versioning](../../generation/versioning/README.md)
- [Variable Processing](../../generation/variables/)
- [Brick System](../../generation/brick/)

---

## Contributing

When adding new generation types:

1. Follow the existing patterns (feature, service, project)
2. Maintain clean architecture boundaries
3. Add comprehensive tests
4. Update this documentation
5. Provide clear error messages
6. Support both interactive and flag-based modes

---

## License

Part of the Fly CLI project. See main LICENSE file for details.

