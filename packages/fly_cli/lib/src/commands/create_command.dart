import 'package:mason_logger/mason_logger.dart';

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'package:fly_cli/src/commands/fly_command.dart';
import 'package:fly_cli/src/templates/template_manager.dart';

/// Create a new Flutter project
class CreateCommand extends FlyCommand {
  @override
  String get name => 'create';

  @override
  String get description => 'Create a new Flutter project';

  @override
  ArgParser get argParser {
    final parser = super.argParser;
    parser
      ..addOption(
        'template',
        abbr: 't',
        help: 'Project template to use',
        allowed: ['minimal', 'riverpod'],
        defaultsTo: 'riverpod',
      )
      ..addOption(
        'organization',
        abbr: 'o',
        help: 'Organization identifier',
        defaultsTo: 'com.example',
      )
      ..addMultiOption(
        'platforms',
        help: 'Target platforms',
        allowed: ['ios', 'android', 'web', 'macos', 'windows', 'linux'],
        defaultsTo: ['ios', 'android'],
      )
      ..addFlag(
        'interactive',
        abbr: 'i',
        help: 'Run in interactive mode',
        negatable: false,
      )
      ..addOption(
        'from-manifest',
        help: 'Create project from manifest file',
      );
    return parser;
  }

  @override
  Future<CommandResult> execute() async {
    final projectName = argResults?.rest.isNotEmpty == true ? argResults!.rest.first : null;
    final template = argResults?['template'] as String? ?? 'riverpod';
    final organization = argResults?['organization'] as String? ?? 'com.example';
    final platforms = argResults?['platforms'] as List<String>? ?? ['ios', 'android'];
    final interactive = argResults?['interactive'] as bool? ?? false;
    final manifestPath = argResults?['from-manifest'] as String?;
    final output = argResults?['output'] as String? ?? 'human';

    // Validate project name
    if (projectName == null || projectName.isEmpty) {
      return CommandResult.error(
        message: 'Project name is required',
        suggestion: 'Provide a project name: fly create <project_name>',
      );
    }

    if (!_isValidProjectName(projectName)) {
      return CommandResult.error(
        message: 'Invalid project name: $projectName',
        suggestion: 'Project name must contain only lowercase letters, numbers, and underscores',
      );
    }

    if (planMode) {
      return _createPlan(template, organization, platforms, interactive, manifestPath);
    }

    try {
      final stopwatch = Stopwatch()..start();
      
      if (output != 'json') {
        logger.info('Creating Flutter project...');
        logger.info('Template: $template');
        logger.info('Organization: $organization');
        logger.info('Platforms: ${platforms.join(', ')}');
        
        if (interactive) {
          logger.info('Running in interactive mode');
        }
        
        if (manifestPath != null) {
          logger.info('Using manifest: $manifestPath');
        }
      }

      // Initialize template manager
      final templateManager = TemplateManager(
        templatesDirectory: _findTemplatesDirectory(),
        logger: logger,
      );

      // Create template variables
      final templateVariables = TemplateVariables(
        projectName: projectName,
        organization: organization,
        platforms: platforms,
        description: 'A new Flutter project',
        features: const [],
      );

      // Generate project using template manager
      final generationResult = await templateManager.generateProject(
        templateName: template,
        projectName: projectName,
        outputDirectory: Directory.current.path,
        variables: templateVariables,
        dryRun: false,
      );

      if (generationResult is TemplateGenerationFailure) {
        return CommandResult.error(
          message: 'Failed to generate project: ${generationResult.error}',
          suggestion: 'Check template availability and try again',
        );
      }

      if (generationResult is! TemplateGenerationSuccess) {
        return CommandResult.error(
          message: 'Unexpected generation result',
          suggestion: 'Try again or contact support',
        );
      }

      stopwatch.stop();

      final result = CommandResult.success(
        command: 'create',
        message: 'Project created successfully',
        data: {
          'project_name': projectName,
          'template': template,
          'organization': organization,
          'platforms': platforms,
          'interactive': interactive,
          'manifest_path': manifestPath,
          'files_generated': generationResult.filesGenerated,
          'duration_ms': stopwatch.elapsedMilliseconds,
          'target_directory': generationResult.targetDirectory,
        },
        nextSteps: [
          NextStep(
            command: 'cd $projectName',
            description: 'Navigate to project directory',
          ),
          const NextStep(
            command: 'flutter run',
            description: 'Run the application',
          ),
        ],
      );
      
      return result;
    } catch (e) {
      return CommandResult.error(
        message: 'Failed to create project: $e',
        suggestion: 'Check your Flutter installation and try again',
      );
    }
  }

  CommandResult _createPlan(String template, String organization, List<String> platforms, bool interactive, String? manifestPath) {
    return CommandResult.success(
      command: 'create',
      message: 'Project creation plan',
      data: {
        'template': template,
        'organization': organization,
        'platforms': platforms,
        'interactive': interactive,
        'manifest_path': manifestPath,
        'estimated_files': template == 'minimal' ? 8 : 25,
        'estimated_duration_ms': 15000,
      },
    );
  }

  bool _isValidProjectName(String name) {
    // Project names should be valid Dart package names
    final regex = RegExp(r'^[a-z][a-z0-9_]*$');
    return regex.hasMatch(name) && name.length <= 50;
  }

  String _findTemplatesDirectory() {
    // Try multiple possible template locations
    final possiblePaths = [
      'templates',
      path.join('..', 'templates'),
      path.join('..', '..', 'templates'),
      path.join(Directory.current.path, 'templates'),
      // Look relative to the CLI executable
      path.join(path.dirname(Platform.script.toFilePath()), '..', '..', '..', 'templates'),
      path.join(path.dirname(Platform.script.toFilePath()), '..', '..', 'templates'),
    ];
    
    for (final templatePath in possiblePaths) {
      final dir = Directory(templatePath);
      if (dir.existsSync()) {
        return templatePath;
      }
    }
    
    // Default fallback
    return 'templates';
  }
}