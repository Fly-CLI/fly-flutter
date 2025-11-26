import 'package:fly_cli/src/generation/application/ports/ivariable_processor.dart';
import 'package:fly_cli/src/generation/application/ports/ivariable_processor_factory.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';

/// Factory implementation for variable processor resolution.
///
/// Maintains a registry of processors mapped by generation mode.
/// Implements the Registry pattern to provide mode-specific processor resolution.
class VariableProcessorFactory implements IVariableProcessorFactory {
  /// Creates a new instance of [VariableProcessorFactory].
  ///
  /// [projectProcessor] - Processor for project generation mode
  /// [featureProcessor] - Processor for feature generation mode
  /// [serviceProcessor] - Processor for service generation mode
  VariableProcessorFactory({
    required IVariableProcessor projectProcessor,
    required IVariableProcessor featureProcessor,
    required IVariableProcessor serviceProcessor,
  }) : _processors = {
          GenerationMode.project: projectProcessor,
          GenerationMode.feature: featureProcessor,
          GenerationMode.service: serviceProcessor,
        };

  final Map<GenerationMode, IVariableProcessor> _processors;

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

