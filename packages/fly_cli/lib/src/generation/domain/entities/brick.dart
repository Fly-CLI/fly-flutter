import 'package:fly_cli/src/generation/brick/brick_metadata.dart' show BrickCategory, BrickType;
import 'package:fly_cli/src/generation/domain/value_objects/brick_variable.dart';
import 'package:fly_cli/src/generation/template/template_compatibility.dart' show NonNullableVersionConverter, VersionConverter;
import 'package:json_annotation/json_annotation.dart';
import 'package:pub_semver/pub_semver.dart';

part 'brick.g.dart';

/// Unified brick entity for the domain layer.
///
/// This is the primary domain entity for representing bricks.
/// It is created directly from YAML files and used throughout the application.
@JsonSerializable(explicitToJson: true, includeIfNull: false)
class Brick {
  const Brick({
    required this.name,
    required this.version,
    required this.description,
    required this.path,
    required this.type,
    required this.category,
    required this.variables,
    required this.features,
    required this.packages,
    this.minFlutterSdk,
    this.minDartSdk,
    this.isValid = true,
    this.validationErrors = const [],
  });

  /// Create Brick from JSON.
  factory Brick.fromJson(Map<String, dynamic> json) =>
      _$BrickFromJson(json);

  /// Create Brick directly from YAML data.
  ///
  /// This is the primary factory method for creating Brick entities
  /// from brick.yaml files.
  factory Brick.fromYaml(
    Map<dynamic, dynamic> yaml,
    String brickPath,
  ) {
    // Helper to treat empty strings as null
    String? nonEmptyString(dynamic value) {
      final str = value as String?;
      return (str != null && str.trim().isNotEmpty) ? str : null;
    }

    // Parse version
    final versionStr = nonEmptyString(yaml['version']) ?? '1.0.0';
    final version = Version.parse(versionStr);

    // Parse type (required field)
    final typeStr = yaml['type'] as String?;
    if (typeStr == null || typeStr.trim().isEmpty) {
      throw ArgumentError(
        'Brick type is required. '
        'Add a "type" field to fly_metadata.yaml with one of: project, feature, service, component, custom',
      );
    }
    final brickType = _parseBrickTypeFromString(typeStr);

    // Parse category (required field)
    final categoryStr = yaml['category'] as String?;
    BrickCategory brickCategory;
    if (categoryStr != null && categoryStr.trim().isNotEmpty) {
      brickCategory = _parseBrickCategoryFromString(categoryStr);
    } else {
      // Infer category from type if not provided
      brickCategory = _inferCategory(brickType);
    }

    // Parse variables from vars section
    final varsSection = yaml['vars'] as Map<dynamic, dynamic>? ?? {};
    final variables = <String, BrickVariable>{};

    for (final entry in varsSection.entries) {
      final key = entry.key as String;
      final value = entry.value as Map<dynamic, dynamic>;

      variables[key] = BrickVariable(
        name: key,
        type: value['type'] as String? ?? 'string',
        required: value['required'] as bool? ?? false,
        defaultValue: value['default']?.toString(),
        choices: (value['choices'] as List<dynamic>?)?.cast<String>(),
        description: value['description'] as String?,
        prompt: value['prompt'] as String?,
      );
    }

    return Brick(
      name: yaml['name'] as String? ?? '',
      version: version,
      description: nonEmptyString(yaml['description']) ?? '',
      path: brickPath,
      type: brickType,
      category: brickCategory,
      variables: variables,
      features: (yaml['features'] as List<dynamic>? ?? []).cast<String>(),
      packages: (yaml['packages'] as List<dynamic>? ?? []).cast<String>(),
      minFlutterSdk: _tryParseVersion(nonEmptyString(yaml['min_flutter_sdk'])),
      minDartSdk: _tryParseVersion(nonEmptyString(yaml['min_dart_sdk'])),
    );
  }

  /// Parse brick type from string.
  static BrickType _parseBrickTypeFromString(String typeStr) {
    switch (typeStr.toLowerCase().trim()) {
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
        throw ArgumentError(
          'Invalid brick type: "$typeStr". '
          'Must be one of: project, feature, service, component, custom',
        );
    }
  }

  /// Parse brick category from string.
  static BrickCategory _parseBrickCategoryFromString(String categoryStr) {
    switch (categoryStr.toLowerCase().trim()) {
      case 'project':
        return BrickCategory.project;
      case 'component':
        return BrickCategory.component;
      case 'addon':
        return BrickCategory.addon;
      default:
        throw ArgumentError(
          'Invalid brick category: "$categoryStr". '
          'Must be one of: project, component, addon',
        );
    }
  }

  /// Helper to safely parse version strings.
  static Version? _tryParseVersion(String? versionStr) {
    if (versionStr == null || versionStr.isEmpty) return null;
    try {
      return Version.parse(versionStr);
    } catch (_) {
      return null;
    }
  }

  /// Infer category from brick type.
  static BrickCategory _inferCategory(BrickType type) {
    switch (type) {
      case BrickType.project:
        return BrickCategory.project;
      case BrickType.feature:
      case BrickType.service:
      case BrickType.component:
        return BrickCategory.component;
      case BrickType.custom:
        return BrickCategory.addon;
    }
  }

  /// Brick name
  final String name;

  /// Brick version (using pub_semver Version)
  @NonNullableVersionConverter()
  final Version version;

  /// Brick description
  final String description;

  /// Path to the brick directory
  final String path;

  /// Brick type
  final BrickType type;

  /// Brick category
  final BrickCategory category;

  /// Brick variables
  final Map<String, BrickVariable> variables;

  /// List of features included in this brick
  final List<String> features;

  /// List of packages used by this brick
  final List<String> packages;

  /// Minimum Flutter SDK version required
  @VersionConverter()
  final Version? minFlutterSdk;

  /// Minimum Dart SDK version required
  @VersionConverter()
  final Version? minDartSdk;

  /// Whether the brick passed validation
  final bool isValid;

  /// Validation errors if any
  final List<String> validationErrors;

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$BrickToJson(this);

  /// Get brick directory path
  String get brickDirectory => path;

  /// Get __brick__ directory path
  String get brickContentPath => '$path/__brick__';

  /// Check if brick has a specific variable
  bool hasVariable(String variableName) => variables.containsKey(variableName);

  /// Get variable by name
  BrickVariable? getVariable(String variableName) => variables[variableName];

  /// Get required variables
  List<BrickVariable> get requiredVariables =>
      variables.values.where((v) => v.required).toList();

  /// Get optional variables
  List<BrickVariable> get optionalVariables =>
      variables.values.where((v) => !v.required).toList();

  /// Check if a variable is required
  bool isVariableRequired(String name) {
    return variables[name]?.required ?? false;
  }

  /// Get variable value with fallback to default
  dynamic getVariableValue(String name, {dynamic defaultValue}) {
    final variable = variables[name];
    return variable?.defaultValue ?? defaultValue;
  }

  @override
  String toString() =>
      'Brick(name: $name, type: $type, category: $category, version: $version)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Brick &&
        other.name == name &&
        other.type == type &&
        other.category == category &&
        other.version == version &&
        other.path == path;
  }

  @override
  int get hashCode =>
      Object.hash(name, type, category, version, path);
}

