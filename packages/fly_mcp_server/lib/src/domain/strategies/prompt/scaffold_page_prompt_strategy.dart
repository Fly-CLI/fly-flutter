import 'package:fly_mcp_server/src/domain/prompt_strategy.dart';

/// Strategy for the fly.scaffold.page prompt
class ScaffoldPagePromptStrategy extends PromptStrategy {
  @override
  String get id => 'fly.scaffold.page';

  @override
  String get title => 'Scaffold a Flutter page';

  @override
  String get description =>
      'Generate a new Flutter page (widget + route) with Fly conventions';

  @override
  List<Map<String, Object?>> getVariables() {
    return [
      {'name': 'name', 'type': 'string', 'required': true},
      {
        'name': 'stateManagement',
        'type': 'string',
        'required': false,
        'default': 'riverpod'
      },
    ];
  }

  @override
  Map<String, Object?> getPrompt(Map<String, Object?> params) {
    final id = params['id'] as String?;
    if (id != this.id) {
      throw StateError('Unknown prompt id');
    }
    final vars =
        (params['variables'] as Map?)?.cast<String, Object?>() ??
        <String, Object?>{};
    final name = vars['name'] as String?;
    if (name == null || name.isEmpty) {
      return {
        'id': id,
        'variablesNeeded': ['name'],
      };
    }
    final state = (vars['stateManagement'] as String?) ?? 'riverpod';
    final template =
        'Create a Flutter page named "$name" using $state. '
        'Include a widget, route, and basic tests.';
    return {
      'id': id,
      'text': template,
    };
  }
}

