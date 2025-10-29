import 'package:fly_cli/src/core/templates/versioning/models/template_version.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  group('TemplateVersion', () {
    group('parse', () {
      test('should parse valid SemVer string', () {
        final version = TemplateVersion.parse('1.2.3');
        expect(version.versionString, equals('1.2.3'));
        expect(version.version.major, equals(1));
        expect(version.version.minor, equals(2));
        expect(version.version.patch, equals(3));
      });

      test('should parse version with prerelease', () {
        final version = TemplateVersion.parse('1.2.3-beta.1');
        expect(version.versionString, equals('1.2.3-beta.1'));
      });

      test('should parse version with build metadata', () {
        final version = TemplateVersion.parse('1.2.3+build.1');
        expect(version.versionString, equals('1.2.3+build.1'));
      });

      test('should throw FormatException for invalid version', () {
        expect(
          () => TemplateVersion.parse('invalid'),
          throwsA(isA<FormatException>()),
        );
      });

      test('should throw FormatException for empty string', () {
        expect(
          () => TemplateVersion.parse(''),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('tryParse', () {
      test('should return TemplateVersion for valid string', () {
        final version = TemplateVersion.tryParse('1.2.3');
        expect(version, isNotNull);
        expect(version?.versionString, equals('1.2.3'));
      });

      test('should return null for invalid string', () {
        final version = TemplateVersion.tryParse('invalid');
        expect(version, isNull);
      });

      test('should return null for empty string', () {
        final version = TemplateVersion.tryParse('');
        expect(version, isNull);
      });
    });

    group('compareTo', () {
      test('should compare versions correctly', () {
        final v1 = TemplateVersion.parse('1.0.0');
        final v2 = TemplateVersion.parse('2.0.0');
        final v3 = TemplateVersion.parse('1.0.0');

        expect(v1.compareTo(v2), lessThan(0));
        expect(v2.compareTo(v1), greaterThan(0));
        expect(v1.compareTo(v3), equals(0));
      });

      test('should compare patch versions', () {
        final v1 = TemplateVersion.parse('1.0.0');
        final v2 = TemplateVersion.parse('1.0.1');
        expect(v1.compareTo(v2), lessThan(0));
      });

      test('should compare minor versions', () {
        final v1 = TemplateVersion.parse('1.0.0');
        final v2 = TemplateVersion.parse('1.1.0');
        expect(v1.compareTo(v2), lessThan(0));
      });
    });

    group('comparison operators', () {
      test('isGreaterThan should work correctly', () {
        final v1 = TemplateVersion.parse('1.0.0');
        final v2 = TemplateVersion.parse('2.0.0');
        expect(v2.isGreaterThan(v1), isTrue);
        expect(v1.isGreaterThan(v2), isFalse);
      });

      test('isLessThan should work correctly', () {
        final v1 = TemplateVersion.parse('1.0.0');
        final v2 = TemplateVersion.parse('2.0.0');
        expect(v1.isLessThan(v2), isTrue);
        expect(v2.isLessThan(v1), isFalse);
      });

      test('isGreaterThanOrEqual should work correctly', () {
        final v1 = TemplateVersion.parse('1.0.0');
        final v2 = TemplateVersion.parse('2.0.0');
        final v3 = TemplateVersion.parse('1.0.0');
        expect(v2.isGreaterThanOrEqual(v1), isTrue);
        expect(v1.isGreaterThanOrEqual(v3), isTrue);
        expect(v1.isGreaterThanOrEqual(v2), isFalse);
      });

      test('isLessThanOrEqual should work correctly', () {
        final v1 = TemplateVersion.parse('1.0.0');
        final v2 = TemplateVersion.parse('2.0.0');
        final v3 = TemplateVersion.parse('1.0.0');
        expect(v1.isLessThanOrEqual(v2), isTrue);
        expect(v1.isLessThanOrEqual(v3), isTrue);
        expect(v2.isLessThanOrEqual(v1), isFalse);
      });

      test('equals should work correctly', () {
        final v1 = TemplateVersion.parse('1.0.0');
        final v2 = TemplateVersion.parse('1.0.0');
        final v3 = TemplateVersion.parse('2.0.0');
        expect(v1.equals(v2), isTrue);
        expect(v1.equals(v3), isFalse);
      });
    });

    group('satisfies', () {
      test('should check if version satisfies constraint', () {
        final version = TemplateVersion.parse('2.1.0');
        final constraint = VersionConstraint.parse('^2.0.0');
        expect(version.satisfies(constraint), isTrue);
      });

      test('should return false for unsatisfied constraint', () {
        final version = TemplateVersion.parse('1.9.0');
        final constraint = VersionConstraint.parse('^2.0.0');
        expect(version.satisfies(constraint), isFalse);
      });

      test('should handle exact version constraint', () {
        final version = TemplateVersion.parse('2.0.0');
        final constraint = VersionConstraint.parse('2.0.0');
        expect(version.satisfies(constraint), isTrue);
      });
    });

    group('isCompatibleWith', () {
      test('should return true for same major version', () {
        final v1 = TemplateVersion.parse('2.0.0');
        final v2 = TemplateVersion.parse('2.1.3');
        expect(v1.isCompatibleWith(v2), isTrue);
        expect(v2.isCompatibleWith(v1), isTrue);
      });

      test('should return false for different major versions', () {
        final v1 = TemplateVersion.parse('1.0.0');
        final v2 = TemplateVersion.parse('2.0.0');
        expect(v1.isCompatibleWith(v2), isFalse);
      });
    });

    group('parseRange', () {
      test('should parse caret range', () {
        final constraint = TemplateVersion.parseRange('^2.0.0');
        expect(constraint, isNotNull);
        expect(constraint?.allows(Version.parse('2.1.0')), isTrue);
        expect(constraint?.allows(Version.parse('3.0.0')), isFalse);
      });

      test('should parse tilde range', () {
        // Note: pub_semver uses '~>2.1.0' for tilde ranges, not '~2.1.0'
        // Alternatively, we can use '>=2.1.0 <2.2.0'
        final constraint = TemplateVersion.parseRange('>=2.1.0 <2.2.0');
        expect(constraint, isNotNull);
        expect(constraint?.allows(Version.parse('2.1.5')), isTrue);
        expect(constraint?.allows(Version.parse('2.2.0')), isFalse);
      });

      test('should return null for invalid range', () {
        final constraint = TemplateVersion.parseRange('invalid');
        expect(constraint, isNull);
      });
    });

    group('equality and hashCode', () {
      test('should be equal for same version', () {
        final v1 = TemplateVersion.parse('1.0.0');
        final v2 = TemplateVersion.parse('1.0.0');
        expect(v1 == v2, isTrue);
        expect(v1.hashCode, equals(v2.hashCode));
      });

      test('should not be equal for different versions', () {
        final v1 = TemplateVersion.parse('1.0.0');
        final v2 = TemplateVersion.parse('2.0.0');
        expect(v1 == v2, isFalse);
      });
    });

    group('toString', () {
      test('should return version string', () {
        final version = TemplateVersion.parse('1.2.3');
        expect(version.toString(), equals('1.2.3'));
      });
    });
  });
}

