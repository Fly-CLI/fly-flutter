import 'package:fly_foundation_planning/fly_foundation_planning.dart';
import 'package:fly_cli/src/core/templates/mason_variable_keys.dart';

/// Deriver that sets project-mode-specific variables.
class ProjectModeDeriver implements VariableDeriver {
  const ProjectModeDeriver();

  @override
  String get id => 'project_mode';

  @override
  bool supports(GenerationContext ctx) =>
      ctx.mode == GenerationMode.project;

  @override
  VariableBag derive(
    GenerationContext ctx,
    VariableBag current,
    PlanningLogger logger,
  ) {
    return current.set(MasonVarKey.isProject.key, true);
  }
}

