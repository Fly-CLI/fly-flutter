import 'package:fly_brick_composer/fly_brick_composer.dart';
import 'package:fly_cli/src/core/generation/utils/mason_variable_keys.dart';

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
    ComposerLogger logger,
  ) {
    return current.set(MasonVarKey.isProject.key, true);
  }
}

