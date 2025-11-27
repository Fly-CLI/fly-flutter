import 'package:fly_cli/src/generation/application/modes/generation_mode_profile.dart';
import 'package:fly_cli/src/generation/application/ports/ivariable_processor.dart';
import 'package:fly_cli/src/generation/application/ports/ivariable_processor_factory.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';

/// Factory implementation for variable processor resolution.
///
/// Maintains a registry of processors mapped by generation mode.
/// Implements the Registry pattern to provide mode-specific processor
/// resolution.
///
/// This factory uses mode profiles as the single source of truth,
/// ensuring consistency with the generation mode registry.
class VariableProcessorFactory implements IVariableProcessorFactory {
  /// Creates a new instance of [VariableProcessorFactory] from mode profiles.
  ///
  /// This constructor uses the centralized mode profiles as the single source
  /// of truth, ensuring consistency with the generation mode registry.
  ///
  /// [profiles] is a map of generation modes to their corresponding profiles.
  /// Each profile contains the variable processor for that mode.
  ///
  /// Throws [ArgumentError] if [profiles] is empty.
  VariableProcessorFactory.fromProfiles(
    Map<GenerationMode, GenerationModeProfile> profiles,
  ) {
    if (profiles.isEmpty) {
      throw ArgumentError('Cannot create factory with empty profiles map');
    }

    final processors = <GenerationMode, IVariableProcessor>{};
    for (final entry in profiles.entries) {
      processors[entry.key] = entry.value.variableProcessor;
    }
    _processors = Map<GenerationMode, IVariableProcessor>.unmodifiable(
      processors,
    );
  }

  late final Map<GenerationMode, IVariableProcessor> _processors;

  @override
  IVariableProcessor getProcessor(GenerationMode mode) {
    final processor = _processors[mode];
    if (processor == null) {
      throw StateError(
        'No processor registered for generation mode: ${mode.key}. '
        'Available modes: ${_processors.keys.map((m) => m.key).join(", ")}',
      );
    }
    return processor;
  }

  @override
  IVariableProcessor? getProcessorOrNull(GenerationMode mode) {
    return _processors[mode];
  }
}
