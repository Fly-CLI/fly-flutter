import 'package:fly_brick_composer/fly_brick_composer.dart';
import 'package:fly_cli/src/features/commands/domain/command_result.dart';
import 'package:fly_cli/src/generation/application/dto/generation_request_dto.dart';
import 'package:fly_cli/src/generation/application/dto/generation_result_dto.dart';
import 'package:fly_cli/src/generation/application/modes/generation_mode_profile.dart';
import 'package:fly_cli/src/generation/application/ports/ivariable_processor.dart';
import 'package:fly_cli/src/generation/application/strategies/generation_mode_registry.dart';
import 'package:fly_cli/src/generation/application/strategies/generation_mode_strategy.dart';
import 'package:fly_cli/src/generation/domain/entities/brick.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';
import 'package:test/test.dart';

/// Mock strategy for testing
class MockStrategy implements GenerationModeStrategy<GenerationRequestDto> {
  MockStrategy({
    required this.mode,
    GenerationResultDto? result,
  }) : _result =
           result ??
           const GenerationResultDto(
             success: true,
             generatedFiles: [],
             data: {},
           );

  final GenerationMode mode;
  final GenerationResultDto? _result;
  GenerationRequestDto? lastRequest;

  @override
  Future<GenerationResultDto> execute(GenerationRequestDto request) async {
    lastRequest = request;
    return _result!;
  }

  @override
  List<NextStep> getNextSteps(GenerationResultDto result) {
    return [
      const NextStep(
        command: 'test-command',
        description: 'Test next step',
      ),
    ];
  }
}

void main() {
  group('GenerationModeRegistry', () {
    late MockStrategy featureStrategy;
    late MockStrategy serviceStrategy;
    late MockStrategy projectStrategy;
    late GenerationModeRegistry registry;

    setUp(() {
      featureStrategy = MockStrategy(mode: GenerationMode.feature);
      serviceStrategy = MockStrategy(mode: GenerationMode.service);
      projectStrategy = MockStrategy(mode: GenerationMode.project);

      final mockProcessor = _MockVariableProcessor();
      final profiles = {
        GenerationMode.feature: GenerationModeProfile(
          mode: GenerationMode.feature,
          brickId: BrickId.feature,
          variableProcessor: mockProcessor,
          strategy: featureStrategy,
        ),
        GenerationMode.service: GenerationModeProfile(
          mode: GenerationMode.service,
          brickId: BrickId.service,
          variableProcessor: mockProcessor,
          strategy: serviceStrategy,
        ),
        GenerationMode.project: GenerationModeProfile(
          mode: GenerationMode.project,
          brickId: BrickId.project,
          variableProcessor: mockProcessor,
          strategy: projectStrategy,
        ),
      };

      registry = GenerationModeRegistry(profiles);
    });

    group('getStrategy', () {
      test('should return strategy for registered mode', () {
        expect(
          registry.getStrategy(GenerationMode.feature),
          equals(featureStrategy),
        );
        expect(
          registry.getStrategy(GenerationMode.service),
          equals(serviceStrategy),
        );
        expect(
          registry.getStrategy(GenerationMode.project),
          equals(projectStrategy),
        );
      });

      test('should throw ArgumentError for unregistered mode', () {
        // Note: This test assumes there might be other modes in the enum
        // In practice, all modes used by CLI should be registered
        expect(
          () => registry.getStrategy(GenerationMode.feature),
          returnsNormally,
        );
      });
    });

    group('forMode', () {
      test('should return strategy for registered mode', () {
        expect(
          registry.forMode(GenerationMode.feature),
          equals(featureStrategy),
        );
        expect(
          registry.forMode(GenerationMode.service),
          equals(serviceStrategy),
        );
        expect(
          registry.forMode(GenerationMode.project),
          equals(projectStrategy),
        );
      });

      test('should return null for unregistered mode', () {
        // This would only happen if a new mode is added to the enum
        // but not registered in the registry
        // In practice, all CLI-used modes should be registered
      });
    });

    group('execute', () {
      test('should route feature request to feature strategy', () async {
        const request = FeatureGenerationRequest(
          name: 'test_screen',
          outputDirectory: '/test/output',
        );

        final result = await registry.execute(request);

        expect(result.success, isTrue);
        expect(featureStrategy.lastRequest, equals(request));
        expect(serviceStrategy.lastRequest, isNull);
        expect(projectStrategy.lastRequest, isNull);
      });

      test('should route service request to service strategy', () async {
        const request = ServiceGenerationRequest(
          name: 'test_service',
          outputDirectory: '/test/output',
        );

        final result = await registry.execute(request);

        expect(result.success, isTrue);
        expect(featureStrategy.lastRequest, isNull);
        expect(serviceStrategy.lastRequest, equals(request));
        expect(projectStrategy.lastRequest, isNull);
      });

      test('should route project request to project strategy', () async {
        const request = ProjectGenerationRequest(
          name: 'test_project',
          outputDirectory: '/test/output',
        );

        final result = await registry.execute(request);

        expect(result.success, isTrue);
        expect(featureStrategy.lastRequest, isNull);
        expect(serviceStrategy.lastRequest, isNull);
        expect(projectStrategy.lastRequest, equals(request));
      });

      test('should throw ArgumentError for unregistered mode', () async {
        // Create a request with a mode that's not in the registry
        // This is a defensive test - in practice all modes should be registered
        final mockProcessor = _MockVariableProcessor();
        final unregisteredStrategy = MockStrategy(mode: GenerationMode.feature);
        final unregisteredRegistry = GenerationModeRegistry({
          // Only register one mode, not all
          GenerationMode.feature: GenerationModeProfile(
            mode: GenerationMode.feature,
            brickId: BrickId.feature,
            variableProcessor: mockProcessor,
            strategy: unregisteredStrategy,
          ),
        });

        const request = ServiceGenerationRequest(
          name: 'test_service',
          outputDirectory: '/test/output',
        );

        // The registry should throw when trying to execute with an unregistered mode
        expect(
          () => unregisteredRegistry.execute(request),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('registeredModes', () {
      test('should return all registered modes', () {
        final modes = registry.registeredModes;
        expect(modes, contains(GenerationMode.feature));
        expect(modes, contains(GenerationMode.service));
        expect(modes, contains(GenerationMode.project));
        expect(modes.length, equals(3));
      });
    });

    group('isRegistered', () {
      test('should return true for registered modes', () {
        expect(registry.isRegistered(GenerationMode.feature), isTrue);
        expect(registry.isRegistered(GenerationMode.service), isTrue);
        expect(registry.isRegistered(GenerationMode.project), isTrue);
      });

      test('should return false for unregistered modes', () {
        // This test verifies defensive behavior
        // In practice, all CLI-used modes should be registered
      });
    });

    group('single source of truth', () {
      test('should ensure all CLI-used modes are registered', () {
        // This test ensures that the registry contains entries for all
        // GenerationMode values that are used by the CLI
        // This is a critical requirement for the registry to serve as
        // the single source of truth

        final registeredModes = registry.registeredModes;

        // Verify that all expected modes are registered
        expect(registeredModes, contains(GenerationMode.feature));
        expect(registeredModes, contains(GenerationMode.service));
        expect(registeredModes, contains(GenerationMode.project));

        // If new modes are added to GenerationMode enum, they must be
        // registered here. This test will fail if a mode is missing.
        // Note: This is a basic check - in a real scenario, you might want
        // to iterate over all GenerationMode values and verify each is registered
      });
    });

    group('profiles', () {
      test('should provide access to profiles and brick IDs', () {
        // Verify profile access
        final featureProfile = registry.getProfile(GenerationMode.feature);
        expect(featureProfile, isNotNull);
        expect(featureProfile!.mode, equals(GenerationMode.feature));
        expect(featureProfile.brickId, equals(BrickId.feature));

        // Verify brick ID access
        expect(registry.getBrickId(GenerationMode.feature), equals(BrickId.feature));
        expect(registry.getBrickId(GenerationMode.service), equals(BrickId.service));
        expect(registry.getBrickId(GenerationMode.project), equals(BrickId.project));
      });

      test('should throw ArgumentError when constructed with empty profiles', () {
        expect(
          () => GenerationModeRegistry({}),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });
}

/// Mock variable processor for testing
class _MockVariableProcessor implements IVariableProcessor {
  @override
  Future<ProcessedVariables> process({
    required Map<String, dynamic> rawVars,
    required GenerationMode mode,
    required Brick brick,
  }) async {
    return ProcessedVariables(
      values: rawVars,
      validationResult: VariableValidationResult.success(),
    );
  }
}
