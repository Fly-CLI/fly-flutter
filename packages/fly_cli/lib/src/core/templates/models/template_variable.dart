import 'package:json_annotation/json_annotation.dart';

part 'template_variable.g.dart';

/// Template variable model
@JsonSerializable(explicitToJson: true, includeIfNull: false)
class TemplateVariable {
  const TemplateVariable({
    required this.name,
    required this.type,
    required this.required,
    this.defaultValue,
    this.choices,
    this.description,
  });

  /// Create TemplateVariable from JSON
  factory TemplateVariable.fromJson(Map<String, dynamic> json) =>
      _$TemplateVariableFromJson(json);
  
  final String name;
  final String type;
  final bool required;
  
  @JsonKey(name: 'default')
  final String? defaultValue;
  final List<String>? choices;
  final String? description;

  /// Convert TemplateVariable to JSON
  Map<String, dynamic> toJson() => _$TemplateVariableToJson(this);
}
