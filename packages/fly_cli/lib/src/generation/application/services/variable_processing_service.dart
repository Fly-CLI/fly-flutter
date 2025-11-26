import 'package:fly_brick_composer/fly_brick_composer.dart';
import 'package:fly_cli/src/generation/application/ports/ivariable_processor.dart';
import 'package:fly_cli/src/generation/domain/entities/brick.dart';
import 'package:fly_cli/src/generation/variables/validation/variable_validation_service.dart';
import 'package:fly_cli/src/generation/variables/variable_derivers/foundation_pipeline.dart';

/// Service for processing variables through the derivation and validation pipeline.
///
/// Implements IVariableProcessor and coordinates variable derivers
/// and validation services.
class VariableProcessingService implements IVariableProcessor {
  /// Creates a new instance of [VariableProcessingService].
  VariableProcessingService({
    VariablePipeline? pipeline,
    ComposerLogger? logger,
  }) : _pipeline = pipeline ?? foundationPipeline,
       _logger = logger ?? const NoOpLogger();

  final VariablePipeline _pipeline;
  final ComposerLogger _logger;

  @override
  Future<ProcessedVariables> process({
    required Map<String, dynamic> rawVars,
    required GenerationMode mode,
    required Brick brick,
  }) async {
    // 1. Create GenerationContext from raw variables and mode
    // GenerationMode is re-exported from fly_brick_composer, so types match
    final context = GenerationContext.fromVars(
      rawVars,
      mode: mode,
    );

    // 2. Start with raw variables in the bag
    var bag = VariableBag.fromMap(rawVars);

    // 3. Run the pipeline to derive additional variables
    try {
      bag = _pipeline.run(context, _logger);
    } catch (e) {
      // If pipeline fails, log and continue with raw vars
      _logger.warn('Variable pipeline failed: $e');
      // Continue with raw variables
    }

    // 4. Convert VariableBag back to Map and merge with raw vars
    // (Derivers add to the bag, so we merge to preserve any raw vars not in bag)
    final processed = {
      ...rawVars,
      ...bag.toMap(),
    };

    // 5. Validate variables
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
