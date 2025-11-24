import 'package:pub_semver/pub_semver.dart' hide VersionRange;

import 'package:fly_cli/src/generation/domain/value_objects/compatibility_result_vo.dart';
import 'package:fly_cli/src/generation/domain/value_objects/version_range.dart' as vo;

/// Domain service for compatibility checking.
///
/// Contains business rules for determining compatibility between
/// versions, SDKs, and other constraints.
abstract class ICompatibilityService {
  /// Check if a version satisfies a version range.
  bool satisfiesVersion(Version version, vo.VersionRange range);

  /// Check if a version range overlaps with another.
  bool rangesOverlap(vo.VersionRange range1, vo.VersionRange range2);

  /// Check SDK compatibility.
  CompatibilityResult checkSdkCompatibility({
    required Version? requiredSdk,
    required Version currentSdk,
  });

  /// Check version compatibility.
  CompatibilityResult checkVersionCompatibility({
    required vo.VersionRange requiredRange,
    required Version currentVersion,
  });
}

/// Implementation of compatibility service.
class CompatibilityService implements ICompatibilityService {
  const CompatibilityService();

  @override
  bool satisfiesVersion(Version version, vo.VersionRange range) {
    return range.satisfies(version);
  }

  @override
  bool rangesOverlap(vo.VersionRange range1, vo.VersionRange range2) {
    return range1.overlaps(range2);
  }

  @override
  CompatibilityResult checkSdkCompatibility({
    required Version? requiredSdk,
    required Version currentSdk,
  }) {
    if (requiredSdk == null) {
      return const CompatibilityResult.compatible();
    }

    if (currentSdk < requiredSdk) {
      return CompatibilityResult.incompatible(
        errors: [
          'SDK version $currentSdk is below required version $requiredSdk',
        ],
      );
    }

    // Check for pre-release warnings
    if (currentSdk.isPreRelease) {
      return CompatibilityResult.compatible(
        warnings: [
          'Current SDK version $currentSdk is a pre-release',
        ],
      );
    }

    return const CompatibilityResult.compatible();
  }

  @override
  CompatibilityResult checkVersionCompatibility({
    required vo.VersionRange requiredRange,
    required Version currentVersion,
  }) {
    if (requiredRange.satisfies(currentVersion)) {
      return const CompatibilityResult.compatible();
    }

    return CompatibilityResult.incompatible(
      errors: [
        'Version $currentVersion does not satisfy range ${requiredRange.toString()}',
      ],
    );
  }
}

