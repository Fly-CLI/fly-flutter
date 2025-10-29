import 'package:pub_semver/pub_semver.dart';

import '../models/template_compatibility.dart';
import '../models/template_version.dart';

/// Utilities for parsing version-related data from YAML
class VersionParser {
  /// Parse a version string, returning null if invalid
  static Version? parseVersion(String? versionString) {
    if (versionString == null || versionString.trim().isEmpty) {
      return null;
    }
    try {
      return Version.parse(versionString.trim());
    } catch (_) {
      return null;
    }
  }

  /// Parse a version constraint string, returning null if invalid
  static VersionConstraint? parseVersionConstraint(String? constraintString) {
    if (constraintString == null || constraintString.trim().isEmpty) {
      return null;
    }
    try {
      return VersionConstraint.parse(constraintString.trim());
    } catch (_) {
      return null;
    }
  }

  /// Parse TemplateVersion from string, returning null if invalid
  static TemplateVersion? parseTemplateVersion(String? versionString) {
    if (versionString == null || versionString.trim().isEmpty) {
      return null;
    }
    return TemplateVersion.tryParse(versionString.trim());
  }

  /// Parse TemplateCompatibility from YAML map
  /// 
  /// Parses compatibility section from template.yaml.
  /// Returns null if compatibility section is missing or invalid.
  static TemplateCompatibility? parseCompatibility(Map<dynamic, dynamic> yaml) {
    // Parse compatibility section if it exists
    if (!yaml.containsKey('compatibility')) {
      return null;
    }

    try {
      return TemplateCompatibility.fromYaml(yaml);
    } catch (e) {
      // Return null on parse errors (invalid format, validation failures, etc.)
      // Error details are logged by TemplateCompatibility.fromYaml if needed
      return null;
    }
  }

  /// Extract version from YAML and validate format
  static String? extractVersionString(Map<dynamic, dynamic> yaml) {
    final version = yaml['version'] as String?;
    if (version == null || version.trim().isEmpty) {
      return null;
    }
    
    // Validate format
    if (parseVersion(version) == null) {
      return null;
    }
    
    return version.trim();
  }
}

