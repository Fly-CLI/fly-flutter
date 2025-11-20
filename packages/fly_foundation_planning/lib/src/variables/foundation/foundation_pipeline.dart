import 'package:fly_foundation_planning/src/variables/foundation/feature_mode_deriver.dart';
import 'package:fly_foundation_planning/src/variables/foundation/naming_deriver.dart';
import 'package:fly_foundation_planning/src/variables/foundation/platform_deriver.dart';
import 'package:fly_foundation_planning/src/variables/foundation/preset_deriver.dart';
import 'package:fly_foundation_planning/src/variables/foundation/project_mode_deriver.dart';
import 'package:fly_foundation_planning/src/variables/foundation/service_mode_deriver.dart';
import 'package:fly_foundation_planning/src/variables/variable_pipeline.dart';

/// Default foundation variable pipeline.
///
/// This pipeline contains the standard derivation steps for Fly foundation
/// project generation. It can be used directly or composed with additional
/// custom derivers.
const foundationPipeline = VariablePipeline([
  NamingDeriver(),
  PlatformDeriver(),
  PresetDeriver(),
  ProjectModeDeriver(),
  FeatureModeDeriver(),
  ServiceModeDeriver(),
]);

/// Creates the default foundation variable pipeline.
///
/// This is a convenience function that returns the standard pipeline.
/// Users can also create custom pipelines by composing derivers directly.
VariablePipeline createFoundationPipeline() {
  return foundationPipeline;
}

