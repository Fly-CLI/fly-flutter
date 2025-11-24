import 'package:args/args.dart';
import 'package:fly_cli/src/features/commands/domain/command_context.dart';

/// Interface for command context factory
///
/// This interface provides abstraction over the context factory implementation,
/// allowing for easier testing and swapping of implementations.
abstract class IContextFactory {
  /// Creates a minimal context for command registration (setup only)
  ///
  /// This context is used during command setup when actual arguments are not
  /// yet available. It uses empty args and is suitable only for command
  /// initialization, not for execution.
  ///
  /// **Note**: This context should NOT be used for command execution.
  /// Use [createExecutionContext] instead for execution contexts.
  CommandContext createRegistrationContext();

  /// Creates a full context for command execution with actual arguments
  ///
  /// This context is used during command execution when actual arguments
  /// are available. It includes all flags and options from the parsed args.
  ///
  /// [args] - Parsed command arguments
  CommandContext createExecutionContext(ArgResults args);

  /// Creates a test context with optional overrides
  ///
  /// This method is designed for testing scenarios where you want to
  /// override specific services or configuration.
  ///
  /// [args] - Parsed command arguments (defaults to empty args)
  /// [services] - Optional service container override
  /// [config] - Optional configuration override
  /// [workingDirectory] - Optional working directory override
  /// [factory] - Optional factory override (uses this factory if not provided)
  CommandContext createTestContext(
    ArgResults args, {
    dynamic services,
    Map<String, dynamic>? config,
    String? workingDirectory,
    IContextFactory? factory,
  });
}
