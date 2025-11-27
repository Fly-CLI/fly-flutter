import 'package:fly_cli/src/cli/application/bootstrapping/generation_services_factory.dart';
import 'package:fly_cli/src/cli/application/bootstrapping/service_bootstrapper.dart';
import 'package:fly_cli/src/cli/application/bootstrapping/service_bootstrapper_config.dart';
import 'package:fly_cli/src/cli/domain/interfaces/i_service_container.dart';
import 'package:fly_cli/src/features/generate/common/generation_command_handler.dart';
import 'package:fly_cli/src/generation/application/strategies/generation_mode_registry.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';
import 'package:fly_cli/src/integrations/mcp/infrastructure/adapters/generation_mcp_adapter.dart';
import 'package:fly_cli/src/shared/logging/infrastructure/structured_mason_logger.dart';
import 'package:test/test.dart';

void main() {
  group('ServiceBootstrapper with GenerationServicesFactory', () {
    test('should use default factory when none provided', () {
      final config = ServiceBootstrapperConfig.test();
      final bootstrapper = ServiceBootstrapper(config);

      bootstrapper.initialize();

      // Verify that generation services are registered
      expect(
        bootstrapper.container.isRegistered<GenerationModeRegistry>(),
        isTrue,
      );
      expect(
        bootstrapper.container.isRegistered<GenerationCommandHandler>(),
        isTrue,
      );
      expect(
        bootstrapper.container.isRegistered<GenerationMcpAdapter>(),
        isTrue,
      );
    });

    test('should accept custom generation services factory', () {
      final config = ServiceBootstrapperConfig.test();
      final customFactory = _TestGenerationServicesFactory();
      final bootstrapper = ServiceBootstrapper(
        config,
        generationServicesFactory: customFactory,
      );

      bootstrapper.initialize();

      // Verify that the custom factory was called
      expect(customFactory.wasCalled, isTrue);
      expect(customFactory.container, same(bootstrapper.container));
    });

    test('should register all expected generation services', () {
      final config = ServiceBootstrapperConfig.test();
      final bootstrapper = ServiceBootstrapper(config);

      bootstrapper.initialize();

      final container = bootstrapper.container;

      // Verify core generation services are registered
      expect(container.isRegistered<GenerationModeRegistry>(), isTrue);
      expect(container.isRegistered<GenerationCommandHandler>(), isTrue);
      expect(container.isRegistered<GenerationMcpAdapter>(), isTrue);

      // Verify registry contains expected modes
      final registry = container.get<GenerationModeRegistry>();
      expect(registry.isRegistered(GenerationMode.feature), isTrue);
      expect(registry.isRegistered(GenerationMode.service), isTrue);
      expect(registry.isRegistered(GenerationMode.project), isTrue);
    });
  });
}

/// Test factory implementation to verify injection works
class _TestGenerationServicesFactory implements IGenerationServicesFactory {
  bool wasCalled = false;
  IServiceContainer? container;

  @override
  void registerGenerationServices({
    required IServiceContainer container,
    required StructuredMasonLogger logger,
    required ServiceBootstrapperConfig config,
  }) {
    wasCalled = true;
    this.container = container;
    // Don't register anything - just verify the call
  }
}
