import 'dart:io';

import 'package:fly_cli/src/core/command/foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/path_management/resolved_path.dart';
import 'package:fly_cli/src/core/templates/foundation_orchestrator.dart';
import 'package:fly_cli/src/core/templates/generation/generation_request.dart';
import 'package:fly_cli/src/core/templates/generation/generation_service.dart';
import 'package:fly_cli/src/core/templates/generation_variable_builder.dart';
import 'package:fly_cli/src/core/templates/generators/generation_result.dart';
import 'package:fly_cli/src/core/validation/validation_rules.dart';
import 'package:fly_mcp/fly_mcp.dart';
import 'package:mason/mason.dart';

/// Unified generation service implementation.
///
/// Consolidates generation logic for both CLI commands and MCP tools.
/// Uses existing variable builders and generators internally to maintain
/// consistency and avoid code duplication.
class ComponentGenerationService implements GenerationService {
  final CommandContext _context;

  ComponentGenerationService({
    required CommandContext context,
  }) : _context = context;

  @override
  Future<GenerationResult> generateFeature({
    required GenerationRequest request,
    ProgressNotifier? progressNotifier,
  }) async {
    try {
      await progressNotifier?.notify(
        message: 'Preparing to generate feature: ${request.componentName}...',
        percent: 10,
      );

      // Build variables using FeatureVariableBuilder
      final variableBuilder = const FeatureVariableBuilder();
      Map<String, dynamic> rawVars;

      // If context is available (CLI command), use context-based building
      // Otherwise, build from the request map (MCP tool)
      if (request.context != null) {
        // For CLI commands, this should already be done by the command,
        // but we'll handle it here as a fallback
        rawVars = request.toVariableMap();
      } else {
        // For MCP tools, build from the request map
        rawVars = variableBuilder.buildFromMap(request.toVariableMap());
      }

      // Validate variables
      final validationResult = variableBuilder.validate(rawVars);
      if (!validationResult.isValid) {
        return GenerationResult.failure(
          error: 'Validation failed: ${validationResult.errors.join(', ')}',
          data: {
            'component_name': request.componentName,
            'validation_errors': validationResult.errors,
          },
        );
      }

      await progressNotifier?.notify(
        message: 'Validating parameters...',
        percent: 30,
      );

      // Resolve output directory if context is available
      String outputDirectory = request.outputDirectory;
      if (request.context != null) {
        // For CLI commands, resolve using PathResolver
        final outputDirResult =
            await request.context!.pathResolver.resolveOutputDirectory(
          request.context!,
          request.outputDirectory.isEmpty ? null : request.outputDirectory,
        );
        if (!outputDirResult.success) {
          return GenerationResult.failure(
            error:
                'Failed to resolve output directory: ${outputDirResult.errors.join(', ')}',
            data: {
              'component_name': request.componentName,
              'output_directory': request.outputDirectory,
            },
          );
        }
        final resolvedPath = outputDirResult.path as WorkingDirectoryPath;
        outputDirectory = resolvedPath.absolute;
      } else {
        // For MCP tools, use provided directory or fall back to current directory
        if (outputDirectory.isEmpty ||
            (!outputDirectory.startsWith('/') &&
                !outputDirectory.startsWith('\\') &&
                !outputDirectory.contains(':'))) {
          outputDirectory = Directory.current.path;
        }
      }

      await progressNotifier?.notify(
        message: 'Generating feature files...',
        percent: 50,
      );

      // Log generation details
      _context.logger.info('Generating feature component: ${rawVars['name']}');
      _context.logger.info('Feature: ${rawVars['feature']}');
      _context.logger.info('Type: ${rawVars['screen_type']}');
      _context.logger.info('With viewmodel: ${rawVars['with_viewmodel']}');
      _context.logger.info('With tests: ${rawVars['with_tests']}');
      if (rawVars['screen_type'] == 'form') {
        _context.logger.info('With validation: ${rawVars['with_validation']}');
      }
      _context.logger.info('With navigation: ${rawVars['with_navigation']}');

      // Create orchestrator and generate directly
      final orchestrator = TemplateGenerationOrchestrator(
        templateManager: _context.templateManager,
        logger: _context.logger,
      );

      final orchestrationResult = await orchestrator.generate(
        rawVars: rawVars,
        outputDirectory: outputDirectory,
      );

      // Convert orchestration result to generation result
      if (!orchestrationResult.success) {
        return GenerationResult.failure(
          error: orchestrationResult.error ?? 'Failed to generate feature component',
          data: {
            'component_name': rawVars['name'],
            'feature': rawVars['feature'],
            'screen_type': rawVars['screen_type'],
          },
        );
      }

      final files = (orchestrationResult.files ?? <GeneratedFile>[]) as List<GeneratedFile>;
      final result = GenerationResult.success(
        files: files,
        targetDirectory: orchestrationResult.targetDirectory ?? outputDirectory,
        data: {
          'component_name': rawVars['name'],
          'feature': rawVars['feature'],
          'screen_type': rawVars['screen_type'],
          'with_viewmodel': rawVars['with_viewmodel'],
          'with_tests': rawVars['with_tests'],
          'with_validation': rawVars['with_validation'] ?? false,
          'with_navigation': rawVars['with_navigation'] ?? false,
        },
      );

      await progressNotifier?.notify(
        message: result.success
            ? 'Feature generated successfully'
            : 'Feature generation failed',
        percent: result.success ? 100 : 90,
      );

      return result;
    } catch (e, stackTrace) {
      _context.logger.err('Feature generation failed: $e');
      if (_context.verbose) {
        _context.logger.err('Stack trace: $stackTrace');
      }
      return GenerationResult.failure(
        error: 'Failed to generate feature: $e',
        data: {
          'component_name': request.componentName,
          'error_type': e.runtimeType.toString(),
        },
      );
    }
  }

  @override
  Future<GenerationResult> generateService({
    required GenerationRequest request,
    ProgressNotifier? progressNotifier,
  }) async {
    try {
      await progressNotifier?.notify(
        message: 'Preparing to generate service: ${request.componentName}...',
        percent: 10,
      );

      // Build variables using ServiceVariableBuilder
      const variableBuilder = ServiceVariableBuilder();
      Map<String, dynamic> rawVars;

      // If context is available (CLI command), use context-based building
      // Otherwise, build from the request map (MCP tool)
      if (request.context != null) {
        // For CLI commands, this should already be done by the command,
        // but we'll handle it here as a fallback
        rawVars = request.toVariableMap();
      } else {
        // For MCP tools, build from the request map
        rawVars = variableBuilder.buildFromMap(request.toVariableMap());
      }

      // Validate variables
      final validationResult = variableBuilder.validate(rawVars);
      if (!validationResult.isValid) {
        return GenerationResult.failure(
          error: 'Validation failed: ${validationResult.errors.join(', ')}',
          data: {
            'component_name': request.componentName,
            'validation_errors': validationResult.errors,
          },
        );
      }

      await progressNotifier?.notify(
        message: 'Validating parameters...',
        percent: 30,
      );

      // Resolve output directory if context is available
      String outputDirectory = request.outputDirectory;
      if (request.context != null) {
        // For CLI commands, resolve using PathResolver
        final outputDirResult =
            await request.context!.pathResolver.resolveOutputDirectory(
          request.context!,
          request.outputDirectory.isEmpty ? null : request.outputDirectory,
        );
        if (!outputDirResult.success) {
          return GenerationResult.failure(
            error:
                'Failed to resolve output directory: ${outputDirResult.errors.join(', ')}',
            data: {
              'component_name': request.componentName,
              'output_directory': request.outputDirectory,
            },
          );
        }
        final resolvedPath = outputDirResult.path as WorkingDirectoryPath;
        outputDirectory = resolvedPath.absolute;
      } else {
        // For MCP tools, use provided directory or fall back to current directory
        if (outputDirectory.isEmpty ||
            (!outputDirectory.startsWith('/') &&
                !outputDirectory.startsWith('\\') &&
                !outputDirectory.contains(':'))) {
          outputDirectory = Directory.current.path;
        }
      }

      await progressNotifier?.notify(
        message: 'Generating service files...',
        percent: 50,
      );

      // Log generation details
      _context.logger.info('Generating service: ${rawVars['name']}');
      _context.logger.info('Feature: ${rawVars['feature']}');
      _context.logger.info('Type: ${rawVars['service_type']}');
      _context.logger.info('With tests: ${rawVars['with_tests']}');
      _context.logger.info('With mocks: ${rawVars['with_mocks']}');
      _context.logger.info('With retry logic: ${rawVars['with_retry_logic']}');
      _context.logger.info('With caching: ${rawVars['with_caching']}');
      if (rawVars['service_type'] == 'api') {
        _context.logger.info('With interceptors: ${rawVars['with_interceptors']}');
        _context.logger.info('Base URL: ${rawVars['api_base_url']}');
      }

      // Create orchestrator and generate directly
      final orchestrator = TemplateGenerationOrchestrator(
        templateManager: _context.templateManager,
        logger: _context.logger,
      );

      final orchestrationResult = await orchestrator.generate(
        rawVars: rawVars,
        outputDirectory: outputDirectory,
      );

      // Convert orchestration result to generation result
      if (!orchestrationResult.success) {
        return GenerationResult.failure(
          error: orchestrationResult.error ?? 'Failed to generate service',
          data: {
            'component_name': rawVars['name'],
            'feature': rawVars['feature'],
            'service_type': rawVars['service_type'],
          },
        );
      }

      final files = (orchestrationResult.files ?? <GeneratedFile>[]) as List<GeneratedFile>;
      final result = GenerationResult.success(
        files: files,
        targetDirectory: orchestrationResult.targetDirectory ?? outputDirectory,
        data: {
          'component_name': rawVars['name'],
          'feature': rawVars['feature'],
          'service_type': rawVars['service_type'],
          'with_tests': rawVars['with_tests'],
          'with_mocks': rawVars['with_mocks'],
          'with_interceptors': rawVars['with_interceptors'] ?? false,
          'with_retry_logic': rawVars['with_retry_logic'] ?? false,
          'with_caching': rawVars['with_caching'] ?? false,
          if (rawVars['api_base_url'] != null) 'base_url': rawVars['api_base_url'],
        },
      );

      await progressNotifier?.notify(
        message: result.success
            ? 'Service generated successfully'
            : 'Service generation failed',
        percent: result.success ? 100 : 90,
      );

      return result;
    } catch (e, stackTrace) {
      _context.logger.err('Service generation failed: $e');
      if (_context.verbose) {
        _context.logger.err('Stack trace: $stackTrace');
      }
      return GenerationResult.failure(
        error: 'Failed to generate service: $e',
        data: {
          'component_name': request.componentName,
          'error_type': e.runtimeType.toString(),
        },
      );
    }
  }
}

