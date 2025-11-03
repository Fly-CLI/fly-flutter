import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_execution_context.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_lifecycle.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_result.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_validator.dart';
import 'package:fly_cli/src/core/command_foundation/flags/cli_flags.dart';
import 'package:fly_cli/src/core/command_foundation/flags/flag_accessor.dart';
import 'package:fly_cli/src/core/command_foundation/flags/global_flags_registry.dart';
import 'package:fly_cli/src/core/command_foundation/infrastructure/command_context_impl.dart';
import 'package:fly_cli/src/core/command_metadata/command_metadata.dart';
import 'package:fly_cli/src/core/errors/error_codes.dart';
import 'package:fly_cli/src/core/errors/error_context.dart';
import 'package:fly_cli/src/core/middleware/domain/command_middleware.dart';
import 'package:fly_cli/src/core/middleware/domain/middleware_pipeline.dart';
import 'package:fly_cli/src/core/middleware/infrastructure/middleware_factory.dart';
import 'package:fly_cli/src/core/progress/infrastructure/progress_factory.dart';
import 'package:fly_core/src/validation/validation.dart';
import 'package:fly_mcp/fly_mcp.dart' hide Logger;
import 'package:mason_logger/mason_logger.dart';

/// Enhanced base command class following SOLID principles
abstract class FlyCommand extends Command<int> implements CommandLifecycle {
  FlyCommand(this.context) : super();

  /// Command execution context with injected dependencies
  final CommandContext context;

  /// List of optional middleware to execute before command logic
  ///
  /// Mandatory middleware (DryRun, Logging, Metrics) are automatically included
  /// via MiddlewareFactory. This list contains only optional command-specific middleware.
  List<CommandMiddleware> get middleware => [];

  /// Get the complete middleware pipeline including mandatory middleware
  ///
  /// Uses MiddlewareFactory to create a configured pipeline with mandatory
  /// and optional middleware in the correct priority order.
  MiddlewarePipeline get middlewarePipeline =>
      MiddlewareFactory.create(
        context: context,
        optional: middleware,
      );

  /// List of validators to run before execution
  List<CommandValidator> get validators => [];

  /// Command metadata definition (optional)
  CommandDefinition? get metadata => null;

  /// Whether to output JSON format for AI integration
  bool get isJsonOutputFormat =>
      FlagAccessor.getString(argResults, GlobalFormatFlag()) == 'json';

  /// Whether to output AI-optimized format
  bool get isAiOutputFormat =>
      FlagAccessor.getString(argResults, GlobalFormatFlag()) == 'ai';

  /// Whether to run in debug mode with verbose error output
  bool get debugMode => FlagAccessor.getBool(argResults, const GlobalDebugFlag());

  /// Whether to run in plan mode (dry-run)
  bool get planMode => FlagAccessor.getBool(argResults, const GlobalPlanFlag());

  /// Whether to run in verbose mode
  bool get verboseMode =>
      FlagAccessor.getBool(argResults, const GlobalVerboseFlag()) || debugMode;

  /// Logger instance (respects output format settings)
  Logger get logger =>
      (isJsonOutputFormat || isAiOutputFormat) ? _SilentLogger() : context.logger;

  @override
  ArgParser get argParser {
    return GlobalFlagsRegistry.createBaseCommandParser();
  }

  /// Execute the command logic - must be implemented by subclasses
  Future<CommandResult> execute();

  @override
  Future<int> run() async {
    // Create execution context at the start of command execution
    final executionContext = CommandExecutionContext(
      commandName: name,
      startTime: DateTime.now(),
      cancellationToken: CancellationToken(),
      currentPhase: ExecutionPhase.initialization,
      progressTracker: ProgressFactory.create(context),
    );
    context.setData('execution_context', executionContext);

    // Set up Ctrl+C signal handling for cancellation
    final signalSubscription = _setupCancellationHandler(executionContext);

    try {
      // Ensure the context reflects the current command's parsed arguments
      // so that middleware and validators see the correct flags (e.g., --plan, --format)
      try {
        if (context is CommandContextImpl && argResults != null) {
          context as CommandContextImpl
          ..argResults = argResults!
          ..commandName = name;

        }
      } catch (_) {
        // Best-effort; continue even if context can't be updated
      }

      // 1. Run validators
      executionContext.setPhase(ExecutionPhase.validation);
      final validationResult = await _runValidators();
      if (!validationResult.isValid) {
        executionContext.setPhase(ExecutionPhase.error);
        return _handleValidationFailure(validationResult, executionContext);
      }

      // 2. Call lifecycle hook
      executionContext.setPhase(ExecutionPhase.middleware);
      await onBeforeExecute(context);

      // 3. Execute middleware pipeline (includes command execution)
      // The pipeline handles all middleware and then calls execute()
      // If middleware short-circuits (e.g., dry-run), it returns a result directly
      executionContext.setPhase(ExecutionPhase.execution);
      final result = await _runMiddlewarePipeline();

      // 4. Call lifecycle hook
      // Create a default result if pipeline returned null (shouldn't happen normally)
      executionContext.setPhase(ExecutionPhase.completion);
      final finalResult = result ??
          CommandResult.error(
            message: 'Command execution returned no result',
            suggestion: 'Check command implementation',
            executionDurationMs: executionContext.elapsedMs,
            executionPhase: executionContext.currentPhase,
            wasCancelled: executionContext.isCancelled,
          );

      // Enhance result with execution metadata including progress
      final progressInfo = executionContext.progressTracker?.currentProgress;
      final enhancedResult = finalResult.copyWith(
        executionDurationMs: executionContext.elapsedMs,
        executionPhase: executionContext.currentPhase,
        wasCancelled: executionContext.isCancelled,
        progress: progressInfo?.toJson(),
      );

      await onAfterExecute(context, enhancedResult);

      // Cancel signal subscription before returning
      await signalSubscription.cancel();

      return _handleResult(enhancedResult);
    } catch (e, stackTrace) {
      // Handle errors with lifecycle hook
      executionContext.setPhase(ExecutionPhase.error);
      await onError(context, e, stackTrace);

      // Simple error result with context
      final errorResult = CommandResult.error(
        message: 'Error: $e',
        suggestion: _getErrorSuggestion(e),
        errorCode: _classifyError(e),
        context: ErrorContext.forCommand(
          name,
          arguments: argResults?.arguments,
        ),
        executionDurationMs: executionContext.elapsedMs,
        executionPhase: executionContext.currentPhase,
        wasCancelled: executionContext.isCancelled,
      );

      // Cancel signal subscription before returning
      await signalSubscription.cancel();

      return _handleResult(errorResult);
    } finally {
      // Ensure signal subscription is cancelled
      await signalSubscription.cancel();
    }
  }

  /// Set up signal handler for Ctrl+C cancellation
  StreamSubscription<ProcessSignal> _setupCancellationHandler(
    CommandExecutionContext executionContext,
  ) {
    // Listen for SIGINT (Ctrl+C)
    final subscription = ProcessSignal.sigint.watch().listen((signal) {
      if (executionContext.isCancelled) {
        // Already cancelled, force exit
        exit(130); // Standard exit code for SIGINT
      }

      // Request cancellation
      executionContext.cancellationToken.cancel();

      // Update execution context phase
      executionContext.setPhase(ExecutionPhase.error);

      // Update progress tracker if available
      final progressTracker = executionContext.progressTracker;
      if (progressTracker != null && progressTracker.isActive) {
        progressTracker.stop('Cancelled by user (Ctrl+C)');
      }

      // Log cancellation message (if not in quiet/JSON mode)
      if (!context.quiet && !context.jsonOutput && !context.aiOutput) {
        context.logger.warn('\n⚠️  Cancellation requested. Cleaning up...');
      }
    });

    return subscription;
  }

  /// Run all validators for this command
  Future<ValidationResult> _runValidators() async {
    final applicableValidators = validators
        .where((v) => v.shouldRun(context, name))
        .toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));

    final results = <ValidationResult>[];

    // Use context.argResults as fallback if Command.argResults is null
    // This allows testing commands without CommandRunner
    final effectiveArgResults = argResults ?? context.argResults;

    for (final validator in applicableValidators) {
      final result = await validator.validate(context, effectiveArgResults);
      results.add(result);

      // Stop on first validation failure
      if (!result.isValid) {
        break;
      }
    }

    return ValidationResult.combine(results);
  }

  /// Run middleware pipeline
  ///
  /// Executes the complete middleware pipeline (mandatory + optional)
  /// followed by the command's execute method.
  Future<CommandResult?> _runMiddlewarePipeline() async {
    return middlewarePipeline.execute(context, execute);
  }

  /// Handle validation failure
  int _handleValidationFailure(
    ValidationResult result,
    CommandExecutionContext executionContext,
  ) {
    final errorResult = CommandResult.error(
      message: 'Validation failed: ${result.errors.join(', ')}',
      suggestion: 'Check your command arguments and try again',
      errorCode: ErrorCode.invalidArgumentValue,
      context: ErrorContext.forValidation(
        'command_arguments',
        argResults?.arguments,
        'Validation failed',
      ),
      executionDurationMs: executionContext.elapsedMs,
      executionPhase: executionContext.currentPhase,
      wasCancelled: executionContext.isCancelled,
    );

    return _handleResult(errorResult);
  }

  /// Handle command result output
  int _handleResult(CommandResult result) {
    if (isJsonOutputFormat) {
      print(json.encode(result.toJson()));
    } else if (isAiOutputFormat) {
      print(json.encode(result.toAiJson()));
    } else if (debugMode) {
      print('DEBUG: ${json.encode(result.toJson())}');
    } else {
      result.displayHuman();
    }

    return result.exitCode;
  }

  /// Simple error classification based on error message
  ErrorCode? _classifyError(Object error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('permission')) return ErrorCode.permissionDenied;
    if (errorStr.contains('network')) return ErrorCode.networkError;
    if (errorStr.contains('template')) return ErrorCode.templateNotFound;
    if (errorStr.contains('validation')) return ErrorCode.invalidArgumentValue;
    if (errorStr.contains('flutter')) return ErrorCode.flutterSdkNotFound;
    if (errorStr.contains('file')) return ErrorCode.fileSystemError;
    if (errorStr.contains('timeout')) return ErrorCode.timeoutError;

    return ErrorCode.unknownError;
  }

  /// Get helpful suggestion for common errors using error codes
  String _getErrorSuggestion(Object error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('permission')) {
      return ErrorCode.permissionDenied.defaultSuggestion;
    } else if (errorString.contains('network')) {
      return ErrorCode.networkError.defaultSuggestion;
    } else if (errorString.contains('not found')) {
      return ErrorCode.flutterSdkNotFound.defaultSuggestion;
    } else if (errorString.contains('template')) {
      return ErrorCode.templateNotFound.defaultSuggestion;
    } else if (errorString.contains('validation')) {
      return ErrorCode.invalidArgumentValue.defaultSuggestion;
    }

    return ErrorCode.unknownError.defaultSuggestion;
  }

  // CommandLifecycle implementation with default no-op behavior
  @override
  Future<void> onBeforeExecute(CommandContext context) async {}

  @override
  Future<void> onAfterExecute(
    CommandContext context,
    CommandResult result,
  ) async {}

  @override
  Future<void> onError(
    CommandContext context,
    Object error,
    StackTrace stackTrace,
  ) async {}

  @override
  Future<ValidationResult> onValidate(
    CommandContext context,
    ArgResults args,
  ) async {
    return ValidationResult.success();
  }
}

/// Silent logger that doesn't output anything
class _SilentLogger extends Logger {
  @override
  void info(String? message, {LogStyle? style}) {
    // Do nothing
  }

  @override
  void err(String? message, {LogStyle? style}) {
    // Do nothing
  }

  @override
  void warn(String? message, {String tag = 'WARN', LogStyle? style}) {
    // Do nothing
  }

  @override
  void success(String? message, {LogStyle? style}) {
    // Do nothing
  }
}
