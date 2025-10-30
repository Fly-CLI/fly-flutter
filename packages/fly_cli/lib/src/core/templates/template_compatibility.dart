import 'package:fly_cli/src/core/templates/compatibility_result.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:pub_semver/pub_semver.dart';

part 'template_compatibility.g.dart';

/// JSON converter for Version
class VersionConverter implements JsonConverter<Version?, String?> {
  const VersionConverter();

  @override
  Version? fromJson(String? json) => json != null ? Version.parse(json) : null;

  @override
  String? toJson(Version? object) => object?.toString();
}

/// JSON converter for VersionConstraint
class VersionConstraintConverter
    implements JsonConverter<VersionConstraint?, String?> {
  const VersionConstraintConverter();

  @override
  VersionConstraint? fromJson(String? json) {
    if (json == null) return null;
    try {
      return VersionConstraint.parse(json);
    } catch (_) {
      return null;
    }
  }

  @override
  String? toJson(VersionConstraint? object) => object?.toString();
}

/// Template compatibility requirements and metadata
@JsonSerializable(explicitToJson: true, includeIfNull: false)
class TemplateCompatibility {
  const TemplateCompatibility({
    this.cliMinVersion,
    this.cliMaxVersion,
    this.flutterMinSdk,
    this.dartMinSdk,
    this.deprecated = false,
    this.deprecationDate,
    this.eolDate,
  });

  /// Create from YAML map
  factory TemplateCompatibility.fromYaml(Map<dynamic, dynamic> yaml) {
    String? parseVersionString(String? value) {
      if (value == null || value.trim().isEmpty) return null;
      return value.trim();
    }

    Version? parseVersion(String? versionString) {
      if (versionString == null) return null;
      try {
        return Version.parse(versionString);
      } catch (_) {
        return null;
      }
    }

    VersionConstraint? parseVersionConstraint(String? constraintString) {
      if (constraintString == null) return null;
      try {
        return VersionConstraint.parse(constraintString.trim());
      } catch (_) {
        return null;
      }
    }

    DateTime? parseDate(String? dateString) {
      if (dateString == null || dateString.trim().isEmpty) return null;
      try {
        return DateTime.parse(dateString);
      } catch (_) {
        return null;
      }
    }

    final compatibility = yaml['compatibility'] as Map<dynamic, dynamic>? ?? {};
    final cliMin = parseVersionString(
      compatibility['cli_min_version'] as String?,
    );
    final cliMax = parseVersionString(
      compatibility['cli_max_version'] as String?,
    );
    final flutterMin = parseVersionString(
      compatibility['flutter_min_sdk'] as String?,
    );
    final dartMin = parseVersionString(
      compatibility['dart_min_sdk'] as String?,
    );

    final parsedCliMin = parseVersion(cliMin);
    final parsedCliMax = cliMax != null ? parseVersionConstraint(cliMax) : null;
    final parsedFlutterMin = parseVersion(flutterMin);
    final parsedDartMin = parseVersion(dartMin);
    final parsedDeprecationDate = parseDate(yaml['deprecation_date'] as String?);
    final parsedEolDate = parseDate(yaml['eol_date'] as String?);

    // Validate version constraints: min <= max if both specified
    if (parsedCliMin != null && parsedCliMax != null) {
      // Check if min version satisfies max constraint
      if (!parsedCliMax.allows(parsedCliMin)) {
        throw FormatException(
          'CLI version constraint invalid: min version $parsedCliMin '
          'does not satisfy max constraint ${parsedCliMax.toString()}',
        );
      }
    }

    // Validate dates: deprecation_date < eol_date if both set
    if (parsedDeprecationDate != null && parsedEolDate != null) {
      if (parsedDeprecationDate.isAfter(parsedEolDate)) {
        throw FormatException(
          'Date validation failed: deprecation_date (${parsedDeprecationDate.toIso8601String().split('T').first}) '
          'must be before eol_date (${parsedEolDate.toIso8601String().split('T').first})',
        );
      }
    }

    return TemplateCompatibility(
      cliMinVersion: parsedCliMin,
      cliMaxVersion: parsedCliMax,
      flutterMinSdk: parsedFlutterMin,
      dartMinSdk: parsedDartMin,
      deprecated: yaml['deprecated'] as bool? ?? false,
      deprecationDate: parsedDeprecationDate,
      eolDate: parsedEolDate,
    );
  }

  /// Create from JSON
  factory TemplateCompatibility.fromJson(Map<String, dynamic> json) =>
      _$TemplateCompatibilityFromJson(json);

  /// Minimum CLI version required (null means no minimum)
  @VersionConverter()
  final Version? cliMinVersion;

  /// Maximum CLI version allowed (null means no maximum)
  @VersionConstraintConverter()
  final VersionConstraint? cliMaxVersion;

  /// Minimum Flutter SDK version required
  @VersionConverter()
  final Version? flutterMinSdk;

  /// Minimum Dart SDK version required
  @VersionConverter()
  final Version? dartMinSdk;

  /// Whether this template is deprecated
  final bool deprecated;

  /// Date when template was deprecated
  final DateTime? deprecationDate;

  /// End of life date
  final DateTime? eolDate;

  /// Check compatibility with current environment
  CompatibilityResult checkCompatibility({
    required Version currentCliVersion,
    required Version currentFlutterVersion,
    required Version currentDartVersion,
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    // Check CLI version
    if (cliMinVersion != null) {
      if (currentCliVersion < cliMinVersion!) {
        errors.add(
          'CLI version $currentCliVersion is less than required '
          'minimum $cliMinVersion. '
          'Please upgrade Fly CLI to $cliMinVersion or later.',
        );
      }
    }

    if (cliMaxVersion != null) {
      if (!cliMaxVersion!.allows(currentCliVersion)) {
        errors.add(
          'CLI version $currentCliVersion is not compatible with this '
          'template. Required: ${cliMaxVersion.toString()}',
        );
      }
    }

    // Check Flutter SDK
    if (flutterMinSdk != null) {
      if (currentFlutterVersion < flutterMinSdk!) {
        errors.add(
          'Flutter SDK version $currentFlutterVersion is less than '
          'required minimum $flutterMinSdk. '
          'Please upgrade Flutter SDK: flutter upgrade',
        );
      }
    }

    // Check Dart SDK
    if (dartMinSdk != null) {
      if (currentDartVersion < dartMinSdk!) {
        errors.add(
          'Dart SDK version $currentDartVersion is less than required '
          'minimum $dartMinSdk. '
          'Please upgrade Dart SDK: dart upgrade',
        );
      }
    }

    // Check deprecation
    if (deprecated) {
      final deprecationMsg = deprecationDate != null
          ? ' (deprecated on ${deprecationDate!.toIso8601String().split('T').first})'
          : '';
      warnings.add(
        'This template is deprecated$deprecationMsg. '
        'Consider using a newer template version.',
      );
    }

    // Check EOL
    if (eolDate != null) {
      final now = DateTime.now();
      if (now.isAfter(eolDate!) || now.isAtSameMomentAs(eolDate!)) {
        errors.add(
          'This template reached end of life on '
          '${eolDate!.toIso8601String().split('T').first}. '
          'This template is no longer supported.',
        );
      } else {
        final daysUntilEol = eolDate!.difference(now).inDays;
        if (daysUntilEol >= 0) {
          warnings.add(
            'This template will reach end of life on '
            '${eolDate!.toIso8601String().split('T').first} '
            '($daysUntilEol days remaining). Consider migrating to a newer version.',
          );
        }
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

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$TemplateCompatibilityToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemplateCompatibility &&
          runtimeType == other.runtimeType &&
          cliMinVersion == other.cliMinVersion &&
          cliMaxVersion == other.cliMaxVersion &&
          flutterMinSdk == other.flutterMinSdk &&
          dartMinSdk == other.dartMinSdk &&
          deprecated == other.deprecated &&
          deprecationDate == other.deprecationDate &&
          eolDate == other.eolDate;

  @override
  int get hashCode => Object.hash(
    cliMinVersion,
    cliMaxVersion,
    flutterMinSdk,
    dartMinSdk,
    deprecated,
    deprecationDate,
    eolDate,
  );
}
