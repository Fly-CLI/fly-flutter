import 'package:args/args.dart';
import 'command_context.dart';
import 'command_result.dart';
import 'command_validator.dart';

/// Lifecycle hooks for command execution phases
abstract class CommandLifecycle {
  /// Called before command execution starts
  /// Use for setup, validation, or resource preparation
  Future<void> onBeforeExecute(CommandContext context);
  
  /// Called after successful command execution
  /// Use for cleanup, logging, or post-processing
  Future<void> onAfterExecute(CommandContext context, CommandResult result);
  
  /// Called when an error occurs during execution
  /// Use for error handling, cleanup, or recovery
  Future<void> onError(CommandContext context, Object error, StackTrace stackTrace);
  
  /// Called during validation phase
  /// Use for custom validation logic
  Future<ValidationResult> onValidate(CommandContext context, ArgResults args);
}
