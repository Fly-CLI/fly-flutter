import 'shared_derived_variables.dart';
import 'mode_specific_variables.dart';

/// Composed derived variables combining shared and mode-specific variables.
///
/// This class is the main result of the variable derivation process, containing
/// both shared variables (common across all modes) and mode-specific variables
/// (unique to project, feature, or service modes).
class ComposedDerivedVariables {
  const ComposedDerivedVariables({
    required this.shared,
    required this.modeSpecific,
  });

  /// Shared variables common to all modes.
  final SharedDerivedVariables shared;

  /// Mode-specific variables (one of ProjectVariables, FeatureVariables, or ServiceVariables).
  final ModeSpecificVariables modeSpecific;

  /// Converts to a Mason variables map by merging shared and mode-specific variables.
  Map<String, dynamic> toMasonVars() {
    final result = <String, dynamic>{};
    result.addAll(shared.toMasonVars());
    result.addAll(modeSpecific.toMasonVars());
    return result;
  }

  /// Creates a copy with updated fields.
  ComposedDerivedVariables copyWith({
    SharedDerivedVariables? shared,
    ModeSpecificVariables? modeSpecific,
  }) {
    return ComposedDerivedVariables(
      shared: shared ?? this.shared,
      modeSpecific: modeSpecific ?? this.modeSpecific,
    );
  }
}

