import 'dart:convert';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_lifecycle.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_middleware.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_result.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_validator.dart';

import '../../../features/schema/domain/command_definition.dart';

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

  /// Whether to run in plan mode (dry-run)
  bool get planMode => argResults?['plan'] == true;

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

      final errorResult = CommandResult.error(
        message: 'Unexpected error: $e',
        suggestion: _getErrorSuggestion(e),
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

    for (final validator in applicableValidators) {
      final result = await validator.validate(context, argResults!);
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
      metadata: {
        'validation_errors': result.errors,
        'validation_warnings': result.warnings,
      },
    );

    return _handleResult(errorResult);
  }

  /// Handle command result output
  int _handleResult(CommandResult result) {
    if (jsonOutput) {
      print(json.encode(result.toJson()));
    } else if (aiOutput) {
      print(json.encode(result.toAiJson()));
    } else {
      result.displayHuman();
    }

    return result.exitCode;
  }

  /// Get helpful suggestion for common errors
  String _getErrorSuggestion(Object error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('permission')) {
      return 'Try running with elevated permissions or check file permissions';
    } else if (errorString.contains('network')) {
      return 'Check your internet connection and try again';
    } else if (errorString.contains('not found')) {
      return 'Make sure Flutter is installed and in your PATH';
    } else if (errorString.contains('template')) {
      return 'Run "fly doctor" to check your setup or try a different template';
    }

    return 'Run "fly doctor" to diagnose system issues';
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
