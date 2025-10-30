import 'package:fly_mcp_server/src/registries/prompt_registry.dart';
import 'package:test/test.dart';

void main() {
  group('PromptRegistry', () {
    late PromptRegistry registry;

    setUp(() {
      registry = PromptRegistry();
    });

    test('should list available prompts', () {
      final prompts = registry.list();
      
      expect(prompts, isA<List>());
      expect(prompts.length, greaterThan(0));
      
      // Should include scaffold page prompt
      final scaffoldPrompt = prompts.firstWhere(
        (p) => p['id'] == 'fly.scaffold.page',
      );
      expect(scaffoldPrompt, isNotNull);
      expect(scaffoldPrompt['title'], isNotNull);
    });

    test('should get prompt by ID', () {
      final result = registry.getPrompt({
        'id': 'fly.scaffold.page',
        'variables': {
          'name': 'HomePage',
          'stateManagement': 'riverpod',
        },
      });

      expect(result['id'], equals('fly.scaffold.page'));
      expect(result['text'], isNotNull);
      expect(result['text'], contains('HomePage'));
      expect(result['text'], contains('riverpod'));
    });

    test('should return variables needed when missing required fields', () {
      final result = registry.getPrompt({
        'id': 'fly.scaffold.page',
        'variables': {},
      });

      expect(result['id'], equals('fly.scaffold.page'));
      expect(result['variablesNeeded'], isNotNull);
      expect(result['variablesNeeded'], contains('name'));
    });

    test('should throw error for missing ID', () {
      expect(
        () => registry.getPrompt({}),
        throwsA(isA<StateError>()),
      );
    });

    test('should throw error for unknown prompt ID', () {
      expect(
        () => registry.getPrompt({'id': 'unknown.prompt'}),
        throwsA(isA<StateError>()),
      );
    });

    test('should handle empty name in variables', () {
      final result = registry.getPrompt({
        'id': 'fly.scaffold.page',
        'variables': {'name': ''},
      });

      expect(result['variablesNeeded'], isNotNull);
      expect(result['variablesNeeded'], contains('name'));
    });

    test('should use default state management when not provided', () {
      final result = registry.getPrompt({
        'id': 'fly.scaffold.page',
        'variables': {'name': 'TestPage'},
      });

      expect(result['text'], contains('riverpod')); // Default
    });
  });
}

