import 'package:json_annotation/json_annotation.dart';
import 'package:yaml/yaml.dart';

part 'brick_info.g.dart';

/// Enum representing different types of Mason bricks
enum BrickType {
  project,
  screen,
  service,
  component,
  custom,
}

/// Metadata container for individual Mason bricks
@JsonSerializable(explicitToJson: true, includeIfNull: false)
class BrickInfo {
  const BrickInfo({
    required this.name,
    required this.version,
    required this.description,
    required this.path,
    required this.type,
    required this.variables,
    required this.features,
    required this.packages,
    required this.minFlutterSdk,
    required this.minDartSdk,
    this.isValid = true,
    this.validationErrors = const [],
  });

  /// Create BrickInfo from brick.yaml content
  factory BrickInfo.fromYaml(
      Map<dynamic, dynamic> yaml, String brickPath, BrickType type) {
    // Helper to treat empty strings as null
    String? nonEmptyString(dynamic value) {
      final str = value as String?;
      return (str != null && str.trim().isNotEmpty) ? str : null;
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

    return BrickInfo(
      name: yaml['name'] as String? ?? '',
      version: nonEmptyString(yaml['version']) ?? '1.0.0',
      description: nonEmptyString(yaml['description']) ?? '',
      path: brickPath,
      type: type,
      variables: variables,
      features: (yaml['features'] as List<dynamic>? ?? []).cast<String>(),
      packages: (yaml['packages'] as List<dynamic>? ?? []).cast<String>(),
      minFlutterSdk: nonEmptyString(yaml['min_flutter_sdk']) ?? '3.10.0',
      minDartSdk: nonEmptyString(yaml['min_dart_sdk']) ?? '3.0.0',
    );
  }

  /// Create BrickInfo from JSON
  factory BrickInfo.fromJson(Map<String, dynamic> json) =>
      _$BrickInfoFromJson(json);

  /// Brick name
  final String name;

  /// Brick version
  final String version;

  /// Brick description
  final String description;

  /// Path to the brick directory
  final String path;

  /// Type of brick
  final BrickType type;

  /// Brick variables
  final Map<String, BrickVariable> variables;

  /// List of features included in this brick
  final List<String> features;

  /// List of packages used by this brick
  final List<String> packages;

  /// Minimum Flutter SDK version required
  @JsonKey(name: 'minFlutterSdk')
  final String minFlutterSdk;

  /// Minimum Dart SDK version required
  @JsonKey(name: 'minDartSdk')
  final String minDartSdk;

  /// Whether the brick passed validation
  @JsonKey(name: 'isValid')
  final bool isValid;

  /// Validation errors if any
  @JsonKey(name: 'validationErrors')
  final List<String> validationErrors;

  /// Convert BrickInfo to JSON for caching
  Map<String, dynamic> toJson() => _$BrickInfoToJson(this);

  /// Get brick directory path (where __brick__ folder is located)
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

  @override
  String toString() => 'BrickInfo(name: $name, type: $type, version: $version)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BrickInfo &&
        other.name == name &&
        other.type == type &&
        other.version == version &&
        other.path == path;
  }

  @override
  int get hashCode =>
      name.hashCode ^ type.hashCode ^ version.hashCode ^ path.hashCode;
}

/// Represents a brick variable
@JsonSerializable(explicitToJson: true, includeIfNull: false)
class BrickVariable {
  const BrickVariable({
    required this.name,
    required this.type,
    required this.required,
    this.defaultValue,
    this.choices,
    this.description,
    this.prompt,
  });

  /// Create BrickVariable from JSON
  factory BrickVariable.fromJson(Map<String, dynamic> json) =>
      _$BrickVariableFromJson(json);

  /// Variable name
  final String name;

  /// Variable type (string, list, bool, etc.)
  final String type;

  /// Whether this variable is required
  final bool required;

  /// Default value for the variable
  final String? defaultValue;

  /// Available choices for the variable
  final List<String>? choices;

  /// Variable description
  final String? description;

  /// Prompt text for interactive mode
  final String? prompt;

  /// Convert BrickVariable to JSON
  Map<String, dynamic> toJson() => _$BrickVariableToJson(this);

  @override
  String toString() =>
      'BrickVariable(name: $name, type: $type, required: $required)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BrickVariable &&
        other.name == name &&
        other.type == type &&
        other.required == required;
  }

  @override
  int get hashCode => name.hashCode ^ type.hashCode ^ required.hashCode;
}
