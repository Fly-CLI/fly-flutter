import 'package:args/args.dart';
import 'package:fly_cli/src/core/command_foundation/command_context.dart';
import 'package:fly_cli/src/core/command_foundation/command_context_impl.dart';
import 'package:fly_cli/src/core/path_management/path_resolver.dart';
import 'package:fly_cli/src/core/dependency_injection/service_container.dart';
import 'package:fly_cli/src/core/templates/template_manager.dart';
import 'package:fly_cli/src/core/command_foundation/interactive_prompt.dart';
import 'package:fly_cli/src/core/diagnostics/system_checker.dart';
import 'package:mason_logger/mason_logger.dart';

import 'mock_classes.dart';
import 'mock_logger.dart';

/// Test harness for command testing
class CommandTestHarness {
  final ServiceContainer container = ServiceContainer();
  
  /// Initialize the test harness
  void initialize() {
    // Initialize with mock services
    container..registerSingleton<Logger>(MockLogger())
    ..registerSingleton<TemplateManager>(MockTemplateManager())
    ..registerSingleton<SystemChecker>(MockSystemChecker())
    ..registerSingleton<InteractivePrompt>(MockInteractivePrompt())
    ..registerSingleton<PathResolver>(PathResolver(
      logger: container.get<Logger>(),
      isDevelopment: true,
    ));
  }
  
  /// Create a mock command context
  CommandContext createMockContext() => CommandContextImpl(
      argResults: ArgParser().parse([]),
      logger: container.get<Logger>(),
      templateManager: container.get<TemplateManager>(),
      systemChecker: container.get<SystemChecker>(),
      interactivePrompt: container.get<InteractivePrompt>(),
      pathResolver: container.get<PathResolver>(),
      config: <String, dynamic>{},
      environment: Environment.current(),
      workingDirectory: '/test/project',
      verbose: false,
      quiet: false,
    );
  
  /// Clear all mock state
  void clearMocks() {
    // Clear mock state as needed
  }
}