/// Template variable model
class TemplateVariable {
  const TemplateVariable({
    required this.name,
    required this.type,
    required this.required,
    this.defaultValue,
    this.choices,
    this.description,
  });
  
  final String name;
  final String type;
  final bool required;
  final String? defaultValue;
  final List<String>? choices;
  final String? description;

  /// Convert TemplateVariable to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'required': required,
      'default': defaultValue,
      'choices': choices,
      'description': description,
    };
  }

  /// Create TemplateVariable from JSON
  factory TemplateVariable.fromJson(Map<String, dynamic> json) {
    return TemplateVariable(
      name: json['name'] as String,
      type: json['type'] as String,
      required: json['required'] as bool,
      defaultValue: json['default'] as String?,
      choices: (json['choices'] as List?)?.cast<String>(),
      description: json['description'] as String?,
    );
  }
}
