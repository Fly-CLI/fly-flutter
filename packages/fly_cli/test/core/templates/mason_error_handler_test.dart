import 'dart:io';

import 'package:fly_cli/src/core/templates/mason_error_handler.dart';
import 'package:mason/mason.dart';
import 'package:test/test.dart';

void main() {
  group('MasonErrorHandler', () {
    test('should classify MasonException as brick generation failed', () {
      final error = MasonException('Generation failed');
      final errorType = MasonErrorHandler.classifyError(error);

      expect(errorType, equals(MasonErrorType.brickGenerationFailed));
    });

    test('should classify FileSystemException as file system error', () {
      final error = FileSystemException('Permission denied');
      final errorType = MasonErrorHandler.classifyError(error);

      expect(errorType, equals(MasonErrorType.fileSystemError));
    });

    test('should classify permission error correctly', () {
      final error = FileSystemException('Permission denied');
      final errorType = MasonErrorHandler.classifyError(error);

      expect(errorType, equals(MasonErrorType.fileSystemError));
    });

    test('should classify unknown error as unknown', () {
      final error = Exception('Unknown error');
      final errorType = MasonErrorHandler.classifyError(error);

      expect(errorType, equals(MasonErrorType.unknown));
    });

    test('should determine if error can be recovered', () {
      expect(MasonErrorHandler.canRecover(MasonException('Brick not found')),
          isTrue);
      expect(
          MasonErrorHandler.canRecover(
              FileSystemException('Permission denied')),
          isTrue);
      expect(MasonErrorHandler.canRecover(Exception('Unknown error')), isFalse);
    });

    test('should provide suggestions for different error types', () {
      final suggestion =
          MasonErrorHandler.getSuggestion(MasonErrorType.brickNotFound, null);
      expect(suggestion, contains('Check if the brick exists'));

      final suggestion2 =
          MasonErrorHandler.getSuggestion(MasonErrorType.fileSystemError, null);
      expect(suggestion2, contains('Check file permissions'));
    });

    test('should get recovery strategies for different error types', () {
      final strategies = MasonErrorHandler.getRecoveryStrategies(
          MasonErrorType.brickNotFound, null);
      expect(strategies, isNotEmpty);
      expect(strategies.first, contains('fly template list'));

      final strategies2 = MasonErrorHandler.getRecoveryStrategies(
          MasonErrorType.cacheError, null);
      expect(strategies2, isNotEmpty);
      expect(strategies2.first, contains('fly template cache clear'));
    });
  });
}
