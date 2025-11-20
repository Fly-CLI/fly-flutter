import 'package:fly_foundation_planning/src/foundation_model.dart';

/// Minimal core template input variables for domain-agnostic planning.
///
/// This class contains only the universally meaningful fields needed by
/// the planning infrastructure, without any domain-specific concerns.
class CoreTemplateInput {
  const CoreTemplateInput({
    required this.name,
    required this.organization,
    required this.generationMode,
    required this.platforms,
    this.description = '',
  });

  /// Project/component name.
  final String name;

  /// Organization identifier (e.g., 'com.example').
  final String organization;

  /// Generation mode (project, feature, service).
  final GenerationMode generationMode;

  /// List of target platforms as string identifiers.
  final List<String> platforms;

  /// Optional project description.
  final String description;

  /// Converts to a map representation.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'organization': organization,
      'generation_mode': generationMode.key,
      'platforms': platforms,
      if (description.isNotEmpty) 'description': description,
    };
  }
}

