import 'package:fly_foundation_planning/src/utils/logger.dart';
import 'package:fly_foundation_planning/src/variables/generation_context.dart';
import 'package:fly_foundation_planning/src/variables/variable_bag.dart';

/// Strategy interface for variable derivation.
///
/// Each deriver implements domain-specific logic to compute variables from
/// a generation context and current variable bag state. Derivers are composed
/// into pipelines where they run in sequence, each potentially modifying the bag.
abstract class VariableDeriver {
  /// Unique identifier for this deriver (for logging and debugging).
  String get id;

  /// Determines whether this deriver should run for the given context.
  ///
  /// This allows derivers to be conditional based on mode, workflow, or
  /// any other context properties. Returning false means the deriver is skipped.
  bool supports(GenerationContext ctx);

  /// Derives variables from the context and current bag state.
  ///
  /// Receives the current variable bag (which may have been modified by
  /// previous derivers) and returns a new bag with additional or modified values.
  ///
  /// [ctx] - The generation context with raw input and metadata
  /// [current] - The current state of the variable bag
  /// [logger] - Logger for debug/info messages
  ///
  /// Returns a new VariableBag with derived values. Should not mutate [current].
  VariableBag derive(
    GenerationContext ctx,
    VariableBag current,
    PlanningLogger logger,
  );
}

