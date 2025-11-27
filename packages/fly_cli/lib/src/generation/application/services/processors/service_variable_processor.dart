import 'package:fly_brick_composer/fly_brick_composer.dart';
import 'package:fly_cli/src/generation/application/ports/ivariable_processor.dart';
import 'package:fly_cli/src/generation/domain/entities/brick.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';
import 'package:fly_cli/src/generation/variables/validation/ivariable_validator.dart';
import 'package:fly_cli/src/generation/variables/validation/service_variable_validator.dart';
import 'package:fly_cli/src/generation/variables/variable_derivers/naming_deriver.dart';
import 'package:fly_cli/src/generation/variables/variable_derivers/preset_deriver.dart';
import 'package:fly_cli/src/generation/variables/variable_derivers/service_mode_deriver.dart';

/// Default service variable pipeline.
///
/// This is the standard pipeline used for service generation.
const servicePipeline = VariablePipeline([
  NamingDeriver(),
  PresetDeriver(),
  ServiceModeDeriver(),
]);

/// Processor for service generation mode variables.
///
/// Handles variable derivation and validation specifically for service generation.
/// Uses a service-specific pipeline that excludes platform derivation.
class ServiceVariableProcessor implements IVariableProcessor {
  /// Creates a new instance of [ServiceVariableProcessor].
  ServiceVariableProcessor({
    VariablePipeline? pipeline,
    ComposerLogger? logger,
    IVariableValidator? validator,
  }) : _pipeline = pipeline ?? servicePipeline,
       _logger = logger ?? const NoOpLogger(),
       _validator = validator ?? ServiceVariableValidator();

  final VariablePipeline _pipeline;
  final ComposerLogger _logger;
  final IVariableValidator _validator;

  @override
  Future<ProcessedVariables> process({
    required Map<String, dynamic> rawVars,
    required GenerationMode mode,
    required Brick brick,
  }) async {
    // Validate that this processor handles service mode
    if (mode != GenerationMode.service) {
      throw ArgumentError(
        'ServiceVariableProcessor only handles GenerationMode.service, '
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

    // 3. Run the service-specific pipeline to derive additional variables
    try {
      bag = _pipeline.run(context, _logger);
    } catch (e) {
      // If pipeline fails, log and continue with raw vars
      _logger.warn('Service variable pipeline failed: $e');
      // Continue with raw variables
    }

    // 4. Convert VariableBag back to Map and merge with raw vars
    // (Derivers add to the bag, so we merge to preserve any raw vars not in bag)
    final processed = {
      ...rawVars,
      ...bag.toMap(),
    };

    // 5. Validate variables using service-specific validation
    final validationErrors = _validator.validateAll(
      brick: brick,
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
