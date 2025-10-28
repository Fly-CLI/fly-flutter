import 'package:args/args.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command_foundation/infrastructure/command_context_impl.dart';
import 'package:fly_cli/src/core/dependency_injection/domain/service_container.dart';
import 'package:fly_cli/src/core/templates/template_manager.dart';
import 'package:fly_cli/src/core/command_foundation/infrastructure/interactive_prompt.dart';
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
    ..registerSingleton<InteractivePrompt>(MockInteractivePrompt());
  }
  
  /// Create a mock command context
  CommandContext createMockContext() => CommandContextImpl(
      argResults: ArgParser().parse([]),
      logger: container.get<Logger>(),
      templateManager: container.get<TemplateManager>(),
      systemChecker: container.get<SystemChecker>(),
      interactivePrompt: container.get<InteractivePrompt>(),
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