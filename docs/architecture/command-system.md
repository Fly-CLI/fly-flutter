# Fly CLI Command Architecture

## Overview

The Fly CLI command architecture follows SOLID principles and clean architecture patterns to provide
a scalable, maintainable, and extensible foundation for rapid command expansion. The architecture
supports dependency injection, middleware pipelines, validation chains, lifecycle hooks, and plugin
systems.

## Architecture Components

### 1. Command Foundation (`features/command_foundation/`)

The command foundation provides the core abstractions and base classes for all commands.

#### Domain Layer
- **`CommandContext`** - Encapsulates execution context with dependencies and configuration
- **`CommandLifecycle`** - Defines lifecycle hooks for command execution phases
- **`CommandMiddleware`** - Interface for cross-cutting concerns
- **`CommandValidator`** - Interface for validation logic
- **`CommandResult`** - Standardized result structure with AI-friendly formats

#### Application Layer
- **`FlyCommand`** - Enhanced base command class with integrated features

#### Infrastructure Layer
- **`CommandContextImpl`** - Concrete implementation of CommandContext
- **`Environment`** - Environment information abstraction

### 2. Dependency Injection (`features/dependency_injection/`)

Factory-based dependency injection system for managing service lifecycles and dependencies.

#### Domain Layer
- **`ServiceContainer`** - Service registration and resolution container
- **`ServiceLifetime`** - Service lifetime management (transient, scoped, singleton)

#### Application Layer
- **`CommandFactory`** - Factory for creating commands with injected dependencies

### 3. Validation System (`features/validation/`)

Composable validation pipeline with common validators for argument and environment validation.

#### Validators
- **`RequiredArgumentValidator`** - Validates required arguments
- **`ProjectNameValidator`** - Validates project name format
- **`FlutterProjectValidator`** - Validates Flutter project structure
- **`DirectoryWritableValidator`** - Validates directory permissions
- **`TemplateExistsValidator`** - Validates template availability
- **`EnvironmentValidator`** - Validates environment prerequisites
- **`NetworkValidator`** - Validates network connectivity

### 4. Middleware System (`features/middleware/`)

Pipeline-based middleware for cross-cutting concerns.

#### Built-in Middleware
- **`LoggingMiddleware`** - Command execution logging
- **`MetricsMiddleware`** - Performance metrics collection
- **`DryRunMiddleware`** - Plan mode execution
- **`CachingMiddleware`** - Result caching
- **`RateLimitingMiddleware`** - Request rate limiting

### 5. Plugin System (`features/plugins/`)

Extensible plugin architecture for third-party command registration.

#### Domain Layer
- **`FlyPlugin`** - Base plugin interface
- **`PluginContext`** - Plugin initialization context
- **`PluginConfig`** - Plugin configuration model

#### Application Layer
- **`PluginRegistry`** - Plugin discovery, loading, and lifecycle management

## Command Lifecycle

Commands follow a structured execution lifecycle:

1. **Validation Phase** - Run all registered validators
2. **Middleware Pipeline** - Execute middleware in priority order
3. **Pre-execution Hook** - Call `onBeforeExecute()`
4. **Command Execution** - Run the main `execute()` method
5. **Post-execution Hook** - Call `onAfterExecute()`
6. **Error Handling** - Call `onError()` if exceptions occur

## Creating a New Command

### 1. Basic Command Structure

```dart
class MyCommand extends FlyCommand {
  MyCommand(CommandContext context) : super(context);

  @override
  String get name => 'my-command';

  @override
  String get description => 'Description of my command';

  @override
  Future<CommandResult> execute() async {
    // Command logic here
    return CommandResult.success(
      command: name,
      message: 'Command completed successfully',
    );
  }
}
```

### 2. Adding Validators

```dart
@override
List<CommandValidator> get validators => [
  const RequiredArgumentValidator('project_name'),
  const ProjectNameValidator(),
  const FlutterProjectValidator(),
];
```

### 3. Adding Middleware

```dart
@override
List<CommandMiddleware> get middleware => [
  const LoggingMiddleware(),
  const MetricsMiddleware(),
  const DryRunMiddleware(),
];
```

### 4. Implementing Lifecycle Hooks

```dart
@override
Future<void> onBeforeExecute(CommandContext context) async {
  logger.info('🔧 Preparing to execute command...');
}

@override
Future<void> onAfterExecute(CommandContext context, CommandResult result) async {
  if (result.success) {
    logger.info('🎉 Command completed successfully!');
  }
}

@override
Future<void> onError(CommandContext context, Object error, StackTrace stackTrace) async {
  logger.err('💥 Command failed: $error');
}
```

## Dependency Injection Usage

### Service Registration

```dart
final container = ServiceContainer()
  ..registerSingleton<Logger>(Logger())
  ..register<TemplateManager>((c) => TemplateManager(...))
  ..registerSingleton<SystemChecker>(SystemChecker());
```

### Service Resolution

```dart
final logger = container.get<Logger>();
final templateManager = container.get<TemplateManager>();
```

### Command Factory Usage

```dart
final factory = CommandFactory(container);
final command = factory.create<MyCommand>();
```

## Validation System Usage

### Custom Validator

```dart
class CustomValidator extends CommandValidator {
  @override
  Future<ValidationResult> validate(CommandContext context, ArgResults args) async {
    // Validation logic
    if (/* validation fails */) {
      return ValidationResult.failure(['Validation error message']);
    }
    return ValidationResult.success();
  }

  @override
  int get priority => 100; // Lower numbers run first
}
```

### Validation Result Handling

```dart
final result = ValidationResult.combine([
  ValidationResult.success(),
  ValidationResult.failure(['Error 1', 'Error 2']),
  ValidationResult.withWarnings(['Warning 1']),
]);
```

## Middleware System Usage

### Custom Middleware

```dart
class CustomMiddleware extends CommandMiddleware {
  @override
  Future<CommandResult?> handle(CommandContext context, NextMiddleware next) async {
    // Pre-processing
    logger.info('Before command execution');
    
    // Execute next middleware or command
    final result = await next();
    
    // Post-processing
    logger.info('After command execution');
    
    return result;
  }

  @override
  int get priority => 150; // Lower numbers run first
}
```

## Plugin System Usage

### Creating a Plugin

```dart
class MyPlugin extends FlyPlugin {
  @override
  String get name => 'my-plugin';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'My custom plugin';

  @override
  Future<void> initialize(PluginContext context) async {
    // Plugin initialization
  }

  @override
  List<Command<int>> registerCommands() {
    return [MyCustomCommand()];
  }

  @override
  List<CommandMiddleware> registerMiddleware() {
    return [MyCustomMiddleware()];
  }

  @override
  Future<void> dispose() async {
    // Cleanup resources
  }
}
```

### Plugin Configuration

```json
{
  "plugins": [
    {
      "name": "my-plugin",
      "version": "1.0.0",
      "enabled": true,
      "config": {
        "custom_setting": "value"
      },
      "dependencies": []
    }
  ]
}
```

## Testing

### Using Test Harness

```dart
void main() {
  group('MyCommand Tests', () {
    late CommandTestHarness harness;

    setUp(() {
      harness = CommandTestHarness();
    });

    test('should execute successfully', () async {
      // Arrange
      final context = harness.createMockContext();
      final command = MyCommand(context);

      // Act
      final result = await command.execute();

      // Assert
      harness.assertSuccess(result, expectedMessage: 'Command completed');
      harness.assertLogMessages(
        infoMessages: ['Command started'],
        successMessages: ['Command completed'],
      );
    });
  });
}
```

### Mock Services

```dart
// Configure mock responses
harness.container.mockInteractivePrompt.setStringResponses(['test-project']);
harness.container.mockTemplateManager.setFailure(false);

// Assert mock interactions
expect(harness.container.mockTemplateManager.generatedProjects, contains('test-project'));
```

## Best Practices

### 1. Command Design
- Keep commands focused on a single responsibility
- Use dependency injection for all external dependencies
- Implement proper error handling with meaningful messages
- Provide helpful suggestions in error results

### 2. Validation
- Use composition over inheritance for validators
- Order validators by priority (required args first, then business logic)
- Provide clear, actionable error messages
- Validate early and fail fast

### 3. Middleware
- Keep middleware stateless when possible
- Use appropriate priority ordering
- Handle errors gracefully
- Log meaningful information

### 4. Testing
- Test commands in isolation using mocks
- Test validation logic separately
- Test middleware pipeline behavior
- Use test harness for consistent setup

### 5. Performance
- Use singleton services for expensive resources
- Implement caching for idempotent operations
- Use lazy loading for optional features
- Monitor execution times with metrics middleware

## Migration Guide

### From Old Architecture

1. **Update Command Class**
   ```dart
   // Old
   class MyCommand extends FlyCommand {
     MyCommand() : super();
   }

   // New
   class MyCommand extends FlyCommand {
     MyCommand(CommandContext context) : super(context);
   }
   ```

2. **Extract Dependencies**
   ```dart
   // Old
   final templateManager = TemplateManager(...);

   // New
   final templateManager = context.templateManager;
   ```

3. **Add Validators**
   ```dart
   @override
   List<CommandValidator> get validators => [
     const RequiredArgumentValidator('project_name'),
     const ProjectNameValidator(),
   ];
   ```

4. **Add Middleware**
   ```dart
   @override
   List<CommandMiddleware> get middleware => [
     const LoggingMiddleware(),
     const MetricsMiddleware(),
   ];
   ```

## Performance Considerations

- **Service Lifecycle**: Use singletons for expensive resources
- **Lazy Loading**: Load plugins and services on demand
- **Caching**: Cache command results for idempotent operations
- **Parallel Execution**: Run independent validators in parallel
- **Memory Management**: Dispose resources properly in plugins

## Troubleshooting

### Common Issues

1. **Service Not Found**
   - Ensure service is registered in ServiceContainer
   - Check service lifetime (singleton vs transient)

2. **Validation Failures**
   - Verify validator priority ordering
   - Check validator shouldRun() conditions

3. **Middleware Issues**
   - Ensure middleware priority is correct
   - Check middleware shouldRun() conditions

4. **Plugin Loading**
   - Verify plugin directory structure
   - Check plugin configuration format
   - Ensure plugin dependencies are met

### Debug Mode

Enable verbose logging to debug issues:

```bash
fly --verbose my-command
```

This will provide detailed information about:
- Service resolution
- Validation results
- Middleware execution
- Plugin loading
- Error stack traces
