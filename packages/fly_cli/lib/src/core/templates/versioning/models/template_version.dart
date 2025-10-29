import 'package:pub_semver/pub_semver.dart';

/// Wrapper around pub_semver.Version with template-specific operations
class TemplateVersion {
  /// Create TemplateVersion from a Version object
  TemplateVersion(this._version);

  /// Create TemplateVersion from a version string
  /// 
  /// Throws [FormatException] if the version string is invalid
  factory TemplateVersion.parse(String versionString) {
    try {
      return TemplateVersion(Version.parse(versionString));
    } catch (e) {
      throw FormatException(
        'Invalid version format: "$versionString". Expected SemVer format (MAJOR.MINOR.PATCH).',
        versionString,
      );
    }
  }

  /// Try to parse a version string, returning null if invalid
  static TemplateVersion? tryParse(String versionString) {
    try {
      return TemplateVersion.parse(versionString);
    } catch (_) {
      return null;
    }
  }

  final Version _version;

  /// Get the underlying Version object
  Version get version => _version;

  /// Get the version string
  String get versionString => _version.toString();

  /// Compare this version with another
  /// 
  /// Returns:
  /// - Negative if this version is less than [other]
  /// - Zero if versions are equal
  /// - Positive if this version is greater than [other]
  int compareTo(TemplateVersion other) => _version.compareTo(other._version);

  /// Check if this version satisfies the given version constraint
  bool satisfies(VersionConstraint constraint) => constraint.allows(_version);

  /// Check if this version is compatible with another using caret range
  /// 
  /// Example: 2.1.3 is compatible with ^2.0.0 (same major version)
  bool isCompatibleWith(TemplateVersion other) {
    // Same major version means compatible
    return _version.major == other._version.major;
  }

  /// Check if this version is greater than another
  bool isGreaterThan(TemplateVersion other) => compareTo(other) > 0;

  /// Check if this version is less than another
  bool isLessThan(TemplateVersion other) => compareTo(other) < 0;

  /// Check if this version is greater than or equal to another
  bool isGreaterThanOrEqual(TemplateVersion other) => compareTo(other) >= 0;

  /// Check if this version is less than or equal to another
  bool isLessThanOrEqual(TemplateVersion other) => compareTo(other) <= 0;

  /// Check if this version equals another
  bool equals(TemplateVersion other) => compareTo(other) == 0;

  /// Parse a version range from a string
  /// 
  /// Supports formats like:
  /// - "^2.1.0" (compatible with 2.x.x)
  /// - ">=2.0.0 <3.0.0" (range)
  /// - "~2.1.0" (approximately 2.1.x)
  static VersionConstraint? parseRange(String rangeString) {
    try {
      return VersionConstraint.parse(rangeString);
    } catch (_) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemplateVersion &&
          runtimeType == other.runtimeType &&
          _version == other._version;

  @override
  int get hashCode => _version.hashCode;

  @override
  String toString() => versionString;
}

