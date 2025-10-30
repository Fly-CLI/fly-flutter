import 'dart:io';

import 'package:fly_cli/src/core/command_foundation/command_result.dart';
import 'package:mason/mason.dart';
import 'package:yaml/yaml.dart';

/// Types of Mason-related errors
enum MasonErrorType {
  brickNotFound,
  brickValidationFailed,
  brickGenerationFailed,
  fileSystemError,
  templateSyntaxError,
  variableValidationFailed,
  cacheError,
  permissionError,
  versionIncompatible,
  versionNotFound,
  unknown,
}

/// Centralized error handling for all Mason operations
class MasonErrorHandler {
  /// Handle Mason-related errors and return appropriate CommandResult
  static CommandResult handleError(
    Exception error, {
    required String operation,
    required String brickName,
    Map<String, dynamic>? context,
  }) {
    final errorType = classifyError(error);
    final suggestion = getSuggestion(errorType, context);

    // Log detailed error information
    final logger = Logger();
    logger.err('Mason $operation error for brick "$brickName": $error');

    if (context != null) {
      logger.detail('Error context: $context');
    }

    return CommandResult.error(
      message: _getErrorMessage(errorType, error, brickName),
      suggestion: suggestion,
    );
  }

  /// Get user-friendly suggestion for error type
  static String getSuggestion(
      MasonErrorType errorType, Map<String, dynamic>? context) {
    switch (errorType) {
      case MasonErrorType.brickNotFound:
        return 'Check if the brick exists and is properly installed. Run "fly template list" to see available templates.';

      case MasonErrorType.brickValidationFailed:
        return 'The brick may be corrupted or incompatible. Try reinstalling the brick or check brick.yaml format.';

      case MasonErrorType.brickGenerationFailed:
        return 'Check your input variables and ensure all required fields are provided. Run with --dry-run to preview generation.';

      case MasonErrorType.fileSystemError:
        return 'Check file permissions and ensure the target directory is writable. Try running with elevated permissions if needed.';

      case MasonErrorType.templateSyntaxError:
        return 'The brick template contains syntax errors. Contact the brick maintainer or try a different version.';

      case MasonErrorType.variableValidationFailed:
        return 'Verify that all required variables are provided and have correct types. Check brick documentation for variable requirements.';

      case MasonErrorType.cacheError:
        return 'Clear the template cache and try again: "fly template cache clear"';

      case MasonErrorType.permissionError:
        return 'Insufficient permissions to write files. Check directory permissions or run with appropriate privileges.';

      case MasonErrorType.versionIncompatible:
        return 'Template version is incompatible with your current CLI or SDK versions. Check compatibility requirements and upgrade if needed.';

      case MasonErrorType.versionNotFound:
        return 'Requested template version not found. Run "fly template list --show-versions" to see available versions.';

      case MasonErrorType.unknown:
        return 'An unexpected error occurred. Check your Flutter installation and try again. If the problem persists, contact support.';
    }
  }

  /// Check if an error can be recovered from
  static bool canRecover(Exception error) {
    final errorType = classifyError(error);

    switch (errorType) {
      case MasonErrorType.brickNotFound:
      case MasonErrorType.brickValidationFailed:
      case MasonErrorType.cacheError:
        return true; // Can try alternative bricks or clear cache

      case MasonErrorType.fileSystemError:
      case MasonErrorType.permissionError:
        return true; // Can try different directory or permissions

      case MasonErrorType.variableValidationFailed:
        return true; // Can prompt for missing variables

      case MasonErrorType.versionIncompatible:
        return true; // Can upgrade CLI/SDK or use different version

      case MasonErrorType.versionNotFound:
        return true; // Can try different version

      case MasonErrorType.brickGenerationFailed:
      case MasonErrorType.templateSyntaxError:
      case MasonErrorType.unknown:
        return false; // Likely need user intervention
    }
  }

  /// Classify error type based on exception
  static MasonErrorType classifyError(Exception error) {
    if (error is MasonException) {
      final message = error.message.toLowerCase();

      if (message.contains('not found') || message.contains('does not exist')) {
        return MasonErrorType.brickNotFound;
      }

      if (message.contains('validation') || message.contains('invalid')) {
        return MasonErrorType.brickValidationFailed;
      }

      if (message.contains('template') || message.contains('syntax')) {
        return MasonErrorType.templateSyntaxError;
      }

      if (message.contains('variable') || message.contains('required')) {
        return MasonErrorType.variableValidationFailed;
      }

      return MasonErrorType.brickGenerationFailed;
    }

    if (error is FileSystemException) {
      final message = error.message.toLowerCase();

      if (message.contains('permission') || message.contains('access')) {
        return MasonErrorType.permissionError;
      }

      return MasonErrorType.fileSystemError;
    }

    if (error is YamlException) {
      return MasonErrorType.templateSyntaxError;
    }

    if (error is ArgumentError) {
      return MasonErrorType.variableValidationFailed;
    }

    return MasonErrorType.unknown;
  }

  /// Get user-friendly error message
  static String _getErrorMessage(
      MasonErrorType errorType, Exception error, String brickName) {
    switch (errorType) {
      case MasonErrorType.brickNotFound:
        return 'Brick "$brickName" not found';

      case MasonErrorType.brickValidationFailed:
        return 'Brick "$brickName" failed validation: ${error.toString()}';

      case MasonErrorType.brickGenerationFailed:
        return 'Failed to generate from brick "$brickName": ${error.toString()}';

      case MasonErrorType.fileSystemError:
        return 'File system error during generation: ${error.toString()}';

      case MasonErrorType.templateSyntaxError:
        return 'Template syntax error in brick "$brickName": ${error.toString()}';

      case MasonErrorType.variableValidationFailed:
        return 'Variable validation failed for brick "$brickName": ${error.toString()}';

      case MasonErrorType.cacheError:
        return 'Cache error: ${error.toString()}';

      case MasonErrorType.permissionError:
        return 'Permission denied: ${error.toString()}';

      case MasonErrorType.versionIncompatible:
        return 'Template version incompatible: ${error.toString()}';

      case MasonErrorType.versionNotFound:
        return 'Template version not found: ${error.toString()}';

      case MasonErrorType.unknown:
        return 'Unexpected error during generation: ${error.toString()}';
    }
  }

  /// Create a recovery strategy for an error
  static List<String> getRecoveryStrategies(
      MasonErrorType errorType, Map<String, dynamic>? context) {
    final strategies = <String>[];
    final brickName = context?['brick_name'] as String? ?? 'brick';

    switch (errorType) {
      case MasonErrorType.brickNotFound:
        strategies.addAll([
          'Try listing available bricks: fly template list',
          'Check if brick is installed: fly template info $brickName',
          'Reinstall brick if needed: fly template install $brickName',
        ]);
        break;

      case MasonErrorType.brickValidationFailed:
        strategies.addAll([
          'Validate brick: fly template validate $brickName',
          'Reinstall brick: fly template install $brickName --force',
          'Check brick documentation for compatibility',
        ]);
        break;

      case MasonErrorType.cacheError:
        strategies.addAll([
          'Clear template cache: fly template cache clear',
          'Refresh brick registry: fly template refresh',
        ]);
        break;

      case MasonErrorType.fileSystemError:
        strategies.addAll([
          'Check target directory permissions',
          'Try a different output directory',
          'Ensure sufficient disk space',
        ]);
        break;

      case MasonErrorType.permissionError:
        strategies.addAll([
          'Run with elevated permissions',
          'Check directory ownership',
          'Try a different target directory',
        ]);
        break;

      case MasonErrorType.variableValidationFailed:
        strategies.addAll([
          'Run in interactive mode: fly create --interactive',
          'Check required variables: fly template info $brickName',
          'Provide all required variables explicitly',
        ]);
        break;

      case MasonErrorType.versionIncompatible:
        strategies.addAll([
          'Check template compatibility: fly template check $brickName',
          'Upgrade CLI: dart pub global activate fly_cli',
          'Upgrade Flutter SDK: flutter upgrade',
          'Try a different template version: fly template list --show-versions',
        ]);
        break;

      case MasonErrorType.versionNotFound:
        strategies.addAll([
          'List available versions: fly template list --show-versions',
          'Use latest version: fly create $brickName',
          'Check template name spelling',
        ]);
        break;

      case MasonErrorType.brickGenerationFailed:
      case MasonErrorType.templateSyntaxError:
      case MasonErrorType.unknown:
        strategies.addAll([
          'Try with --dry-run to preview generation',
          'Check Flutter installation: flutter doctor',
          'Update Fly CLI to latest version',
        ]);
        break;
    }

    return strategies;
  }

  /// Log error with context for debugging
  static void logError(
    Exception error, {
    required String operation,
    required String brickName,
    Map<String, dynamic>? context,
    Logger? logger,
  }) {
    final log = logger ?? Logger();

    log.err('=== Mason Error ===');
    log.err('Operation: $operation');
    log.err('Brick: $brickName');
    log.err('Error: $error');

    if (context != null) {
      log.err('Context:');
      for (final entry in context.entries) {
        log.err('  ${entry.key}: ${entry.value}');
      }
    }

    log.err('Error Type: ${classifyError(error)}');
    log.err('Can Recover: ${canRecover(error)}');

    if (error is MasonException) {
      log.err('Mason Details:');
      log.err('  Message: ${error.message}');
      // MasonException doesn't have a details field, so we'll skip that
    }

    log.err('==================');
  }
}
