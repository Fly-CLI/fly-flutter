import 'dart:convert';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_lifecycle.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_middleware.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_result.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_validator.dart';
import 'package:fly_cli/src/core/command_metadata/command_metadata.dart';
import 'package:fly_cli/src/core/errors/error_codes.dart';
import 'package:fly_cli/src/core/errors/error_context.dart';
import 'package:mason_logger/mason_logger.dart';

/// Enhanced base command class following SOLID principles
abstract class FlyCommand extends Command<int> implements CommandLifecycle {
  FlyCommand(this.context) : super();

  /// Command execution context with injected dependencies
  final CommandContext context;

  /// List of middleware to execute before command logic
  List<CommandMiddleware> get middleware => [];

  /// List of validators to run before execution
  List<CommandValidator> get validators => [];

  /// Command metadata definition (optional)
  CommandDefinition? get metadata => null;

  /// Whether to output JSON format for AI integration
  bool get jsonOutput => argResults?['output'] == 'json';

  /// Whether to output AI-optimized format
  bool get aiOutput => argResults?['output'] == 'ai';

  /// Whether to run in debug mode with verbose error output
  bool get debugMode => argResults?['debug'] == true;

  /// Whether to run in plan mode (dry-run)
  bool get planMode => argResults?['plan'] == true;

  /// Whether to run in verbose mode
  bool get verboseMode => argResults?['verbose'] == true || debugMode;

  /// Logger instance (respects output format settings)
  Logger get logger =>
      (jsonOutput || aiOutput) ? _SilentLogger() : context.logger;

  @override
  ArgParser get argParser {
    final parser = ArgParser()
      ..addOption(
        'output',
        abbr: 'f',
        allowed: ['human', 'json', 'ai'],
        defaultsTo: 'human',
        help: 'Output format (human, json, or ai)',
      )
      ..addFlag(
        'debug',
        abbr: 'd',
        help: 'Enable debug mode with verbose error output',
      )..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Enable verbose output',
      )..addFlag(
        'plan',
        help: 'Run in plan mode (dry-run)',
        negatable: false,
      );
    return parser;
  }

  /// Execute the command logic - must be implemented by subclasses
  Future<CommandResult> execute();

  @override
  Future<int> run() async {
    try {
      // 1. Run validators
      final validationResult = await _runValidators();
      if (!validationResult.isValid) {
        return _handleValidationFailure(validationResult);
      }

      // 2. Execute middleware pipeline
      final middlewareResult = await _runMiddlewarePipeline();
      if (middlewareResult != null) {
        return _handleResult(middlewareResult);
      }

      // 3. Call lifecycle hook
      await onBeforeExecute(context);

      // 4. Execute command logic
      final result = await execute();

      // 5. Call lifecycle hook
      await onAfterExecute(context, result);

      return _handleResult(result);
    } catch (e, stackTrace) {
      // 6. Handle errors with lifecycle hook
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
      );

      return _handleResult(errorResult);
    }
  }

  /// Run all validators for this command
  Future<ValidationResult> _runValidators() async {
    final applicableValidators =
        validators.where((v) => v.shouldRun(context, name)).toList()
          ..sort((a, b) => a.priority.compareTo(b.priority));

    final results = <ValidationResult>[];

    // Use context.argResults as fallback if Command.argResults is null
    // This allows testing commands without CommandRunner
    final effectiveArgResults = argResults ?? context.argResults;
    if (effectiveArgResults == null) {
      return ValidationResult.failure(['Command arguments not available']);
    }

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
  Future<CommandResult?> _runMiddlewarePipeline() async {
    final applicableMiddleware =
        middleware.where((m) => m.shouldRun(context, name)).toList()
          ..sort((a, b) => a.priority.compareTo(b.priority));

    if (applicableMiddleware.isEmpty) {
      return null;
    }

    int currentIndex = 0;

    Future<CommandResult?> next() async {
      if (currentIndex >= applicableMiddleware.length) {
        return null;
      }

      final middleware = applicableMiddleware[currentIndex++];
      return middleware.handle(context, next);
    }

    return next();
  }

  /// Handle validation failure
  int _handleValidationFailure(ValidationResult result) {
    final errorResult = CommandResult.error(
      message: 'Validation failed: ${result.errors.join(', ')}',
      suggestion: 'Check your command arguments and try again',
      errorCode: ErrorCode.invalidArgumentValue,
      context: ErrorContext.forValidation(
        'command_arguments',
        argResults?.arguments,
        'Validation failed',
      ),
    );

    return _handleResult(errorResult);
  }

  /// Handle command result output
  int _handleResult(CommandResult result) {
    if (jsonOutput) {
      print(json.encode(result.toJson()));
    } else if (aiOutput) {
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
