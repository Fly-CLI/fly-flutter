import 'dart:io';

import 'package:fly_cli/src/core/manifest/manifest_parser.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectManifest', () {
    group('fromYaml', () {
      test('should parse minimal manifest', () {
        final yaml = {
          'name': 'test_app',
          'template': 'minimal',
        };
        
        final manifest = ProjectManifest.fromYaml(yaml);
        
        expect(manifest.name, equals('test_app'));
        expect(manifest.template, equals('minimal'));
        expect(manifest.organization, equals('com.example'));
        expect(manifest.platforms, equals(['ios', 'android']));
        expect(manifest.screens, isEmpty);
        expect(manifest.services, isEmpty);
        expect(manifest.packages, isEmpty);
      });

      test('should parse complete manifest', () {
        final yaml = {
          'name': 'production_app',
          'template': 'riverpod',
          'organization': 'com.company',
          'description': 'Production-ready Flutter app',
          'platforms': ['ios', 'android', 'web'],
          'screens': [
            {
              'name': 'login',
              'type': 'auth',
              'features': ['validation', 'biometric_auth'],
            },
            {
              'name': 'home',
              'type': 'list',
              'features': ['pull_to_refresh'],
            },
          ],
          'services': [
            {
              'name': 'auth_service',
              'api_base': 'https://api.company.com',
              'type': 'api',
              'features': ['token_refresh'],
            },
          ],
          'packages': ['firebase_core', 'firebase_auth'],
          'config': {
            'min_sdk_version': 21,
            'target_sdk_version': 34,
            'ios_deployment_target': '12.0',
            'code_generation': {
              'generate_tests': true,
              'generate_docs': false,
            },
            'ai_integration': {
              'generate_context': true,
              'include_examples': false,
            },
          },
        };
        
        final manifest = ProjectManifest.fromYaml(yaml);
        
        expect(manifest.name, equals('production_app'));
        expect(manifest.template, equals('riverpod'));
        expect(manifest.organization, equals('com.company'));
        expect(manifest.description, equals('Production-ready Flutter app'));
        expect(manifest.platforms, equals(['ios', 'android', 'web']));
        expect(manifest.screens.length, equals(2));
        expect(manifest.services.length, equals(1));
        expect(manifest.packages, equals(['firebase_core', 'firebase_auth']));
        
        // Check screen configs
        final loginScreen = manifest.screens.first;
        expect(loginScreen.name, equals('login'));
        expect(loginScreen.type, equals('auth'));
        expect(loginScreen.features, equals(['validation', 'biometric_auth']));
        
        // Check service configs
        final authService = manifest.services.first;
        expect(authService.name, equals('auth_service'));
        expect(authService.apiBase, equals('https://api.company.com'));
        expect(authService.type, equals('api'));
        expect(authService.features, equals(['token_refresh']));
        
        // Check config
        expect(manifest.config.minSdkVersion, equals(21));
        expect(manifest.config.targetSdkVersion, equals(34));
        expect(manifest.config.iosDeploymentTarget, equals('12.0'));
        expect(manifest.config.generateTests, isTrue);
        expect(manifest.config.generateDocs, isFalse);
        expect(manifest.config.generateContext, isTrue);
        expect(manifest.config.includeExamples, isFalse);
      });

      test('should throw exception for missing name', () {
        final yaml = {
          'template': 'minimal',
        };
        
        expect(
          () => ProjectManifest.fromYaml(yaml),
          throwsA(isA<ManifestException>()),
        );
      });

      test('should throw exception for missing template', () {
        final yaml = {
          'name': 'test_app',
        };
        
        expect(
          () => ProjectManifest.fromYaml(yaml),
          throwsA(isA<ManifestException>()),
        );
      });

      test('should throw exception for invalid project name', () {
        final yaml = {
          'name': 'Invalid-Name',
          'template': 'minimal',
        };
        
        expect(
          () => ProjectManifest.fromYaml(yaml),
          throwsA(isA<ManifestException>()),
        );
      });

      test('should throw exception for invalid template', () {
        final yaml = {
          'name': 'test_app',
          'template': 'invalid_template',
        };
        
        expect(
          () => ProjectManifest.fromYaml(yaml),
          throwsA(isA<ManifestException>()),
        );
      });

      test('should throw exception for invalid platform', () {
        final yaml = {
          'name': 'test_app',
          'template': 'minimal',
          'platforms': ['ios', 'invalid_platform'],
        };
        
        expect(
          () => ProjectManifest.fromYaml(yaml),
          throwsA(isA<ManifestException>()),
        );
      });
    });

    group('toTemplateVariables', () {
      test('should convert to TemplateVariables', () {
        final manifest = ProjectManifest(
          name: 'test_app',
          template: 'riverpod',
          organization: 'com.test',
          description: 'Test app',
          platforms: ['ios', 'android', 'web'],
          screens: [
            ScreenConfig(
              name: 'login',
              type: 'auth',
              features: ['validation'],
            ),
          ],
          services: [
            ServiceConfig(
              name: 'api_service',
              type: 'api',
              features: ['caching'],
            ),
          ],
        );
        
        final variables = manifest.toTemplateVariables();
        
        expect(variables.projectName, equals('test_app'));
        expect(variables.organization, equals('com.test'));
        expect(variables.platforms, equals(['ios', 'android', 'web']));
        expect(variables.description, equals('Test app'));
        expect(variables.features, contains('validation'));
        expect(variables.features, contains('caching'));
      });
    });

    group('fromFile', () {
      late Directory tempDir;
      late File manifestFile;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('fly_test_');
        manifestFile = File('${tempDir.path}/test_manifest.yaml');
      });

      tearDown(() {
        tempDir.deleteSync(recursive: true);
      });

      test('should parse manifest from file', () async {
        await manifestFile.writeAsString('''
name: test_app
template: minimal
organization: com.test
platforms: [ios, android]
''');
        
        final manifest = await ProjectManifest.fromFile(manifestFile.path);
        
        expect(manifest.name, equals('test_app'));
        expect(manifest.template, equals('minimal'));
        expect(manifest.organization, equals('com.test'));
      });

      test('should throw exception for non-existent file', () async {
        expect(
          () => ProjectManifest.fromFile('non_existent.yaml'),
          throwsA(isA<ManifestException>()),
        );
      });

      test('should throw exception for invalid YAML', () async {
        await manifestFile.writeAsString('invalid: yaml: content: [');
        
        expect(
          () => ProjectManifest.fromFile(manifestFile.path),
          throwsA(isA<ManifestException>()),
        );
      });
    });
  });

  group('ScreenConfig', () {
    test('should parse screen config from YAML', () {
      final yaml = {
        'name': 'login',
        'type': 'auth',
        'features': ['validation', 'biometric_auth'],
      };
      
      final screen = ScreenConfig.fromYaml(yaml);
      
      expect(screen.name, equals('login'));
      expect(screen.type, equals('auth'));
      expect(screen.features, equals(['validation', 'biometric_auth']));
    });

    test('should parse screen config with minimal fields', () {
      final yaml = {
        'name': 'home',
      };
      
      final screen = ScreenConfig.fromYaml(yaml);
      
      expect(screen.name, equals('home'));
      expect(screen.type, isNull);
      expect(screen.features, isEmpty);
    });

    test('should throw exception for missing name', () {
      final yaml = {
        'type': 'auth',
      };
      
      expect(
        () => ScreenConfig.fromYaml(yaml),
        throwsA(isA<ManifestException>()),
      );
    });

    test('should throw exception for invalid name', () {
      final yaml = {
        'name': 'Invalid-Name',
      };
      
      expect(
        () => ScreenConfig.fromYaml(yaml),
        throwsA(isA<ManifestException>()),
      );
    });
  });

  group('ServiceConfig', () {
    test('should parse service config from YAML', () {
      final yaml = {
        'name': 'auth_service',
        'api_base': 'https://api.example.com',
        'type': 'api',
        'features': ['token_refresh', 'offline_support'],
      };
      
      final service = ServiceConfig.fromYaml(yaml);
      
      expect(service.name, equals('auth_service'));
      expect(service.apiBase, equals('https://api.example.com'));
      expect(service.type, equals('api'));
      expect(service.features, equals(['token_refresh', 'offline_support']));
    });

    test('should parse service config with minimal fields', () {
      final yaml = {
        'name': 'local_service',
      };
      
      final service = ServiceConfig.fromYaml(yaml);
      
      expect(service.name, equals('local_service'));
      expect(service.apiBase, isNull);
      expect(service.type, isNull);
      expect(service.features, isEmpty);
    });

    test('should throw exception for missing name', () {
      final yaml = {
        'type': 'api',
      };
      
      expect(
        () => ServiceConfig.fromYaml(yaml),
        throwsA(isA<ManifestException>()),
      );
    });
  });

  group('ManifestConfig', () {
    test('should parse config from YAML', () {
      final yaml = {
        'min_sdk_version': 21,
        'target_sdk_version': 34,
        'ios_deployment_target': '12.0',
        'code_generation': {
          'generate_tests': true,
          'generate_docs': false,
        },
        'ai_integration': {
          'generate_context': true,
          'include_examples': false,
        },
      };
      
      final config = ManifestConfig.fromYaml(yaml);
      
      expect(config.minSdkVersion, equals(21));
      expect(config.targetSdkVersion, equals(34));
      expect(config.iosDeploymentTarget, equals('12.0'));
      expect(config.generateTests, isTrue);
      expect(config.generateDocs, isFalse);
      expect(config.generateContext, isTrue);
      expect(config.includeExamples, isFalse);
    });

    test('should use defaults for null config', () {
      final config = ManifestConfig.fromYaml(null);
      
      expect(config.minSdkVersion, isNull);
      expect(config.targetSdkVersion, isNull);
      expect(config.iosDeploymentTarget, isNull);
      expect(config.generateTests, isTrue);
      expect(config.generateDocs, isFalse);
      expect(config.generateContext, isTrue);
      expect(config.includeExamples, isFalse);
    });

    test('should use defaults for empty config', () {
      final config = ManifestConfig.fromYaml({});
      
      expect(config.minSdkVersion, isNull);
      expect(config.targetSdkVersion, isNull);
      expect(config.iosDeploymentTarget, isNull);
      expect(config.generateTests, isTrue);
      expect(config.generateDocs, isFalse);
      expect(config.generateContext, isTrue);
      expect(config.includeExamples, isFalse);
    });
  });

  group('ManifestException', () {
    test('should create exception with message', () {
      final exception = ManifestException('Test error');
      expect(exception.message, equals('Test error'));
      expect(exception.toString(), equals('ManifestException: Test error'));
    });
  });
}
