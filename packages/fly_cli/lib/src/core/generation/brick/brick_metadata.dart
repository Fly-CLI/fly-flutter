import 'package:pub_semver/pub_semver.dart';

/// Brick category enumeration
enum BrickCategory {
  project,
  component,
  addon,
}

/// Brick type enumeration
enum BrickType {
  project,
  feature,
  service,
  component,
  custom,
}

/// Self-describing brick metadata loaded from brick.yaml
///
/// This replaces path-based type inference with explicit metadata
/// declared in the brick.yaml file.
class BrickMetadata {
  const BrickMetadata({
    required this.name,
    required this.version,
    required this.type,
    required this.category,
    required this.path,
    required this.description,
    required this.requiredVariables,
    required this.defaults,
    this.features = const [],
    this.packages = const [],
    this.minFlutterSdk,
    this.minDartSdk,
    this.isValid = true,
    this.validationErrors = const [],
  });

  /// Brick name
  final String name;

  /// Brick version
  final Version version;

  /// Brick type (from brick.yaml, not inferred)
  final BrickType type;

  /// Brick category (project | component | addon)
  final BrickCategory category;

  /// Absolute path to brick directory
  final String path;

  /// Brick description
  final String description;

  /// Required variables for this brick
  final List<String> requiredVariables;

  /// Default values for variables
  final Map<String, dynamic> defaults;

  /// Optional features this brick supports
  final List<String> features;

  /// Dependencies this brick requires
  final List<String> packages;

  /// Minimum Flutter SDK version required
  final Version? minFlutterSdk;

  /// Minimum Dart SDK version required
  final Version? minDartSdk;

  /// Whether this brick is valid
  final bool isValid;

  /// Validation errors if any
  final List<String> validationErrors;

  /// Create BrickMetadata from YAML data
  factory BrickMetadata.fromYaml(
    Map<dynamic, dynamic> yaml,
    String brickPath,
  ) {
    try {
      // Parse version
      final versionStr = yaml['version'] as String? ?? '1.0.0';
      final version = Version.parse(versionStr);

      // Parse type (required)
      final typeStr = yaml['type'] as String?;
      if (typeStr == null) {
        throw ArgumentError('Brick type is required in brick.yaml');
      }
      final type = _parseBrickType(typeStr);

      // Parse category (required)
      final categoryStr = yaml['category'] as String?;
      if (categoryStr == null) {
        throw ArgumentError('Brick category is required in brick.yaml');
      }
      final category = _parseBrickCategory(categoryStr);

      // Parse required variables
      final requiredVars = <String>[];
      final variables = yaml['variables'] as Map<String, dynamic>? ?? {};
      for (final entry in variables.entries) {
        final varName = entry.key;
        final varConfig = entry.value;
        if (varConfig is Map<String, dynamic>) {
          final isRequired = varConfig['required'] as bool? ?? false;
          if (isRequired) {
            requiredVars.add(varName);
          }
        }
      }

      // Parse defaults
      final defaults = <String, dynamic>{};
      for (final entry in variables.entries) {
        final varName = entry.key;
        final varConfig = entry.value;
        if (varConfig is Map<String, dynamic>) {
          final defaultValue = varConfig['default'];
          if (defaultValue != null) {
            defaults[varName] = defaultValue;
          }
        }
      }

      // Parse optional fields
      final features =
          (yaml['features'] as List<dynamic>?)?.cast<String>() ?? [];
      final packages =
          (yaml['packages'] as List<dynamic>?)?.cast<String>() ?? [];

      final minFlutterSdkStr = yaml['min_flutter_sdk'] as String?;
      final minFlutterSdk =
          minFlutterSdkStr != null ? Version.parse(minFlutterSdkStr) : null;

      final minDartSdkStr = yaml['min_dart_sdk'] as String?;
      final minDartSdk =
          minDartSdkStr != null ? Version.parse(minDartSdkStr) : null;

      return BrickMetadata(
        name: yaml['name'] as String? ?? '',
        version: version,
        type: type,
        category: category,
        path: brickPath,
        description: yaml['description'] as String? ?? '',
        requiredVariables: requiredVars,
        defaults: defaults,
        features: features,
        packages: packages,
        minFlutterSdk: minFlutterSdk,
        minDartSdk: minDartSdk,
      );
    } catch (e) {
      return BrickMetadata(
        name: yaml['name'] as String? ?? 'unknown',
        version: Version.parse('1.0.0'),
        type: BrickType.custom,
        category: BrickCategory.addon,
        path: brickPath,
        description: 'Invalid brick metadata',
        requiredVariables: const [],
        defaults: const {},
        isValid: false,
        validationErrors: ['Failed to parse brick metadata: $e'],
      );
    }
  }

  /// Parse brick type from string
  static BrickType _parseBrickType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'project':
        return BrickType.project;
      case 'feature':
        return BrickType.feature;
      case 'service':
        return BrickType.service;
      case 'component':
        return BrickType.component;
      case 'custom':
        return BrickType.custom;
      default:
        throw ArgumentError('Unknown brick type: $typeStr');
    }
  }

  /// Parse brick category from string
  static BrickCategory _parseBrickCategory(String categoryStr) {
    switch (categoryStr.toLowerCase()) {
      case 'project':
        return BrickCategory.project;
      case 'component':
        return BrickCategory.component;
      case 'addon':
        return BrickCategory.addon;
      default:
        throw ArgumentError('Unknown brick category: $categoryStr');
    }
  }

  /// Get variable value with fallback to default
  dynamic getVariable(String name, {dynamic defaultValue}) {
    return defaults[name] ?? defaultValue;
  }

  /// Check if a variable is required
  bool isVariableRequired(String name) {
    return requiredVariables.contains(name);
  }

  /// Get all variable names (required + optional)
  List<String> getAllVariables() {
    final allVars = <String>{};
    allVars.addAll(requiredVariables);
    allVars.addAll(defaults.keys);
    return allVars.toList();
  }

  /// Validate brick metadata
  BrickValidationResult validate() {
    final errors = <String>[];

    if (name.isEmpty) {
      errors.add('Brick name is required');
    }

    if (description.isEmpty) {
      errors.add('Brick description is required');
    }

    if (path.isEmpty) {
      errors.add('Brick path is required');
    }

    // Validate type and category consistency
    switch (category) {
      case BrickCategory.project:
        if (type != BrickType.project) {
          errors.add('Project category must have project type');
        }
        break;
      case BrickCategory.component:
        if (![BrickType.feature, BrickType.service, BrickType.component]
            .contains(type)) {
          errors.add(
              'Component category must have feature, service, or component type');
        }
        break;
      case BrickCategory.addon:
        if (type != BrickType.custom) {
          errors.add('Addon category must have custom type');
        }
        break;
    }

    return BrickValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: [],
    );
  }

  @override
  String toString() =>
      'BrickMetadata(name: $name, type: $type, category: $category, version: $version)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BrickMetadata &&
        other.name == name &&
        other.version == version &&
        other.type == type &&
        other.category == category &&
        other.path == path;
  }

  @override
  int get hashCode {
    return Object.hash(name, version, type, category, path);
  }
}

/// Brick validation result
class BrickValidationResult {
  const BrickValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  /// Create a successful validation result
  factory BrickValidationResult.success() => const BrickValidationResult(
    isValid: true,
    errors: [],
    warnings: [],
  );

  /// Create a failed validation result
  factory BrickValidationResult.failure(List<String> errors,
      [List<String>? warnings]) =>
      BrickValidationResult(
        isValid: false,
        errors: errors,
        warnings: warnings ?? [],
      );

  @override
  String toString() =>
      'BrickValidationResult(isValid: $isValid, errors: ${errors.length}, warnings: ${warnings.length})';
}
