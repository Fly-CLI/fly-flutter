import 'package:fly_cli/src/core/errors/error_codes.dart';
import 'package:fly_cli/src/core/utils/version_utils.dart';
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
  });

  factory CommandResult.success({
    required String command,
    required String message,
    Map<String, dynamic>? data,
    List<NextStep>? nextSteps,
    Map<String, dynamic>? metadata,
  }) => CommandResult(
      success: true,
      command: command,
      message: message,
      data: data,
      nextSteps: nextSteps,
      metadata: metadata,
    );

  factory CommandResult.error({
    required String message,
    String? suggestion,
    Map<String, dynamic>? metadata,
    ErrorCode? errorCode,
    Map<String, dynamic>? context,
  }) => CommandResult(
      success: false,
      command: 'error',
      message: message,
      suggestion: suggestion,
      metadata: metadata,
      errorCode: errorCode,
      errorContext: context,
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

  int get exitCode => success ? 0 : 1;

  /// Convert to JSON for AI integration
  Map<String, dynamic> toJson() => {
      'success': success,
      'command': command,
      'message': message,
      if (data != null) 'data': data,
      if (nextSteps != null) 'next_steps': nextSteps?.map((e) => e.toJson()).toList(),
      if (suggestion != null) 'suggestion': suggestion,
      if (errorCode != null) 'error_code': errorCode!.code,
      if (errorContext != null) 'error_context': errorContext,
      'metadata': {
        'cli_version': VersionUtils.getCurrentVersion(),
        'timestamp': DateTime.now().toIso8601String(),
        ...?metadata,
      },
    };

  /// Convert to AI-optimized JSON format with enhanced structure
  Map<String, dynamic> toAiJson() => {
      'status': success ? 'success' : 'error',
      'command': command,
      'summary': message,
      if (data != null) 'details': data,
      if (nextSteps != null) 'actions': nextSteps?.map((e) => {
        'command': e.command,
        'description': e.description,
        'type': 'terminal_command',
      }).toList(),
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
