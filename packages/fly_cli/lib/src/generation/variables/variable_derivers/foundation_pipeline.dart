import 'package:fly_brick_composer/fly_brick_composer.dart';
import 'package:fly_cli/src/generation/variables/variable_derivers/feature_mode_deriver.dart';
import 'package:fly_cli/src/generation/variables/variable_derivers/naming_deriver.dart';
import 'package:fly_cli/src/generation/variables/variable_derivers/platform_deriver.dart';
import 'package:fly_cli/src/generation/variables/variable_derivers/preset_deriver.dart';
import 'package:fly_cli/src/generation/variables/variable_derivers/project_mode_deriver.dart';
import 'package:fly_cli/src/generation/variables/variable_derivers/service_mode_deriver.dart';

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
