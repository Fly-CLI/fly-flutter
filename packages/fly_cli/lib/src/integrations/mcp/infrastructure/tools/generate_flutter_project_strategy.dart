import 'dart:io';

import 'package:fly_cli/src/cli/infrastructure/validation/validation_rules.dart';
import 'package:fly_cli/src/features/commands/domain/command_context.dart';
import 'package:fly_cli/src/integrations/mcp/application/mcp_tool_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/infrastructure/adapters/generation_mcp_adapter.dart';
import 'package:fly_cli/src/integrations/mcp/infrastructure/errors/mcp_error.dart';
import 'package:fly_cli/src/integrations/mcp/infrastructure/tools/types/generate_project_params.dart';
import 'package:fly_cli/src/integrations/mcp/infrastructure/tools/types/generate_project_result.dart';
import 'package:fly_mcp/fly_mcp.dart';

/// Strategy for fly.generate.project tool
class GenerateFlutterProjectStrategy
    extends McpToolStrategy<GenerateProjectParams, GenerateProjectResult> {
  @override
  String get name => 'fly.generate.project';

  @override
  String get description =>
      'Generate a new Flutter project from templates. '
      'Project names must be valid Dart package names (lowercase, alphanumeric with underscores). '
      'The tool generates a complete Flutter project structure with optional features and platform support.';

  @override
  ObjectSchema get paramsSchema => ObjectSchema(
    description:
        'Parameters for generating a Flutter project. Project names must be valid Dart package names.',
    properties: {
      'projectName': Schema.string(
        description:
            'The name of the project to create. Must be a valid Dart package name: '
            'lowercase, start with a letter, and contain only letters, numbers, and underscores. '
            'Examples: "my_app", "flutter_project", "user_dashboard".',
      ),
      'template': Schema.string(
        description:
            'The template to use for project generation. Defaults to "fly_foundation".',
      ),
      'organization': Schema.string(
        description:
            'Organization identifier (e.g., "com.example"). Defaults to "com.example".',
      ),
      'description': Schema.string(
        description: 'Project description. Optional.',
      ),
      'platforms': Schema.list(
        items: Schema.string(),
        description:
            'Target platforms for the project. Valid values: ios, android, web, macos, windows, linux. '
            'Defaults to ["ios", "android"].',
      ),
      'features': Schema.list(
        items: Schema.string(),
        description:
            'Initial features to generate in the project. Optional list of feature names.',
      ),
      'outputDir': Schema.string(
        description:
            'Output directory where the project will be created. '
            'If not specified, uses the current working directory. '
            'The project will be created in a subdirectory named after the project name.',
      ),
    },
    required: ['projectName'],
    additionalProperties: false,
  );

  @override
  ObjectSchema get resultSchema => ObjectSchema(
    description:
        'Result from generating a project. Contains success status, generated files count, and project path.',
    properties: {
      'success': Schema.bool(
        description: 'Whether the project was generated successfully',
      ),
      'message': Schema.string(
        description: 'Human-readable message describing the operation result',
      ),
      'filesGenerated': Schema.int(
        description: 'Number of files generated for the project',
      ),
      'projectPath': Schema.string(
        description: 'Path to the generated project directory',
      ),
    },
    required: ['success', 'message'],
  );

  @override
  bool get readOnly => false;

  @override
  bool get writesToDisk => true;

  @override
  bool get requiresConfirmation => false;

  @override
  bool get idempotent => false;

  @override
  Duration? get timeout => const Duration(minutes: 5);

  @override
  GenerateProjectParams paramsFromJson(Map<String, Object?> json) {
    return GenerateProjectParams.fromJson(json);
  }

  @override
  TypedToolHandler<GenerateProjectParams, GenerateProjectResult>
  createTypedHandler(
    CommandContext context,
    ResourceRegistry resourceRegistry,
  ) {
    return (params, {cancelToken, progressNotifier}) async {
      cancelToken?.throwIfCancelled();

      // Validate project name
      final validationErrors = <String>[];
      if (params.projectName.isEmpty) {
        validationErrors.add('Missing required parameter: projectName');
      } else {
        final validationResult = NameValidationRule.validateProjectName(
          params.projectName,
        );
        if (!validationResult.isValid) {
          throw McpError.validationError(
            field: 'projectName',
            value: params.projectName,
            reason: validationResult.errors.join('; '),
            tool: name,
            suggestion:
                'Use a valid Dart package name: lowercase, start with a letter, '
                'and contain only letters, numbers, and underscores',
          );
        }
      }

      if (validationErrors.isNotEmpty) {
        throw McpError.invalidParams(
          tool: name,
          errors: validationErrors,
          context: {
            'project_name': params.projectName,
          },
        );
      }

      // Resolve project path
      final projectPathResult = await context.pathResolver.resolveProjectPath(
        context,
        params.projectName,
        params.outputDir,
      );

      if (!projectPathResult.success) {
        throw McpError.fileSystemError(
          operation: 'resolve project path',
          path: params.outputDir ?? Directory.current.path,
          error: projectPathResult.errors.join(', '),
          context: {
            'project_name': params.projectName,
            'output_dir': params.outputDir,
          },
        );
      }

      final projectPath = projectPathResult.path!;

      // Convert features list to feature instances format
      final featureInstances = (params.features ?? []).map((featureName) {
        return {
          'name': featureName,
          'type': 'feature',
          'params': {
            'feature': featureName,
            'screen_type': 'list',
            'with_viewmodel': true,
            'with_tests': true,
            'with_validation': false,
            'with_navigation': false,
          },
        };
      }).toList();

      // If no features specified, add default home feature
      if (featureInstances.isEmpty) {
        featureInstances.add({
          'name': 'home',
          'type': 'feature',
          'params': {
            'feature': 'home',
            'screen_type': 'list',
            'with_viewmodel': true,
            'with_tests': true,
            'with_validation': false,
            'with_navigation': false,
          },
        });
      }

      // Convert MCP params to raw variables
      final rawVars = <String, dynamic>{
        'name': params.projectName,
        'generation_mode': 'project',
        'template': params.template ?? 'fly_foundation',
        'organization': params.organization ?? 'com.example',
        'description': params.description ?? 'A new Flutter project',
        'platforms': params.platforms ?? ['ios', 'android'],
        'features': featureInstances,
        'preset': 'starter',
      };

      // Get MCP adapter from service container
      final adapter = context.getService<GenerationMcpAdapter>();

      // Generate project using new architecture
      final result = await adapter.generateProject(
        projectName: params.projectName,
        template: params.template,
        organization: params.organization,
        description: params.description,
        platforms: params.platforms,
        features: params.features,
        outputDirectory: projectPath.absolute,
      );

      cancelToken?.throwIfCancelled();

      if (!result.success) {
        throw McpError.templateError(
          templateId: params.template ?? 'fly_foundation',
          error: result.error ?? 'Project generation failed',
          variables: rawVars,
          context: {
            'project_name': params.projectName,
            'template': params.template ?? 'fly_foundation',
            'organization': params.organization ?? 'com.example',
            'platforms': params.platforms ?? ['ios', 'android'],
          },
        );
      }

      return GenerateProjectResult(
        success: true,
        message: 'Project generated successfully',
        filesGenerated: result.generatedFiles.length,
        projectPath: projectPath.absolute,
      );
    };
  }
}
