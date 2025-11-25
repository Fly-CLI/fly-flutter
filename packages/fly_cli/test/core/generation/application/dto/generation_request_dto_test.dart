import 'package:fly_cli/src/generation/application/dto/generation_request_dto.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';
import 'package:test/test.dart';

void main() {
  group('GenerationRequestDto', () {
    test('should create FeatureGenerationRequest from constructor', () {
      // Act
      final dto = FeatureGenerationRequest(
        variables: {'name': 'test'},
        outputDirectory: '/test/output',
        dryRun: false,
      );

      // Assert
      expect(dto.mode, equals(GenerationMode.feature));
      expect(dto.variables, equals({'name': 'test'}));
      expect(dto.outputDirectory, equals('/test/output'));
      expect(dto.dryRun, isFalse);
      expect(dto, isA<FeatureGenerationRequest>());
    });

    test('should create ServiceGenerationRequest from constructor', () {
      // Act
      final dto = ServiceGenerationRequest(
        variables: {'name': 'test_service'},
        outputDirectory: '/test/output',
        dryRun: true,
      );

      // Assert
      expect(dto.mode, equals(GenerationMode.service));
      expect(dto.variables, equals({'name': 'test_service'}));
      expect(dto.dryRun, isTrue);
      expect(dto, isA<ServiceGenerationRequest>());
    });

    test('should create ProjectGenerationRequest from constructor', () {
      // Act
      final dto = ProjectGenerationRequest(
        variables: {'name': 'test_project'},
        outputDirectory: '/test/output',
        dryRun: false,
      );

      // Assert
      expect(dto.mode, equals(GenerationMode.project));
      expect(dto.variables, equals({'name': 'test_project'}));
      expect(dto.outputDirectory, equals('/test/output'));
      expect(dto.dryRun, isFalse);
      expect(dto, isA<ProjectGenerationRequest>());
    });

    test('should create from map with feature mode', () {
      // Act
      final dto = GenerationRequestDto.fromMap(
        mode: GenerationMode.feature,
        variables: {'name': 'test_feature'},
        outputDirectory: '/test/output',
        dryRun: true,
      );

      // Assert
      expect(dto.mode, equals(GenerationMode.feature));
      expect(dto.variables, equals({'name': 'test_feature'}));
      expect(dto.dryRun, isTrue);
      expect(dto, isA<FeatureGenerationRequest>());
    });

    test('should create from map with service mode', () {
      // Act
      final dto = GenerationRequestDto.fromMap(
        mode: GenerationMode.service,
        variables: {'name': 'test_service'},
        outputDirectory: '/test/output',
        dryRun: true,
      );

      // Assert
      expect(dto.mode, equals(GenerationMode.service));
      expect(dto.variables, equals({'name': 'test_service'}));
      expect(dto.dryRun, isTrue);
      expect(dto, isA<ServiceGenerationRequest>());
    });

    test('should create from map with project mode', () {
      // Act
      final dto = GenerationRequestDto.fromMap(
        mode: GenerationMode.project,
        variables: {'name': 'test_project'},
        outputDirectory: '/test/output',
        dryRun: false,
      );

      // Assert
      expect(dto.mode, equals(GenerationMode.project));
      expect(dto.variables, equals({'name': 'test_project'}));
      expect(dto.dryRun, isFalse);
      expect(dto, isA<ProjectGenerationRequest>());
    });

    test('should convert FeatureGenerationRequest to map', () {
      // Arrange
      final dto = FeatureGenerationRequest(
        variables: {'name': 'test_feature'},
        outputDirectory: '/test/output',
        dryRun: false,
      );

      // Act
      final map = dto.toMap();

      // Assert
      expect(map['mode'], equals('feature'));
      expect(map['variables'], equals({'name': 'test_feature'}));
      expect(map['output_directory'], equals('/test/output'));
      expect(map['dry_run'], isFalse);
    });

    test('should convert ServiceGenerationRequest to map', () {
      // Arrange
      final dto = ServiceGenerationRequest(
        variables: {'name': 'test_service'},
        outputDirectory: '/test/output',
        dryRun: true,
      );

      // Act
      final map = dto.toMap();

      // Assert
      expect(map['mode'], equals('service'));
      expect(map['variables'], equals({'name': 'test_service'}));
      expect(map['output_directory'], equals('/test/output'));
      expect(map['dry_run'], isTrue);
    });

    test('should convert ProjectGenerationRequest to map', () {
      // Arrange
      final dto = ProjectGenerationRequest(
        variables: {'name': 'test_project'},
        outputDirectory: '/test/output',
        dryRun: false,
      );

      // Act
      final map = dto.toMap();

      // Assert
      expect(map['mode'], equals('project'));
      expect(map['variables'], equals({'name': 'test_project'}));
      expect(map['output_directory'], equals('/test/output'));
      expect(map['dry_run'], isFalse);
    });
  });
}
