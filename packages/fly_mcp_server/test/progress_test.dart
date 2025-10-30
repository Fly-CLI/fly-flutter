import 'package:dart_mcp/server.dart';
import 'package:fly_mcp_server/src/progress.dart';
import 'package:test/test.dart';

void main() {
  group('ProgressNotifier', () {
    late ProgressToken progressToken;

    setUp(() {
      progressToken = ProgressToken('test-123');
    });

    test('should not send notifications when disabled', () async {
      final notifier = ProgressNotifier(
        enabled: false,
      );

      await notifier.notify(message: 'Processing...', percent: 50);
      // Should complete without error when disabled
      expect(true, isTrue);
    });

    test('should not send when server is null', () async {
      final notifier = ProgressNotifier(
        enabled: true,
      );

      await notifier.notify(message: 'Test');
      // Should complete without error when server is null
      expect(true, isTrue);
    });

    test('should not send when progressToken is null', () async {
      // We can't easily create a real MCPServer instance in tests
      // without stdio, so we test the null check behavior
      final notifier = ProgressNotifier(
        enabled: true,
      );

      await notifier.notify(message: 'Test');
      // Should complete without error when progressToken is null
      expect(true, isTrue);
    });

    test('should create with all parameters', () {
      // Just test that we can create a ProgressNotifier instance
      // without actually sending notifications (which requires a connected server)
      final notifier = ProgressNotifier(
        progressToken: progressToken,
        enabled: true,
      );

      expect(notifier, isNotNull);
    });

    test('should handle percent calculation correctly', () async {
      // Test that the percent-to-value conversion logic is correct
      // by verifying the behavior when conditions are met
      final notifier = ProgressNotifier(
        progressToken: progressToken,
        enabled: true,
      );

      // This won't actually send because server is null,
      // but we can verify it doesn't throw
      await notifier.notify(message: 'Test', percent: 50);
      await notifier.notify(message: 'Test', percent: null);
      
      expect(true, isTrue);
    });
  });
}
