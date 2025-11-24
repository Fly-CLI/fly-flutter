import 'package:fly_cli/src/generation/domain/services/compatibility_service.dart';
import 'package:fly_cli/src/generation/domain/value_objects/version_range.dart' as vo;
import 'package:pub_semver/pub_semver.dart' hide VersionRange;
import 'package:test/test.dart';

void main() {
  group('CompatibilityService', () {
    late CompatibilityService service;

    setUp(() {
      service = const CompatibilityService();
    });

    group('checkSdkCompatibility', () {
      test('should return compatible when no SDK required', () {
        // Act
        final result = service.checkSdkCompatibility(
          requiredSdk: null,
          currentSdk: Version.parse('3.10.0'),
        );

        // Assert
        expect(result.isCompatible, isTrue);
      });

      test('should return compatible when SDK meets requirement', () {
        // Act
        final result = service.checkSdkCompatibility(
          requiredSdk: Version.parse('3.10.0'),
          currentSdk: Version.parse('3.15.0'),
        );

        // Assert
        expect(result.isCompatible, isTrue);
      });

      test('should return incompatible when SDK below requirement', () {
        // Act
        final result = service.checkSdkCompatibility(
          requiredSdk: Version.parse('3.15.0'),
          currentSdk: Version.parse('3.10.0'),
        );

        // Assert
        expect(result.isCompatible, isFalse);
        expect(result.errors, isNotEmpty);
      });

      test('should warn on pre-release SDK', () {
        // Act
        final result = service.checkSdkCompatibility(
          requiredSdk: Version.parse('3.10.0'),
          currentSdk: Version.parse('3.15.0-dev.1'),
        );

        // Assert
        expect(result.isCompatible, isTrue);
        expect(result.warnings, isNotEmpty);
      });
    });

    group('checkVersionCompatibility', () {
      test('should return compatible when version satisfies range', () {
        // Arrange
        final range = vo.VersionRange(
          minVersion: Version.parse('1.0.0'),
          maxVersion: Version.parse('2.0.0'),
        );

        // Act
        final result = service.checkVersionCompatibility(
          requiredRange: range,
          currentVersion: Version.parse('1.5.0'),
        );

        // Assert
        expect(result.isCompatible, isTrue);
      });

      test('should return incompatible when version outside range', () {
        // Arrange
        final range = vo.VersionRange(
          minVersion: Version.parse('1.0.0'),
          maxVersion: Version.parse('2.0.0'),
        );

        // Act
        final result = service.checkVersionCompatibility(
          requiredRange: range,
          currentVersion: Version.parse('2.5.0'),
        );

        // Assert
        expect(result.isCompatible, isFalse);
        expect(result.errors, isNotEmpty);
      });
    });

    group('satisfiesVersion', () {
      test('should check if version satisfies range', () {
        // Arrange
        final range = vo.VersionRange(
          minVersion: Version.parse('1.0.0'),
          maxVersion: Version.parse('2.0.0'),
        );

        // Act & Assert
        expect(
          service.satisfiesVersion(Version.parse('1.5.0'), range),
          isTrue,
        );
        expect(
          service.satisfiesVersion(Version.parse('0.9.0'), range),
          isFalse,
        );
      });
    });

    group('rangesOverlap', () {
      test('should detect overlapping ranges', () {
        // Arrange
        final range1 = vo.VersionRange(
          minVersion: Version.parse('1.0.0'),
          maxVersion: Version.parse('2.0.0'),
        );
        final range2 = vo.VersionRange(
          minVersion: Version.parse('1.5.0'),
          maxVersion: Version.parse('2.5.0'),
        );

        // Act & Assert
        expect(service.rangesOverlap(range1, range2), isTrue);
      });

      test('should detect non-overlapping ranges', () {
        // Arrange
        final range1 = vo.VersionRange(
          minVersion: Version.parse('1.0.0'),
          maxVersion: Version.parse('2.0.0'),
        );
        final range2 = vo.VersionRange(
          minVersion: Version.parse('3.0.0'),
          maxVersion: Version.parse('4.0.0'),
        );

        // Act & Assert
        expect(service.rangesOverlap(range1, range2), isFalse);
      });
    });
  });
}


