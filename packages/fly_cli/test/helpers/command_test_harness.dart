import 'package:args/args.dart';
import 'package:fly_cli/src/cli/domain/interfaces/i_context_factory.dart';
import 'package:fly_cli/src/features/commands/domain/command_context.dart';
import 'package:fly_cli/src/features/commands/infrastructure/command_context_impl.dart';
import 'package:fly_cli/src/features/commands/infrastructure/interactive_prompt.dart';
import 'package:fly_cli/src/shared/di/service_container.dart';
import 'package:fly_cli/src/features/diagnostics/domain/system_checker.dart';
import 'package:fly_cli/src/cli/infrastructure/path_management/path_resolver.dart';
import 'package:fly_cli/src/cli/infrastructure/telemetry/infrastructure/metrics_config.dart';
import 'package:fly_cli/src/cli/infrastructure/telemetry/infrastructure/metrics_factory.dart';
import 'package:fly_cli/src/generation/template/template_manager.dart';
import 'package:mason/mason.dart';
import 'package:mason_logger/mason_logger.dart';

import 'command_test_helper.dart';
import 'mock_classes.dart';
import 'mock_logger.dart';

/// Test harness for command testing
class CommandTestHarness {
  final ServiceContainer container = ServiceContainer();

  /// Initialize the test harness
  void initialize() {
    // Initialize with mock services
    container
      ..registerSingleton<Logger>(Logger())
      ..registerSingleton<TemplateManager>(MockTemplateManager())
      ..registerSingleton<SystemChecker>(MockSystemChecker())
      ..registerSingleton<InteractivePrompt>(MockInteractivePrompt())
      ..registerSingleton<PathResolver>(PathResolver(
        logger: container.get<Logger>(),
        isDevelopment: true,
      ));
  }

  /// Create a mock command context
  CommandContext createMockContext({IContextFactory? factory}) {
    // Create a metrics collector for testing (disabled to avoid noise)
    const metricsConfig = MetricsConfig(enabled: false);
    final metricsFactory = MetricsFactory(metricsConfig);
    final metricsCollector = metricsFactory.create();
    final mockFactory = factory ?? MockContextFactory();

    return CommandContextImpl(
      argResults: ArgParser().parse([]),
      logger: container.get<Logger>(),
      templateManager: container.get<TemplateManager>(),
      systemChecker: container.get<SystemChecker>(),
      interactivePrompt: container.get<InteractivePrompt>(),
      pathResolver: container.get<PathResolver>(),
      metricsCollector: metricsCollector,
      config: <String, dynamic>{},
      environment: Environment.current(),
      workingDirectory: '/test/project',
      verbose: false,
      quiet: false,
      factory: mockFactory,
    );
  }

  /// Clear all mock state
  void clearMocks() {
    // Clear mock state as needed
  }
}
