import 'package:fly_cli/src/core/templates/brick_info.dart';
import 'package:fly_cli/src/core/templates/template_info.dart';
import 'package:fly_cli/src/core/templates/template_compatibility.dart';
import 'package:fly_cli/src/core/templates/compatibility_checker.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  group('CompatibilityChecker', () {
    late CompatibilityChecker checker;

    setUp(() {
      checker = CompatibilityChecker(
        currentCliVersion: Version.parse('2.0.0'),
        currentFlutterVersion: Version.parse('3.12.0'),
        currentDartVersion: Version.parse('3.2.0'),
      );
    });

    group('checkTemplateCompatibility', () {
      test('should return compatible when no compatibility data', () {
        const template = TemplateInfo(
          name: 'test',
          version: '1.0.0',
          description: 'Test template',
          path: '/path',
          minFlutterSdk: '3.10.0',
          minDartSdk: '3.0.0',
          variables: const [],
          features: const [],
          packages: const [],
        );

        final result = checker.checkTemplateCompatibility(template);
        expect(result.isCompatible, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should return compatible when all checks pass', () {
        final template = TemplateInfo(
          name: 'test',
          version: '1.0.0',
          description: 'Test template',
          path: '/path',
          minFlutterSdk: '3.10.0',
          minDartSdk: '3.0.0',
          variables: const [],
          features: const [],
          packages: const [],
          compatibility: TemplateCompatibility(
            cliMinVersion: Version.parse('1.0.0'),
            flutterMinSdk: Version.parse('3.10.0'),
            dartMinSdk: Version.parse('3.0.0'),
          ),
        );

        final result = checker.checkTemplateCompatibility(template);
        expect(result.isCompatible, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should return incompatible when CLI version too low', () {
        final template = TemplateInfo(
          name: 'test',
          version: '1.0.0',
          description: 'Test template',
          path: '/path',
          minFlutterSdk: '3.10.0',
          minDartSdk: '3.0.0',
          variables: const [],
          features: const [],
          packages: const [],
          compatibility: TemplateCompatibility(
            cliMinVersion: Version.parse('3.0.0'),
          ),
        );

        final result = checker.checkTemplateCompatibility(template);
        expect(result.isIncompatible, isTrue);
        expect(result.errors.length, greaterThan(0));
      });

      test('should return incompatible when Flutter SDK too low', () {
        final template = TemplateInfo(
          name: 'test',
          version: '1.0.0',
          description: 'Test template',
          path: '/path',
          minFlutterSdk: '3.10.0',
          minDartSdk: '3.0.0',
          variables: const [],
          features: const [],
          packages: const [],
          compatibility: TemplateCompatibility(
            flutterMinSdk: Version.parse('4.0.0'),
          ),
        );

        final result = checker.checkTemplateCompatibility(template);
        expect(result.isIncompatible, isTrue);
        expect(result.errors.length, greaterThan(0));
      });

      test('should return incompatible when Dart SDK too low', () {
        final template = TemplateInfo(
          name: 'test',
          version: '1.0.0',
          description: 'Test template',
          path: '/path',
          minFlutterSdk: '3.10.0',
          minDartSdk: '3.0.0',
          variables: const [],
          features: const [],
          packages: const [],
          compatibility: TemplateCompatibility(
            dartMinSdk: Version.parse('4.0.0'),
          ),
        );

        final result = checker.checkTemplateCompatibility(template);
        expect(result.isIncompatible, isTrue);
        expect(result.errors.length, greaterThan(0));
      });

      test('should include warnings when deprecated', () {
        const template = TemplateInfo(
          name: 'test',
          version: '1.0.0',
          description: 'Test template',
          path: '/path',
          minFlutterSdk: '3.10.0',
          minDartSdk: '3.0.0',
          variables: const [],
          features: const [],
          packages: const [],
          compatibility: const TemplateCompatibility(deprecated: true),
        );

        final result = checker.checkTemplateCompatibility(template);
        expect(result.isCompatible, isTrue);
        expect(result.warnings.length, greaterThan(0));
      });
    });

    group('checkBrickCompatibility', () {
      test('should return compatible when all checks pass', () {
        const brick = BrickInfo(
          name: 'test_brick',
          version: '1.0.0',
          description: 'Test brick',
          path: '/path',
          type: BrickType.project,
          variables: const {},
          features: const [],
          packages: const [],
          minFlutterSdk: '3.10.0',
          minDartSdk: '3.0.0',
        );

        final result = checker.checkBrickCompatibility(brick);
        expect(result.isCompatible, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should return incompatible when Flutter SDK too low', () {
        const brick = BrickInfo(
          name: 'test_brick',
          version: '1.0.0',
          description: 'Test brick',
          path: '/path',
          type: BrickType.project,
          variables: const {},
          features: const [],
          packages: const [],
          minFlutterSdk: '4.0.0',
          minDartSdk: '3.0.0',
        );

        final result = checker.checkBrickCompatibility(brick);
        expect(result.isIncompatible, isTrue);
        expect(result.errors.length, greaterThan(0));
      });

      test('should return incompatible when Dart SDK too low', () {
        const brick = BrickInfo(
          name: 'test_brick',
          version: '1.0.0',
          description: 'Test brick',
          path: '/path',
          type: BrickType.project,
          variables: const {},
          features: const [],
          packages: const [],
          minFlutterSdk: '3.10.0',
          minDartSdk: '4.0.0',
        );

        final result = checker.checkBrickCompatibility(brick);
        expect(result.isIncompatible, isTrue);
        expect(result.errors.length, greaterThan(0));
      });

      test('should handle invalid version format gracefully', () {
        const brick = BrickInfo(
          name: 'test_brick',
          version: '1.0.0',
          description: 'Test brick',
          path: '/path',
          type: BrickType.project,
          variables: const {},
          features: const [],
          packages: const [],
          minFlutterSdk: 'invalid',
          minDartSdk: '3.0.0',
        );

        final result = checker.checkBrickCompatibility(brick);
        // Should skip invalid version check and return compatible
        expect(result.isCompatible, isTrue);
      });

      test('should handle empty SDK version strings', () {
        const brick = BrickInfo(
          name: 'test_brick',
          version: '1.0.0',
          description: 'Test brick',
          path: '/path',
          type: BrickType.project,
          variables: const {},
          features: const [],
          packages: const [],
          minFlutterSdk: '',
          minDartSdk: '',
        );

        final result = checker.checkBrickCompatibility(brick);
        expect(result.isCompatible, isTrue);
      });
    });

    group('satisfiesVersionRequirement', () {
      test('should return true when version meets requirement', () {
        final result = checker.satisfiesVersionRequirement(
          requiredVersion: Version.parse('1.0.0'),
          currentVersion: Version.parse('2.0.0'),
        );
        expect(result, isTrue);
      });

      test('should return false when version below requirement', () {
        final result = checker.satisfiesVersionRequirement(
          requiredVersion: Version.parse('3.0.0'),
          currentVersion: Version.parse('2.0.0'),
        );
        expect(result, isFalse);
      });

      test('should return true when requirement is null', () {
        final result = checker.satisfiesVersionRequirement(
          requiredVersion: null,
          currentVersion: Version.parse('2.0.0'),
        );
        expect(result, isTrue);
      });
    });

    group('satisfiesVersionConstraint', () {
      test('should return true when version satisfies constraint', () {
        final result = checker.satisfiesVersionConstraint(
          constraint: VersionConstraint.parse('^2.0.0'),
          currentVersion: Version.parse('2.1.0'),
        );
        expect(result, isTrue);
      });

      test('should return false when version does not satisfy constraint', () {
        final result = checker.satisfiesVersionConstraint(
          constraint: VersionConstraint.parse('^2.0.0'),
          currentVersion: Version.parse('3.0.0'),
        );
        expect(result, isFalse);
      });

      test('should return true when constraint is null', () {
        final result = checker.satisfiesVersionConstraint(
          constraint: null,
          currentVersion: Version.parse('2.0.0'),
        );
        expect(result, isTrue);
      });
    });
  });
}
