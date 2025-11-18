import '../foundation_model.dart';
import '../mason_variable_keys.dart';

/// Sealed class for mode-specific variables.
///
/// This sealed class ensures type safety by allowing only one of the three
/// mode-specific variable types: ProjectVariables, FeatureVariables, or ServiceVariables.
abstract class ModeSpecificVariables {
  const ModeSpecificVariables();

  /// The generation mode this variable set represents.
  GenerationMode get mode;

  /// Converts to a Mason variables map.
  Map<String, dynamic> toMasonVars();
}

