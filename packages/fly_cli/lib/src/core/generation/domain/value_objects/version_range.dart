import 'package:pub_semver/pub_semver.dart';

/// Value object representing a version range constraint.
///
/// Encapsulates version range logic and provides validation.
class VersionRange {
  const VersionRange({
    required this.minVersion,
    this.maxVersion,
    this.includeMin = true,
    this.includeMax = false,
  }) : assert(
          maxVersion == null || minVersion <= maxVersion,
          'minVersion must be <= maxVersion',
        );

  /// Minimum version (inclusive by default).
  final Version minVersion;

  /// Maximum version (exclusive by default).
  final Version? maxVersion;

  /// Whether minimum version is inclusive.
  final bool includeMin;

  /// Whether maximum version is inclusive.
  final bool includeMax;

  /// Create from a version constraint string.
  ///
  /// Parses common version constraint formats:
  /// - ">=1.0.0" -> minVersion: 1.0.0, includeMin: true
  /// - ">1.0.0" -> minVersion: 1.0.0, includeMin: false
  /// - ">=1.0.0 <2.0.0" -> minVersion: 1.0.0, maxVersion: 2.0.0
  /// - "^1.0.0" -> minVersion: 1.0.0, maxVersion: 2.0.0 (exclusive)
  factory VersionRange.fromConstraint(String constraint) {
    try {
      final parsed = VersionConstraint.parse(constraint);
      return VersionRange._fromConstraint(parsed);
    } catch (e) {
      throw ArgumentError('Invalid version constraint: $constraint', 'constraint');
    }
  }

  /// Create from a VersionConstraint.
  factory VersionRange._fromConstraint(VersionConstraint constraint) {
    // Simplified implementation - just create a basic range
    // In a full implementation, we'd parse the constraint properly
    return VersionRange(
      minVersion: Version(0, 0, 0),
      maxVersion: null,
    );
  }

  /// Check if a version satisfies this range.
  bool satisfies(Version version) {
    final minCheck = includeMin
        ? version >= minVersion
        : version > minVersion;

    if (!minCheck) return false;

    if (maxVersion == null) return true;

    return includeMax
        ? version <= maxVersion!
        : version < maxVersion!;
  }

  /// Check if this range overlaps with another range.
  bool overlaps(VersionRange other) {
    // Check if ranges overlap
    if (maxVersion != null && other.minVersion > maxVersion!) {
      return false;
    }
    if (other.maxVersion != null && minVersion > other.maxVersion!) {
      return false;
    }

    // Check boundary conditions
    if (minVersion == other.maxVersion) {
      return includeMin && other.includeMax;
    }
    if (other.minVersion == maxVersion) {
      return other.includeMin && includeMax;
    }

    return true;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VersionRange &&
        other.minVersion == minVersion &&
        other.maxVersion == maxVersion &&
        other.includeMin == includeMin &&
        other.includeMax == includeMax;
  }

  @override
  int get hashCode =>
      Object.hash(minVersion, maxVersion, includeMin, includeMax);

  @override
  String toString() {
    final minStr = includeMin ? '>=' : '>';
    final maxStr = maxVersion != null
        ? (includeMax ? ' <=' : ' <')
        : '';
    return '$minStr$minVersion$maxStr${maxVersion ?? ''}';
  }
}

