import 'package:fly_foundation_planning/src/utils/logger.dart';
import 'package:fly_foundation_planning/src/variables/generation_context.dart';
import 'package:fly_foundation_planning/src/variables/variable_bag.dart';
import 'package:fly_foundation_planning/src/variables/variable_deriver.dart';

/// Pipeline that orchestrates variable derivation through a sequence of strategies.
///
/// The pipeline runs each deriver in order, passing the accumulated variable bag
/// from one deriver to the next. Only derivers that support the context (via
/// their `supports()` method) are executed.
class VariablePipeline {
  /// Ordered list of variable derivers to execute.
  final List<VariableDeriver> steps;

  /// Creates a variable pipeline with the given steps.
  const VariablePipeline(this.steps);

  /// Runs the pipeline to derive variables from a generation context.
  ///
  /// Steps execute in order, with each step receiving the bag produced by
  /// previous steps. Only steps that return true for `supports(ctx)` are executed.
  ///
  /// Returns a VariableBag containing all derived variables.
  VariableBag run(GenerationContext ctx, PlanningLogger logger) {
    var bag = VariableBag.empty();

    for (final step in steps) {
      if (step.supports(ctx)) {
        logger.detail('Running variable deriver: ${step.id}');
        try {
          bag = step.derive(ctx, bag, logger);
        } catch (e, stackTrace) {
          logger.err('Error in deriver "${step.id}": $e');
          rethrow;
        }
      } else {
        logger.detail('Skipping variable deriver: ${step.id} (not supported)');
      }
    }

    return bag;
  }
}

