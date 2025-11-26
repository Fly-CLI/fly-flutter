import 'package:fly_brick_composer/fly_brick_composer.dart';
import 'package:fly_cli/src/generation/application/ports/ivariable_processor.dart';
import 'package:fly_cli/src/generation/domain/entities/brick.dart';
import 'package:fly_cli/src/generation/variables/validation/variable_validation_service.dart';
import 'package:fly_cli/src/generation/variables/variable_derivers/naming_deriver.dart';
import 'package:fly_cli/src/generation/variables/variable_derivers/platform_deriver.dart';
import 'package:fly_cli/src/generation/variables/variable_derivers/preset_deriver.dart';
import 'package:fly_cli/src/generation/variables/variable_derivers/project_mode_deriver.dart';

/// Default project variable pipeline.
///
/// This is the standard pipeline used for project generation.
const projectPipeline = VariablePipeline([
  NamingDeriver(),
  PlatformDeriver(),
  PresetDeriver(),
  ProjectModeDeriver(),
]);

/// Processor for project generation mode variables.
///
/// Handles variable derivation and validation specifically for project generation.
/// Uses a project-specific pipeline that includes platform support derivation.
class ProjectVariableProcessor implements IVariableProcessor {
  /// Creates a new instance of [ProjectVariableProcessor].
  ProjectVariableProcessor({
    VariablePipeline? pipeline,
    ComposerLogger? logger,
  }) : _pipeline = pipeline ?? projectPipeline,
       _logger = logger ?? const NoOpLogger();

  final VariablePipeline _pipeline;
  final ComposerLogger _logger;

  @override
  Future<ProcessedVariables> process({
    required Map<String, dynamic> rawVars,
    required GenerationMode mode,
    required Brick brick,
  }) async {
    // Validate that this processor handles project mode
    if (mode != GenerationMode.project) {
      throw ArgumentError(
        'ProjectVariableProcessor only handles GenerationMode.project, '
        'but received ${mode.key}',
      );
    }

    // 1. Create GenerationContext from raw variables and mode
    final context = GenerationContext.fromVars(
      rawVars,
      mode: mode,
    );

    // 2. Start with raw variables in the bag
    var bag = VariableBag.fromMap(rawVars);

    // 3. Run the project-specific pipeline to derive additional variables
    try {
      bag = _pipeline.run(context, _logger);
    } catch (e) {
      // If pipeline fails, log and continue with raw vars
      _logger.warn('Project variable pipeline failed: $e');
      // Continue with raw variables
    }

    // 4. Convert VariableBag back to Map and merge with raw vars
    // (Derivers add to the bag, so we merge to preserve any raw vars not in bag)
    final processed = {
      ...rawVars,
      ...bag.toMap(),
    };

    // 5. Validate variables using project-specific validation
    final validationErrors = VariableValidationService.validateAll(
      brick: brick,
      mode: mode,
      variables: processed,
    );

    final validationResult = validationErrors.isEmpty
        ? VariableValidationResult.success()
        : VariableValidationResult.failure(validationErrors);

    return ProcessedVariables(
      values: processed,
      validationResult: validationResult,
    );
  }
}
