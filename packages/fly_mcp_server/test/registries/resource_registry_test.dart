import 'package:fly_mcp_server/src/log_resource_provider.dart';
import 'package:fly_mcp_server/src/registries/resource_registry.dart';
import 'package:test/test.dart';

void main() {
  group('ResourceRegistry', () {
    late ResourceRegistry registry;

    setUp(() {
      registry = ResourceRegistry();
    });

    test('should list workspace resources by default', () {
      final result = registry.list({'uri': 'workspace://'});
      
      expect(result, contains('items'));
      expect(result, contains('total'));
      expect(result['items'], isA<List>());
    });

    test('should list log resources', () {
      // Store some test logs
      registry.logProvider.storeRunLog('test-process', 'Log entry 1');
      registry.logProvider.storeBuildLog('test-build', 'Build log 1');

      final result = registry.list({'uri': 'logs://run/'});
      
      expect(result, contains('items'));
      expect(result['items'], isA<List>());
    });

    test('should read workspace resources', () {
      // This will depend on actual file system
      // For now, just test that it doesn't throw for invalid URIs
      expect(
        () => registry.read({'uri': 'workspace://nonexistent'}),
        throwsA(isA<StateError>()),
      );
    });

    test('should read log resources', () {
      final processId = 'test-process-123';
      registry.logProvider.storeRunLog(processId, 'Log line 1\nLog line 2');

      final result = registry.read({'uri': 'logs://run/$processId'});
      
      expect(result, contains('content'));
      expect(result['content'], contains('Log line 1'));
      expect(result['encoding'], equals('utf-8'));
    });

    test('should throw error for missing URI', () {
      expect(
        () => registry.read({}),
        throwsA(isA<StateError>()),
      );
    });

    test('should throw error for invalid URI', () {
      expect(
        () => registry.read({'uri': 'invalid://uri'}),
        throwsA(isA<StateError>()),
      );
    });

    test('should support pagination in list', () {
      final result1 = registry.list({
        'uri': 'logs://',
        'page': 0,
        'pageSize': 10,
      });
      
      final result2 = registry.list({
        'uri': 'logs://',
        'page': 1,
        'pageSize': 10,
      });

      expect(result1, contains('page'));
      expect(result2, contains('page'));
      expect(result1['page'], equals(0));
      expect(result2['page'], equals(1));
    });

    test('should support partial reads with start and length', () {
      final processId = 'test-process';
      registry.logProvider.storeRunLog(
        processId,
        'Line 1\nLine 2\nLine 3\nLine 4',
      );

      final result = registry.read({
        'uri': 'logs://run/$processId',
        'start': 5,
        'length': 10,
      });

      expect(result, contains('start'));
      expect(result, contains('length'));
      expect(result['start'], isA<int>());
      expect(result['length'], isA<int>());
    });

    test('should provide access to log provider', () {
      expect(registry.logProvider, isA<LogResourceProvider>());
      
      registry.logProvider.storeRunLog('test', 'entry');
      expect(
        () => registry.read({'uri': 'logs://run/test'}),
        returnsNormally,
      );
    });
  });
}

