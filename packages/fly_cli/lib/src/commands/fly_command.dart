import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

/// Base command class for all Fly CLI commands with AI-native features
abstract class FlyCommand extends Command<int> {
  FlyCommand() : super();

  @override
  ArgParser get argParser {
    final parser = ArgParser();
    // AI-native flags
    parser
      ..addFlag(
        'plan',
        help: 'Show execution plan without running',
        negatable: false,
      )
      ..addOption(
        'output',
        abbr: 'f',
        allowed: ['human', 'json'],
        defaultsTo: 'human',
        help: 'Output format (human or json)',
      );
    return parser;
  }

  final Logger _logger = Logger();

  Logger get logger => jsonOutput ? _SilentLogger() : _logger;

  String getErrorSuggestion(Object error) => _getErrorSuggestion(error);

  /// Whether to output JSON format for AI integration
  bool get jsonOutput => argResults?['output'] == 'json';

  /// Whether to run in plan mode (dry-run)
  bool get planMode => argResults?['plan'] == true;


  /// Execute the command logic
  Future<CommandResult> execute();

  @override
  Future<int> run() async {
    try {
      final result = await execute();
      
      if (jsonOutput) {
        print(json.encode(result.toJson()));
      } else {
        result.displayHuman();
      }
      
      return result.exitCode;
    } catch (e) {
      final errorResult = CommandResult.error(
        message: 'Unexpected error: $e',
        suggestion: getErrorSuggestion(e),
      );
      
      if (jsonOutput) {
        print(json.encode(errorResult.toJson()));
      } else {
        errorResult.displayHuman();
      }
      
      return errorResult.exitCode;
    }
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
}

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
  }) => CommandResult(
      success: false,
      command: 'error',
      message: message,
      suggestion: suggestion,
      metadata: metadata,
    );

  final bool success;
  final String command;
  final String message;
  final Map<String, dynamic>? data;
  final List<NextStep>? nextSteps;
  final String? suggestion;
  final Map<String, dynamic>? metadata;

  int get exitCode => success ? 0 : 1;

  /// Convert to JSON for AI integration
  Map<String, dynamic> toJson() => {
      'success': success,
      'command': command,
      'message': message,
      if (data != null) 'data': data,
      if (nextSteps != null) 'next_steps': nextSteps?.map((e) => e.toJson()).toList(),
      if (suggestion != null) 'suggestion': suggestion,
      'metadata': {
        'cli_version': '0.1.0',
        'timestamp': DateTime.now().toIso8601String(),
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
      if (suggestion != null) {
        logger.info('\n💡 Suggestion: $suggestion');
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
