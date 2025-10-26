import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:fly_cli/src/core/command_foundation/application/command_base.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_middleware.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_result.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_validator.dart';

import '../domain/models/models.dart';
import '../infrastructure/analysis/context_generator.dart';

/// ContextCommand using new architecture
class ContextCommand extends FlyCommand {
  ContextCommand(CommandContext context) : super(context);

  @override
  String get name => 'context';

  @override
  String get description => 'Export project context for AI integration';

  @override
  ArgParser get argParser {
    final parser = super.argParser

      ..addOption(
        'file',
        abbr: 'o',
        help: 'Output file path (default: stdout)',
      )
      ..addFlag(
        'include-code',
        help: 'Include source code in context export',
        negatable: false,
      )
      ..addFlag(
        'include-dependencies',
        help: 'Include dependency analysis in context export',
        negatable: false,
      )..addFlag(
        'include-architecture',
        help: 'Include architecture analysis in context export',
        defaultsTo: true,
      )..addFlag(
        'include-suggestions',
        help: 'Include AI suggestions in context export',
        defaultsTo: true,
      )
      ..addOption(
        'max-files',
        help: 'Maximum number of files to analyze',
        defaultsTo: '50',
      )..addOption(
        'max-file-size',
        help: 'Maximum file size to include (in bytes)',
        defaultsTo: '10000',
      );
    return parser;
  }

  @override
  List<CommandValidator> get validators =>
      [
        FlutterProjectValidator(),
        DirectoryWritableValidator(),
      ];

  @override
  List<CommandMiddleware> get middleware => [
    LoggingMiddleware(),
    MetricsMiddleware(),
  ];

  @override
  Future<CommandResult> execute() async {
    try {
      final outputFile = argResults!['file'] as String?;
      final includeCode = argResults!['include-code'] as bool? ?? false;
      final includeDependencies = argResults!['include-dependencies'] as bool? ??
          false;
      final includeArchitecture = argResults!['include-architecture'] as bool? ??
          true;
      final includeSuggestions = argResults!['include-suggestions'] as bool? ??
          true;
      final maxFiles = int.tryParse(
          argResults!['max-files'] as String? ?? '50') ?? 50;
      final maxFileSize = int.tryParse(
          argResults!['max-file-size'] as String? ?? '10000') ?? 10000;

      logger.info('🔍 Analyzing project context...');

      // Create context generator configuration
      final config = ContextGeneratorConfig(
        includeCode: includeCode,
        includeDependencies: includeDependencies,
        includeArchitecture: includeArchitecture,
        includeSuggestions: includeSuggestions,
        maxFiles: maxFiles,
        maxFileSize: maxFileSize,
        includeTests: false,
        includeGenerated: false,
      );

      // Generate context using the actual context generator
      final contextGenerator = ContextGenerator(logger: logger);
      final projectDir = Directory(context.workingDirectory);

      final contextData = await contextGenerator.generate(projectDir, config);

      // Add command-specific metadata
      final enrichedData = {
        ...contextData,
        'export_config': {
          'include_code': includeCode,
          'include_dependencies': includeDependencies,
          'include_architecture': includeArchitecture,
          'include_suggestions': includeSuggestions,
          'max_files': maxFiles,
          'max_file_size': maxFileSize,
        },
        'export_metadata': {
          'exported_at': DateTime.now().toIso8601String(),
          'cli_version': '0.1.0',
          'working_directory': context.workingDirectory,
          'output_file': outputFile,
        },
      };

      // Write to file if specified
      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsString(
            jsonOutput ? json.encode(enrichedData) :
            aiOutput ? json.encode(enrichedData) :
            _formatHumanOutput(enrichedData)
        );

        return CommandResult.success(
          command: 'context',
          message: 'Context exported to $outputFile',
          data: {
            'output_file': outputFile,
            'file_size_bytes': await file.length(),
            'sections_included': _getIncludedSections(enrichedData),
          },
          nextSteps: [
            NextStep(
              command: 'cat $outputFile',
              description: 'View the exported context file',
            ),
          ],
        );
      }

      return CommandResult.success(
        command: 'context',
        message: 'Context exported successfully',
        data: enrichedData,
        nextSteps: [
          const NextStep(
            command: 'fly context --file=context.json',
            description: 'Save context to a file for later use',
          ),
        ],
      );
    } catch (e) {
      return CommandResult.error(
        message: 'Failed to export context: $e',
        suggestion: 'Check your project structure and try again',
      );
    }
  }

  /// Format context data for human-readable output
  String _formatHumanOutput(Map<String, dynamic> data) {
    final buffer = StringBuffer()
      ..writeln('📋 Project Context Export')..writeln(
          '========================')..writeln();

    if (data.containsKey('project')) {
      final project = data['project'] as Map<String, dynamic>;
      buffer..writeln('📁 Project: ${project['name'] ?? 'Unknown'}')..writeln(
          '📦 Package: ${project['package_name'] ?? 'Unknown'}')..writeln(
          '🏗️  Type: ${project['project_type'] ?? 'Unknown'}')..writeln();
    }

    if (data.containsKey('structure')) {
      final structure = data['structure'] as Map<String, dynamic>;
      buffer..writeln('📂 Structure:')..writeln(
          '  - Directories: ${structure['directory_count'] ?? 0}')..writeln(
          '  - Files: ${structure['file_count'] ?? 0}')..writeln();
    }

    if (data.containsKey('commands')) {
      final commands = data['commands'] as Map<String, dynamic>;
      final available = commands['available'] as List<dynamic>? ?? [];
      buffer..writeln('⚡ Available Commands: ${available.length}')..writeln();
    }

    buffer..writeln('📊 Export Summary:')..writeln(
        '  - Sections: ${data.keys.length}')..writeln(
        '  - Exported: ${data['export_metadata']?['exported_at'] ??
            'Unknown'}')..writeln();

    return buffer.toString();
  }

  /// Get list of included sections for metadata
  List<String> _getIncludedSections(Map<String, dynamic> data) =>
      data.keys.where((key) =>
      !['export_config', 'export_metadata'].contains(key)
      ).toList();
}
