import 'package:fly_cli/src/features/commands/domain/command_execution_context.dart';
import 'package:fly_cli/src/shared/errors/domain/error_codes.dart';
import 'package:fly_cli/src/shared/utils/version_utils.dart';
import 'package:mason_logger/mason_logger.dart';

/// Result of a command execution with AI-friendly structure
class CommandResult {
  const CommandResult({
    required this.success,
    required this.command,
    required this.message,
    this.data,
    this.nextSteps,
    this.suggestion,
    this.metadata,
    this.errorCode,
    this.errorContext,
    this.executionDurationMs,
    this.executionPhase,
    this.wasCancelled,
    this.progress,
  });

  factory CommandResult.success({
    required String command,
    required String message,
    Map<String, dynamic>? data,
    List<NextStep>? nextSteps,
    Map<String, dynamic>? metadata,
    int? executionDurationMs,
    ExecutionPhase? executionPhase,
    bool? wasCancelled,
    Map<String, dynamic>? progress,
  }) => CommandResult(
    success: true,
    command: command,
    message: message,
    data: data,
    nextSteps: nextSteps,
    metadata: metadata,
    executionDurationMs: executionDurationMs,
    executionPhase: executionPhase,
    wasCancelled: wasCancelled,
    progress: progress,
  );

  factory CommandResult.error({
    required String message,
    String? suggestion,
    Map<String, dynamic>? metadata,
    ErrorCode? errorCode,
    Map<String, dynamic>? context,
    int? executionDurationMs,
    ExecutionPhase? executionPhase,
    bool? wasCancelled,
    Map<String, dynamic>? progress,
  }) => CommandResult(
    success: false,
    command: 'error',
    message: message,
    suggestion: suggestion,
    metadata: metadata,
    errorCode: errorCode,
    errorContext: context,
    executionDurationMs: executionDurationMs,
    executionPhase: executionPhase,
    wasCancelled: wasCancelled,
    progress: progress,
  );

  final bool success;
  final String command;
  final String message;
  final Map<String, dynamic>? data;
  final List<NextStep>? nextSteps;
  final String? suggestion;
  final Map<String, dynamic>? metadata;
  final ErrorCode? errorCode;
  final Map<String, dynamic>? errorContext;

  /// Execution duration in milliseconds
  final int? executionDurationMs;

  /// Execution phase when result was created
  final ExecutionPhase? executionPhase;

  /// Whether execution was cancelled
  final bool? wasCancelled;

  /// Progress information (for long-running commands)
  /// This is a placeholder for Phase 3 progress tracking
  final Map<String, dynamic>? progress;

  int get exitCode => success ? 0 : 1;

  /// Convert to JSON for AI integration
  Map<String, dynamic> toJson() => {
    'success': success,
    'command': command,
    'message': message,
    if (data != null) 'data': data,
    if (nextSteps != null)
      'next_steps': nextSteps?.map((e) => e.toJson()).toList(),
    if (suggestion != null) 'suggestion': suggestion,
    if (errorCode != null) 'error_code': errorCode!.code,
    if (errorContext != null) 'error_context': errorContext,
    'metadata': {
      'cli_version': VersionUtils.getCurrentVersion(),
      'timestamp': DateTime.now().toIso8601String(),
      ...?metadata,
    },
    if (executionDurationMs != null ||
        executionPhase != null ||
        wasCancelled != null ||
        progress != null)
      'execution_metadata': {
        if (executionDurationMs != null) 'duration_ms': executionDurationMs,
        if (executionPhase != null) 'phase': executionPhase!.name,
        if (wasCancelled != null) 'cancelled': wasCancelled,
        if (progress != null) 'progress': progress,
      },
  };

  /// Convert to AI-optimized JSON format with enhanced structure
  Map<String, dynamic> toAiJson() => {
    'status': success ? 'success' : 'error',
    'command': command,
    'summary': message,
    if (data != null) 'details': data,
    if (nextSteps != null)
      'actions': nextSteps
          ?.map(
            (e) => {
              'command': e.command,
              'description': e.description,
              'type': 'terminal_command',
            },
          )
          .toList(),
    if (suggestion != null) 'recommendation': suggestion,
    if (errorCode != null) 'error_code': errorCode!.code,
    if (errorContext != null) 'error_context': errorContext,
    'context': {
      'tool': 'fly_cli',
      'version': VersionUtils.getCurrentVersion(),
      'timestamp': DateTime.now().toIso8601String(),
      'format': 'ai_optimized',
      ...?metadata,
    },
    if (executionDurationMs != null ||
        executionPhase != null ||
        wasCancelled != null ||
        progress != null)
      'execution_metadata': {
        if (executionDurationMs != null) 'duration_ms': executionDurationMs,
        if (executionPhase != null) 'phase': executionPhase!.name,
        if (wasCancelled != null) 'cancelled': wasCancelled,
        if (progress != null) 'progress': progress,
      },
  };

  /// Display human-readable output
  void displayHuman() {
    final logger = Logger();
    if (success) {
      logger.info('✅ $message');

      if (nextSteps != null && nextSteps!.isNotEmpty) {
        logger.info('\nNext steps:');
        for (final step in nextSteps!) {
          logger.info('  ${step.command} - ${step.description}');
        }
      }
    } else {
      logger.err('❌ $message');

      if (errorCode != null) {
        logger.err('Error Code: ${errorCode!.code}');
      }

      if (suggestion != null) {
        logger.info('\n💡 Suggestion: $suggestion');
      }

      if (errorContext != null && errorContext!.isNotEmpty) {
        logger.info('\nContext:');
        for (final entry in errorContext!.entries) {
          logger.info('  ${entry.key}: ${entry.value}');
        }
      }
    }
  }

  /// Create a copy of this result with updated fields
  CommandResult copyWith({
    bool? success,
    String? command,
    String? message,
    Map<String, dynamic>? data,
    List<NextStep>? nextSteps,
    String? suggestion,
    Map<String, dynamic>? metadata,
    ErrorCode? errorCode,
    Map<String, dynamic>? errorContext,
    int? executionDurationMs,
    ExecutionPhase? executionPhase,
    bool? wasCancelled,
    Map<String, dynamic>? progress,
  }) => CommandResult(
    success: success ?? this.success,
    command: command ?? this.command,
    message: message ?? this.message,
    data: data ?? this.data,
    nextSteps: nextSteps ?? this.nextSteps,
    suggestion: suggestion ?? this.suggestion,
    metadata: metadata ?? this.metadata,
    errorCode: errorCode ?? this.errorCode,
    errorContext: errorContext ?? this.errorContext,
    executionDurationMs: executionDurationMs ?? this.executionDurationMs,
    executionPhase: executionPhase ?? this.executionPhase,
    wasCancelled: wasCancelled ?? this.wasCancelled,
    progress: progress ?? this.progress,
  );
}

/// Represents a next step for the user
class NextStep {
  const NextStep({
    required this.command,
    required this.description,
  });

  final String command;
  final String description;

  Map<String, dynamic> toJson() => {
    'command': command,
    'description': description,
  };
}
