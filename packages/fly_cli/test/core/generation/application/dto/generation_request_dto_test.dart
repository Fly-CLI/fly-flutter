import 'package:fly_cli/src/generation/application/dto/generation_request_dto.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';
import 'package:test/test.dart';

void main() {
  group('GenerationRequestDto', () {
    test('should create FeatureGenerationRequest from constructor', () {
      // Act
      const dto = FeatureGenerationRequest(
        name: 'test',
        outputDirectory: '/test/output',
        dryRun: false,
      );

      // Assert
      expect(dto.mode, equals(GenerationMode.feature));
      expect(dto.name, equals('test'));
      expect(dto.outputDirectory, equals('/test/output'));
      expect(dto.dryRun, isFalse);
      expect(dto, isA<FeatureGenerationRequest>());
    });

    test('should create ServiceGenerationRequest from constructor', () {
      // Act
      const dto = ServiceGenerationRequest(
        name: 'test_service',
        outputDirectory: '/test/output',
        dryRun: true,
      );

      // Assert
      expect(dto.mode, equals(GenerationMode.service));
      expect(dto.name, equals('test_service'));
      expect(dto.dryRun, isTrue);
      expect(dto, isA<ServiceGenerationRequest>());
    });

    test('should create ProjectGenerationRequest from constructor', () {
      // Act
      const dto = ProjectGenerationRequest(
        name: 'test_project',
        outputDirectory: '/test/output',
        dryRun: false,
      );

      // Assert
      expect(dto.mode, equals(GenerationMode.project));
      expect(dto.name, equals('test_project'));
      expect(dto.outputDirectory, equals('/test/output'));
      expect(dto.dryRun, isFalse);
      expect(dto, isA<ProjectGenerationRequest>());
    });

    test('should convert FeatureGenerationRequest to map', () {
      // Arrange
      const dto = FeatureGenerationRequest(
        name: 'test_feature',
        outputDirectory: '/test/output',
        dryRun: false,
      );

      // Act
      final map = dto.toMap();

      // Assert
      expect(map['mode'], equals('feature'));
      expect(map['output_directory'], equals('/test/output'));
      expect(map['dry_run'], isFalse);
      final variables = map['variables'] as Map<String, dynamic>;
      expect(variables['name'], equals('test_feature'));
    });

    test('should convert ServiceGenerationRequest to map', () {
      // Arrange
      const dto = ServiceGenerationRequest(
        name: 'test_service',
        outputDirectory: '/test/output',
        dryRun: true,
      );

      // Act
      final map = dto.toMap();

      // Assert
      expect(map['mode'], equals('service'));
      expect(map['output_directory'], equals('/test/output'));
      expect(map['dry_run'], isTrue);
      final variables = map['variables'] as Map<String, dynamic>;
      expect(variables['name'], equals('test_service'));
    });

    test('should convert ProjectGenerationRequest to map', () {
      // Arrange
      const dto = ProjectGenerationRequest(
        name: 'test_project',
        outputDirectory: '/test/output',
        dryRun: false,
      );

      // Act
      final map = dto.toMap();

      // Assert
      expect(map['mode'], equals('project'));
      expect(map['output_directory'], equals('/test/output'));
      expect(map['dry_run'], isFalse);
      final variables = map['variables'] as Map<String, dynamic>;
      expect(variables['name'], equals('test_project'));
    });
  });
}
