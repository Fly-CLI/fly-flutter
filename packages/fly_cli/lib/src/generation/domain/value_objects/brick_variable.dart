import 'package:json_annotation/json_annotation.dart';

part 'brick_variable.g.dart';

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

