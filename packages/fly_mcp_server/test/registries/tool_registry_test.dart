import 'package:dart_mcp/server.dart';
import 'package:fly_mcp_server/src/cancellation.dart';
import 'package:fly_mcp_server/src/progress.dart';
import 'package:fly_mcp_server/src/registries/tool_registry.dart';
import 'package:test/test.dart';

void main() {
  group('ToolRegistry', () {
    late ToolRegistry registry;

    setUp(() {
      registry = ToolRegistry();
    });

    test('should register and list tools', () {
      final tool = createTool(
        name: 'test.tool',
        description: 'Test tool',
      );
      Future<Map> handler(params, {cancelToken, progressNotifier}) async => {};
      registry.register(tool, handler);

      final tools = registry.list();
      expect(tools.length, equals(1));
      expect(tools.first.name, equals('test.tool'));
      expect(tools.first.description, equals('Test tool'));
    });

    test('should include metadata in tool list', () {
      final tool = createTool(
        name: 'test.tool',
        description: 'Test tool',
        inputSchema: ObjectSchema(),
        outputSchema: ObjectSchema(),
        readOnly: true,
        writesToDisk: false,
        requiresConfirmation: true,
        idempotent: true,
      );
      final handler = (params, {cancelToken, progressNotifier}) async => {};
      registry.register(tool, handler);

      final tools = registry.list();
      final toolResult = tools.first;
      expect(toolResult.toolAnnotations?.readOnlyHint, isTrue);
      expect(toolResult.toolAnnotations?.destructiveHint, isNull); // false values are omitted
      expect(toolResult.toolAnnotations?.idempotentHint, isTrue);
      expect(toolResult.inputSchema, isNotNull);
      expect(toolResult.outputSchema, isNotNull);
    });

    test('should call registered tools', () async {
      var called = false;
      final tool = createTool(
        name: 'test.tool',
        description: 'Test tool',
      );
      final handler = (params, {cancelToken, progressNotifier}) async {
        called = true;
        return {'result': 'success'};
      };
      registry.register(tool, handler);

      final result = await registry.call(
        'test.tool',
        {'param1': 'value1'},
      );

      expect(called, isTrue);
      expect(result, equals({'result': 'success'}));
    });

    test('should throw StateError for unknown tool', () async {
      expect(
        () => registry.call('unknown.tool', {}),
        throwsA(isA<StateError>()),
      );
    });

    test('should pass cancellation token to handler', () async {
      CancellationToken? receivedToken;
      final tool = createTool(
        name: 'test.tool',
        description: 'Test tool',
      );
      final handler = (
        Map<String, Object?> params, {
        CancellationToken? cancelToken,
        ProgressNotifier? progressNotifier,
      }) async {
        receivedToken = cancelToken;
        return {};
      };
      registry.register(tool, handler);

      final token = CancellationToken();
      await registry.call(
        'test.tool',
        {},
        cancelToken: token,
      );

      expect(receivedToken, equals(token));
    });

    test('should pass progress notifier to handler', () async {
      ProgressNotifier? receivedNotifier;
      final tool = createTool(
        name: 'test.tool',
        description: 'Test tool',
      );
      Future<Map> handler(
        Map<String, Object?> params, {
        CancellationToken? cancelToken,
        ProgressNotifier? progressNotifier,
      }) async {
        receivedNotifier = progressNotifier;
        return {};
      }
      registry.register(tool, handler);

      // For testing, we can pass null since handler is responsible
      await registry.call(
        'test.tool',
        {},
        progressNotifier: null,
      );

      expect(receivedNotifier, isNull);
    });

    test('should get tool by name', () {
      final tool = createTool(
        name: 'test.tool',
        description: 'Test tool',
      );
      final handler = (params, {cancelToken, progressNotifier}) async => {};
      registry.register(tool, handler);

      expect(registry.getTool('test.tool'), equals(tool));
      expect(registry.getTool('unknown.tool'), isNull);
    });

    test('should support multiple tools', () {
      final tool1 = createTool(
        name: 'tool1',
        description: 'Tool 1',
      );
      final tool2 = createTool(
        name: 'tool2',
        description: 'Tool 2',
      );
      final handler = (params, {cancelToken, progressNotifier}) async => {};
      registry.register(tool1, handler);
      registry.register(tool2, handler);

      final tools = registry.list();
      expect(tools.length, equals(2));
      expect(tools.map((t) => t.name), containsAll(['tool1', 'tool2']));
    });

    test('should overwrite tools with same name', () {
      final tool1 = createTool(
        name: 'test.tool',
        description: 'First',
      );
      final tool2 = createTool(
        name: 'test.tool',
        description: 'Second',
      );
      final handler = (params, {cancelToken, progressNotifier}) async => {};
      registry.register(tool1, handler);
      registry.register(tool2, handler);

      final tools = registry.list();
      expect(tools.length, equals(1));
      expect(tools.first.description, equals('Second'));
    });
  });
}

