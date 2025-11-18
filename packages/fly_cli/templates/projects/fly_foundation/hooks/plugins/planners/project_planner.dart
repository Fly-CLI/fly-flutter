import 'package:mason/mason.dart';
import '../foundation_model.dart';
import '../variables/mode_specific_variables.dart';
import '../variables/project_variables.dart';
import 'mode_specific_planner.dart';

/// Planner that derives project-specific variables.
///
/// Note: Platform flags (supports_ios, supports_android, etc.) are derived
/// by PlatformPlanner (a cross-cutting planner) and stored in SharedDerivedVariables.
/// This planner only handles project-mode-specific variables.
class ProjectPlanner implements ModeSpecificPlanner {
  @override
  GenerationMode get supportedMode => GenerationMode.project;

  @override
  ProjectVariables derive(
    BaseTemplateVariables base,
    Logger logger,
  ) {
    return const ProjectVariables(
      isProject: true,
    );
  }
}

