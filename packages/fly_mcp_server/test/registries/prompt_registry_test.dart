import 'package:dart_mcp/server.dart';
import 'package:fly_mcp_server/src/domain/prompt_strategy.dart';
import 'package:fly_mcp_server/src/domain/prompt_strategy_registry_provider.dart';
import 'package:fly_mcp_server/src/domain/prompt_type.dart';
import 'package:fly_mcp_server/src/registries/prompt_registry.dart';
import 'package:test/test.dart';

/// Mock prompt strategy for testing
class MockScaffoldPagePromptStrategy extends PromptStrategy {
  @override
  String get id => 'fly.scaffold.page';

  @override
  String get title => 'Scaffold a Flutter page';

  @override
  String get description => 'Generate a new Flutter page (widget + route) with Fly conventions';

  @override
  List<PromptArgument> getVariables() {
    return [
      PromptArgument(
        name: 'name',
        description: 'The name of the page to scaffold',
        required: true,
      ),
      PromptArgument(
        name: 'stateManagement',
        description: 'State management approach (default: riverpod)',
        required: false,
      ),
    ];
  }

  @override
  Future<GetPromptResult> getPrompt(Map<String, Object?> params) async {
    final argumentsValue = params['arguments'] ?? params['variables'];
    Map<String, Object?>? arguments;
    if (argumentsValue is Map) {
      arguments = Map<String, Object?>.from(argumentsValue);
    }
    final name = arguments?['name'] as String?;
    if (name == null || name.isEmpty) {
      throw StateError('Missing required parameter: name');
    }
    final state = (arguments?['stateManagement'] as String?) ?? 'riverpod';
    final template = 'Create a Flutter page named "$name" using $state. Include a widget, route, and basic tests.';
    
    return GetPromptResult(
      messages: [
        PromptMessage(
          role: Role.user,
          content: TextContent(text: template),
        ),
      ],
    );
  }
}

/// Mock registry provider for testing
class MockPromptStrategyRegistryProvider implements PromptStrategyRegistryProvider {
  final Map<PromptType, PromptStrategy> _strategies = {
    PromptType.scaffoldPage: MockScaffoldPagePromptStrategy(),
  };

  @override
  PromptStrategy getStrategy(PromptType promptType) {
    final strategy = _strategies[promptType];
    if (strategy == null) {
      throw StateError('Unknown prompt type: $promptType');
    }
    return strategy;
  }
}

void main() {
  group('PromptRegistry', () {
    late PromptRegistry registry;

    setUp(() {
      // Initialize the registry provider with mock strategies
      setPromptStrategyRegistryProvider(MockPromptStrategyRegistryProvider());
      registry = PromptRegistry();
    });

    test('should list available prompts', () {
      final prompts = registry.list();
      
      expect(prompts, isA<List<Prompt>>());
      expect(prompts.length, greaterThan(0));
      
      // Should include scaffold page prompt
      final scaffoldPrompt = prompts.firstWhere(
        (p) => p.name == 'fly.scaffold.page',
      );
      expect(scaffoldPrompt, isNotNull);
      expect(scaffoldPrompt.title, isNotNull);
      expect(scaffoldPrompt.description, isNotNull);
      expect(scaffoldPrompt.arguments, isNotNull);
      expect(scaffoldPrompt.arguments!.length, greaterThan(0));
    });

    test('should get prompt by ID', () async {
      final result = await registry.getPrompt({
        'id': 'fly.scaffold.page',
        'variables': {
          'name': 'HomePage',
          'stateManagement': 'riverpod',
        },
      });

      expect(result, isA<GetPromptResult>());
      expect(result.messages, isNotEmpty);
      expect(result.messages.length, equals(1));
      
      final message = result.messages.first;
      expect(message.role, equals(Role.user));
      expect(message.content.isText, isTrue);
      
      final textContent = message.content as TextContent;
      expect(textContent.text, contains('HomePage'));
      expect(textContent.text, contains('riverpod'));
    });

    test('should throw error when missing required fields', () async {
      expect(
        () => registry.getPrompt({
          'id': 'fly.scaffold.page',
          'variables': {},
        }),
        throwsA(isA<StateError>()),
      );
    });

    test('should throw error for missing ID', () async {
      expect(
        () => registry.getPrompt({}),
        throwsA(isA<StateError>()),
      );
    });

    test('should throw error for unknown prompt ID', () async {
      expect(
        () => registry.getPrompt({'id': 'unknown.prompt'}),
        throwsA(isA<StateError>()),
      );
    });

    test('should throw error for empty name in variables', () async {
      expect(
        () => registry.getPrompt({
          'id': 'fly.scaffold.page',
          'variables': {'name': ''},
        }),
        throwsA(isA<StateError>()),
      );
    });

    test('should use default state management when not provided', () async {
      final result = await registry.getPrompt({
        'id': 'fly.scaffold.page',
        'variables': {'name': 'TestPage'},
      });

      expect(result, isA<GetPromptResult>());
      expect(result.messages, isNotEmpty);
      
      final textContent = result.messages.first.content as TextContent;
      expect(textContent.text, contains('riverpod')); // Default
    });
  });
}

