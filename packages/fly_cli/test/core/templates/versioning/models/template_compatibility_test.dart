import 'package:fly_cli/src/core/templates/versioning/models/template_compatibility.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  group('TemplateCompatibility', () {
    group('fromYaml', () {
      test('should parse basic compatibility data', () {
        final yaml = {
          'compatibility': {
            'cli_min_version': '1.0.0',
            'flutter_min_sdk': '3.10.0',
            'dart_min_sdk': '3.0.0',
          },
          'deprecated': false,
        };

        final compatibility = TemplateCompatibility.fromYaml(yaml);

        expect(compatibility.cliMinVersion?.toString(), equals('1.0.0'));
        expect(compatibility.flutterMinSdk?.toString(), equals('3.10.0'));
        expect(compatibility.dartMinSdk?.toString(), equals('3.0.0'));
        expect(compatibility.deprecated, isFalse);
      });

      test('should parse with max CLI version constraint', () {
        final yaml = {
          'compatibility': {
            'cli_min_version': '1.0.0',
            'cli_max_version': '<3.0.0',
          },
        };

        final compatibility = TemplateCompatibility.fromYaml(yaml);

        expect(compatibility.cliMinVersion?.toString(), equals('1.0.0'));
        expect(compatibility.cliMaxVersion?.toString(), contains('<3.0.0'));
      });

      test('should parse deprecation dates', () {
        final yaml = {
          'compatibility': {},
          'deprecated': true,
          'deprecation_date': '2024-01-01',
          'eol_date': '2024-12-31',
        };

        final compatibility = TemplateCompatibility.fromYaml(yaml);

        expect(compatibility.deprecated, isTrue);
        expect(compatibility.deprecationDate, isNotNull);
        expect(compatibility.eolDate, isNotNull);
      });

      test('should throw FormatException for invalid version constraints', () {
        final yaml = {
          'compatibility': {
            'cli_min_version': '2.0.0',
            'cli_max_version': '<1.0.0', // Invalid: min > max
          },
        };

        expect(
          () => TemplateCompatibility.fromYaml(yaml),
          throwsA(isA<FormatException>()),
        );
      });

      test('should throw FormatException for invalid date order', () {
        final yaml = {
          'compatibility': {},
          'deprecation_date': '2024-12-31',
          'eol_date': '2024-01-01', // Invalid: deprecation after EOL
        };

        expect(
          () => TemplateCompatibility.fromYaml(yaml),
          throwsA(isA<FormatException>()),
        );
      });

      test('should handle missing compatibility section', () {
        final yaml = {'deprecated': false};

        final compatibility = TemplateCompatibility.fromYaml(yaml);

        expect(compatibility.cliMinVersion, isNull);
        expect(compatibility.deprecated, isFalse);
      });

      test('should handle empty compatibility section', () {
        final yaml = {'compatibility': {}, 'deprecated': false};

        final compatibility = TemplateCompatibility.fromYaml(yaml);

        expect(compatibility.cliMinVersion, isNull);
        expect(compatibility.deprecated, isFalse);
      });
    });

    group('checkCompatibility', () {
      test('should return compatible when all checks pass', () {
        final compatibility = TemplateCompatibility(
          cliMinVersion: Version.parse('1.0.0'),
          flutterMinSdk: Version.parse('3.10.0'),
          dartMinSdk: Version.parse('3.0.0'),
        );

        final result = compatibility.checkCompatibility(
          currentCliVersion: Version.parse('2.0.0'),
          currentFlutterVersion: Version.parse('3.12.0'),
          currentDartVersion: Version.parse('3.2.0'),
        );

        expect(result.isCompatible, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should return incompatible when CLI version is too low', () {
        final compatibility = TemplateCompatibility(
          cliMinVersion: Version.parse('2.0.0'),
        );

        final result = compatibility.checkCompatibility(
          currentCliVersion: Version.parse('1.0.0'),
          currentFlutterVersion: Version.parse('3.12.0'),
          currentDartVersion: Version.parse('3.2.0'),
        );

        expect(result.isIncompatible, isTrue);
        expect(result.errors.length, greaterThan(0));
        expect(result.errors.first, contains('CLI version'));
      });

      test('should return incompatible when CLI version exceeds max', () {
        final compatibility = TemplateCompatibility(
          cliMaxVersion: VersionConstraint.parse('<3.0.0'),
        );

        final result = compatibility.checkCompatibility(
          currentCliVersion: Version.parse('3.0.0'),
          currentFlutterVersion: Version.parse('3.12.0'),
          currentDartVersion: Version.parse('3.2.0'),
        );

        expect(result.isIncompatible, isTrue);
        expect(result.errors.length, greaterThan(0));
      });

      test('should return incompatible when Flutter SDK is too low', () {
        final compatibility = TemplateCompatibility(
          flutterMinSdk: Version.parse('3.12.0'),
        );

        final result = compatibility.checkCompatibility(
          currentCliVersion: Version.parse('1.0.0'),
          currentFlutterVersion: Version.parse('3.10.0'),
          currentDartVersion: Version.parse('3.2.0'),
        );

        expect(result.isIncompatible, isTrue);
        expect(result.errors.first, contains('Flutter SDK'));
      });

      test('should return incompatible when Dart SDK is too low', () {
        final compatibility = TemplateCompatibility(
          dartMinSdk: Version.parse('3.2.0'),
        );

        final result = compatibility.checkCompatibility(
          currentCliVersion: Version.parse('1.0.0'),
          currentFlutterVersion: Version.parse('3.12.0'),
          currentDartVersion: Version.parse('3.0.0'),
        );

        expect(result.isIncompatible, isTrue);
        expect(result.errors.first, contains('Dart SDK'));
      });

      test('should add warning when deprecated', () {
        final compatibility = TemplateCompatibility(
          deprecated: true,
          deprecationDate: DateTime(2024, 1, 1),
        );

        final result = compatibility.checkCompatibility(
          currentCliVersion: Version.parse('2.0.0'),
          currentFlutterVersion: Version.parse('3.12.0'),
          currentDartVersion: Version.parse('3.2.0'),
        );

        expect(result.isCompatible, isTrue);
        expect(result.warnings.length, greaterThan(0));
        expect(result.warnings.first, contains('deprecated'));
      });

      test('should return error when EOL date passed', () {
        final compatibility = TemplateCompatibility(
          eolDate: DateTime(2020, 1, 1), // Past date
        );

        final result = compatibility.checkCompatibility(
          currentCliVersion: Version.parse('2.0.0'),
          currentFlutterVersion: Version.parse('3.12.0'),
          currentDartVersion: Version.parse('3.2.0'),
        );

        expect(result.isIncompatible, isTrue);
        expect(result.errors.first, contains('end of life'));
      });

      test('should add warning when approaching EOL', () {
        final eolDate = DateTime.now().add(const Duration(days: 30));
        final compatibility = TemplateCompatibility(eolDate: eolDate);

        final result = compatibility.checkCompatibility(
          currentCliVersion: Version.parse('2.0.0'),
          currentFlutterVersion: Version.parse('3.12.0'),
          currentDartVersion: Version.parse('3.2.0'),
        );

        expect(result.isCompatible, isTrue);
        expect(result.warnings.length, greaterThan(0));
        expect(result.warnings.first, contains('end of life'));
      });

      test('should handle null values gracefully', () {
        const compatibility = TemplateCompatibility();

        final result = compatibility.checkCompatibility(
          currentCliVersion: Version.parse('2.0.0'),
          currentFlutterVersion: Version.parse('3.12.0'),
          currentDartVersion: Version.parse('3.2.0'),
        );

        expect(result.isCompatible, isTrue);
        expect(result.errors, isEmpty);
      });
    });

    group('JSON serialization', () {
      test('should serialize to JSON', () {
        final compatibility = TemplateCompatibility(
          cliMinVersion: Version.parse('1.0.0'),
          flutterMinSdk: Version.parse('3.10.0'),
          deprecated: true,
          deprecationDate: DateTime(2024, 1, 1),
        );

        final json = compatibility.toJson();

        expect(json['cliMinVersion'], equals('1.0.0'));
        expect(json['flutterMinSdk'], equals('3.10.0'));
        expect(json['deprecated'], isTrue);
      });

      test('should deserialize from JSON', () {
        final json = {
          'cliMinVersion': '1.0.0',
          'flutterMinSdk': '3.10.0',
          'dartMinSdk': '3.0.0',
          'deprecated': false,
        };

        final compatibility = TemplateCompatibility.fromJson(json);

        expect(compatibility.cliMinVersion?.toString(), equals('1.0.0'));
        expect(compatibility.flutterMinSdk?.toString(), equals('3.10.0'));
        expect(compatibility.deprecated, isFalse);
      });
    });

    group('equality', () {
      test('should be equal for same values', () {
        final c1 = TemplateCompatibility(
          cliMinVersion: Version.parse('1.0.0'),
          deprecated: false,
        );
        final c2 = TemplateCompatibility(
          cliMinVersion: Version.parse('1.0.0'),
          deprecated: false,
        );
        expect(c1 == c2, isTrue);
        expect(c1.hashCode, equals(c2.hashCode));
      });

      test('should not be equal for different values', () {
        final c1 = TemplateCompatibility(cliMinVersion: Version.parse('1.0.0'));
        final c2 = TemplateCompatibility(cliMinVersion: Version.parse('2.0.0'));
        expect(c1 == c2, isFalse);
      });
    });
  });
}
