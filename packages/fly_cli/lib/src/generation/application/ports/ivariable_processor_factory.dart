import 'package:fly_cli/src/generation/application/ports/ivariable_processor.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';

/// Interface for variable processor factory.
///
/// Provides a registry pattern for resolving mode-specific processors.
/// Follows the Dependency Inversion Principle by allowing consumers to
/// depend on this abstraction rather than concrete processor implementations.
abstract class IVariableProcessorFactory {
  /// Gets the processor for the specified generation mode.
  ///
  /// [mode] - The generation mode (project, feature, service)
  ///
  /// Returns the appropriate processor for the mode.
  /// Throws an exception if no processor is registered for the mode.
  IVariableProcessor getProcessor(GenerationMode mode);

  /// Gets the processor for the specified generation mode, or null if not found.
  ///
  /// [mode] - The generation mode (project, feature, service)
  ///
  /// Returns the appropriate processor for the mode, or null if not registered.
  IVariableProcessor? getProcessorOrNull(GenerationMode mode);
}

