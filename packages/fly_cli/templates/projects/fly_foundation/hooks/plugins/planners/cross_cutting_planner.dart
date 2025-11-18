import 'package:mason/mason.dart';
import '../foundation_model.dart';
import '../variables/shared_derived_variables.dart';

/// Interface for planners that derive cross-cutting variables.
///
/// Cross-cutting planners handle variables that are shared across all modes,
/// such as naming variants, platform flags, and template metadata.
abstract class CrossCuttingPlanner {
  /// Determines if this planner can handle the given base variables.
  bool canHandle(BaseTemplateVariables base);

  /// Derives shared variables from base template variables.
  ///
  /// The [acc] parameter contains the accumulated shared variables from
  /// previous cross-cutting planners, allowing for sequential composition.
  SharedDerivedVariables derive(
    BaseTemplateVariables base,
    SharedDerivedVariables acc,
    Logger logger,
  );
}

