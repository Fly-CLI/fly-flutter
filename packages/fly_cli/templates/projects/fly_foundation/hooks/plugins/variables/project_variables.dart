import 'mode_specific_variables.dart';
import '../foundation_model.dart';
import '../mason_variable_keys.dart';

/// Project-specific derived variables.
///
/// Note: Platform flags (supports_ios, supports_android, etc.) are derived
/// by PlatformPlanner and stored in SharedDerivedVariables, not here.
/// This class only contains project-mode-specific flags.
final class ProjectVariables extends ModeSpecificVariables {
  const ProjectVariables({
    this.isProject = true,
  });

  /// Whether this is a project generation (vs feature or service).
  final bool isProject;

  @override
  GenerationMode get mode => GenerationMode.project;

  @override
  Map<String, dynamic> toMasonVars() {
    return {
      MasonVarKey.isProject.key: isProject,
    };
  }

  /// Creates a copy with updated fields.
  ProjectVariables copyWith({
    bool? isProject,
  }) {
    return ProjectVariables(
      isProject: isProject ?? this.isProject,
    );
  }
}

