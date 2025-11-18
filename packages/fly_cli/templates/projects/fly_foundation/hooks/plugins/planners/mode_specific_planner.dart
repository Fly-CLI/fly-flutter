import 'package:mason/mason.dart';
import '../foundation_model.dart';
import '../variables/mode_specific_variables.dart';

/// Interface for planners that derive mode-specific variables.
///
/// Each mode (project, feature, service) has a corresponding planner that
/// implements this interface to derive mode-specific variables.
abstract class ModeSpecificPlanner {
  /// The generation mode this planner supports.
  GenerationMode get supportedMode;

  /// Derives mode-specific variables from base template variables.
  ModeSpecificVariables derive(
    BaseTemplateVariables base,
    Logger logger,
  );
}

