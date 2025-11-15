import 'package:fly_cli/src/core/templates/generation_variable_validator.dart';
import 'package:test/test.dart';

void main() {
  group('GenerationVariableValidator', () {
    test('returns no errors for valid project variables', () {
      final errors = GenerationVariableValidator.validate({
        'generation_mode': 'project',
        'project_name': 'sample_app',
        'organization': 'com.example.app',
        'platforms': ['ios', 'android'],
      });

      expect(errors, isEmpty);
    });

    test('reports invalid project name', () {
      final errors = GenerationVariableValidator.validate({
        'generation_mode': 'project',
        'project_name': 'SampleApp',
        'organization': 'com.example.app',
        'platforms': ['ios'],
      });

      expect(errors, contains(contains('project_name')));
    });

    test('reports missing platforms', () {
      final errors = GenerationVariableValidator.validate({
        'generation_mode': 'project',
        'project_name': 'sample_app',
        'organization': 'com.example.app',
      });

      expect(errors, contains(contains('platforms')));
    });

    test('reports unsupported generation mode', () {
      final errors = GenerationVariableValidator.validate({
        'generation_mode': 'screen',
        'component_name': 'home',
      });

      expect(errors.length, 1);
      expect(errors.first, contains('not yet implemented'));
    });
  });
}
