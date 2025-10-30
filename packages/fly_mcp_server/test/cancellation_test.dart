import 'package:fly_mcp_server/src/cancellation.dart';
import 'package:test/test.dart';

void main() {
  group('CancellationToken', () {
    test('should start uncancelled', () {
      final token = CancellationToken();
      expect(token.isCancelled, isFalse);
    });

    test('should be cancellable', () {
      final token = CancellationToken();
      token.cancel();
      expect(token.isCancelled, isTrue);
    });

    test('should complete onCancel future when cancelled', () async {
      final token = CancellationToken();
      final future = token.onCancel;
      token.cancel();
      await expectLater(future, completes);
    });

    test('should throw CancellationException when checked after cancel', () {
      final token = CancellationToken();
      token.cancel();
      expect(() => token.throwIfCancelled(), throwsA(isA<CancellationException>()));
    });

    test('should not throw when checked before cancel', () {
      final token = CancellationToken();
      expect(() => token.throwIfCancelled(), returnsNormally);
    });

    test('should handle multiple cancel calls gracefully', () {
      final token = CancellationToken();
      token.cancel();
      token.cancel(); // Second call should not cause issues
      expect(token.isCancelled, isTrue);
    });
  });

  group('CancellationRegistry', () {
    test('should register tokens', () {
      final registry = CancellationRegistry();
      final token = CancellationToken();
      registry.register('request1', token);
      
      expect(registry.getToken('request1'), equals(token));
    });

    test('should cancel registered requests', () {
      final registry = CancellationRegistry();
      final token = CancellationToken();
      registry.register('request1', token);
      
      expect(token.isCancelled, isFalse);
      registry.cancel('request1');
      expect(token.isCancelled, isTrue);
    });

    test('should remove tokens after cancel', () {
      final registry = CancellationRegistry();
      final token = CancellationToken();
      registry.register('request1', token);
      registry.cancel('request1');
      
      expect(registry.getToken('request1'), isNull);
    });

    test('should remove tokens explicitly', () {
      final registry = CancellationRegistry();
      final token = CancellationToken();
      registry.register('request1', token);
      registry.remove('request1');
      
      expect(registry.getToken('request1'), isNull);
    });

    test('should handle non-existent request IDs gracefully', () {
      final registry = CancellationRegistry();
      expect(() => registry.cancel('nonexistent'), returnsNormally);
      expect(() => registry.remove('nonexistent'), returnsNormally);
    });

    test('should support multiple concurrent requests', () {
      final registry = CancellationRegistry();
      final token1 = CancellationToken();
      final token2 = CancellationToken();
      
      registry.register('request1', token1);
      registry.register('request2', token2);
      
      expect(registry.getToken('request1'), equals(token1));
      expect(registry.getToken('request2'), equals(token2));
      
      registry.cancel('request1');
      expect(token1.isCancelled, isTrue);
      expect(token2.isCancelled, isFalse);
    });
  });

  group('CancellationException', () {
    test('should have message', () {
      final exception = CancellationException('Test message');
      expect(exception.message, equals('Test message'));
      expect(exception.toString(), equals('Test message'));
    });
  });
}

