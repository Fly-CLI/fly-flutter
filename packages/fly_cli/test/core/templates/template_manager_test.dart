import 'dart:io';

import 'package:fly_cli/src/core/templates/models/template_info.dart';
import 'package:fly_cli/src/core/templates/template_manager.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockLogger extends Mock implements Logger {}

void main() {
  group('TemplateManager', () {
    late TemplateManager templateManager;
    late MockLogger mockLogger;
    late Directory tempDir;

    setUp(() {
      mockLogger = MockLogger();
      tempDir = Directory.systemTemp.createTempSync('fly_test_');
      templateManager = TemplateManager(
        templatesDirectory: tempDir.path,
        logger: mockLogger,
      );
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    group('getAvailableTemplates', () {
      test('returns empty list when templates directory does not exist', () async {
        final templates = await templateManager.getAvailableTemplates();
        expect(templates, isEmpty);
      });

      test('returns templates when directory exists with valid templates', () async {
        // Create a mock template directory
        final templateDir = Directory('${tempDir.path}/minimal');
        templateDir.createSync();
        
        // Create __brick__ subdirectory
        final brickDir = Directory('${templateDir.path}/__brick__');
        brickDir.createSync();
        
        // Create template.yaml
        final templateYaml = File('${templateDir.path}/template.yaml');
        templateYaml.writeAsStringSync('''
name: minimal
version: 1.0.0
description: Minimal template
min_flutter_sdk: "3.10.0"
min_dart_sdk: "3.0.0"
variables: {}
features: []
packages: []
''');

        final templates = await templateManager.getAvailableTemplates();
        expect(templates, hasLength(1));
        expect(templates.first.name, 'minimal');
        expect(templates.first.version, '1.0.0');
        expect(templates.first.description, 'Minimal template');
      });

      test('skips directories without template.yaml', () async {
        // Create a directory without template.yaml
        final templateDir = Directory('${tempDir.path}/invalid');
        templateDir.createSync();

        final templates = await templateManager.getAvailableTemplates();
        expect(templates, isEmpty);
      });
    });

    group('getTemplate', () {
      test('returns null when template does not exist', () async {
        final template = await templateManager.getTemplate('nonexistent');
        expect(template, isNull);
      });

      test('returns template info when template exists', () async {
        // Create a mock template directory
        final templateDir = Directory('${tempDir.path}/minimal');
        templateDir.createSync();
        
        // Create __brick__ subdirectory
        final brickDir = Directory('${templateDir.path}/__brick__');
        brickDir.createSync();
        
        // Create template.yaml
        final templateYaml = File('${templateDir.path}/template.yaml');
        templateYaml.writeAsStringSync('''
name: minimal
version: 1.0.0
description: Minimal template
min_flutter_sdk: "3.10.0"
min_dart_sdk: "3.0.0"
variables: {}
features: []
packages: []
''');

        final template = await templateManager.getTemplate('minimal');
        expect(template, isNotNull);
        expect(template!.name, 'minimal');
        expect(template.version, '1.0.0');
      });
    });

    group('validateTemplate', () {
      test('returns failure when template does not exist', () async {
        final result = await templateManager.validateTemplate('nonexistent');
        expect(result.isValid, false);
        expect(result.issues, contains('Template "nonexistent" not found'));
      });

      test('returns validation issues for invalid template', () async {
        // Create a mock template directory
        final templateDir = Directory('${tempDir.path}/minimal');
        templateDir.createSync();
        
        // Create __brick__ subdirectory
        final brickDir = Directory('${templateDir.path}/__brick__');
        brickDir.createSync();
        
        // Create template.yaml with missing required fields
        final templateYaml = File('${templateDir.path}/template.yaml');
        templateYaml.writeAsStringSync('''
name: minimal
version: ""
description: ""
min_flutter_sdk: "3.10.0"
min_dart_sdk: "3.0.0"
variables: {}
features: []
packages: []
''');

        // Create a new template manager with the test directory
        final testTemplateManager = TemplateManager(
          templatesDirectory: tempDir.path,
          logger: mockLogger,
        );

        // Clear any cache to ensure we load from the test directory
        await testTemplateManager.clearTemplateCache();

        final result = await testTemplateManager.validateTemplate('minimal');
        expect(result.isValid, false);
        expect(result.issues, contains('Missing template description'));
        expect(result.issues, contains('Missing template version'));
      });
    });
  });

  group('TemplateVariables', () {
    test('converts to Mason variables correctly', () {
      const variables = TemplateVariables(
        projectName: 'My App',
        organization: 'com.example',
        platforms: ['ios', 'android'],
        description: 'A test app',
        features: ['routing', 'state_management'],
      );

      final masonVars = variables.toMasonVars();
      
      expect(masonVars['project_name'], 'My App');
      expect(masonVars['organization'], 'com.example');
      expect(masonVars['platforms'], ['ios', 'android']);
      expect(masonVars['description'], 'A test app');
      expect(masonVars['features'], ['routing', 'state_management']);
      expect(masonVars['project_name_snake'], 'my_app');
      expect(masonVars['project_name_camel'], 'myApp');
      expect(masonVars['project_name_pascal'], 'MyApp');
    });

    test('handles empty project name', () {
      const variables = TemplateVariables(
        projectName: '',
        organization: 'com.example',
        platforms: ['ios'],
      );

      final masonVars = variables.toMasonVars();
      
      expect(masonVars['project_name'], '');
      expect(masonVars['project_name_snake'], '');
      expect(masonVars['project_name_camel'], '');
      expect(masonVars['project_name_pascal'], '');
    });

    test('converts multi-word project names correctly', () {
      const variables = TemplateVariables(
        projectName: 'My Awesome App',
        organization: 'com.example',
        platforms: ['ios'],
      );

      final masonVars = variables.toMasonVars();
      
      expect(masonVars['project_name_snake'], 'my_awesome_app');
      expect(masonVars['project_name_camel'], 'myAwesomeApp');
      expect(masonVars['project_name_pascal'], 'MyAwesomeApp');
    });
  });

  group('TemplateInfo', () {
    test('parses YAML correctly', () {
      final yaml = <String, dynamic>{
        'name': 'test_template',
        'version': '2.0.0',
        'description': 'Test template',
        'min_flutter_sdk': '3.12.0',
        'min_dart_sdk': '3.1.0',
        'variables': {
          'project_name': {
            'type': 'string',
            'required': true,
            'description': 'Project name',
          },
          'organization': {
            'type': 'string',
            'required': false,
            'default': 'com.example',
          },
        },
        'features': ['routing', 'state_management'],
        'packages': ['flutter', 'riverpod'],
      };

      final templateInfo = TemplateInfo.fromYaml(yaml, '/path/to/template');
      
      expect(templateInfo.name, 'test_template');
      expect(templateInfo.version, '2.0.0');
      expect(templateInfo.description, 'Test template');
      expect(templateInfo.minFlutterSdk, '3.12.0');
      expect(templateInfo.minDartSdk, '3.1.0');
      expect(templateInfo.variables, hasLength(2));
      expect(templateInfo.features, ['routing', 'state_management']);
      expect(templateInfo.packages, ['flutter', 'riverpod']);
    });

    test('handles missing optional fields', () {
      final yaml = <String, dynamic>{
        'name': 'minimal_template',
        'variables': {},
        'features': [],
        'packages': [],
      };

      final templateInfo = TemplateInfo.fromYaml(yaml, '/path/to/template');
      
      expect(templateInfo.name, 'minimal_template');
      expect(templateInfo.version, '1.0.0'); // default
      expect(templateInfo.description, ''); // default
      expect(templateInfo.minFlutterSdk, '3.10.0'); // default
      expect(templateInfo.minDartSdk, '3.0.0'); // default
    });
  });
}
