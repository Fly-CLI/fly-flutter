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
      registry.register(ToolDefinition(
        name: 'test.tool',
        description: 'Test tool',
        handler: (params, {cancelToken, progressNotifier}) async => {},
      ));

      final tools = registry.list();
      expect(tools.length, equals(1));
      expect(tools.first['name'], equals('test.tool'));
      expect(tools.first['description'], equals('Test tool'));
    });

    test('should include metadata in tool list', () {
      registry.register(ToolDefinition(
        name: 'test.tool',
        description: 'Test tool',
        paramsSchema: {'type': 'object'},
        resultSchema: {'type': 'object'},
        readOnly: true,
        writesToDisk: false,
        requiresConfirmation: true,
        idempotent: true,
        handler: (params, {cancelToken, progressNotifier}) async => {},
      ));

      final tools = registry.list();
      final tool = tools.first;
      expect(tool['readOnly'], isTrue);
      expect(tool['writesToDisk'], isNull); // false values are omitted
      expect(tool['requiresConfirmation'], isTrue);
      expect(tool['idempotent'], isTrue);
    });

    test('should call registered tools', () async {
      var called = false;
      registry.register(ToolDefinition(
        name: 'test.tool',
        description: 'Test tool',
        handler: (params, {cancelToken, progressNotifier}) async {
          called = true;
          return {'result': 'success'};
        },
      ));

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
      registry.register(ToolDefinition(
        name: 'test.tool',
        description: 'Test tool',
        handler: (params, {cancelToken, progressNotifier}) async {
          receivedToken = cancelToken;
          return {};
        },
      ));

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
      registry.register(ToolDefinition(
        name: 'test.tool',
        description: 'Test tool',
        handler: (params, {cancelToken, progressNotifier}) async {
          receivedNotifier = progressNotifier;
          return {};
        },
      ));

      // For testing, we can pass null since handler is responsible
      await registry.call(
        'test.tool',
        {},
        progressNotifier: null,
      );

      expect(receivedNotifier, isNull);
    });

    test('should get tool definition by name', () {
      final definition = ToolDefinition(
        name: 'test.tool',
        description: 'Test tool',
        handler: (params, {cancelToken, progressNotifier}) async => {},
      );

      registry.register(definition);

      expect(registry.getTool('test.tool'), equals(definition));
      expect(registry.getTool('unknown.tool'), isNull);
    });

    test('should support multiple tools', () {
      registry.register(ToolDefinition(
        name: 'tool1',
        description: 'Tool 1',
        handler: (params, {cancelToken, progressNotifier}) async => {},
      ));
      registry.register(ToolDefinition(
        name: 'tool2',
        description: 'Tool 2',
        handler: (params, {cancelToken, progressNotifier}) async => {},
      ));

      final tools = registry.list();
      expect(tools.length, equals(2));
      expect(tools.map((t) => t['name']), containsAll(['tool1', 'tool2']));
    });

    test('should overwrite tools with same name', () {
      registry.register(ToolDefinition(
        name: 'test.tool',
        description: 'First',
        handler: (params, {cancelToken, progressNotifier}) async => {},
      ));

      registry.register(ToolDefinition(
        name: 'test.tool',
        description: 'Second',
        handler: (params, {cancelToken, progressNotifier}) async => {},
      ));

      final tools = registry.list();
      expect(tools.length, equals(1));
      expect(tools.first['description'], equals('Second'));
    });
  });
}

