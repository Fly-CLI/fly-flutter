import 'dart:async';
import 'dart:io';

import 'package:fly_core/src/process_execution/command_builder.dart';
import 'package:fly_core/src/process_execution/output_parser.dart';
import 'package:fly_core/src/process_execution/process_result.dart';
import 'package:fly_core/src/retry/retry.dart';

/// Executor for process operations
/// 
/// Provides a unified interface for executing external processes
/// with timeout, retry, and error handling support.
class ProcessExecutor {
  /// Creates a process executor
  const ProcessExecutor({
    this.defaultTimeout = const Duration(minutes: 5),
    this.retryExecutor,
    this.onProcessStart,
    this.onProcessComplete,
    CommandBuilder? commandBuilder,
    OutputParser? outputParser,
  }) : _commandBuilder = commandBuilder ?? const CommandBuilder(),
       _outputParser = outputParser ?? const OutputParser();

  /// Default timeout for process execution
  final Duration defaultTimeout;

  /// Optional retry executor for failed processes
  final RetryExecutor? retryExecutor;

  /// Callback when process starts
  final void Function(String command, List<String> args)? onProcessStart;

  /// Callback when process completes
  final void Function(ProcessExecutionResult)? onProcessComplete;

  final CommandBuilder _commandBuilder;
  final OutputParser _outputParser;

  /// Execute a process
  Future<ProcessExecutionResult> execute(
    String command,
    List<String> args, {
    Duration? timeout,
    Map<String, String>? environment,
    String? workingDirectory,
    bool runInShell = false,
    bool includeParentEnvironment = true,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    if (onProcessStart != null) {
      onProcessStart!(command, args);
    }

    try {
      final result = retryExecutor != null
          ? await _executeWithRetry(
              command,
              args,
              timeout: timeout ?? defaultTimeout,
              environment: environment,
              workingDirectory: workingDirectory,
              runInShell: runInShell,
              includeParentEnvironment: includeParentEnvironment,
            )
          : await _executeOnce(
              command,
              args,
              timeout: timeout ?? defaultTimeout,
              environment: environment,
              workingDirectory: workingDirectory,
              runInShell: runInShell,
              includeParentEnvironment: includeParentEnvironment,
            );

      stopwatch.stop();
      final finalResult = ProcessExecutionResult(
        exitCode: result.exitCode,
        stdout: result.stdout,
        stderr: result.stderr,
        command: _commandBuilder.createCommandSummary(command, args),
        duration: stopwatch.elapsed,
      );

      if (onProcessComplete != null) {
        onProcessComplete!(finalResult);
      }

      return finalResult;
    } catch (e) {
      stopwatch.stop();
      final errorResult = ProcessExecutionResult.failure(
        stdout: '',
        stderr: e.toString(),
        command: _commandBuilder.createCommandSummary(command, args),
        duration: stopwatch.elapsed,
      );

      if (onProcessComplete != null) {
        onProcessComplete!(errorResult);
      }

      return errorResult;
    }
  }

  /// Execute a process synchronously
  ProcessExecutionResult executeSync(
    String command,
    List<String> args, {
    Map<String, String>? environment,
    String? workingDirectory,
    bool runInShell = false,
    bool includeParentEnvironment = true,
  }) {
    try {
      final stopwatch = Stopwatch()..start();
      final processResult = Process.runSync(
        command,
        args,
        environment: _prepareEnvironment(
          environment,
          includeParentEnvironment: includeParentEnvironment,
        ),
        workingDirectory: workingDirectory,
        runInShell: runInShell,
      );

      stopwatch.stop();
      return ProcessExecutionResult(
        exitCode: processResult.exitCode,
        stdout: processResult.stdout.toString(),
        stderr: processResult.stderr.toString(),
        command: _commandBuilder.createCommandSummary(command, args),
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      return ProcessExecutionResult.failure(
        stdout: '',
        stderr: e.toString(),
        command: _commandBuilder.createCommandSummary(command, args),
      );
    }
  }

  /// Execute with retry support
  Future<ProcessExecutionResult> _executeWithRetry(
    String command,
    List<String> args, {
    required Duration timeout,
    Map<String, String>? environment,
    String? workingDirectory,
    bool runInShell = false,
    bool includeParentEnvironment = true,
  }) async {
    if (retryExecutor == null) {
      return await _executeOnce(
        command,
        args,
        timeout: timeout,
        environment: environment,
        workingDirectory: workingDirectory,
        runInShell: runInShell,
        includeParentEnvironment: includeParentEnvironment,
      );
    }

    final result = await retryExecutor!.execute(() async {
      final processResult = await _executeOnce(
        command,
        args,
        timeout: timeout,
        environment: environment,
        workingDirectory: workingDirectory,
        runInShell: runInShell,
        includeParentEnvironment: includeParentEnvironment,
      );

      if (!processResult.success) {
        throw ProcessExecutionException(processResult);
      }

      return processResult;
    });

    return result;
  }

  /// Execute a single process run
  Future<ProcessExecutionResult> _executeOnce(
    String command,
    List<String> args, {
    required Duration timeout,
    Map<String, String>? environment,
    String? workingDirectory,
    bool runInShell = false,
    bool includeParentEnvironment = true,
  }) async {
    try {
      final processResult = await Process.run(
        command,
        args,
        environment: _prepareEnvironment(
          environment,
          includeParentEnvironment: includeParentEnvironment,
        ),
        workingDirectory: workingDirectory,
        runInShell: runInShell,
      ).timeout(timeout);

      return ProcessExecutionResult(
        exitCode: processResult.exitCode,
        stdout: processResult.stdout.toString(),
        stderr: processResult.stderr.toString(),
        command: _commandBuilder.createCommandSummary(command, args),
      );
    } catch (e) {
      if (e is TimeoutException) {
        return ProcessExecutionResult.failure(
          stdout: '',
          stderr: 'Process timed out after ${timeout.inSeconds}s',
          command: _commandBuilder.createCommandSummary(command, args),
        );
      }
      rethrow;
    }
  }

  /// Prepare environment variables
  Map<String, String> _prepareEnvironment(
    Map<String, String>? environment, {
    required bool includeParentEnvironment,
  }) {
    return _commandBuilder.prepareEnvironment(
      additionalVars: environment,
      includeSystemEnv: includeParentEnvironment,
    );
  }

  /// Get the output parser
  OutputParser get outputParser => _outputParser;

  /// Get the command builder
  CommandBuilder get commandBuilder => _commandBuilder;

  /// Create a copy with modified configuration
  ProcessExecutor copyWith({
    Duration? defaultTimeout,
    RetryExecutor? retryExecutor,
    void Function(String, List<String>)? onProcessStart,
    void Function(ProcessExecutionResult)? onProcessComplete,
    CommandBuilder? commandBuilder,
    OutputParser? outputParser,
  }) {
    return ProcessExecutor(
      defaultTimeout: defaultTimeout ?? this.defaultTimeout,
      retryExecutor: retryExecutor ?? this.retryExecutor,
      onProcessStart: onProcessStart ?? this.onProcessStart,
      onProcessComplete: onProcessComplete ?? this.onProcessComplete,
      commandBuilder: commandBuilder ?? _commandBuilder,
      outputParser: outputParser ?? _outputParser,
    );
  }

  /// Create a default executor
  factory ProcessExecutor.defaults() {
    return const ProcessExecutor();
  }

  /// Create an executor with retry support
  factory ProcessExecutor.withRetry() {
    return ProcessExecutor(
      retryExecutor: RetryExecutor.defaults(),
    );
  }

  /// Create an executor with aggressive retry
  factory ProcessExecutor.withAggressiveRetry() {
    return ProcessExecutor(
      retryExecutor: RetryExecutor.aggressive(),
    );
  }
}

/// Exception for process execution failures
class ProcessExecutionException implements Exception {
  const ProcessExecutionException(this.result);

  final ProcessExecutionResult result;

  @override
  String toString() {
    return 'ProcessExecutionException: ${result.stderr}';
  }
}

