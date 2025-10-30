import 'package:fly_cli/src/core/templates/version_parser.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  group('VersionParser', () {
    group('parseVersion', () {
      test('should parse valid version string', () {
        final version = VersionParser.parseVersion('1.2.3');
        expect(version, isNotNull);
        expect(version?.toString(), equals('1.2.3'));
      });

      test('should return null for invalid version', () {
        final version = VersionParser.parseVersion('invalid');
        expect(version, isNull);
      });

      test('should return null for null input', () {
        final version = VersionParser.parseVersion(null);
        expect(version, isNull);
      });

      test('should return null for empty string', () {
        final version = VersionParser.parseVersion('');
        expect(version, isNull);
      });

      test('should trim whitespace', () {
        final version = VersionParser.parseVersion('  1.2.3  ');
        expect(version?.toString(), equals('1.2.3'));
      });
    });

    group('parseVersionConstraint', () {
      test('should parse valid constraint', () {
        final constraint = VersionParser.parseVersionConstraint('^2.0.0');
        expect(constraint, isNotNull);
        expect(constraint?.allows(Version.parse('2.1.0')), isTrue);
      });

      test('should return null for invalid constraint', () {
        final constraint = VersionParser.parseVersionConstraint('invalid');
        expect(constraint, isNull);
      });

      test('should return null for null input', () {
        final constraint = VersionParser.parseVersionConstraint(null);
        expect(constraint, isNull);
      });

      test('should trim whitespace', () {
        final constraint = VersionParser.parseVersionConstraint('  ^2.0.0  ');
        expect(constraint, isNotNull);
      });
    });

    group('parseTemplateVersion', () {
      test('should parse valid version', () {
        final version = VersionParser.parseTemplateVersion('1.2.3');
        expect(version, isNotNull);
        expect(version?.versionString, equals('1.2.3'));
      });

      test('should return null for invalid version', () {
        final version = VersionParser.parseTemplateVersion('invalid');
        expect(version, isNull);
      });

      test('should return null for null input', () {
        final version = VersionParser.parseTemplateVersion(null);
        expect(version, isNull);
      });

      test('should trim whitespace', () {
        final version = VersionParser.parseTemplateVersion('  1.2.3  ');
        expect(version?.versionString, equals('1.2.3'));
      });
    });

    group('parseCompatibility', () {
      test('should parse compatibility section', () {
        final yaml = {
          'compatibility': {
            'cli_min_version': '1.0.0',
            'flutter_min_sdk': '3.10.0',
          },
        };

        final compatibility = VersionParser.parseCompatibility(yaml);
        expect(compatibility, isNotNull);
        expect(compatibility?.cliMinVersion?.toString(), equals('1.0.0'));
      });

      test('should return null when compatibility section missing', () {
        final yaml = {'name': 'test', 'version': '1.0.0'};

        final compatibility = VersionParser.parseCompatibility(yaml);
        expect(compatibility, isNull);
      });

      test('should return null for invalid compatibility data', () {
        final yaml = {
          'compatibility': {
            'cli_min_version': '2.0.0',
            'cli_max_version': '<1.0.0', // Invalid constraint
          },
        };

        // Should return null on parse error
        final compatibility = VersionParser.parseCompatibility(yaml);
        expect(compatibility, isNull);
      });

      test('should return null for malformed compatibility section', () {
        final yaml = {
          'compatibility': 'not a map', // Invalid type
        };

        final compatibility = VersionParser.parseCompatibility(yaml);
        expect(compatibility, isNull);
      });
    });

    group('extractVersionString', () {
      test('should extract valid version string', () {
        final yaml = {'version': '1.2.3'};

        final version = VersionParser.extractVersionString(yaml);
        expect(version, equals('1.2.3'));
      });

      test('should return null for missing version', () {
        final yaml = {'name': 'test'};

        final version = VersionParser.extractVersionString(yaml);
        expect(version, isNull);
      });

      test('should return null for invalid version format', () {
        final yaml = {'version': 'invalid'};

        final version = VersionParser.extractVersionString(yaml);
        expect(version, isNull);
      });

      test('should return null for empty version', () {
        final yaml = {'version': ''};

        final version = VersionParser.extractVersionString(yaml);
        expect(version, isNull);
      });

      test('should trim whitespace', () {
        final yaml = {'version': '  1.2.3  '};

        final version = VersionParser.extractVersionString(yaml);
        expect(version, equals('1.2.3'));
      });
    });
  });
}
