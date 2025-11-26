import 'package:fly_brick_composer/fly_brick_composer.dart';
import 'package:fly_cli/src/generation/application/ports/ivariable_processor.dart';
import 'package:fly_cli/src/generation/domain/entities/brick.dart';
import 'package:fly_cli/src/generation/variables/validation/variable_validation_service.dart';
import 'package:fly_cli/src/generation/variables/variable_derivers/feature_mode_deriver.dart';
import 'package:fly_cli/src/generation/variables/variable_derivers/naming_deriver.dart';
import 'package:fly_cli/src/generation/variables/variable_derivers/preset_deriver.dart';

/// Default feature variable pipeline.
///
/// This is the standard pipeline used for feature (screen) generation.
const featurePipeline = VariablePipeline([
  NamingDeriver(),
  PresetDeriver(),
  FeatureModeDeriver(),
]);

/// Processor for feature (screen) generation mode variables.
///
/// Handles variable derivation and validation specifically for feature generation.
/// Uses a feature-specific pipeline that excludes platform derivation.
class FeatureVariableProcessor implements IVariableProcessor {
  /// Creates a new instance of [FeatureVariableProcessor].
  FeatureVariableProcessor({
    VariablePipeline? pipeline,
    ComposerLogger? logger,
  }) : _pipeline = pipeline ?? featurePipeline,
       _logger = logger ?? const NoOpLogger();

  final VariablePipeline _pipeline;
  final ComposerLogger _logger;

  @override
  Future<ProcessedVariables> process({
    required Map<String, dynamic> rawVars,
    required GenerationMode mode,
    required Brick brick,
  }) async {
    // Validate that this processor handles feature mode
    if (mode != GenerationMode.feature) {
      throw ArgumentError(
        'FeatureVariableProcessor only handles GenerationMode.feature, '
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

    // 3. Run the feature-specific pipeline to derive additional variables
    try {
      bag = _pipeline.run(context, _logger);
    } catch (e) {
      // If pipeline fails, log and continue with raw vars
      _logger.warn('Feature variable pipeline failed: $e');
      // Continue with raw variables
    }

    // 4. Convert VariableBag back to Map and merge with raw vars
    // (Derivers add to the bag, so we merge to preserve any raw vars not in bag)
    final processed = {
      ...rawVars,
      ...bag.toMap(),
    };

    // 5. Validate variables using feature-specific validation
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
