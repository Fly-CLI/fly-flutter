import 'package:args/command_runner.dart';

import 'package:fly_cli/src/core/dependency_injection/domain/service_container.dart';
import 'package:fly_cli/src/core/command_foundation/application/command_base.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';

/// Factory for creating commands with dependency injection
class CommandFactory {
  const CommandFactory(this._container);

  final ServiceContainer _container;

  /// Create a command instance with injected dependencies
  T create<T extends FlyCommand>() {
    // Get command context from container
    final context = _container.get<CommandContext>();
    
    // Create command instance using reflection or manual mapping
    // For now, we'll use a registry pattern
    return _createCommand<T>(context);
  }

  /// Create command instance - override this for specific command types
  T _createCommand<T extends FlyCommand>(CommandContext context) {
    // This would typically use reflection or a command registry
    // For now, we'll throw an error to indicate this needs implementation
    throw UnimplementedError('Command creation not implemented for type $T');
  }

  /// Register a command type with its constructor
  void registerCommand<T extends FlyCommand>(
    T Function(CommandContext) constructor,
  ) {
    _container.register<T>((container) => constructor(container.get<CommandContext>()));
  }
}

/// Extension to CommandRunner for dependency injection
extension CommandRunnerDI on CommandRunner<int> {
  /// Add a command using the factory
  void addCommandWithDI<T extends FlyCommand>(CommandFactory factory) {
    addCommand(factory.create<T>());
  }
}
