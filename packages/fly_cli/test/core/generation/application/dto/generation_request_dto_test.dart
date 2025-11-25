import 'package:fly_cli/src/generation/application/dto/generation_request_dto.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';
import 'package:test/test.dart';

void main() {
  group('GenerationRequestDto', () {
    test('should create from constructor', () {
      // Act
      final dto = GenerationRequestDto(
        mode: GenerationMode.feature,
        variables: {'name': 'test'},
        outputDirectory: '/test/output',
        dryRun: false,
      );

      // Assert
      expect(dto.mode, equals(GenerationMode.feature));
      expect(dto.variables, equals({'name': 'test'}));
      expect(dto.outputDirectory, equals('/test/output'));
      expect(dto.dryRun, isFalse);
    });

    test('should create from map', () {
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
    });

    test('should convert to map', () {
      // Arrange
      final dto = GenerationRequestDto(
        mode: GenerationMode.project,
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
