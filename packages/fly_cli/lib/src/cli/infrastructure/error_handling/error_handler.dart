import 'dart:async';
import 'dart:io';

import 'package:fly_cli/src/cli/domain/interfaces/i_output_formatter.dart';
import 'package:fly_cli/src/cli/domain/output_format.dart';
import 'package:fly_cli/src/cli/infrastructure/error_handling/exit_code_mapper.dart';
import 'package:fly_cli/src/cli/infrastructure/formatting/output_format_parser.dart';
import 'package:fly_cli/src/features/commands/domain/command_result.dart';
import 'package:fly_cli/src/shared/errors/domain/error_codes.dart';
import 'package:fly_cli/src/shared/utils/version_utils.dart';
import 'package:mason_logger/mason_logger.dart';

/// Centralized error handler for CLI errors
///
/// This class provides centralized error handling with proper exit code mapping
/// and error formatting following POSIX standards.
class ErrorHandler {
  /// Create an error handler
  ///
  /// [formatter] - Output formatter for error formatting
  /// [logger] - Logger for error logging (optional)
  ErrorHandler({
    required IOutputFormatter formatter,
    Logger? logger,
  }) : _formatter = formatter,
       _logger = logger;

  final IOutputFormatter _formatter;
  final Logger? _logger;

  /// Handle an error with proper exit code mapping
  ///
  /// Handles errors by:
  /// 1. Classifying the error to determine ErrorCode
  /// 2. Mapping ErrorCode to CliExitCode
  /// 3. Formatting error output based on output format
  /// 4. Returning the appropriate exit code
  ///
  /// [error] - The error object
  /// [stackTrace] - The stack trace (optional)
  /// [args] - Command arguments (optional, for format detection)
  /// [commandName] - Command name (optional)
  /// [isVerbose] - Whether verbose output is enabled
  /// Returns the exit code to use
  Future<int> handleError(
    Object error,
    StackTrace? stackTrace,
    Iterable<String>? args, {
    String? commandName,
    bool isVerbose = false,
  }) async {
    // Parse output format from args
    final outputFormat = args != null
        ? OutputFormatParser.parseFromArgs(args)
        : OutputFormat.human;

    // Classify error
    final errorCode = _classifyError(error);

    // Map to exit code
    final exitCode = ExitCodeMapper.mapErrorCode(errorCode);

    // Create error result
    final errorResult = CommandResult.error(
      message: error.toString(),
      suggestion: _getErrorSuggestion(error, errorCode),
      errorCode: errorCode,
      metadata: {
        'cli_version': VersionUtils.getCurrentVersion(),
        'timestamp': DateTime.now().toIso8601String(),
        'verbose': isVerbose,
        'command': commandName,
      },
    );

    // Log error if logger is available
    final logger = _logger;
    if (logger != null) {
      logger.err('Error: $error');
      if (stackTrace != null && isVerbose) {
        logger.err('Stack trace: $stackTrace');
      }
    }

    // Format and output error
    final formattedOutput = _formatter.formatError(errorResult, outputFormat);
    // Use stderr for error output
    stderr.writeln(formattedOutput);

    return exitCode.code;
  }

  /// Classify an error to determine ErrorCode
  ///
  /// Uses heuristics to classify errors based on error message content.
  ///
  /// [error] - The error object
  /// Returns the classified ErrorCode or null if unknown
  ErrorCode? _classifyError(Object error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('permission') || errorStr.contains('denied')) {
      return ErrorCode.permissionDenied;
    }
    if (errorStr.contains('network')) {
      return ErrorCode.networkError;
    }
    if (errorStr.contains('template')) {
      return ErrorCode.templateNotFound;
    }
    if (errorStr.contains('validation') || errorStr.contains('invalid')) {
      return ErrorCode.invalidArgumentValue;
    }
    if (errorStr.contains('flutter')) {
      return ErrorCode.flutterSdkNotFound;
    }
    if (errorStr.contains('dart')) {
      return ErrorCode.dartSdkNotFound;
    }
    if (errorStr.contains('file') || errorStr.contains('directory')) {
      return ErrorCode.fileSystemError;
    }
    if (errorStr.contains('timeout')) {
      return ErrorCode.timeoutError;
    }
    if (errorStr.contains('not found') || errorStr.contains('missing')) {
      return ErrorCode.missingRequiredArgument;
    }

    return ErrorCode.unknownError;
  }

  /// Get helpful suggestion for an error
  ///
  /// Returns a user-friendly suggestion based on the error and error code.
  ///
  /// [error] - The error object
  /// [errorCode] - The classified error code (optional)
  /// Returns a suggestion string
  String _getErrorSuggestion(Object error, ErrorCode? errorCode) {
    if (errorCode != null && errorCode != ErrorCode.unknownError) {
      return errorCode.defaultSuggestion;
    }

    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('permission')) {
      return 'Check file permissions or run with elevated privileges';
    }
    if (errorStr.contains('network')) {
      return 'Check your internet connection and try again';
    }
    if (errorStr.contains('not found')) {
      return 'Make sure Flutter is installed and in your PATH';
    }
    if (errorStr.contains('template')) {
      return 'Run "fly doctor" to check your setup or try a different template';
    }
    if (errorStr.contains('validation') || errorStr.contains('invalid')) {
      return 'Check your command syntax and try again';
    }

    return 'Check your command syntax and try again';
  }
}
