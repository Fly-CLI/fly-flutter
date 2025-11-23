import 'package:fly_cli/src/core/generation/domain/entities/brick.dart';
import 'package:fly_cli/src/core/generation/versioning/compatibility_result.dart';
import 'package:fly_cli/src/core/generation/template/template_info.dart';
import 'package:pub_semver/pub_semver.dart';

/// Service for checking template compatibility with current environment
///
/// Performs compatibility checks using TemplateCompatibility data when available.
/// Templates without compatibility data are considered compatible (no constraints).
class CompatibilityChecker {
  CompatibilityChecker({
    required this.currentCliVersion,
    required this.currentFlutterVersion,
    required this.currentDartVersion,
  });

  /// Current CLI version
  final Version currentCliVersion;

  /// Current Flutter SDK version
  final Version currentFlutterVersion;

  /// Current Dart SDK version
  final Version currentDartVersion;

  /// Check compatibility of a TemplateInfo
  ///
  /// Uses TemplateInfo.compatibility for full versioning checks.
  /// If compatibility data is not present, returns compatible result
  /// (no constraints means compatible).
  ///
  /// Returns CompatibilityResult indicating whether the template is compatible
  /// with the current environment (CLI version, Flutter SDK, Dart SDK).
  CompatibilityResult checkTemplateCompatibility(TemplateInfo template) {
    final compatibility = template.compatibility;

    // If compatibility data exists, use it for full checks
    if (compatibility != null) {
      return compatibility.checkCompatibility(
        currentCliVersion: currentCliVersion,
        currentFlutterVersion: currentFlutterVersion,
        currentDartVersion: currentDartVersion,
      );
    }

    // No compatibility data means no constraints - template is compatible
    return const CompatibilityResult.compatible();
  }

  /// Check compatibility of a Brick
  CompatibilityResult checkBrickCompatibility(Brick brick) {
    final errors = <String>[];
    final warnings = <String>[];

    // Check Flutter SDK
    final minFlutterSdk = brick.minFlutterSdk;
    if (minFlutterSdk != null) {
      if (currentFlutterVersion < minFlutterSdk) {
        errors.add(
          'Flutter SDK version $currentFlutterVersion is less than required minimum $minFlutterSdk. '
          'Please upgrade Flutter SDK: flutter upgrade',
        );
      }
    }

    // Check Dart SDK
    final minDartSdk = brick.minDartSdk;
    if (minDartSdk != null) {
      if (currentDartVersion < minDartSdk) {
        errors.add(
          'Dart SDK version ${currentDartVersion} is less than required minimum ${minDartSdk}. '
          'Please upgrade Dart SDK: dart upgrade',
        );
      }
    }

    if (errors.isNotEmpty) {
      return CompatibilityResult.incompatible(
        errors: errors,
        warnings: warnings,
      );
    }

    return CompatibilityResult.compatible(warnings: warnings);
  }

  /// Check if a version satisfies a requirement
  bool satisfiesVersionRequirement({
    required Version? requiredVersion,
    required Version currentVersion,
  }) {
    if (requiredVersion == null) return true;
    return currentVersion >= requiredVersion;
  }

  /// Check if a version is within a constraint
  bool satisfiesVersionConstraint({
    required VersionConstraint? constraint,
    required Version currentVersion,
  }) {
    if (constraint == null) return true;
    return constraint.allows(currentVersion);
  }
}
