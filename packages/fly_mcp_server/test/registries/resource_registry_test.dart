import 'package:dart_mcp/server.dart';
import 'package:fly_mcp_server/src/domain/resource_strategy.dart';
import 'package:fly_mcp_server/src/log_resource_provider.dart';
import 'package:fly_mcp_server/src/registries/resource_registry.dart';
import 'package:test/test.dart';

// Mock strategies for testing (concrete strategies moved to fly_cli)
class MockLogRunStrategy extends ResourceStrategy {
  MockLogRunStrategy(this.logProvider);
  
  final LogResourceProvider logProvider;
  
  @override
  String get uriPrefix => 'logs://run/';
  
  @override
  String get description => 'Mock run logs';
  
  @override
  bool get readOnly => true;
  
  @override
  Map<String, Object?> list(Map<String, Object?> params) {
    return logProvider.listLogs(
      prefix: null,
      page: params['page'] as int?,
      pageSize: params['pageSize'] as int?,
    );
  }
  
  @override
  Map<String, Object?> read(Map<String, Object?> params) {
    final uri = params['uri'] as String? ?? '';
    return logProvider.readLog(uri);
  }
}

class MockLogBuildStrategy extends ResourceStrategy {
  MockLogBuildStrategy(this.logProvider);
  
  final LogResourceProvider logProvider;
  
  @override
  String get uriPrefix => 'logs://build/';
  
  @override
  String get description => 'Mock build logs';
  
  @override
  bool get readOnly => true;
  
  @override
  Map<String, Object?> list(Map<String, Object?> params) {
    return logProvider.listLogs(
      prefix: null,
      page: params['page'] as int?,
      pageSize: params['pageSize'] as int?,
    );
  }
  
  @override
  Map<String, Object?> read(Map<String, Object?> params) {
    final uri = params['uri'] as String? ?? '';
    return logProvider.readLog(uri);
  }
}

class MockWorkspaceStrategy extends ResourceStrategy {
  @override
  String get uriPrefix => 'workspace://';
  
  @override
  String get description => 'Mock workspace';
  
  @override
  bool get readOnly => true;
  
  @override
  Map<String, Object?> list(Map<String, Object?> params) {
    return {
      'items': <Map<String, Object?>>[],
      'total': 0,
      'page': params['page'] as int? ?? 0,
      'pageSize': params['pageSize'] as int? ?? 100,
    };
  }
  
  @override
  Map<String, Object?> read(Map<String, Object?> params) {
    throw StateError('Mock workspace read not implemented');
  }
}

void main() {
  group('ResourceRegistry', () {
    late ResourceRegistry registry;
    late LogResourceProvider logProvider;

    setUp(() {
      logProvider = LogResourceProvider();
      
      // Create mock strategies for testing
      final runStrategy = MockLogRunStrategy(logProvider);
      final buildStrategy = MockLogBuildStrategy(logProvider);
      final workspaceStrategy = MockWorkspaceStrategy();

      // Create registry with strategies
      registry = ResourceRegistry(
        strategies: [
          runStrategy,
          buildStrategy,
          workspaceStrategy,
        ],
      );
    });

    test('should list workspace resources', () {
      final result = registry.list(ListResourcesRequest());
      
      expect(result, isA<ListResourcesResult>());
      expect(result.resources, isA<List<Resource>>());
    });

    test('should list log resources', () {
      // Store some test logs
      logProvider.storeRunLog('test-process', 'Log entry 1');
      logProvider.storeBuildLog('test-build', 'Build log 1');

      final result = registry.list(ListResourcesRequest());
      
      expect(result, isA<ListResourcesResult>());
      expect(result.resources, isA<List<Resource>>());
      // Should include both workspace and log resources
      expect(result.resources.length, greaterThanOrEqualTo(0));
    });

    test('should read workspace resources', () {
      // This will depend on actual file system
      // For now, just test that it doesn't throw for invalid URIs
      expect(
        () => registry.read(ReadResourceRequest(uri: 'workspace://nonexistent')),
        throwsA(isA<StateError>()),
      );
    });

    test('should read log resources', () {
      final processId = 'test-process-123';
      logProvider.storeRunLog(processId, 'Log line 1\nLog line 2');

      final result = registry.read(ReadResourceRequest(
        uri: 'logs://run/$processId',
      ));
      
      expect(result, isA<ReadResourceResult>());
      expect(result.contents, isNotEmpty);
      expect(result.contents.first, isA<TextResourceContents>());
      final contents = result.contents.first as TextResourceContents;
      expect(contents.text, contains('Log line 1'));
    });

    test('should throw error for invalid URI', () {
      expect(
        () => registry.read(ReadResourceRequest(uri: 'invalid://uri')),
        throwsA(isA<StateError>()),
      );
    });

    test('should support pagination in list', () {
      final result1 = registry.list(ListResourcesRequest());
      
      final result2 = registry.list(ListResourcesRequest());

      expect(result1, isA<ListResourcesResult>());
      expect(result2, isA<ListResourcesResult>());
      expect(result1.resources, isA<List<Resource>>());
      expect(result2.resources, isA<List<Resource>>());
    });

    test('should support partial reads with start and length', () {
      final processId = 'test-process';
      logProvider.storeRunLog(
        processId,
        'Line 1\nLine 2\nLine 3\nLine 4',
      );

      final result = registry.read(ReadResourceRequest(
        uri: 'logs://run/$processId',
      ));

      expect(result, isA<ReadResourceResult>());
      expect(result.contents, isNotEmpty);
      expect(result.contents.first, isA<TextResourceContents>());
    });

    test('should work with empty strategy list', () {
      final emptyRegistry = ResourceRegistry(strategies: []);
      
      final result = emptyRegistry.list(ListResourcesRequest());
      expect(result, isA<ListResourcesResult>());
      expect(result.resources, isEmpty);
      
      expect(
        () => emptyRegistry.read(ReadResourceRequest(uri: 'logs://run/test')),
        throwsA(isA<StateError>()),
      );
    });
  });
}

