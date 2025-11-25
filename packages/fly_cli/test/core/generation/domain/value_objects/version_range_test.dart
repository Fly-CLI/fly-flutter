import 'package:fly_cli/src/generation/domain/value_objects/version_range.dart';
import 'package:pub_semver/pub_semver.dart' hide VersionRange;
import 'package:test/test.dart';

void main() {
  group('VersionRange', () {
    group('satisfies', () {
      test('should satisfy version within range', () {
        // Arrange
        final range = VersionRange(
          minVersion: Version.parse('1.0.0'),
          maxVersion: Version.parse('2.0.0'),
        );

        // Act & Assert
        expect(range.satisfies(Version.parse('1.5.0')), isTrue);
        // Inclusive min
        expect(range.satisfies(Version.parse('1.0.0')), isTrue);
        // Exclusive max
        expect(range.satisfies(Version.parse('2.0.0')), isFalse);
      });

      test('should not satisfy version below minimum', () {
        // Arrange
        final range = VersionRange(
          minVersion: Version.parse('1.0.0'),
          maxVersion: Version.parse('2.0.0'),
        );

        // Act & Assert
        expect(range.satisfies(Version.parse('0.9.0')), isFalse);
      });

      test('should not satisfy version above maximum', () {
        // Arrange
        final range = VersionRange(
          minVersion: Version.parse('1.0.0'),
          maxVersion: Version.parse('2.0.0'),
        );

        // Act & Assert
        expect(range.satisfies(Version.parse('2.1.0')), isFalse);
      });

      test('should handle range without maximum', () {
        // Arrange
        final range = VersionRange(
          minVersion: Version.parse('1.0.0'),
        );

        // Act & Assert
        expect(range.satisfies(Version.parse('1.0.0')), isTrue);
        expect(range.satisfies(Version.parse('10.0.0')), isTrue);
      });

      test('should respect inclusive/exclusive flags', () {
        // Arrange
        final exclusiveMin = VersionRange(
          minVersion: Version.parse('1.0.0'),
          includeMin: false,
        );
        final inclusiveMax = VersionRange(
          minVersion: Version.parse('1.0.0'),
          maxVersion: Version.parse('2.0.0'),
          includeMax: true,
        );

        // Act & Assert
        expect(exclusiveMin.satisfies(Version.parse('1.0.0')), isFalse);
        expect(inclusiveMax.satisfies(Version.parse('2.0.0')), isTrue);
      });
    });

    group('overlaps', () {
      test('should detect overlapping ranges', () {
        // Arrange
        final range1 = VersionRange(
          minVersion: Version.parse('1.0.0'),
          maxVersion: Version.parse('2.0.0'),
        );
        final range2 = VersionRange(
          minVersion: Version.parse('1.5.0'),
          maxVersion: Version.parse('2.5.0'),
        );

        // Act & Assert
        expect(range1.overlaps(range2), isTrue);
      });

      test('should detect non-overlapping ranges', () {
        // Arrange
        final range1 = VersionRange(
          minVersion: Version.parse('1.0.0'),
          maxVersion: Version.parse('2.0.0'),
        );
        final range2 = VersionRange(
          minVersion: Version.parse('3.0.0'),
          maxVersion: Version.parse('4.0.0'),
        );

        // Act & Assert
        expect(range1.overlaps(range2), isFalse);
      });
    });

    group('fromConstraint', () {
      test('should parse version constraint string', () {
        // Act
        final range = VersionRange.fromConstraint('>=1.0.0 <2.0.0');

        // Assert
        expect(range.minVersion, equals(Version.parse('1.0.0')));
        expect(range.maxVersion, equals(Version.parse('2.0.0')));
      });

      test('should throw on invalid constraint', () {
        // Act & Assert
        expect(
          () => VersionRange.fromConstraint('invalid'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });
}
