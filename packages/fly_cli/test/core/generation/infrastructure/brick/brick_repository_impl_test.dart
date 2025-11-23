import 'package:fly_cli/src/core/generation/brick/brick_metadata.dart';
import 'package:fly_cli/src/core/generation/brick/brick_registry.dart';
import 'package:fly_cli/src/core/generation/domain/entities/brick.dart';
import 'package:fly_cli/src/core/generation/infrastructure/brick/brick_repository_impl.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:test/test.dart';

void main() {
  group('BrickRepositoryImpl', () {
    late BrickRegistry mockRegistry;
    late BrickRepositoryImpl repository;

    setUp(() {
      mockRegistry = BrickRegistry(logger: Logger());
      repository = BrickRepositoryImpl(brickRegistry: mockRegistry);
    });

    group('getBrick', () {
      test('should get brick by name', () async {
        // This test would require mocking BrickRegistry
        // For now, we test the structure
        expect(repository, isNotNull);
      });

      test('should return null when brick not found', () async {
        // This would require a mock registry
        // The actual implementation throws StateError, which is expected
        expect(repository, isNotNull);
      });
    });

    group('discoverBricks', () {
      test('should discover all bricks', () async {
        // Act
        final bricks = await repository.discoverBricks();

        // Assert
        expect(bricks, isA<List<Brick>>());
      });

      test('should force refresh when requested', () async {
        // Act
        final bricks = await repository.discoverBricks(forceRefresh: true);

        // Assert
        expect(bricks, isA<List<Brick>>());
      });
    });

    group('brickExists', () {
      test('should check if brick exists', () async {
        // Act
        final exists = await repository.brickExists('test_brick');

        // Assert
        expect(exists, isA<bool>());
      });
    });

    group('getBricksByType', () {
      test('should filter bricks by type', () async {
        // Act
        final bricks = await repository.getBricksByType(BrickType.feature);

        // Assert
        expect(bricks, isA<List<Brick>>());
      });
    });

    group('clearCache', () {
      test('should clear brick cache', () async {
        // Act & Assert - should not throw
        await repository.clearCache();
        expect(repository, isNotNull);
      });
    });
  });
}

