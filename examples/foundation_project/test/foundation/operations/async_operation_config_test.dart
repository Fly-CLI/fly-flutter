import 'package:flutter_test/flutter_test.dart';
import 'package:fly_glow_guard/fly_glow_guard.dart';
import '../test_helpers/mocks.dart';

void main() {
  group('AsyncOperationConfig', () {
    test('should have correct timeout constants', () {
      expect(AsyncOperationConfig.quickTimeout, equals(const Duration(seconds: 10)));
      expect(AsyncOperationConfig.standardTimeout, equals(const Duration(seconds: 30)));
      expect(AsyncOperationConfig.longTimeout, equals(const Duration(seconds: 60)));
      expect(AsyncOperationConfig.veryLongTimeout, equals(const Duration(seconds: 120)));
      expect(AsyncOperationConfig.backgroundTimeout, equals(const Duration(seconds: 100 * 60)));
    });

    test('should have correct retry configs', () {
      expect(AsyncOperationConfig.defaultRetryConfig, isNull);
      expect(AsyncOperationConfig.criticalRetryConfig, isA<RetryConfig>());
      expect(AsyncOperationConfig.standardRetryConfig, isA<RetryConfig>());
      expect(AsyncOperationConfig.destructiveRetryConfig, isA<RetryConfig>());
    });

    test('should have correct connectivity defaults', () {
      expect(AsyncOperationConfig.checkConnectivityByDefault, isFalse);
      expect(AsyncOperationConfig.queueIfOfflineByDefault, isFalse);
    });

    test('should have correct queue configuration', () {
      expect(AsyncOperationConfig.maxQueueSize, equals(100));
      expect(AsyncOperationConfig.defaultQueuePriority, equals(1));
      expect(AsyncOperationConfig.defaultQueueExpiry, equals(const Duration(hours: 24)));
      expect(AsyncOperationConfig.maxQueuedOperationRetries, equals(3));
    });

    group('getTimeoutForOperation', () {
      test('should return veryLongTimeout for upload operations', () {
        final timeout = AsyncOperationConfig.getTimeoutForOperation('upload');
        expect(timeout, equals(AsyncOperationConfig.veryLongTimeout));
      });

      test('should return veryLongTimeout for download operations', () {
        final timeout = AsyncOperationConfig.getTimeoutForOperation('download');
        expect(timeout, equals(AsyncOperationConfig.veryLongTimeout));
      });

      test('should return longTimeout for report operations', () {
        final timeout = AsyncOperationConfig.getTimeoutForOperation('report');
        expect(timeout, equals(AsyncOperationConfig.longTimeout));
      });

      test('should return longTimeout for export operations', () {
        final timeout = AsyncOperationConfig.getTimeoutForOperation('export');
        expect(timeout, equals(AsyncOperationConfig.longTimeout));
      });

      test('should return quickTimeout for validate operations', () {
        final timeout = AsyncOperationConfig.getTimeoutForOperation('validate');
        expect(timeout, equals(AsyncOperationConfig.quickTimeout));
      });

      test('should return quickTimeout for check operations', () {
        final timeout = AsyncOperationConfig.getTimeoutForOperation('check');
        expect(timeout, equals(AsyncOperationConfig.quickTimeout));
      });

      test('should return backgroundTimeout for background operations', () {
        final timeout = AsyncOperationConfig.getTimeoutForOperation('background');
        expect(timeout, equals(AsyncOperationConfig.backgroundTimeout));
      });

      test('should return backgroundTimeout for sync operations', () {
        final timeout = AsyncOperationConfig.getTimeoutForOperation('sync');
        expect(timeout, equals(AsyncOperationConfig.backgroundTimeout));
      });

      test('should return standardTimeout for unknown operations', () {
        final timeout = AsyncOperationConfig.getTimeoutForOperation('unknown');
        expect(timeout, equals(AsyncOperationConfig.standardTimeout));
      });
    });

    group('getRetryConfigForOperation', () {
      test('should return criticalRetryConfig for payment operations', () {
        final config = AsyncOperationConfig.getRetryConfigForOperation('payment');
        expect(config, equals(AsyncOperationConfig.criticalRetryConfig));
      });

      test('should return criticalRetryConfig for order operations', () {
        final config = AsyncOperationConfig.getRetryConfigForOperation('order');
        expect(config, equals(AsyncOperationConfig.criticalRetryConfig));
      });

      test('should return criticalRetryConfig for transaction operations', () {
        final config = AsyncOperationConfig.getRetryConfigForOperation('transaction');
        expect(config, equals(AsyncOperationConfig.criticalRetryConfig));
      });

      test('should return destructiveRetryConfig for delete operations', () {
        final config = AsyncOperationConfig.getRetryConfigForOperation('delete');
        expect(config, equals(AsyncOperationConfig.destructiveRetryConfig));
      });

      test('should return destructiveRetryConfig for remove operations', () {
        final config = AsyncOperationConfig.getRetryConfigForOperation('remove');
        expect(config, equals(AsyncOperationConfig.destructiveRetryConfig));
      });

      test('should return standardRetryConfig for fetch operations', () {
        final config = AsyncOperationConfig.getRetryConfigForOperation('fetch');
        expect(config, equals(AsyncOperationConfig.standardRetryConfig));
      });

      test('should return standardRetryConfig for get operations', () {
        final config = AsyncOperationConfig.getRetryConfigForOperation('get');
        expect(config, equals(AsyncOperationConfig.standardRetryConfig));
      });

      test('should return standardRetryConfig for create operations', () {
        final config = AsyncOperationConfig.getRetryConfigForOperation('create');
        expect(config, equals(AsyncOperationConfig.standardRetryConfig));
      });

      test('should return noRetry for validate operations', () {
        final config = AsyncOperationConfig.getRetryConfigForOperation('validate');
        expect(config, equals(RetryConfig.noRetry()));
      });

      test('should return defaultRetryConfig for unknown operations', () {
        final config = AsyncOperationConfig.getRetryConfigForOperation('unknown');
        expect(config, equals(AsyncOperationConfig.defaultRetryConfig));
      });
    });

    group('shouldCheckConnectivity', () {
      test('should return true for fetch operations', () {
        expect(AsyncOperationConfig.shouldCheckConnectivity('fetch'), isTrue);
      });

      test('should return true for upload operations', () {
        expect(AsyncOperationConfig.shouldCheckConnectivity('upload'), isTrue);
      });

      test('should return true for payment operations', () {
        expect(AsyncOperationConfig.shouldCheckConnectivity('payment'), isTrue);
      });

      test('should return false for unknown operations', () {
        expect(AsyncOperationConfig.shouldCheckConnectivity('unknown'), isFalse);
      });
    });

    group('shouldQueueIfOffline', () {
      test('should return true for payment operations', () {
        expect(AsyncOperationConfig.shouldQueueIfOffline('payment'), isTrue);
      });

      test('should return true for create operations', () {
        expect(AsyncOperationConfig.shouldQueueIfOffline('create'), isTrue);
      });

      test('should return false for fetch operations', () {
        expect(AsyncOperationConfig.shouldQueueIfOffline('fetch'), isFalse);
      });

      test('should return false for unknown operations', () {
        expect(AsyncOperationConfig.shouldQueueIfOffline('unknown'), isFalse);
      });
    });

    group('calculateFileTransferTimeout', () {
      test('should calculate timeout based on file size', () {
        final timeout = AsyncOperationConfig.calculateFileTransferTimeout(
          fileSizeInBytes: 10 * 1024 * 1024, // 10 MB
          speedInBytesPerSecond: 1024 * 1024, // 1 MB/s
        );
        expect(timeout.inSeconds, greaterThan(10));
      });

      test('should enforce minimum timeout', () {
        final timeout = AsyncOperationConfig.calculateFileTransferTimeout(
          fileSizeInBytes: 100, // Very small file
          speedInBytesPerSecond: 1024 * 1024,
          minimumTimeout: const Duration(seconds: 60),
        );
        expect(timeout.inSeconds, equals(60));
      });

      test('should apply buffer multiplier', () {
        final timeout = AsyncOperationConfig.calculateFileTransferTimeout(
          fileSizeInBytes: 5 * 1024 * 1024, // 5 MB
          speedInBytesPerSecond: 1024 * 1024, // 1 MB/s
          bufferMultiplier: 2.0,
        );
        // Should be approximately 10 seconds (5s * 2)
        expect(timeout.inSeconds, greaterThanOrEqualTo(10));
      });
    });

    group('getConfigSummary', () {
      test('should return summary map', () {
        final summary = AsyncOperationConfig.getConfigSummary();
        expect(summary, isA<Map<String, dynamic>>());
        expect(summary.containsKey('timeouts'), isTrue);
        expect(summary.containsKey('retry'), isTrue);
        expect(summary.containsKey('connectivity'), isTrue);
        expect(summary.containsKey('queue'), isTrue);
        expect(summary.containsKey('logging'), isTrue);
      });
    });

    group('printConfigSummary', () {
      test('should log config summary', () {
        final logger = MockFlyLogger();
        AsyncOperationConfig.printConfigSummary(logger);
        expect(logger.logMessages.length, greaterThan(0));
        expect(logger.logMessages.any((msg) => msg.contains('FlowGuardConfig')), isTrue);
      });
    });
  });
}

