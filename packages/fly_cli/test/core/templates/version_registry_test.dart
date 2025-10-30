import 'dart:io';

import 'package:fly_cli/src/core/templates/template_info.dart';
import 'package:fly_cli/src/core/templates/version_registry.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../../../../helpers/mock_logger.dart';

void main() {
  group('VersionRegistry', () {
    late Directory tempDir;
    late MockLogger logger;
    late VersionRegistry registry;
    late Directory templatesDir;

    Future<TemplateInfo?> loadTemplateInfo(String templatePath) async {
      final templateYamlPath = path.join(templatePath, 'template.yaml');
      final templateYamlFile = File(templateYamlPath);

      if (!await templateYamlFile.exists()) {
        return null;
      }

      try {
        final yamlContent = await templateYamlFile.readAsString();
        final yaml = loadYaml(yamlContent) as Map<dynamic, dynamic>;

        return TemplateInfo.fromYaml(yaml, templatePath);
      } catch (_) {
        return null;
      }
    }

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fly_test_');
      templatesDir = Directory(path.join(tempDir.path, 'templates'));
      templatesDir.createSync(recursive: true);
      logger = MockLogger();

      registry = VersionRegistry(
        templatesDirectory: templatesDir.path,
        logger: logger,
        loadTemplateInfo: loadTemplateInfo,
      );
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
      logger.clear();
    });

    group('getVersions', () {
      test(
        'should return version from template.yaml for single version',
        () async {
          // Create single version template
          final templateDir = Directory(
            path.join(templatesDir.path, 'test_template'),
          );
          templateDir.createSync();

          final templateYaml = File(
            path.join(templateDir.path, 'template.yaml'),
          );
          await templateYaml.writeAsString('''
name: test_template
version: 1.0.0
description: Test template
variables: {}
features: []
packages: []
min_flutter_sdk: 3.10.0
min_dart_sdk: 3.0.0
''');

          final versions = await registry.getVersions('test_template');

          expect(versions, contains('1.0.0'));
          expect(versions.length, equals(1));
        },
      );

      test('should return versions from versions.yaml', () async {
        final templateDir = Directory(
          path.join(templatesDir.path, 'test_template'),
        );
        templateDir.createSync();

        final versionsYaml = File(path.join(templateDir.path, 'versions.yaml'));
        await versionsYaml.writeAsString('''
versions:
  - "2.1.0"
  - "2.0.0"
  - "1.9.0"
''');

        final versions = await registry.getVersions('test_template');

        expect(versions, containsAll(['2.1.0', '2.0.0', '1.9.0']));
        // Should be sorted (latest first)
        expect(versions.first, equals('2.1.0'));
      });

      test('should return versions from versioned directories', () async {
        final templateDir = Directory(
          path.join(templatesDir.path, 'test_template'),
        );
        templateDir.createSync();

        // Create versioned directories
        Directory(path.join(templateDir.path, '2.0.0')).createSync();
        Directory(path.join(templateDir.path, '2.1.0')).createSync();
        Directory(path.join(templateDir.path, '1.9.0')).createSync();
        Directory(
          path.join(templateDir.path, 'not_a_version'),
        ).createSync(); // Should be skipped

        final versions = await registry.getVersions('test_template');

        expect(versions, containsAll(['2.1.0', '2.0.0', '1.9.0']));
        expect(versions, isNot(contains('not_a_version')));
        // Should be sorted (latest first)
        expect(versions.first, equals('2.1.0'));
      });

      test('should deduplicate versions from multiple sources', () async {
        final templateDir = Directory(
          path.join(templatesDir.path, 'test_template'),
        );
        templateDir.createSync();

        // Create versions.yaml
        final versionsYaml = File(path.join(templateDir.path, 'versions.yaml'));
        await versionsYaml.writeAsString('''
versions:
  - "2.0.0"
''');

        // Create versioned directory with same version
        Directory(path.join(templateDir.path, '2.0.0')).createSync();

        final versions = await registry.getVersions('test_template');

        // Should deduplicate
        expect(versions.where((v) => v == '2.0.0').length, equals(1));
      });

      test('should filter invalid versions from versions.yaml', () async {
        final templateDir = Directory(
          path.join(templatesDir.path, 'test_template'),
        );
        templateDir.createSync();

        final versionsYaml = File(path.join(templateDir.path, 'versions.yaml'));
        await versionsYaml.writeAsString('''
versions:
  - "2.0.0"
  - "invalid"
  - "1.0.0"
''');

        final versions = await registry.getVersions('test_template');

        expect(versions, containsAll(['2.0.0', '1.0.0']));
        expect(versions, isNot(contains('invalid')));
        expect(
          logger.warningMessages.any(
            (m) => m.contains('Invalid version format'),
          ),
          isTrue,
        );
      });

      test('should sanitize template name to prevent path traversal', () async {
        // The sanitization removes '..' and path separators, so '../test' becomes 'test'
        // We should check that the sanitized name is used, not that it throws
        final templateDir = Directory(path.join(templatesDir.path, 'test'));
        templateDir.createSync();

        final templateYaml = File(path.join(templateDir.path, 'template.yaml'));
        await templateYaml.writeAsString('''
name: test
version: 1.0.0
description: Test template
variables: {}
features: []
packages: []
min_flutter_sdk: 3.10.0
min_dart_sdk: 3.0.0
''');

        // Should work even with path traversal attempt (sanitized to 'test')
        final versions = await registry.getVersions('../test');
        expect(versions, contains('1.0.0'));

        // Should log a warning about sanitization
        expect(
          logger.warningMessages.any((m) => m.contains('sanitized')),
          isTrue,
        );
      });

      test('should throw ArgumentError for empty template name', () async {
        expect(() => registry.getVersions(''), throwsA(isA<ArgumentError>()));
      });

      test('should use cache for subsequent calls', () async {
        final templateDir = Directory(
          path.join(templatesDir.path, 'test_template'),
        );
        templateDir.createSync();

        final templateYaml = File(path.join(templateDir.path, 'template.yaml'));
        await templateYaml.writeAsString('''
name: test_template
version: 1.0.0
description: Test template
variables: {}
features: []
packages: []
min_flutter_sdk: 3.10.0
min_dart_sdk: 3.0.0
''');

        final versions1 = await registry.getVersions('test_template');
        final versions2 = await registry.getVersions('test_template');

        expect(versions1, equals(versions2));
      });

      test('should handle missing template gracefully', () async {
        final versions = await registry.getVersions('nonexistent');
        expect(versions, isEmpty);
      });
    });

    group('getTemplateVersion', () {
      test('should return template from versioned directory', () async {
        final templateDir = Directory(
          path.join(templatesDir.path, 'test_template'),
        );
        templateDir.createSync();

        final versionDir = Directory(
          path.join(templateDir.path, 'versions', '2.0.0'),
        );
        versionDir.createSync(recursive: true);

        final templateYaml = File(path.join(versionDir.path, 'template.yaml'));
        await templateYaml.writeAsString('''
name: test_template
version: 2.0.0
description: Test template
variables: {}
features: []
packages: []
min_flutter_sdk: 3.10.0
min_dart_sdk: 3.0.0
''');

        final template = await registry.getTemplateVersion(
          'test_template',
          '2.0.0',
        );

        expect(template, isNotNull);
        expect(template?.version, equals('2.0.0'));
      });

      test('should return template from name@version directory', () async {
        final templateVersionDir = Directory(
          path.join(templatesDir.path, 'test_template@2.0.0'),
        );
        templateVersionDir.createSync();

        final templateYaml = File(
          path.join(templateVersionDir.path, 'template.yaml'),
        );
        await templateYaml.writeAsString('''
name: test_template
version: 2.0.0
description: Test template
variables: {}
features: []
packages: []
min_flutter_sdk: 3.10.0
min_dart_sdk: 3.0.0
''');

        final template = await registry.getTemplateVersion(
          'test_template',
          '2.0.0',
        );

        expect(template, isNotNull);
        expect(template?.version, equals('2.0.0'));
      });

      test('should return null for invalid version format', () async {
        final template = await registry.getTemplateVersion(
          'test_template',
          'invalid',
        );
        expect(template, isNull);
        expect(
          logger.warningMessages.any(
            (m) => m.contains('Invalid version format'),
          ),
          isTrue,
        );
      });

      test('should sanitize template name', () async {
        final templateDir = Directory(path.join(templatesDir.path, 'test'));
        templateDir.createSync();

        final templateYaml = File(path.join(templateDir.path, 'template.yaml'));
        await templateYaml.writeAsString('''
name: test
version: 1.0.0
description: Test template
variables: {}
features: []
packages: []
min_flutter_sdk: 3.10.0
min_dart_sdk: 3.0.0
''');

        // Should work even with path traversal attempt (sanitized to 'test')
        final template = await registry.getTemplateVersion('../test', '1.0.0');
        expect(template, isNotNull);
        expect(template?.version, equals('1.0.0'));

        // Should log a warning about sanitization
        expect(
          logger.warningMessages.any((m) => m.contains('sanitized')),
          isTrue,
        );
      });
    });

    group('getLatestVersion', () {
      test('should return latest version', () async {
        final templateDir = Directory(
          path.join(templatesDir.path, 'test_template'),
        );
        templateDir.createSync();

        final versionsYaml = File(path.join(templateDir.path, 'versions.yaml'));
        await versionsYaml.writeAsString('''
versions:
  - "1.0.0"
  - "2.1.0"
  - "2.0.0"
''');

        final latest = await registry.getLatestVersion('test_template');

        expect(latest, equals('2.1.0'));
      });

      test('should return null when no versions exist', () async {
        final latest = await registry.getLatestVersion('nonexistent');
        expect(latest, isNull);
      });
    });

    group('getVersionsInRange', () {
      test('should return versions within range', () async {
        final templateDir = Directory(
          path.join(templatesDir.path, 'test_template'),
        );
        templateDir.createSync();

        final versionsYaml = File(path.join(templateDir.path, 'versions.yaml'));
        await versionsYaml.writeAsString('''
versions:
  - "1.0.0"
  - "2.0.0"
  - "2.1.0"
  - "3.0.0"
''');

        final versions = await registry.getVersionsInRange(
          'test_template',
          '^2.0.0',
        );

        expect(versions, containsAll(['2.0.0', '2.1.0']));
        expect(versions, isNot(contains('1.0.0')));
        expect(versions, isNot(contains('3.0.0')));
      });

      test('should return empty list for invalid constraint', () async {
        final versions = await registry.getVersionsInRange(
          'test_template',
          'invalid',
        );
        expect(versions, isEmpty);
      });
    });

    group('getNextVersion', () {
      test('should return next version', () async {
        final templateDir = Directory(
          path.join(templatesDir.path, 'test_template'),
        );
        templateDir.createSync();

        final versionsYaml = File(path.join(templateDir.path, 'versions.yaml'));
        await versionsYaml.writeAsString('''
versions:
  - "1.0.0"
  - "2.0.0"
  - "2.1.0"
''');

        final next = await registry.getNextVersion('test_template', '1.0.0');

        expect(next, equals('2.1.0')); // Latest version > 1.0.0
      });

      test('should return null when no next version exists', () async {
        final templateDir = Directory(
          path.join(templatesDir.path, 'test_template'),
        );
        templateDir.createSync();

        final versionsYaml = File(path.join(templateDir.path, 'versions.yaml'));
        await versionsYaml.writeAsString('''
versions:
  - "1.0.0"
''');

        final next = await registry.getNextVersion('test_template', '2.0.0');
        expect(next, isNull);
      });
    });

    group('getPreviousVersion', () {
      test('should return previous version', () async {
        final templateDir = Directory(
          path.join(templatesDir.path, 'test_template'),
        );
        templateDir.createSync();

        final versionsYaml = File(path.join(templateDir.path, 'versions.yaml'));
        await versionsYaml.writeAsString('''
versions:
  - "1.0.0"
  - "2.0.0"
  - "2.1.0"
''');

        final previous = await registry.getPreviousVersion(
          'test_template',
          '2.1.0',
        );

        expect(previous, equals('2.0.0'));
      });

      test('should return null when no previous version exists', () async {
        final templateDir = Directory(
          path.join(templatesDir.path, 'test_template'),
        );
        templateDir.createSync();

        final versionsYaml = File(path.join(templateDir.path, 'versions.yaml'));
        await versionsYaml.writeAsString('''
versions:
  - "1.0.0"
''');

        final previous = await registry.getPreviousVersion(
          'test_template',
          '1.0.0',
        );
        expect(previous, isNull);
      });
    });

    group('versionExists', () {
      test('should return true when version exists', () async {
        final templateDir = Directory(
          path.join(templatesDir.path, 'test_template'),
        );
        templateDir.createSync();

        final versionsYaml = File(path.join(templateDir.path, 'versions.yaml'));
        await versionsYaml.writeAsString('''
versions:
  - "1.0.0"
''');

        final exists = await registry.versionExists('test_template', '1.0.0');
        expect(exists, isTrue);
      });

      test('should return false when version does not exist', () async {
        final exists = await registry.versionExists('test_template', '999.0.0');
        expect(exists, isFalse);
      });
    });

    group('cache management', () {
      test('should clear cache', () async {
        final templateDir = Directory(
          path.join(templatesDir.path, 'test_template'),
        );
        templateDir.createSync();

        final templateYaml = File(path.join(templateDir.path, 'template.yaml'));
        await templateYaml.writeAsString('''
name: test_template
version: 1.0.0
description: Test template
variables: {}
features: []
packages: []
min_flutter_sdk: 3.10.0
min_dart_sdk: 3.0.0
''');

        await registry.getVersions('test_template');
        registry.clearCache();

        // Cache should be cleared
        final versions = await registry.getVersions('test_template');
        expect(versions, isNotEmpty);
      });

      test('should clear cache for specific template', () async {
        final templateDir = Directory(
          path.join(templatesDir.path, 'test_template'),
        );
        templateDir.createSync();

        final templateYaml = File(path.join(templateDir.path, 'template.yaml'));
        await templateYaml.writeAsString('''
name: test_template
version: 1.0.0
description: Test template
variables: {}
features: []
packages: []
min_flutter_sdk: 3.10.0
min_dart_sdk: 3.0.0
''');

        await registry.getVersions('test_template');
        registry.clearCacheForTemplate('test_template');

        // Should work after clearing
        final versions = await registry.getVersions('test_template');
        expect(versions, isNotEmpty);
      });
    });
  });
}
