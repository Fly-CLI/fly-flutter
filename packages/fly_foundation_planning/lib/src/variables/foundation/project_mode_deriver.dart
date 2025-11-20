import 'package:fly_foundation_planning/src/foundation_model.dart';
import 'package:fly_foundation_planning/src/logger.dart';
import 'package:fly_foundation_planning/src/mason_variable_keys.dart';
import 'package:fly_foundation_planning/src/variables/generation_context.dart';
import 'package:fly_foundation_planning/src/variables/variable_bag.dart';
import 'package:fly_foundation_planning/src/variables/variable_deriver.dart';

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

